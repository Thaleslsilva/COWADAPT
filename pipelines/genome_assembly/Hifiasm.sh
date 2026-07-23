#!/bin/bash

################################################################################
# HiFiasm Long-Read Genome Assembly
################################################################################
#
# Description:
#   Performs de novo genome assembly from PacBio HiFi long-read sequencing data
#   using the HiFiasm assembler.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-05-28
#
# Dependencies:
#   - hifiasm (v0.19 or later)
#   - gzip
#
# Environment Variables:
#   READS_DIR   - Directory containing input .fq.gz files (default: ./reads)
#   SAMPLE_FILE - Input filtered fastq file
#   OUTPUT_DIR  - Base output directory (default: ./hifiasm_output)
#
# Usage:
#   export READS_DIR="/path/to/reads"
#   export OUTPUT_DIR="/path/to/output"
#   ./hifiasm.sh /path/to/sample_filt.fq.gz
#
#   Or with environment variables:
#   SAMPLE_FILE="/cluster/work/pausch/thales/KG000421/KG000421_fq/2_filtered_fqs/COWADAPT_004_filt.fq.gz" \
#   OUTPUT_DIR="/cluster/work/pausch/thales/KG000421/KG000421_fq/4_assembly/hifiasm_output" ./hifiasm.sh
#
################################################################################

set -euo pipefail

# Optional: Add custom bin directory to PATH
export PATH="${HOME}/bin:${PATH}"

# Input sample file (can be passed as argument or environment variable)
SAMPLE_FILE="${1:-${SAMPLE_FILE:-}}"

if [[ -z "$SAMPLE_FILE" ]]; then
    echo "ERROR: No input file specified."
    echo "Usage: $0 <fastq_file>"
    exit 1
fi

# Set default directories if not already defined
OUTPUT_DIR="${OUTPUT_DIR:-.}"

# Extract sample basename
SAMPLE_NAME=$(basename "$SAMPLE_FILE" _filt.fq.gz)

# Create output directory
OUTPUT_PATH="${OUTPUT_DIR}/${SAMPLE_NAME}"
mkdir -p "$OUTPUT_PATH"

# Run HiFiasm assembly
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting HiFiasm assembly for: $SAMPLE_NAME"
hifiasm -k 31 -t 32 --ont -o "${OUTPUT_PATH}/${SAMPLE_NAME}.asm" "$SAMPLE_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] HiFiasm assembly completed for: $SAMPLE_NAME"

