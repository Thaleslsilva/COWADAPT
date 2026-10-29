#!/bin/bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/pipeline.config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VG_CONFIG="${PROJECT_ROOT}/config/vg_deconstruct.yaml"
if [ ! -f "$VG_CONFIG" ]; then
    echo "[ERROR] $VG_CONFIG not found. Copy config/vg_deconstruct.template.yaml and edit it."
    exit 1
fi

AUTOSOMES="ARS_autoss.txt"

TOTAL_CORES=$DEFAULT_THREADS
CORES_POR_CROM=64
MAX_JOBS=1

echo "Total cores: $TOTAL_CORES"
echo "Cores per chromosome: $CORES_POR_CROM"
echo "Max simultaneous chromosomes: $MAX_JOBS"
echo ""

job_count=0

while IFS= read -r CHROM_REF; do

    CHROMOSOME="${CHROM_REF##*#}"
    
    (
        echo "Running chromosome: ${CHROMOSOME}"
        echo "PID: $BASHPID"

        WORKDIR="snmk_out/${CHROMOSOME}"
        mkdir -p "$WORKDIR"

        snakemake -s "${SCRIPT_DIR}/vg_deconstruct.smk" \
            --configfile "${VG_CONFIG}" \
            --config ref_ID=$CHROM_REF prefix=$CHROMOSOME \
            --cores $CORES_POR_CROM \
            --rerun-incomplete \
            --printshellcmds \
            --directory "$WORKDIR"

        echo "Finished chromosome: ${CHROMOSOME}"
    ) &

    ((job_count++)) || true

    if [[ "$job_count" -ge "$MAX_JOBS" ]]; then
        wait -n
        ((job_count--)) || true
    fi

done < "$AUTOSOMES"

wait

echo "All chromosomes completed."