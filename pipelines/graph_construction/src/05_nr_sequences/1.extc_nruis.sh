#!/bin/bash

echo "##########################################################################"
echo "# Extracting non-repetitive sequences for downstream analysis...          "
echo "##########################################################################"
echo ""
set -euo pipefail

################################################################################
# After masking, only the non-repetitive regions need to be extracted
# (uppercase in the soft-masked FASTA) to feed BLASTx and Augustus.
# Use BEDTools with the generated GFF:
################################################################################

echo "### 1. Ensure a compatible .sizes file"
samtools faidx nruis.fasta.masked
cut -f1,2 nruis.fasta.masked.fai > nruis.genome.sizes
echo ""

echo "### 2. Convert GFF to BED"
awk '$2=="RepeatMasker" {print $1"\t"$4-1"\t"$5}' nruis.fasta.out.gff > repeats.bed
echo ""

echo "### 3. Sort correctly"
bedtools sort -faidx nruis.genome.sizes -i repeats.bed > repeats.sorted.bed
echo ""

echo "### 4. Merge (CRITICAL)"
bedtools merge -i repeats.sorted.bed > repeats.merged.bed
echo ""

echo "### 5. Invert the repeat coordinates to obtain the non-repetitive regions"
bedtools complement -i repeats.merged.bed -g nruis.genome.sizes > nruis_nonrepetitive_regions.bed
echo ""

echo "### 6. Merge nearby regions"
# The -d parameter sets the maximum distance for merging - d=200: joins blocks separated by up to 200 bp of TE
bedtools merge -i nruis_nonrepetitive_regions.bed -d 200 > nruis_regions_merged_200bp.bed
echo ""

echo "### 7. Filter by minimum size after merging"
awk '$3-$2 > 100' nruis_regions_merged_200bp.bed > non_repeats.filt100.bed
awk '$3-$2 > 500' nruis_regions_merged_200bp.bed > non_repeats.filt500.bed
echo ""

echo "### 8. Extract sequences"
bedtools getfasta -fi nruis.fasta.masked -bed non_repeats.filt100.bed -fo nruis_nonrepetitive.BLASTx.fasta
bedtools getfasta -fi nruis.fasta.masked -bed non_repeats.filt500.bed -fo nruis_nonrepetitive.Augustus.fasta
echo ""

echo "### 6. Checking"

# Cleanup
rm nruis.genome.sizes repeats.bed repeats.sorted.bed repeats.merged.bed nruis_nonrepetitive_regions.bed

echo "# Check how many sequences were generated"
grep -c ">" nruis_nonrepetitive.Augustus.fasta
grep -c ">" nruis_nonrepetitive.BLASTx.fasta

echo "# Check size distribution"
seqkit stats nruis_nonrepetitive.Augustus.fasta
seqkit stats nruis_nonrepetitive.BLASTx.fasta
echo ""

awk '/^>/{next}{print length($0)}' nruis_nonrepetitive.Augustus.fasta | sort -n | \
    awk 'BEGIN{n=0}{n++;a[n]=$1} END{
        print "N50:", a[int(n*0.5)], "bp"
        print "Total blocks:", n
    }'

awk '/^>/{next}{print length($0)}' nruis_nonrepetitive.BLASTx.fasta | sort -n | \
    awk 'BEGIN{n=0}{n++;a[n]=$1} END{
        print "N50:", a[int(n*0.5)], "bp"
        print "Total blocks:", n
    }'

###########
# An N50 of 200-500 bp is already usable for BLASTx. For Augustus, blocks should ideally be >= 1 kb.
###########

echo "Extraction complete!!!"
