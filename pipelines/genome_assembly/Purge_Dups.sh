#!/bin/bash

################################################################################
# Purge Duplications from Assembly
################################################################################
#
# Description:
#   Identifies and removes duplicate sequences and haplotigs from haplotype-
#   collapsed genome assemblies using coverage analysis and self-alignment.
#   Produces purged primary sequence and haplotype outputs.
#
# Version: 1.0
# Author: Genome Assembly Pipeline
# Updated: 2026-05-28
#
# Dependencies:
#   - minimap2 (v2.17 or later)
#   - samtools (v1.10 or later)
#   - purge_dups (v1.2.5 or later)
#   - purge_dups helper scripts: pbcstat, calcuts, split_fa, get_seqs
#
# Environment Variables:
#   READS_DIR     - Directory containing filtered fastq files (required)
#   ASSEMBLY_DIR  - Directory containing assembly fasta files (required)
#   OUTPUT_DIR    - Output directory for purged sequences (required)
#   SAMPLE_ID     - Sample identifier to process (required)
#   THREADS       - Number of threads for minimap2 (default: 32)
#   SAMTOOLS_THREADS - Number of threads for samtools (default: 8)
#
# Usage:
#   export READS_DIR="/path/to/reads"
#   export ASSEMBLY_DIR="/path/to/assemblies"
#   export OUTPUT_DIR="/path/to/output"
#   ./purge_dups.sh COWADAPT_008
#
#   Or with environment variables:
#   READS_DIR=/path ASSEMBLY_DIR=/path OUTPUT_DIR=/path SAMPLE_ID=COWADAPT_008 ./purge_dups.sh
#
# Output Files:
#   - {SAMPLE_ID}_purged.fa         - Primary purged sequence
#   - {SAMPLE_ID}_haplotigs.fa      - Haplotype sequences
#   - PB.stat                        - Coverage statistics
#   - dups.bed                       - Duplication coordinates
#   - asm.split.self.paf.gz        - Self-alignment PAF
#
################################################################################

set -euo pipefail

# Configuration from environment or defaults
READS_DIR="${READS_DIR:-.}"
ASSEMBLY_DIR="${ASSEMBLY_DIR:-.}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
SAMPLE_ID="${SAMPLE_ID:-${1:-}}"
THREADS="${THREADS:-32}"
SAMTOOLS_THREADS="${SAMTOOLS_THREADS:-8}"

# Validate inputs
if [[ -z "$SAMPLE_ID" ]]; then
    echo "ERROR: SAMPLE_ID not specified."
    echo "Usage: SAMPLE_ID=SAMPLE_NAME $0"
    echo "   or: $0 SAMPLE_NAME"
    exit 1
fi

# Define file paths
READS_FILE="${READS_DIR}/${SAMPLE_ID}_filt.fq.gz"
ASSEMBLY_FILE="${ASSEMBLY_DIR}/${SAMPLE_ID}/${SAMPLE_ID}.fasta"

# Verify input files exist
if [[ ! -f "$READS_FILE" ]]; then
    echo "ERROR: Reads file not found: $READS_FILE"
    exit 1
fi

if [[ ! -f "$ASSEMBLY_FILE" ]]; then
    echo "ERROR: Assembly file not found: $ASSEMBLY_FILE"
    exit 1
fi

# Create and enter working directory
WORK_DIR="${OUTPUT_DIR}/${SAMPLE_ID}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting purge_dups pipeline for: $SAMPLE_ID"

# Step 1: Map reads to assembly and generate sorted BAM with index
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 1: Mapping reads to assembly"
minimap2 -ax map-ont -t "$THREADS" -a "$ASSEMBLY_FILE" "$READS_FILE" | \
    samtools view -@ "$SAMTOOLS_THREADS" -b -F 0x4 - | \
    samtools sort -@ "$SAMTOOLS_THREADS" -o aln.bam --write-index

# Step 2: Generate PacBio coverage statistics
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 2: Computing coverage statistics"
pbcstat aln.bam

# Step 3: Calculate coverage cutoffs
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 3: Calculating coverage cutoffs"
calcuts PB.stat > cutoffs 2> calcuts.log

# Step 4: Detect duplications via self-alignment
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 4: Detecting duplications (self-alignment)"
split_fa "$ASSEMBLY_FILE" > asm.split
minimap2 -x asm5 -DP -t "$THREADS" asm.split asm.split | gzip -c > asm.split.self.paf.gz

# Step 5: Identify duplicated sequences
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 5: Identifying duplicated sequences"
purge_dups -2 -T cutoffs -c PB.base.cov asm.split.self.paf.gz > dups.bed

# Step 6: Extract purged and haplotigs sequences
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 6: Extracting purged sequences and haplotigs"
get_seqs dups.bed "$ASSEMBLY_FILE"

# Rename output files with sample identifier
mv purged.fa "${SAMPLE_ID}_purged.fa"
mv hap.fa "${SAMPLE_ID}_haplotigs.fa"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Purge_dups pipeline completed for: $SAMPLE_ID"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Output files:"
echo "  - Primary sequence: ${SAMPLE_ID}_purged.fa"
echo "  - Haplotigs:       ${SAMPLE_ID}_haplotigs.fa"
