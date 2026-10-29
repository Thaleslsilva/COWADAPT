#!/bin/bash

set -euo pipefail

mkdir -p blastx_db && cd blastx_db

# --- Database 1: UniProtKB/Swiss-Prot (curated, smaller, more precise) ---
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
gunzip uniprot_sprot.fasta.gz

# --- Database 2: RefSeq proteins from Bovidae (more comprehensive) ---
# Bos taurus (txid9913), Bos indicus (txid9915), Bos mutus (txid72004)
# Via NCBI Datasets CLI (recommended):
#datasets download genome taxon 9913 --include protein --filename bos_taurus_protein.zip
#unzip bos_taurus_protein.zip
#cat ncbi_dataset/data/*/protein.faa > bos_taurus_protein.faa

# Or directly via FTP:
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.1_ARS-UCD1.2/GCF_002263795.1_ARS-UCD1.2_protein.faa.gz
gunzip GCF_002263795.1_ARS-UCD1.2_protein.faa.gz

# --- Combine the databases ---
cat uniprot_sprot.fasta \
    GCF_002263795.1_ARS-UCD1.2_protein.faa \
    > combined_bos_sprot.faa

# --- Build the DIAMOND index ---
diamond makedb \
    --in combined_bos_sprot.faa \
    --db combined_bos_sprot \
    --threads 16 \
    --log

# Check the database created
diamond dbinfo --db combined_bos_sprot.dmnd
