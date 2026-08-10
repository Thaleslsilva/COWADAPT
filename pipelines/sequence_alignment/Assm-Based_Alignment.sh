#!/bin/bash

################################################################################
# Assembly-Based Read Alignment
################################################################################
#
# Description:
#   Aligns filtered long-read sequencing data to corresponding genome assemblies
#   using minimap2 and generates indexed BAM files.
#
# Version: 1.1
# Author: Genome Assembly Pipeline
# Updated: 2026-08-07
#
# Dependencies:
#   - minimap2 (v2.17 or later)
#   - samtools (v1.10 or later)
#
# Environment Variables:
#   BASE_DIR        - Base project directory (default: .)
#   READS_DIR       - Directory containing filtered fastq files (REQUIRED, no default -
#                      not present under BASE_DIR in the current tree, so it must be set explicitly)
#   ASSEMBLIES_DIR  - Directory containing per-sample assembly folders (default: BASE_DIR/hifiasm_output)
#   OUTPUT_DIR      - Output directory for BAM files (default: BASE_DIR/alignments/assmBased)
#   SAMPLE_PATTERN  - Sample folder pattern to process (default: unespONT_*)
#
# Usage:
#   export BASE_DIR="/home/breeder9/gen_alin_novo/seq_Holanda/4.genome_assembly"
#   export READS_DIR="/home/breeder9/gen_alin_novo/seq_Holanda/2.qc_fastq/Filtered_fq"
#   ./Minimap2.sh
#
################################################################################

set -euo pipefail

# Set default directories based on the hifiasm_output layout
BASE_DIR="${BASE_DIR:-.}"
ASSEMBLIES_DIR="${ASSEMBLIES_DIR:-${BASE_DIR}/hifiasm_output}"
OUTPUT_DIR="${OUTPUT_DIR:-${BASE_DIR}/alignments/assmBased}"
SAMPLE_PATTERN="${SAMPLE_PATTERN:-unespONT_*}"

# READS_DIR has no safe default: no fastq directory exists under BASE_DIR
# in the provided tree, so fail loudly instead of guessing a wrong path
READS_DIR="${READS_DIR:?ERROR: READS_DIR must be set explicitly - no filtered fastq directory found in tree.txt}"

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p logs

# Find all sample directories matching the pattern (e.g. unespONT_001 ... unespONT_020)
SAMPLES=($(find "$ASSEMBLIES_DIR" -maxdepth 1 -type d -name "$SAMPLE_PATTERN" -exec basename {} \; | sort))

if [[ ${#SAMPLES[@]} -eq 0 ]]; then
    echo "WARNING: No samples found matching pattern: $SAMPLE_PATTERN in $ASSEMBLIES_DIR"
    exit 0
fi

# Process each sample
for SAMPLE in "${SAMPLES[@]}"; do
    # Define file paths
    # Assembly target is the primary contig fasta produced by GFA2FASTA_conversion.sh,
    # gzip-compressed (minimap2 reads .gz references natively, no manual decompression needed)
    ASSEMBLY_FILE="${ASSEMBLIES_DIR}/${SAMPLE}/${SAMPLE}.1ctg.fasta.gz"
    READS_FILE="${READS_DIR}/${SAMPLE}_filt.fq.gz"
    BAM_FILE="${OUTPUT_DIR}/${SAMPLE}_alnRead.bam"

    # Check if both input files exist
    if [[ -f "$ASSEMBLY_FILE" && -f "$READS_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aligning reads for sample: $SAMPLE"

        # Align reads to assembly and create sorted BAM
        minimap2 -t 64 -ax map-ont "$ASSEMBLY_FILE" "$READS_FILE" | \
            samtools sort -@ 8 -o "$BAM_FILE"
        samtools index "$BAM_FILE"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Alignment completed for sample: $SAMPLE"
    else
        echo "ERROR: Missing files for sample: $SAMPLE"
        echo "  Assembly: $ASSEMBLY_FILE (exists: $(test -f "$ASSEMBLY_FILE" && echo "yes" || echo "no"))"
        echo "  Reads:    $READS_FILE (exists: $(test -f "$READS_FILE" && echo "yes" || echo "no"))"
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] All samples processed."