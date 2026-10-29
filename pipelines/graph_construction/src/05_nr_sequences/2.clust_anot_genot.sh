#!/bin/bash


echo "#############################################################################################"
echo "###                                                                                          "
echo "###                               -  COWADAPT PROJECT  -                                     "
echo "### Downstream Validation Pipeline                                                           "
echo "### Adapted by Thales de Lima Silva                                             v.2026.03.30 "
echo "###                                                                                          "
echo "#############################################################################################"

set -euo pipefail


# ===== Input and output paths =====
FASTA_IN="SV_INS.FASTA"
FASTA_OUT="SV_nonRef_clustered.FASTA"


echo "##################################################"
echo "# Step 1: Reduce redundancy (clustering)...      "
echo "##################################################"

# Install CD-HIT if you don't have it yet (e.g. via conda)
# conda install -c bioconda cd-hit

# Clustering command
# -i: input file
# -o: output file (representative sequences)
# -c 0.95: identity threshold (95%). Sequences with >= 95% identity are grouped together.
# -n 10: uses 100% of the longest sequence for alignment.
# -M 0: unlimited memory (adjust as needed)
# -T 6: uses 6 threads

cd-hit-est -i ${FASTA_IN} -o ${FASTA_OUT} -c 0.95 -n 10 -M 0 -T 64
echo "Clustered FASTA created: ${FASTA_OUT}"
echo ""


echo "##########################################################################"
echo "# Step 2: Identification and masking of transposable elements (TEs)...   "
echo "##########################################################################"

### Repeat screening (critical step)

# 1. Replace ALL '>' with '|'. Then replace only the FIRST '|' on each line back to '>'
# and save to a new .fasta file

sed 's/>/|/g' ${FASTA_OUT} | sed 's/|/\>/ 1' > SV_nonRef_clustered.clean.FASTA
sed 's/>/|/g' SV_nonRef_clustered.FASTA | sed 's/|/\>/ 1' > nruis.clean.fasta

# clean up the header
awk '
/^>/ { sub(/_INS_len[0-9]*/, "") }
{ print }
' nruis.clean.fasta > nruis.fasta

rm nruis.clean.fasta

# Check the total number of bases
seqtk comp nruis.fasta | awk '{sum+=$2} END{print sum/1e6 " Mb"}'

# 2. Read the file and rename the chromosomes (e.g. >chr1) in the header

awk '
/^>/ {
  if(match($0, /NC_037[0-9]{3}\.1/)){
    nc = substr($0, RSTART, RLENGTH)
    num = substr(nc, 7, 3) + 0
    chr = "chr" (num - 327)
    sub(nc, chr)
  }
}
{ print }
' SV_nonRef_clustered.clean.FASTA > SV_nonRef_clustered.short.FASTA


########################################################################################################### END ###
