#!/bin/bash


echo "#############################################################################################"
echo "###                                                                                          "
echo "###                               -  COWADAPT PROJECT  -                                     "
echo "### Extracting specific sequences from a zebu cattle pangenome.                              "
echo "### Adapted by Thales de Lima Silva                                             v.2026.03.30 "
echo "###                                                                                          "
echo "#############################################################################################"

set -euo pipefail

echo ""

# ===== Input and output paths =====
VCF_SV="../snmk_out/SV.vcf.gz"
VCF_INSERTIONS="SV_INS.vcf"
FASTA_OUT="SV_INS.FASTA"

# ===== CREATE FOLDERS =====

echo "##########################################"
echo "# Step 1: Filter INS from VCF files...    "
echo "##########################################"

# Option 1. Create a new VCF containing only true structural insertions
#bcftools view -i 'strlen(ALT) > strlen(REF) && ALT!="."' ${VCF_SV} -Oz -o ${VCF_INSERTIONS}

# Option 2. Apply a size filter: the absolute size difference between ALT and REF must be >= 100 bp
bcftools view -i '(strlen(ALT) - strlen(REF)) >= 100 && ALT!="."' ${VCF_SV} -Oz -o ${VCF_INSERTIONS}

echo ""

echo "##########################################"
echo "# Step 2: Extract Seq. to a FASTA...      "
echo "##########################################"

# Use 'awk' to read the insertions VCF and write a FASTA file
# The FASTA header will include the chromosome, position, and insertion size
awk '/^[^#]/ {
    info=$8;
    match(info, /LEN=([^;]+)/, arr);
    svlen=arr[1];
    printf ">%s_%s_%s_INS_len%s\n%s\n", $1, $2, $3, svlen, $5
}' ${VCF_INSERTIONS} > ${FASTA_OUT}

echo ""
echo ""

########################################################################################################### END ###
