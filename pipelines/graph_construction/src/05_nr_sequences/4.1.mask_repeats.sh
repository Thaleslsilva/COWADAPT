#!/bin/bash

echo "##########################################################################"
echo "# Step 4: Identification and masking of transposable elements (TEs)      "
echo "##########################################################################"

set -euo pipefail

# ========= CONFIGURATION =========
FASTA="SV_nonRef_clustered.clean.FASTA"     # input fasta file
OUTDIR="repeatmasker_out/"                   # output folder
THREADS=16
EXP_MASKED="SV_nonRef_clustered.short.masked.FASTA"
BLAST_RES="SV_blastRES.txt"


# Install and configure via conda (recommended for reproducibility)
#conda install -c bioconda repeatmasker

# Check the version - always use >= 4.0.9
RepeatMasker --version

# Check whether Repbase/Dfam are installed
ls $(dirname $(which RepeatMasker))/../share/RepeatMasker/Libraries/
# You should see: Dfam.h5, RepeatMasker.lib, etc.


# ========= 1. REPEATMASKER =========
echo "[2/6] Running RepeatMasker (using the de novo library)..."
#LIB=$(ls RM_*/consensi.fa.classified | head -n1)
#RepeatMasker -pa ${THREADS} -gff -xsmall -species "bos taurus" -engine rmblast -dir ${OUTDIR} ${FASTA}
#RepeatMasker -pa ${THREADS} -gff -xsmall -lib RM_2170505*/consensi.fa.classified -engine rmblast -dir ${OUTDIR} ${FASTA}


### Extracting non-repetitive sequences for downstream analysis
# After masking, only the non-repetitive regions (uppercase in the soft-masked
# FASTA) need to be extracted to feed BLASTx and Augustus. Use BEDTools with the generated GFF:

# 1. Convert GFF to BED
awk '$2=="RepeatMasker" {print $1"\t"$4-1"\t"$5}' nruis.fasta.out.gff > repeats.bed

# 2. Sort correctly
bedtools sort -i repeats.bed > repeats.sorted.bed

# 3. Merge (CRITICAL)
bedtools merge -i repeats.sorted.bed > repeats.merged.bed

# 4. Ensure a compatible .sizes file
samtools faidx nruis.fasta.masked

cut -f1,2 nruis.fasta.masked.fai > nruis.genome.sizes

sort -k1,1 nruis.genome.sizes > nruis.genome.sorted.sizes

# 5. Invert the repeat coordinates to obtain the non-repetitive regions
bedtools complement -i repeats.merged.bed -g nruis.genome.sorted.sizes > nruis_nonrepetitive_regions.bed

awk '$3-$2 > 100' nruis_nonrepetitive_regions.bed > non_repeats.filt100.bed
bedtools getfasta -fi nruis.fasta.masked -bed non_repeats.filt100.bed -fo nruis_nonrepetitive.BLASTx.fasta

awk '$3-$2 > 500' nruis_nonrepetitive_regions.bed > non_repeats.filt500.bed
bedtools getfasta -fi nruis.fasta.masked -bed non_repeats.filt500.bed -fo nruis_nonrepetitive.Augustus.fasta

# 6. Checking
# Cleanup
rm nruis_genome.sizes repeats.bed repeats.sorted.bed

# Check how many sequences were generated
grep -c ">" nruis_nonrepetitive.Augustus.fasta
grep -c ">" nruis_nonrepetitive.BLASTx.fasta

# Check size distribution
seqkit stats nruis_nonrepetitive.Augustus.fasta
seqkit stats nruis_nonrepetitive.BLASTx.fasta


# ========= 3. TRF (Tandem Repeats Finder) =========
echo "[3/6] Running TRF..."
trf ../SV_nonRef_clustered.short.FASTA 2 7 7 80 10 50 500 -d -h

# convert TRF .dat -> BED
echo "[4/6] Converting TRF to BED..."
grep -A1 "Sequence:" *.dat | \
  awk '/Sequence:/{seq=$2} /^[0-9]/{print seq"\t"$1-1"\t"$2}' > trf.bed


# ========= 4. MERGE REPEATS (RepeatMasker + TRF) =========
echo "[5/6] Merging repetitive regions..."
awk '$3=="match" {print $1"\t"$4-1"\t"$5}' *.out.gff > rm.bed
cat rm.bed trf.bed | bedtools sort -i - | bedtools merge -i - > repeats_merged.bed


# ========= 5. GENERATE MASKED FASTA =========
echo "[6/6] Applying mask to the FASTA..."
#bedtools maskfasta -fi ../${FASTA} -bed repeats_merged.bed -fo contigs.masked.fa -soft


# ========= 6. QC =========
echo "Generating QC report..."
#python3 - <<'PY'
#from Bio import SeqIO
#with open("mask_qc.tsv","w") as out:
#    out.write("contig\tlength\tmasked_bases\tpercent_masked\n")
#    for rec in SeqIO.parse("contigs.masked.fa","fasta"):
#        seq=str(rec.seq)
#        L=len(seq)
#        masked=sum(1 for c in seq if c.islower() or c=='N')
#        out.write(f"{rec.id}\t{L}\t{masked}\t{masked/L*100:.2f}\n")
#PY

echo "Screening and masking complete!"
echo "Main outputs:"
echo " - contigs.masked.fa"
echo " - repeats_merged.bed"
echo " - mask_qc.tsv"

