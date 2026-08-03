#!/bin/bash

################################################################################
# Reference-Based Bam File Quality Control
################################################################################
#
# Description:
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-08-03
#
# Dependencies:
#
# Environment Variables:
#   BASE_DIR       - Base project directory (default: /home/...)
#   READS_DIR      - Directory containing filtered fastq files
#   OUTPUT_DIR     - Output directory for BAM files
#   SAMPLE_PATTERN - Sample name pattern to process (default: ONT_*)
#
# Usage:
#   export BASE_DIR="/home/breeder9/gen_alin_novo/seq_Holanda"
#   ./BAM_QC.sh
#
#   Or with custom directories:
#   BASE_DIR=/path/to/project \
#   READS_DIR=/path/to/reads \
#   OUTPUT_DIR=/path/to/output \
#   ./BAM_QC.sh
#
################################################################################


MAX_JOBS=10

############################
# Directories
############################

BASE_DIR="${BASE_DIR:-.}"

READS_DIR="${READS_DIR:-${BASE_DIR}/2.qc_fastq/Filtered_fq}"
OUTPUT_DIR="${OUTPUT_DIR:-${BASE_DIR}/3.align_fastq/Align_ARS2}"
QLTCTR_DIR="${OUTPUT_DIR:-${BASE_DIR}/3.align_fastq/Qlty_Ctrl}"


mkdir -p "${QLTCTR_DIR}"


############################
# Process each BAM
############################

for READS_FILE in "${READS_DIR}"/*_filt.fq.gz
do
(
    SAMPLE=$(basename "$READS_FILE")
    SAMPLE=${SAMPLE%_filt.fq.gz}

    BAM_FILE="${OUTPUT_DIR}/${SAMPLE}.sorted.bam"

    echo "====================================================="
    echo "$(date)"
    echo "Sample: ${SAMPLE}"
    echo "Reads : ${READS_FILE}"
    echo "Bam File: ${BAM_FILE}"
    echo "====================================================="
 

    #samtools flagstat "${BAM_FILE}" > "${QLTCTR_DIR}/${SAMPLE}.flagstat"
    samtools stats "${BAM_FILE}" > "${QLTCTR_DIR}/${SAMPLE}.stat"
    samtools idxstats "${BAM_FILE}" > "${QLTCTR_DIR}/${SAMPLE}.idxstat"
)&

while (( $(jobs -r | wc -l) >= MAX_JOBS ))
do
    sleep 1
done

done

wait