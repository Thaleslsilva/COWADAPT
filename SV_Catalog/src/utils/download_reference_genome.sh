#!/bin/bash

################################################################################
#
# COWADAPT - Utility: Download ARS-UCD2.0 Reference Genome
#
# Downloads and validates the Bos taurus ARS-UCD2.0 reference genome from
# NCBI GenBank. Creates samtools index (.fai) for efficient access.
#
# Source: NCBI GenBank GCF_002263795.3
# URL: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_002263795.3/
#
# Usage:
#   bash src/utils/download_reference_genome.sh
#   bash src/utils/download_reference_genome.sh [output_directory]
#
# Example:
#   bash src/utils/download_reference_genome.sh
#   bash src/utils/download_reference_genome.sh data/reference
#
# Output:
#   Genome FASTA:   data/reference/ARS-UCD2.0_genomic.fa
#   Index file:     data/reference/ARS-UCD2.0_genomic.fa.fai
#   Download log:   LOGS_DIR/genome_download.log
#
# Requirements:
#   - wget (for downloading)
#   - unzip or tar (for extracting)
#   - samtools (for indexing)
#   - 3-4 GB disk space
#   - Internet connection
#
# Notes:
#   - Download size: ~900 MB compressed
#   - Extracted size: ~2.7 GB
#   - Index size: ~30 KB
#   - Downloads from official NCBI source
#
################################################################################

set -euo pipefail

# ============================================================================
# SOURCE CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -f "$PROJECT_ROOT/config/pipeline.config" ]; then
    echo "[ERROR] Configuration file not found: $PROJECT_ROOT/config/pipeline.config"
    exit 1
fi

source "$PROJECT_ROOT/config/pipeline.config"

# ============================================================================
# VALIDATE PREREQUISITES
# ============================================================================

log_info "Checking prerequisites..."

if ! command_exists wget; then
    log_error "wget not found in PATH"
    log_error "Install with: apt-get install wget (or brew install wget on macOS)"
    exit 1
fi

if ! command_exists samtools; then
    log_warn "samtools not found - index will need to be created manually"
fi

if ! command_exists unzip && ! command_exists tar; then
    log_error "Neither unzip nor tar found in PATH"
    exit 1
fi

log_info "[OK] Prerequisites verified"

echo ""

# ============================================================================
# PREPARE CONFIGURATION
# ============================================================================

GENOME_NAME="ARS-UCD2.0_genomic.fa"
NCBI_ACCESSION="GCF_002263795.3"
DOWNLOAD_URL="https://www.ncbi.nlm.nih.gov/datasets/api/v1/genome/accession/$NCBI_ACCESSION/download?include_annotation_type=FASTA&taxon_filter=Bos_taurus"

# Create output directory from config
GENOME_DIR=$(dirname "$REFERENCE_GENOME")
mkdir -p "$GENOME_DIR"
mkdir -p "${LOGS_DIR}"

log_file="${LOGS_DIR}/genome_download.log"

# ============================================================================
# DISPLAY INFORMATION
# ============================================================================

log_info "============================================================="
log_info "Download ARS-UCD2.0 Reference Genome"
log_info "============================================================="

log_info "Source: NCBI GenBank ($NCBI_ACCESSION)"
log_info "Output directory: $GENOME_DIR"
log_info "Genome file: $GENOME_NAME"
log_info "Expected size: ~2.7 GB (uncompressed)"

echo ""

# ============================================================================
# CHECK IF GENOME ALREADY EXISTS
# ============================================================================

GENOME_PATH="$GENOME_DIR/$GENOME_NAME"

if [ -f "$GENOME_PATH" ]; then
    log_info "[OK] Genome file already exists: $GENOME_PATH"

    file_size=$(get_file_size "$GENOME_PATH")
    seq_count=$(grep -c "^>" "$GENOME_PATH" || echo "0")

    log_info "  File size: $file_size"
    log_info "  Sequences: $seq_count"

    # Check for index
    if [ -f "${GENOME_PATH}.fai" ]; then
        log_info "[OK] Index file also exists"
        log_info "Genome is ready to use!"
        echo ""
        exit 0
    else
        log_warn "Index file (.fai) not found"
        log_info "Creating index..."
    fi
else
    log_info "Genome file not found, will download"
fi

echo ""

# ============================================================================
# DOWNLOAD GENOME
# ============================================================================

log_info "============================================================="
log_info "Downloading genome (this may take 10-30 minutes)"
log_info "============================================================="

