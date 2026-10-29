#!/bin/bash

echo "##########################################################################"
echo "# Step 5: Ab Initio ORF Prediction and Homology Search                    "
echo "##########################################################################"

set -euo pipefail

# ========= CONFIGURATION =========
FA1="nruis_nonrepetitive.Augustus.fasta"
FA2="nruis_nonrepetitive.BLASTx.fasta"
DIR="repeatmasker_out/denovo"

# ========= 1. AUGUSTUS =========
echo "[1/2] Building database and running RepeatModeler..."


# ========= 2. DIAMOND BLASTx =========
echo "[2/2] Running DIAMOND BLASTx..."

diamond blastx \
    --query ${DIR}/${FA2} \
    --db blastx_db/combined_bos_sprot.dmnd \
    --out nruis_blastx_results.tsv \
    --outfmt 6 qseqid sseqid pident length mismatch gapopen \
                 qstart qend sstart send evalue bitscore \
                 qlen slen stitle \
    --evalue 1e-5 \
    --query-cover 20 \
    --subject-cover 20 \
    --max-target-seqs 5 \
    --sensitive \
    --threads 100 \
    --log \
    --verbose

echo "Functional annotation complete."
echo ""

# HOW TO INTERPRET:
# Open the nruis_blastx_results.tsv file. If one of your sequences (e.g. NC_037332.1...) has a strong "hit"
# against a known protein (e.g. "Bovine olfactory receptor 7"), you have just found a potential gene or exon
# that is absent from the Hereford reference!
echo ""
