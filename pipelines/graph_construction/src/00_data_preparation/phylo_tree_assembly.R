################################################################################
#       Given mash distance construct phylogenetic tree from it
#
# Thales de Lima Silva                                            V.: 2025.10.28
#
# Usage: Rscript phylo_tree_assembly.R <combined_distance.tsv> [out_dir]
#   input:  `mash dist` table produced by src/00_data_preparation/phylo_tree.sh
#   output: outmat.tsv (distance matrix) and nj_tree.pdf (NJ tree) in out_dir
#
################################################################################


args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) >= 1) args[1] else "combined_distance.tsv"
out_dir    <- if (length(args) >= 2) args[2] else "."
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)


# Loading library 
library("tidyverse")
library("ape")


datdis <- read.table(input_file, header=FALSE, stringsAsFactors =FALSE)


# Rename the header
colnames(datdis)  <- c("anim1","anim2","distr","comp4","comp5")


# Give correct assembly name
datdis$anim1c <- gsub("\\.f(ast)?a(\\.gz)?$", "", basename(datdis$anim1))
datdis$anim2c <- gsub("\\.f(ast)?a(\\.gz)?$", "", basename(datdis$anim2))
datsel <- datdis %>% select(anim1c,anim2c, distr)

datsel[, 1:2] <- lapply(datsel[, 1:2], \(x) gsub("BRAGUZ_M_07_", "", x))
datsel[, 1:2] <- lapply(datsel[, 1:2], \(x) gsub("BRASIN_F_08_", "", x))
datsel[, 1:2] <- lapply(datsel[, 1:2], \(x) gsub("BRATAB_F_8423_", "", x))
datsel[, 1:2] <- lapply(datsel[, 1:2], \(x) gsub("SxGCHEF120170207244.hap1", "Gir", x))
datsel[, 1:2] <- lapply(datsel[, 1:2], \(x) gsub("ARS-UCD2.0_autossm", "ARS-UCD2.0", x))

# Make distance into a wide matrix 
datwide <- datsel %>% pivot_wider(names_from = anim2c, values_from = distr)

datmat <- as.matrix(datwide %>% select(-anim1c))
rownames(datmat) <- datwide$anim1c; head (datmat)

datmat <- matrix(as.numeric(datmat), nrow = nrow(datmat), dimnames = dimnames(datmat))
head(datmat)

write.table(datmat, file=file.path(out_dir, "outmat.tsv"), sep="\t", quote = FALSE)


# select outgroup from the distance matrix
ref="ARS-UCD2.0"
outgroup <- colnames(datmat)[ which.max(datmat[ref, ]) ]
print(outgroup)

# apply neighbor joining 
dist_obj <- as.dist(datmat)
tr <- nj(dist_obj)


# visualize the tree
pdf(file.path(out_dir, "nj_tree.pdf"), width=12, height=10)

plot.phylo(root(tr, outgroup=outgroup), cex=2, edge.width=2)
axisPhylo(backward=FALSE, cex.axis=2)

dev.off()