log_info "URL: $DOWNLOAD_URL"

cd "$GENOME_DIR"

# Download with retry logic
if wget \
    -c "$DOWNLOAD_URL" \
    -O "${NCBI_ACCESSION}.zip" \
    --timeout=30 \
    --retry-connrefused \
    --waitretry=3 \
    --continue \
    2>&1 | tee -a "$log_file"
then
    log_info "[OK] Download successful"
else
    log_error "Download failed!"
    log_error "Try manually downloading from:"
    log_error "https://www.ncbi.nlm.nih.gov/datasets/genome/$NCBI_ACCESSION/"
    exit 1
fi

echo ""

# ============================================================================
# EXTRACT GENOME
# ============================================================================

log_info "Extracting genome from archive..."

# Try unzip first, fallback to tar
if command_exists unzip; then
    if unzip -j "${NCBI_ACCESSION}.zip" "*.fna" -d . 2>&1 | head -5 | tee -a "$log_file"; then
        log_debug "unzip extraction completed"
    fi
else
    if tar -xzf "${NCBI_ACCESSION}.zip" --wildcards "*.fna" -C . 2>&1 | head -5 | tee -a "$log_file"; then
        log_debug "tar extraction completed"
    fi
fi

# Find extracted FASTA file
FASTA_FILE=$(find . -maxdepth 1 -name "*.fna" -o -name "*.fa" -o -name "*.fasta" | head -1)

if [ -z "$FASTA_FILE" ]; then
    log_error "Could not find FASTA file in archive!"
    log_error "Archive contents:"
    unzip -l "${NCBI_ACCESSION}.zip" 2>/dev/null | grep -E "\.fna|\.fa" || true
    exit 1
fi

log_info "Found: $FASTA_FILE"

# Rename to standard name
if [ "$FASTA_FILE" != "$GENOME_NAME" ]; then
    mv "$FASTA_FILE" "$GENOME_NAME"
    log_info "Renamed to: $GENOME_NAME"
fi

echo ""

# ============================================================================
# VERIFY GENOME
# ============================================================================

log_info "Verifying genome file..."

if [ ! -s "$GENOME_NAME" ]; then
    log_error "Genome file is empty!"
    exit 1
fi

file_size=$(get_file_size "$GENOME_NAME")
seq_count=$(grep -c "^>" "$GENOME_NAME" || echo "0")

log_info "[OK] Genome verified"
log_info "  File size: $file_size"
log_info "  Sequences: $seq_count"

# Check header for species verification
HEADER=$(head -1 "$GENOME_NAME")
if [[ "$HEADER" == *"Bos taurus"* ]] || [[ "$HEADER" == *"cattle"* ]] || [[ "$HEADER" == *"ARS-UCD"* ]]; then
    log_info "[OK] Verified: Bos taurus (cattle) ARS-UCD assembly"
else
    log_warn "Could not automatically verify species from header"
    log_info "First line: $HEADER"
fi

echo ""

# ============================================================================
# CREATE SAMTOOLS INDEX
# ============================================================================

log_info "Creating samtools index (.fai)..."

if command_exists samtools; then
    if samtools faidx "$GENOME_NAME" 2>&1 | tee -a "$log_file"; then
        log_info "[OK] Index created: $GENOME_NAME.fai"

        if [ -f "$GENOME_NAME.fai" ]; then
            index_size=$(get_file_size "$GENOME_NAME.fai")
            log_info "  Index size: $index_size"
        fi
    else
        log_error "Failed to create index!"
        exit 1
    fi
else
    log_warn "samtools not found - index cannot be created automatically"
    log_warn "Create index manually with:"
    log_warn "  samtools faidx $GENOME_DIR/$GENOME_NAME"
fi

echo ""

# ============================================================================
# CLEANUP
# ============================================================================

log_info "Cleaning up temporary files..."
rm -f "${NCBI_ACCESSION}.zip"
log_info "[OK] Cleanup complete"

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

log_info "============================================================="
log_info "Genome Download Complete!"
log_info "============================================================="

log_info "Reference genome is ready:"
log_info "  FASTA: $GENOME_PATH"
log_info "  Index: ${GENOME_PATH}.fai"
log_info "  Size: $file_size"

echo ""
log_info "Next steps:"
log_info "  1. Download BovineHD chip reference"
log_info "     See: docs/DATA_SOURCES.md"
log_info "  2. Initialize pipeline"
log_info "     bash src/utils/init_pipeline.sh"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
