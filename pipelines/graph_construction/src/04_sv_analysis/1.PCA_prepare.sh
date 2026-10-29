#!/bin/bash

# Define filenames
SV_VCF="../snmk_out/SV.vcf.gz"
SMALL_VCF="../snmk_out/small.vcf.gz"
MERGED_VCF="../snmk_out/merged_ZEB.vcf.gz"
FIXED_VCF="IND_fixed_ids.vcf.gz"

echo "Step 1: Assigning short, unique IDs to VCF to bypass PLINK buffer limits..."
# We use awk to rename the ID column ($3) to a safe format
# This is much faster and avoids the 99kb string issue in PLINK
zcat ${SV_VCF} | awk 'BEGIN{OFS="\t"} 
    /^#/ {print $0; next} 
    {
        count[$1"_"$2]++; 
        $3=$1":"$2":"count[$1"_"$2]; 
        print $0
    }' | bgzip > ${FIXED_VCF}

bcftools index ${FIXED_VCF}

echo "Step 2: Generating binary files with high-quality filters..."
# --geno 0.1: Remove variants with >10% missing data (crucial for graph deconstruction)
# --set-missing-var-ids: Fallback to ensure everything has a name
plink2 --vcf ${FIXED_VCF} \
       --allow-extra-chr \
       --geno 0.1 \
       --vcf-half-call m \
       --make-pgen \
       --out pangenome_unique

echo "Step 3: Calculating frequencies..."
plink2 --pfile pangenome_unique \
       --allow-extra-chr \
       --freq \
       --out pangenome_freqs

echo "Step 4: LD Pruning (Linkage Equilibrium)..."
plink2 --pfile pangenome_unique \
       --allow-extra-chr \
       --indep-pairwise 50 10 0.1 \
       --out pruned_set

echo "Step 5: Running PCA..."
# Added --mac 2 to remove singletons that bias small population PCAs
plink2 --pfile pangenome_unique \
       --allow-extra-chr \
       --read-freq pangenome_freqs.afreq \
       --extract pruned_set.prune.in \
       --mac 2 \
       --pca 10 \
       --out cowadapt_pca

echo "Pipeline finished. Use 'cowadapt_pca.eigenvec' for R plotting."