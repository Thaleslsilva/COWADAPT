#!/bin/bash

################################################################################
#
# COWADAPT - Download example SV dataset (20 Nelore bulls) from Zenodo
#
# Downloads the autosomal Sniffles2 and SVIM VCFs from
# https://doi.org/10.5281/zenodo.21878484 and renames them to the layout
# expected by Step 2 (run_survivor_merge.sh):
#
#   results/sv_calls/sniffles2/COWADAPT_001.vcf
#   results/sv_calls/svim/COWADAPT_001.vcf
#
# Usage:
#   bash src/utils/download_example_data.sh
#
# Note:
#   The dataset contains VCFs only (no BAMs), so Step 1 cannot be replicated
#   and Step 3 (read-based validation) cannot be run with it.
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ZENODO_RECORD="21878484"
BASE_URL="https://zenodo.org/records/${ZENODO_RECORD}/files"

SNIFFLES_DIR="${PROJECT_ROOT}/results/sv_calls/sniffles2"
SVIM_DIR="${PROJECT_ROOT}/results/sv_calls/svim"

# Sample IDs in the Zenodo deposit (no 007, 021, 022)
SAMPLES=(001 002 003 004 005 006 008 009 010 011 012 013 014 015 016 017 018 019 020 023)

mkdir -p "$SNIFFLES_DIR" "$SVIM_DIR"

download() {
    local remote="$1" dest="$2"
    if [ -s "$dest" ]; then
        echo "[SKIP] $dest already exists"
        return
    fi
    echo "[GET ] $remote"
    curl -fL --retry 3 -o "${dest}.tmp" "${BASE_URL}/${remote}?download=1"
    mv "${dest}.tmp" "$dest"
}

for n in "${SAMPLES[@]}"; do
    id="COWADAPT_${n}"
    download "${id}.autoss.snfl.vcf" "${SNIFFLES_DIR}/${id}.vcf"
    download "${id}.autoss.svim.vcf" "${SVIM_DIR}/${id}.vcf"
done

echo "[DONE] ${#SAMPLES[@]} samples downloaded."
echo "Next: bash src/02_sv_merge/run_survivor_merge.sh"
