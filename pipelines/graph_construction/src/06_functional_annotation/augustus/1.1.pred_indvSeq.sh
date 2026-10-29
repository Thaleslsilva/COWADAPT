#!/bin/bash

set -euo pipefail

# Augustus uses the FULL soft-masked sequence of the NRUIs.
# Check the soft-masked file. The correct file has lowercase letters in
# TE regions and uppercase letters everywhere else.
head -5 nruis_nonrepetitive.Augustus.fasta

echo "Confirm the presence of soft-masking. Should return > 0 if soft-masked"
grep -v "^>" nruis_nonrepetitive.Augustus.fasta | grep -c "[acgt]"


### Installation and verification of the bovine model
# Check the installation
augustus --version
# Should return: AUGUSTUS (3.4.0) or higher

# List available models
augustus --species=help 2>&1 | grep -i "bos\|cow\|cattle\|bovine\|human"
# You should see: Bos_taurus_refseq or similar

# Check where the training parameters are located
echo $AUGUSTUS_CONFIG_PATH
ls $AUGUSTUS_CONFIG_PATH/species/ | grep -i human

# If using conda:
ls $(dirname $(which augustus))/../config/species/ | grep -i human



echo "##########################################################################"
echo "# Mode 1 - Prediction per individual sequence (for NRUIs < 100 kb)...     "
echo "##########################################################################"
echo ""

# Run Augustus on each sequence individually
# Best for short NRUIs where gene models are wanted per node

mkdir -p augustus_out

augustus \
    --species=human \
    --softmasking=1 \
    --gff3=on \
    --outfile=augustus_out/nruis_augustus.gff3 \
    --errfile=augustus_out/nruis_augustus.err \
    --stopCodonExcludedFromCDS=false \
    --min_intron_len=50 \
    --UTR=off \
    nruis_nonrepetitive.Augustus.fasta
