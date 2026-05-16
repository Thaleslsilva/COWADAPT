#!/bin/bash

################################################################################
#
# COWADAPT - Utility: Setup All Reference Data
#
# Orchestrates download and setup of all reference data for the COWADAPT
# pipeline. Supports both automated downloads (genome, VEP cache) and
# guides for manual downloads (BovineHD chip, Zebu SNPmap).
#
# Reference Data:
#   1. ARS-UCD2.0 Genome - automated NCBI download
#   2. Reference Index (.fai) - created locally with samtools
#   3. BovineHD Chip Positions - manual download guide
#   4. Zebu SNPmap - manual download guide
#   5. VEP Cache - automated Ensembl download
#
# Usage:
#   bash src/utils/setup_reference_data.sh
#
# Output:
#   All reference files in data/reference/
#   Setup report: printed to stdout
#
# Requirements:
#   - wget (for downloads)
#   - samtools (for indexing)
#   - vep_install (for VEP cache setup)
#
# Time:
#   Genome download: 15-30 minutes
#   VEP cache download: 30-60 minutes
#   Total: 45-90 minutes
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

log_info "============================================================="
log_info "Checking Prerequisites"
log_info "============================================================="

missing_tools=0

if ! command_exists wget; then
    log_error "wget not found in PATH"
    missing_tools=1
else
    log_info "[OK] wget found"
fi

if ! command_exists samtools; then
    log_warn "samtools not found (needed for index creation)"
else
    log_info "[OK] samtools found"
fi

if ! command_exists unzip && ! command_exists tar; then
    log_error "Neither unzip nor tar found"
    missing_tools=1
fi

if [ $missing_tools -ne 0 ]; then
    log_error "Install missing tools first"
    exit 1
fi

echo ""

# ============================================================================
# SETUP ARS-UCD2.0 GENOME
# ============================================================================

log_info "============================================================="
log_info "Step 1: ARS-UCD2.0 Reference Genome"
log_info "============================================================="

GENOME_DIR=$(dirname "$REFERENCE_GENOME")
mkdir -p "$GENOME_DIR"

if [ -f "$REFERENCE_GENOME" ]; then
    log_info "[OK] Genome already present"

    genome_size=$(get_file_size "$REFERENCE_GENOME")
    seq_count=$(grep -c "^>" "$REFERENCE_GENOME" 2>/dev/null || echo "0")

    log_info "  Size: $genome_size"
    log_info "  Sequences: $seq_count"

    if [ ! -f "$REFERENCE_INDEX" ]; then
        log_warn "Index (.fai) missing, will create"
    else
        log_info "[OK] Index also present"
        echo ""
    fi
else
    log_warn "Genome not found, downloading..."
    echo ""

    if [ -x "$SCRIPT_DIR/download_reference_genome.sh" ]; then
        bash "$SCRIPT_DIR/download_reference_genome.sh" "$GENOME_DIR" || {
            log_error "Genome download failed"
            exit 1
        }
    else
        log_error "Download script not found: $SCRIPT_DIR/download_reference_genome.sh"
        exit 1
    fi
fi

# Create index if needed
if [ -f "$REFERENCE_GENOME" ] && [ ! -f "$REFERENCE_INDEX" ]; then
    log_info "Creating samtools index (.fai)..."

    if command_exists samtools; then
        if samtools faidx "$REFERENCE_GENOME" 2>/dev/null; then
            log_info "[OK] Index created: $REFERENCE_INDEX"
            index_size=$(get_file_size "$REFERENCE_INDEX")
            log_info "  Index size: $index_size"
        else
            log_error "Failed to create index"
            exit 1
        fi
    else
        log_error "samtools not found - cannot create index"
        exit 1
    fi
fi

echo ""

# ============================================================================
# SETUP BovineHD CHIP
# ============================================================================

log_info "============================================================="
log_info "Step 2: BovineHD Chip Positions"
log_info "============================================================="

mkdir -p "$(dirname "$BOVINE_HD_BED")"

if [ -f "$BOVINE_HD_BED" ]; then
    log_info "[OK] BovineHD chip file present"

    chip_snps=$(wc -l < "$BOVINE_HD_BED")
    log_info "  File: $BOVINE_HD_BED"
    log_info "  SNPs: $chip_snps"
else
    log_warn "BovineHD chip file NOT found"
    log_info "  Expected: $BOVINE_HD_BED"
    log_info ""
    log_info "Manual action required:"
    log_info "  1. Obtain bovineHD_ARS-UCD2.0.bed file"
    log_info "  2. Save to: $BOVINE_HD_BED"
    log_info ""
    log_info "Sources:"
    log_info "  * Illumina SNP Database (requires registration)"
    log_info "  * Published papers with BovineHD array data"
    log_info "  * Your institution's genomics repository"
    log_info "  * SNPchiMp v3: https://bioinformatics.tecnoparco.org/SNPchimp"
    log_info ""
    log_info "Alternatively, you can create from manifest:"
    log_info "  bash src/05_snp_extraction/map_bovhd_to_arsucd.sh <manifest.csv>"
