#!/bin/bash


echo "#############################################################################################"
echo "###                                                                                          "
echo "###                               -  COWADAPT PROJECT  -                                     "
echo "### GO/KEGG Annotation for NRUIs                                                              "
echo "### Adapted by Thales de Lima Silva                                             v.2026.04.07 "
echo "###                                                                                          "
echo "#############################################################################################"

set -euo pipefail


# Confirm the available files before starting
echo "=== Required inputs ==="

# 1. Proteins predicted by Augustus
ls -lh augustus/augustus_proteins.faa
grep -c ">" augustus/augustus_proteins.faa
echo ""

# 2. Best BLASTx hits (with reference protein IDs)
ls -lh blastx_res/nruis_blastx_best_hits.tsv
head -2 blastx_res/nruis_blastx_best_hits.tsv
echo ""

# 3. Integrated Augustus + BLASTx table
ls -lh augustus/nruis_gene_models_integrated.tsv
echo ""

echo "### Path A - eggNOG-mapper (recommended, current Q1 standard)"

#conda install -c bioconda -c conda-forge eggnog-mapper

# Check the version - use >= 2.1.9
emapper.py --version

# Download the database (only needed once)
# ~50 Gb - do this on cluster storage
#mkdir -p ~/eggnog_db
#download_eggnog_data.py --data_dir ~/eggnog_db -y

# Download only the diamond database (smaller, ~8 Gb) (-P proteins only)
#download_eggnog_data.py --data_dir eggnog_db -y -d bactNOG,eukNOG -P

emapper.py \
    -i augustus/augustus_proteins.faa \
    --itype proteins \
    -o nruis_eggnog \
    --output_dir eggnog_out/ \
    --data_dir eggnog_db/ \
    --cpu 64 \
    --go_evidence non-electronic \
    --tax_scope Eukaryota \
    --target_orthologs all \
    --seed_ortholog_evalue 0.001 \
    --seed_ortholog_score 60 \
    --override \
    --excel

echo "Checking outputs"
ls eggnog_out/
# nruis_eggnog.emapper.annotations      <- main file
# nruis_eggnog.emapper.hits             <- raw hits
# nruis_eggnog.emapper.seed_orthologs   <- seed orthologs
echo""

echo " Check how many proteins were annotated"
grep -v "^#" eggnog_out/nruis_eggnog.emapper.annotations | grep -v "^$" | wc -l
echo""

echo " View the available columns"
grep -m 1 "^#query" eggnog_out/nruis_eggnog.emapper.annotations | tr "\t" "\n" | nl
echo""
