#!/bin/bash

set -euo pipefail

# ========= CONFIGURATION =========
FASTA="SV_nonRef_clustered.clean.FASTA"     # input fasta file
OUTDIR="repeatmasker_out"                   # output folder
THREADS=16

mkdir -p ${OUTDIR}
cd ${OUTDIR}


# ========= BUILD DATABASE + REPEATMODELER =========
echo " Building database and running RepeatModeler..."
BuildDatabase -name genomeDB ../${FASTA}
RepeatModeler -database genomeDB -threads ${THREADS} -LTRStruct

# Takes approximately 7 hours for the current database
