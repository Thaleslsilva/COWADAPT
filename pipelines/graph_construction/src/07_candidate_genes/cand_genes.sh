#What to do with the candidates found
#Once the script returns the list, the next step is to evaluate each candidate along three dimensions:


### Dimension 1 - Is it really Indicine-specific?
# Check in how many of the 5 breeds the NRUI is present
# using the PAV matrix you should have from the pangenome graph

grep "GENE_ID" nruis_pav_matrix.tsv
# If present in all 5 Indicine breeds and absent in taurine breeds = strong candidate



### Dimension 2 - Is there transcriptomic support?
# If you have RNA-seq from any Indicine breed available,
# check whether the region has read coverage
samtools view -c rna_indicine.bam "NRUI_contig:start-end"



### Dimension 3 - Does the neighboring gene confirm the biology?
# Check the coordinates in the extended reference genome
# and identify the closest gene in ARS-UCD1.2
bedtools closest \
    -a candidate_nrui.bed \
    -b ARS-UCD1.2_genes.bed \
    -d
