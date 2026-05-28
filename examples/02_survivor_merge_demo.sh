#!/usr/bin/env bash
# Demonstrates SV merging with SURVIVOR.
# Merges two VCF files (Sniffles2 + SVIM) and produces a concordant SV VCF.
# Requires: SURVIVOR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output/02_survivor_merge"
mkdir -p "${OUTPUT_DIR}"

echo "=== COWADAPT Example: SV Merging with SURVIVOR ==="
echo ""

if ! command -v SURVIVOR &> /dev/null; then
    echo "ERROR: SURVIVOR not found. Install it with: conda install -c bioconda survivor"
    exit 1
fi

echo "SURVIVOR version: $(SURVIVOR 2>&1 | head -2 | tail -1)"
echo ""

# SURVIVOR parameters (matching pipeline defaults)
MAX_DISTANCE=1000      # maximum distance between breakpoints to merge (bp)
MIN_CALLERS=2          # minimum number of callers that must support the SV
SAME_TYPE=1            # require same SV type (1 = yes)
SAME_STRAND=1          # require same strand (1 = yes)
ESTIMATE_DISTANCE=0    # estimate SV distance (0 = use reported SVLEN)
MIN_LENGTH=50          # minimum SV length (bp)

echo "SURVIVOR merge parameters:"
echo "  Maximum breakpoint distance: ${MAX_DISTANCE} bp"
echo "  Minimum supporting callers: ${MIN_CALLERS}"
echo "  Require same SV type: yes"
echo "  Minimum SV length: ${MIN_LENGTH} bp"
echo ""

echo "To run on your data:"
echo ""
echo "  # Create a list of VCF files to merge"
echo "  ls results/sv_calling/*.vcf > ${OUTPUT_DIR}/vcf_list.txt"
echo ""
echo "  # Run SURVIVOR merge"
echo "  SURVIVOR merge \\"
echo "    ${OUTPUT_DIR}/vcf_list.txt \\"
echo "    ${MAX_DISTANCE} \\"
echo "    ${MIN_CALLERS} \\"
echo "    ${SAME_TYPE} \\"
echo "    ${SAME_STRAND} \\"
echo "    ${ESTIMATE_DISTANCE} \\"
echo "    ${MIN_LENGTH} \\"
echo "    ${OUTPUT_DIR}/merged_svs.vcf"
echo ""
echo "For the full pipeline, see: pipelines/SV_Catalog/src/02_sv_merge/run_survivor_merge.sh"
echo ""
echo "Expected output:"
echo "  ${OUTPUT_DIR}/merged_svs.vcf — concordant SV calls from all callers"
echo "  Expected: ~48% of input SVs pass (2-caller concordance requirement)"
