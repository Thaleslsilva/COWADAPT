#!/bin/bash

################################################################################
# Assembly Quality Control (QC) Statistics
################################################################################
#
# Description:
#   Generates comprehensive quality control statistics for genome assemblies
#   using seqkit. Computes sequence length distribution, GC content, N-count,
#   and other assembly metrics.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-05-28
#
# Dependencies:
#   - seqkit (v2.8.2 or later)
#
# Environment Variables:
#   ASSEMBLY_DIR  - Directory containing assembly fasta files (required)
#   OUTPUT_DIR    - Output directory for statistics files (default: current dir)
#   SAMPLE_LIST   - File containing sample IDs, one per line
#                   If not provided, processes single sample from argument
#   THREADS       - Number of parallel threads (default: 4)
#
# Usage:
#   Single sample:
#   ASSEMBLY_DIR="/path/to/assemblies" ./assem_QC.sh SAMPLE_NAME
#
#   Multiple samples from file:
#   ASSEMBLY_DIR="/path/to/assemblies" SAMPLE_LIST="samples.txt" ./assem_QC.sh
#
#   Examples:
#   ./assem_QC.sh COWADAPT_001
#   ASSEMBLY_DIR="./hifiasm_output" SAMPLE_LIST="allSamples.txt" ./assem_QC.sh
#
################################################################################

set -euo pipefail

# Optional: Add custom bin directory to PATH
export PATH="${HOME}/bin:${PATH}"

# Configuration
ASSEMBLY_DIR="${ASSEMBLY_DIR:-.}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
THREADS="${THREADS:-4}"
SAMPLE_LIST="${SAMPLE_LIST:-}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Process samples
if [[ -n "$SAMPLE_LIST" && -f "$SAMPLE_LIST" ]]; then
    # Process multiple samples from file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing samples from list: $SAMPLE_LIST"

    while IFS= read -r SAMPLE_ID; do
        # Skip empty lines and comments
        [[ -z "$SAMPLE_ID" || "$SAMPLE_ID" =~ ^# ]] && continue

        ASSEMBLY_FILE="${ASSEMBLY_DIR}/${SAMPLE_ID}/${SAMPLE_ID}.fasta"

        if [[ -f "$ASSEMBLY_FILE" ]]; then
            OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE_ID}_assm_stats.tsv"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Computing statistics for: $SAMPLE_ID"

            seqkit stats -a -T "$ASSEMBLY_FILE" -j "$THREADS" > "$OUTPUT_FILE"

            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Statistics saved to: $OUTPUT_FILE"
        else
            echo "ERROR: Assembly file not found: $ASSEMBLY_FILE"
        fi
    done < "$SAMPLE_LIST"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All samples processed."

elif [[ $# -gt 0 ]]; then
    # Process single sample from command-line argument
    SAMPLE_ID="$1"
    ASSEMBLY_FILE="${ASSEMBLY_DIR}/${SAMPLE_ID}/${SAMPLE_ID}.fasta"

    if [[ -f "$ASSEMBLY_FILE" ]]; then
        OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE_ID}_assm_stats.tsv"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Computing statistics for: $SAMPLE_ID"

        seqkit stats -a -T "$ASSEMBLY_FILE" -j "$THREADS" > "$OUTPUT_FILE"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Statistics saved to: $OUTPUT_FILE"
    else
        echo "ERROR: Assembly file not found: $ASSEMBLY_FILE"
        exit 1
    fi
else
    echo "ERROR: No samples specified."
    echo "Usage: $0 <sample_id>"
    echo "   or: SAMPLE_LIST=samples.txt $0"
    exit 1
fi
