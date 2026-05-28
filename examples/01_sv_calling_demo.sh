#!/usr/bin/env bash
# Demonstrates SV calling with Sniffles2 on a small test BAM file.
# Requires: sniffles2, samtools

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output/01_sv_calling"
mkdir -p "${OUTPUT_DIR}"

echo "=== COWADAPT Example: SV Calling with Sniffles2 ==="
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Check that sniffles2 is available
if ! command -v sniffles &> /dev/null; then
    echo "ERROR: sniffles2 not found. Install it with: conda install -c bioconda sniffles2"
    exit 1
fi

if ! command -v samtools &> /dev/null; then
    echo "ERROR: samtools not found. Install it with: conda install -c bioconda samtools"
    exit 1
fi

echo "Sniffles2 version: $(sniffles --version 2>&1 | head -1)"
echo "samtools version: $(samtools --version | head -1)"
echo ""

# In a real run, replace this with your actual BAM file path
# BAM_FILE="/path/to/your/sample.bam"
# REFERENCE="/path/to/ARS-UCD2.0.fa"

echo "This example requires a BAM file aligned to ARS-UCD2.0."
echo ""
echo "To run on your data:"
echo ""
echo "  sniffles \\"
echo "    --input your_sample.bam \\"
echo "    --vcf ${OUTPUT_DIR}/svs.vcf \\"
echo "    --snf ${OUTPUT_DIR}/svs.snf \\"
echo "    --reference /path/to/ARS-UCD2.0.fa \\"
echo "    --minsvlen 50 \\"
echo "    --mapq 20 \\"
echo "    --threads 8"
echo ""
echo "For the full pipeline, see: pipelines/SV_Catalog/src/01_sv_calling/run_sniffles2_calling.sh"
echo ""
echo "Expected output files:"
echo "  ${OUTPUT_DIR}/svs.vcf    — VCF with SV calls"
echo "  ${OUTPUT_DIR}/svs.snf    — Sniffles2 SNF file for joint calling"
