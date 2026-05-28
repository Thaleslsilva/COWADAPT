#!/bin/bash

################################################################################
# Assembly-Based Read Alignment
################################################################################
#
# Description:
#   Aligns filtered long-read sequencing data to corresponding genome assemblies
#   using minimap2 and generates indexed BAM files.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-05-28
#
# Dependencies:
#   - minimap2 (v2.17 or later)
#   - samtools (v1.10 or later)
#
# Environment Variables:
#   BASE_DIR    - Base project directory (default: /home/bt-h1/KG000421)
#   READS_DIR   - Directory containing filtered fastq files
#   ASSEMBLIES_DIR - Directory containing assembly fasta files
#   OUTPUT_DIR  - Output directory for BAM files
#   SAMPLE_PATTERN - Sample name pattern to process (default: COWADAPT_*)
#
# Usage:
#   export BASE_DIR="/home/bt-h1/KG000421"
#   ./align_assmBased_Local.sh
#
#   Or with custom directories:
#   BASE_DIR=/path/to/project READS_DIR=/path/to/reads ASSEMBLIES_DIR=/path/to/assemblies \
#   OUTPUT_DIR=/path/to/output ./align_assmBased_Local.sh
#
################################################################################

set -euo pipefail

# Set default directories
BASE_DIR="${BASE_DIR:-.}"
READS_DIR="${READS_DIR:-${BASE_DIR}/KG000421_fq/2_filtered_fqs}"
ASSEMBLIES_DIR="${ASSEMBLIES_DIR:-${BASE_DIR}/KG000421_fq/4_assembly}"
OUTPUT_DIR="${OUTPUT_DIR:-${BASE_DIR}/KG000421_bam/assmBased}"
SAMPLE_PATTERN="${SAMPLE_PATTERN:-COWADAPT_*}"

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p logs

# Find all sample directories matching the pattern
SAMPLES=($(find "$ASSEMBLIES_DIR" -maxdepth 1 -type d -name "$SAMPLE_PATTERN" -exec basename {} \; | sort))

if [[ ${#SAMPLES[@]} -eq 0 ]]; then
    echo "WARNING: No samples found matching pattern: $SAMPLE_PATTERN"
    exit 0
fi

# Process each sample
for SAMPLE in "${SAMPLES[@]}"; do
    # Define file paths
    ASSEMBLY_FILE="${ASSEMBLIES_DIR}/${SAMPLE}/${SAMPLE}.fasta"
    READS_FILE="${READS_DIR}/${SAMPLE}_filt.fq.gz"
    BAM_FILE="${OUTPUT_DIR}/${SAMPLE}_alnRead.bam"

    # Check if both input files exist
    if [[ -f "$ASSEMBLY_FILE" && -f "$READS_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aligning reads for sample: $SAMPLE"

        # Align reads to assembly and create indexed BAM
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