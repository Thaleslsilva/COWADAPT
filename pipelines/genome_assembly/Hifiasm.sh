#!/bin/bash

################################################################################
# HiFiasm Long-Read Genome Assembly (batch mode)
################################################################################
#
# Description:
#   Performs de novo genome assembly from PacBio HiFi / ONT long-read
#   sequencing data using the HiFiasm assembler, looping over every filtered
#   fastq file in READS_DIR.
#
# Version: 2.0
# Author: Genome Assembly Pipeline
# Updated: 2026-07-23
#
# Dependencies:
#   - hifiasm (v0.19 or later)
#   - gzip
#
# Environment Variables:
#   READS_DIR   - Directory containing input .fq.gz files
#                 (default: /home/2.qc_fastq/Filtered_fq)
#   OUTPUT_DIR  - Base output directory (default: ./hifiasm_output)
#
# Usage:
#   OUTPUT_DIR="./hifiasm_output" ./Hifiasm.sh
#
#   Or overriding defaults:
#   READS_DIR="/path/to/reads" OUTPUT_DIR="/path/to/output" ./Hifiasm.sh
#
################################################################################

set -euo pipefail

# Optional: Add custom bin directory to PATH
export PATH="${HOME}/bin:${PATH}"

# Directory holding all filtered fastq files to assemble
READS_DIR="${READS_DIR:-/home/2.qc_fastq/Filtered_fq}"

# Base output directory
OUTPUT_DIR="${OUTPUT_DIR:-./hifiasm_output}"

if [[ ! -d "$READS_DIR" ]]; then
    echo "ERROR: READS_DIR does not exist: $READS_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Collect all filtered fastq files (adjust the pattern here if your naming differs)
shopt -s nullglob
FASTQ_FILES=("$READS_DIR"/*_filt.fq.gz)
shopt -u nullglob

if [[ ${#FASTQ_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No *_filt.fq.gz files found in: $READS_DIR"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found ${#FASTQ_FILES[@]} file(s) to assemble in: $READS_DIR"

for SAMPLE_FILE in "${FASTQ_FILES[@]}"; do
    # Extract sample basename
    SAMPLE_NAME=$(basename "$SAMPLE_FILE" _filt.fq.gz)

    # Create per-sample output directory
    OUTPUT_PATH="${OUTPUT_DIR}/${SAMPLE_NAME}"
    mkdir -p "$OUTPUT_PATH"

    # Run HiFiasm assembly
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting HiFiasm assembly for: $SAMPLE_NAME"
    hifiasm -k 31 -t 32 --ont -o "${OUTPUT_PATH}/${SAMPLE_NAME}.asm" "$SAMPLE_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] HiFiasm assembly completed for: $SAMPLE_NAME"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] All assemblies finished."
