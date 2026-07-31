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
#   BASE_DIR       - Base project directory (default: /home/...)
#   READS_DIR      - Directory containing filtered fastq files
#   REFER_DIR      - Directory containing genome reference fasta files
#   OUTPUT_DIR     - Output directory for BAM files
#   SAMPLE_PATTERN - Sample name pattern to process (default: ONT_*)
#
# Usage:
#   export BASE_DIR="/path/to/project"
#   ./Minimap2.sh
#
#   Or with custom directories:
#   BASE_DIR=/path/to/project \
#   READS_DIR=/path/to/reads \
#   REFER_DIR=/path/to/genome_reference \
#   OUTPUT_DIR=/path/to/output \
#   ./align_assmBased_Local.sh
#
################################################################################

set -euo pipefail

############################
# Directories
############################

BASE_DIR="${BASE_DIR:-.}"

READS_DIR="${READS_DIR:-${BASE_DIR}/2.qc_fastq/Filtered_fq}"
REFER_DIR="${REFER_DIR:-${BASE_DIR}/genRef}"
OUTPUT_DIR="${OUTPUT_DIR:-${BASE_DIR}/4.align_fastq/Align_ARS2}"

REFERENCE="${REFERENCE:-${REFER_DIR}/ARS-UCD2.0_genomic.fa}"

THREADS="${THREADS:-64}"

mkdir -p "${OUTPUT_DIR}"
mkdir -p logs

############################
# Check reference
############################

if [[ ! -f "$REFERENCE" ]]; then
    echo "Reference genome not found:"
    echo "$REFERENCE"
    exit 1
fi

############################
# Process each FASTQ
############################

shopt -s nullglob

for READS_FILE in "${READS_DIR}"/*_filt.fq.gz
do

    SAMPLE=$(basename "$READS_FILE")
    SAMPLE=${SAMPLE%_filt.fq.gz}

    BAM_FILE="${OUTPUT_DIR}/${SAMPLE}.sorted.bam"

    echo "====================================================="
    echo "$(date)"
    echo "Sample: ${SAMPLE}"
    echo "Reads : ${READS_FILE}"
    echo "Output: ${BAM_FILE}"
    echo "====================================================="

    minimap2 \
        -t ${THREADS} \
        -ax map-ont \
        "${REFERENCE}" \
        "${READS_FILE}" | \
    samtools sort \
        -@ ${THREADS} \
        -o "${BAM_FILE}" -

    samtools index -@ ${THREADS} "${BAM_FILE}"

    samtools flagstat "${BAM_FILE}" > "${OUTPUT_DIR}/${SAMPLE}.flagstat"

done

echo
echo "Alignment finished."
echo "$(date)"
