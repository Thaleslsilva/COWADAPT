#!/bin/bash

echo "##########################################################################"
echo "# Step 4.1: Quality control checklist before proceeding                   "
echo "##########################################################################"

set -euo pipefail

DIR="repeatmasker_out/denovo"

echo "# 1. Total masked vs. non-masked bases"
grep "bases masked" ${DIR}/nruis.fasta.tbl

echo "# 2. How many sequences have at least 100 bp of non-repetitive region"
grep -c ">" ${DIR}/nruis_nonrepetitive.BLASTx.fasta

echo "# 3. Size distribution of the non-repetitive regions"
awk '/^>/{next} {print length($0)}' ${DIR}/nruis_nonrepetitive.BLASTx.fasta | \
  sort -n | awk 'BEGIN{n=0} {n++; a[n]=$1} END{
    print "N50:", a[int(n*0.5)], "bp";
    print "Total:", n, "blocks"
  }'

########################################################################################
# If the masked percentage is very low (< 50%), suspect problems with the repeat
# library or that the input sequences are not true NRUIs. If it is very
# high (> 95%), check whether you are not re-masking sequences that have already been
# soft-masked.
########################################################################################

# bases masked:   11868312 bp ( 59.68 %)
# 14593
# N50: 240 bp
# Total: 14593 blocks
