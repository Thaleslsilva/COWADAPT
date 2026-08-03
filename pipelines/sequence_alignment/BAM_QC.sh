#!/bin/bash

################################################################################
# Reference-Based Bam File Quality Control
################################################################################
#
# Description:
#   Runs quality-control metrics (flagstat, stats, idxstats) on the sorted,
#   indexed BAM files produced by Minimap2.sh.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-08-03
#
# Dependencies:
#   - samtools (v1.10 or later)
#
# Environment Variables:
#   BASE_DIR   - Base project directory (default: .)
#   OUTPUT_DIR - Directory containing sorted BAM files (output of Minimap2.sh)
#   QLTCTR_DIR - Output directory for QC reports
#   MAX_JOBS   - Maximum number of samples processed in parallel (default: 10)
#
# Usage:
#   export BASE_DIR="/path/to/project"
#   ./BAM_QC.sh
#
#   Or with custom directories:
#   BASE_DIR=/path/to/project \
#   OUTPUT_DIR=/path/to/output \
#   QLTCTR_DIR=/path/to/qc \
#   ./BAM_QC.sh
#
################################################################################

set -euo pipefail

MAX_JOBS="${MAX_JOBS:-10}"

############################
# Directories
############################

BASE_DIR="${BASE_DIR:-.}"

OUTPUT_DIR="${OUTPUT_DIR:-${BASE_DIR}/3.align_fastq/Align_ARS2}"
QLTCTR_DIR="${QLTCTR_DIR:-${BASE_DIR}/3.align_fastq/Qlty_Ctrl}"

mkdir -p "${QLTCTR_DIR}"
mkdir -p logs

############################
# Process each BAM
############################

shopt -s nullglob

for BAM_FILE in "${OUTPUT_DIR}"/*.sorted.bam
do
(
    SAMPLE=$(basename "$BAM_FILE")
    SAMPLE=${SAMPLE%.sorted.bam}

    echo "====================================================="
    echo "$(date)"
    echo "Sample  : ${SAMPLE}"
    echo "Bam File: ${BAM_FILE}"
    echo "====================================================="

    samtools flagstat "${BAM_FILE}" > "${QLTCTR_DIR}/${SAMPLE}.flagstat"
    samtools stats "${BAM_FILE}" > "${QLTCTR_DIR}/${SAMPLE}.stat"
    samtools idxstats "${BAM_FILE}" > "${QLTCTR_DIR}/${SAMPLE}.idxstat"
)&

while (( $(jobs -r | wc -l) >= MAX_JOBS ))
do
    sleep 1
done

done

wait

echo
echo "BAM QC finished."
echo "$(date)"