fi

echo ""

# ============================================================================
# SETUP ZEBU SNPMAP
# ============================================================================

log_info "============================================================="
log_info "Step 3: Zebu-Specificity SNPmap"
log_info "============================================================="

mkdir -p "$(dirname "$ZEBU_SNPMAP")"

if [ -f "$ZEBU_SNPMAP" ]; then
    log_info "[OK] Zebu SNPmap present"

    snpmap_lines=$(wc -l < "$ZEBU_SNPMAP")
    log_info "  File: $ZEBU_SNPMAP"
    log_info "  Entries: $snpmap_lines"
else
    log_warn "Zebu SNPmap NOT found"
    log_info "  Expected: $ZEBU_SNPMAP"
    log_info ""
    log_info "Manual action required:"
    log_info "  1. Obtain SNPmap_IND_TAU_ARS.txt"
    log_info "  2. Save to: $ZEBU_SNPMAP"
    log_info ""
    log_info "Source (Kasarapu et al. 2017):"
    log_info "  DOI: https://doi.org/10.1038/ncomms14482"
    log_info "  Supplementary Data 1"
    log_info ""
    log_info "Zebu-Specificity Analysis Requirements:"
    log_info "  * Indicus-specific SNPs (IND)"
    log_info "  * Taurus-specific SNPs (TAU)"
    log_info "  * For Step 7 analysis"
fi

echo ""

# ============================================================================
# SETUP VEP CACHE
# ============================================================================

log_info "============================================================="
log_info "Step 4: VEP Annotation Cache"
log_info "============================================================="

mkdir -p "$VEP_CACHE_DIR"

if [ -d "$VEP_SPECIES_CACHE" ]; then
    log_info "[OK] VEP cache already present"

    cache_size=$(du -sh "$VEP_SPECIES_CACHE" 2>/dev/null | awk '{print $1}' || echo "unknown")
    cache_files=$(find "$VEP_SPECIES_CACHE" -type f 2>/dev/null | wc -l || echo "0")

    log_info "  Location: $VEP_SPECIES_CACHE"
    log_info "  Size: $cache_size"
    log_info "  Files: $cache_files"
else
    log_warn "VEP cache not found"
    log_info "  Location: $VEP_SPECIES_CACHE"
    log_info ""
    log_info "Setup option 1: Automated setup (recommended)"
    log_info "  bash src/04_functional_annotation/install_and_run_vep.sh"
    log_info ""
    log_info "Setup option 2: Manual with vep_install"
    log_info "  vep_install --AUTO cf --SPECIES bos_taurus \\"
    log_info "    --ASSEMBLY ARS-UCD2.0 --CACHEDIR $VEP_CACHE_DIR/"
    log_info ""
    log_info "Note: Download size ~15-20 GB, time ~30-60 minutes"
fi

echo ""

# ============================================================================
# SUMMARY REPORT
# ============================================================================

log_info "============================================================="
log_info "Reference Data Status"
log_info "============================================================="

echo ""

# Check each component
all_ready=1

# ARS-UCD2.0
if [ -f "$REFERENCE_GENOME" ] && [ -f "$REFERENCE_INDEX" ]; then
    log_info "[OK] ARS-UCD2.0 Genome: READY"
else
    log_warn "  ARS-UCD2.0 Genome: MISSING or incomplete"
    all_ready=0
fi

# BovineHD
if [ -f "$BOVINE_HD_BED" ]; then
    log_info "[OK] BovineHD Chip: READY (optional)"
else
    log_warn "  BovineHD Chip: MISSING (optional, needed for Step 5)"
    all_ready=0
fi

# Zebu SNPmap
if [ -f "$ZEBU_SNPMAP" ]; then
    log_info "[OK] Zebu SNPmap: READY (optional)"
else
    log_warn "  Zebu SNPmap: MISSING (optional, needed for Step 7)"
fi

# VEP Cache
if [ -d "$VEP_SPECIES_CACHE" ]; then
    log_info "[OK] VEP Cache: READY (optional)"
else
    log_warn "  VEP Cache: MISSING (optional, needed for Step 4)"
fi

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

if [ $all_ready -eq 1 ]; then
    log_info "============================================================="
    log_info "Reference Data Setup Complete!"
    log_info "============================================================="
    log_info ""
    log_info "Next step: Initialize pipeline and start analysis"
    log_info "  bash src/utils/init_pipeline.sh"
else
    log_info "============================================================="
    log_warn "Reference Data Setup - Some items incomplete"
    log_info "============================================================="
    log_info ""
    log_info "Required files are ready. Optional files can be added later."
    log_info "Run init_pipeline.sh to start analysis:"
    log_info "  bash src/utils/init_pipeline.sh"
fi

echo ""

################################################################################
# END OF SCRIPT
################################################################################
