#!/bin/bash

################################################################################
# GFA to FASTA Conversion and Indexing
################################################################################
#
# Description:
#   Converts graph assembly format (GFA) files to FASTA sequences and compresses
#   them with bgzip. Automatically generates FASTA indices (.fai and .gzi files)
#   for both haplotype1 (hap1) and haplotype2 (hap2) outputs. Useful for
#   converting hifiasm or other graph-based assembler outputs.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-05-28
#
# Dependencies:
#   - gfatools (v0.4.1 or later)
#   - bgzip (from htslib)
#   - samtools (v1.10 or later) - for FASTA indexing
#
# Environment Variables:
#   BASE_DIR      - Directory containing sample subdirectories (required)
#   GFA_PATTERN_HAP1 - File pattern for haplotype1 (default: *.asm.bp.hap1.p_ctg.gfa)
#   GFA_PATTERN_HAP2 - File pattern for haplotype2 (default: *.asm.bp.hap2.p_ctg.gfa)
#   FORCE_OVERWRITE - Overwrite existing compressed files (default: false)
#
# Usage:
#   export BASE_DIR="/path/to/samples"
#   ./conv_gfa2fa.sh
#
#   Or with custom patterns:
#   BASE_DIR="/path/to/samples" \
#   GFA_PATTERN_HAP1="*.hap1.gfa" \
#   GFA_PATTERN_HAP2="*.hap2.gfa" \
#   ./conv_gfa2fa.sh
#
# Output:
#   For each sample and haplotype:
#   - {sample}.hap1.fasta.gz  / {sample}.hap2.fasta.gz  - Compressed FASTA
#   - {sample}.hap1.fasta.gz.fai / {sample}.hap2.fasta.gz.fai - FASTA index
#   - {sample}.hap1.fasta.gz.gzi / {sample}.hap2.fasta.gz.gzi - Compressed index
#
################################################################################

set -euo pipefail

# Configuration
BASE_DIR="${BASE_DIR:-.}"
GFA_PATTERN_HAP1="${GFA_PATTERN_HAP1:-*.asm.bp.hap1.p_ctg.gfa}"
GFA_PATTERN_HAP2="${GFA_PATTERN_HAP2:-*.asm.bp.hap2.p_ctg.gfa}"
FORCE_OVERWRITE="${FORCE_OVERWRITE:-false}"

if [[ ! -d "$BASE_DIR" ]]; then
    echo "ERROR: Base directory not found: $BASE_DIR"
    exit 1
fi

# Counter for processed files
PROCESSED_HAP1=0
PROCESSED_HAP2=0
NOT_FOUND_HAP1=0
NOT_FOUND_HAP2=0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting GFA to FASTA conversion"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Base directory: $BASE_DIR"

# Function to process GFA file
process_gfa_file() {
    local gfa_file="$1"
    local haplotype="$2"

    if [[ ! -f "$gfa_file" ]]; then
        return 1
    fi

    local sample_dir=$(dirname "$gfa_file")
    local sample_name=$(basename "$sample_dir")
    local output_file="${sample_dir}/${sample_name}.${haplotype}.fasta.gz"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Converting $haplotype for: $sample_name"
    echo "  Input:  $gfa_file"
    echo "  Output: $output_file"

    # Convert GFA to FASTA and compress
    gfatools gfa2fa "$gfa_file" | bgzip -f -c > "$output_file"

    # Generate indices (.fai and .gzi)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Indexing: $output_file"
    samtools faidx "$output_file"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed for $sample_name ($haplotype)"
    return 0
}

# Process haplotype 1 files
echo ""
echo "Processing haplotype 1 (hap1) files..."
for sample_dir in "$BASE_DIR"/*/; do
    sample_name=$(basename "$sample_dir")

    # Build GFA file path with pattern
    gfa_file=$(find "$sample_dir" -maxdepth 1 -name "$GFA_PATTERN_HAP1" | head -1)

    if process_gfa_file "$gfa_file" "hap1"; then
        ((PROCESSED_HAP1++))
    else
        echo "WARNING: Haplotype 1 GFA file not found for: $sample_name"
        ((NOT_FOUND_HAP1++))
    fi
done

# Process haplotype 2 files
echo ""
echo "Processing haplotype 2 (hap2) files..."
for sample_dir in "$BASE_DIR"/*/; do
    sample_name=$(basename "$sample_dir")

    # Build GFA file path with pattern
    gfa_file=$(find "$sample_dir" -maxdepth 1 -name "$GFA_PATTERN_HAP2" | head -1)

    if process_gfa_file "$gfa_file" "hap2"; then
        ((PROCESSED_HAP2++))
    else
        echo "WARNING: Haplotype 2 GFA file not found for: $sample_name"
        ((NOT_FOUND_HAP2++))
    fi
done

# Summary
echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Conversion pipeline completed"
echo "Summary:"
echo "  Haplotype 1: $PROCESSED_HAP1 processed, $NOT_FOUND_HAP1 not found"
echo "  Haplotype 2: $PROCESSED_HAP2 processed, $NOT_FOUND_HAP2 not found"
