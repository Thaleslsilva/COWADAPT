#!/bin/bash

################################################################################
# Reference-Based Bam File Coverage
################################################################################
#
# Description:
#   Computes per-base and windowed (100kb) sequencing coverage for the sorted,
#   indexed BAM files produced by Minimap2.sh, using mosdepth.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-08-03
#
# Dependencies:
#   - mosdepth (v0.3 or later)
#
# Environment Variables:
#   BASE_DIR   - Base project directory (default: .)
#   OUTPUT_DIR - Directory containing sorted BAM files (output of Minimap2.sh)
#   COVRG_DIR  - Output directory for coverage reports
#   MAX_JOBS   - Maximum number of samples processed in parallel (default: 10)
#
# Usage:
#   export BASE_DIR="/path/to/project"
#   ./Coverage.sh
#
#   Or with custom directories:
#   BASE_DIR=/path/to/project \
#   OUTPUT_DIR=/path/to/output \
#   COVRG_DIR=/path/to/coverage \
#   ./Coverage.sh
#
################################################################################

set -euo pipefail

MAX_JOBS="${MAX_JOBS:-10}"

############################
# Directories
############################

BASE_DIR="${BASE_DIR:-.}"

OUTPUT_DIR="${OUTPUT_DIR:-${BASE_DIR}/3.align_fastq/Align_ARS2}"
COVRG_DIR="${COVRG_DIR:-${BASE_DIR}/3.align_fastq/Coverage}"

mkdir -p "${COVRG_DIR}"
mkdir -p logs

shopt -s nullglob

############################
# Whole-genome coverage
############################

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

    mosdepth --threads 4 "${COVRG_DIR}/${SAMPLE}" "${BAM_FILE}"
)&

while (( $(jobs -r | wc -l) >= MAX_JOBS ))
do
    sleep 1
done

done

wait

############################
# Windowed coverage (100kb)
############################

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

    mosdepth --by 100000 "${COVRG_DIR}/${SAMPLE}.100kb" "${BAM_FILE}"
)&

while (( $(jobs -r | wc -l) >= MAX_JOBS ))
do
    sleep 1
done

done

wait

echo
echo "Coverage finished."
echo "$(date)"
