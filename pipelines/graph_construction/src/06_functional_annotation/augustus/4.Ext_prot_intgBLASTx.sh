#!/bin/bash

set -euo pipefail

# Extract CDS and translate to proteins
# Augustus generates an .aa file if you use --protein=on
# If it wasn't generated, use agat or gffread

# Option 1: re-run with --protein=on (cleaner)
augustus \
    --species=human \
    --softmasking=1 \
    --gff3=on \
    --protein=on \
    --codingseq=on \
    --stopCodonExcludedFromCDS=false \
    --min_intron_len=50 \
    --UTR=off \
    --outfile=augustus_out/nruis_with_protein.gff3 \
    nruis_nonrepetitive.Augustus.fasta

# Extract proteins from the output
#grep -A1 "^# protein sequence" augustus_out/nruis_with_protein.gff3 | \
#    grep -v "^#" | grep -v "^--" > augustus_proteins_raw.txt

# Option 2: use gffread (more robust for chunks)
#gffread augustus_out/nruis_augustus_combined.gff3 \
#    -g nruis_softmasked.fasta \
#    -y augustus_proteins.faa

# Check
#grep -c ">" augustus_proteins.faa
#head -4 augustus_proteins.faa
