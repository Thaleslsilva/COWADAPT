################################################################################
#   Mash-based genomic similarity analysis
#   - Principal Coordinate Analysis (PCoA)
#   - Heatmap of pairwise Mash distances
#
#   Author: Thales de Lima Silva
#   Version: 2025-10-28
#
#   Usage: Rscript mash_distances.R <combined_distance.tsv> [out_dir]
#   input:  `mash dist` table produced by src/00_data_preparation/phylo_tree.sh
#   output: mash_distance_matrix.tsv, Mash_PCoA.png, Mash_distance_heatmap.png (Figure 1)
################################################################################

args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) >= 1) args[1] else "combined_distance.tsv"
out_dir    <- if (length(args) >= 2) args[2] else "."
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# -------------------------------
# Load required libraries
# -------------------------------
library(tidyverse)
library(ape)
library(pheatmap)

# -------------------------------
# Read Mash distance table
# -------------------------------
datdis <- read.table(input_file, header = FALSE, stringsAsFactors = FALSE)
colnames(datdis) <- c("anim1", "anim2", "distance", "shared1", "shared2")

# -------------------------------
# Clean assembly names
# -------------------------------
datdis$anim1c <- gsub("\\.f(ast)?a(\\.gz)?$", "", basename(datdis$anim1))
datdis$anim2c <- gsub("\\.f(ast)?a(\\.gz)?$", "", basename(datdis$anim2))

# Remove project-specific prefixes
datdis[, c("anim1c", "anim2c")] <- lapply(
  datdis[, c("anim1c", "anim2c")],
  \(x) gsub("BRAGUZ_M_07_|BRASIN_F_08_|BRATAB_F_8423_", "", x)
)

# Harmonize specific sample names


datdis$anim1c <- gsub("SxGCHEF120170207244.hap1", "Gyr", datdis$anim1c)
datdis$anim2c <- gsub("SxGCHEF120170207244.hap1", "Gyr", datdis$anim2c)

datdis$anim1c <- gsub("ARS-UCD2.0_autossm", "ARS-UCD2.0", datdis$anim1c)
datdis$anim2c <- gsub("ARS-UCD2.0_autossm", "ARS-UCD2.0", datdis$anim2c)

datdis$anim1c <- gsub("COWADAPT_005", "Nelore_005", datdis$anim1c)
datdis$anim2c <- gsub("COWADAPT_005", "Nelore_005", datdis$anim2c)

datdis$anim1c <- gsub("COWADAPT_010", "Nelore_010", datdis$anim1c)
datdis$anim2c <- gsub("COWADAPT_010", "Nelore_010", datdis$anim2c)

datdis$anim1c <- gsub("COWADAPT_011", "Nelore_011", datdis$anim1c)
datdis$anim2c <- gsub("COWADAPT_011", "Nelore_011", datdis$anim2c)

datdis$anim1c <- gsub("COWADAPT_017", "Nelore_017", datdis$anim1c)
datdis$anim2c <- gsub("COWADAPT_017", "Nelore_017", datdis$anim2c)

datdis$anim1c <- gsub("COWADAPT_019", "Nelore_019", datdis$anim1c)
datdis$anim2c <- gsub("COWADAPT_019", "Nelore_019", datdis$anim2c)

datdis$anim1c <- gsub("COWADAPT_020", "Nelore_020", datdis$anim1c)
datdis$anim2c <- gsub("COWADAPT_020", "Nelore_020", datdis$anim2c)

# -------------------------------
# Build distance matrix
# -------------------------------
datsel <- datdis %>% select(anim1c, anim2c, distance)

# Remove duplicated pairs (keep the minimum distance)
datsel <- datsel %>%
  group_by(anim1c, anim2c) %>%
  summarise(distance = min(as.numeric(distance)), .groups = "drop")

datwide <- datsel %>%
  pivot_wider(names_from = anim2c, values_from = distance)

datmat <- as.matrix(datwide %>% select(-anim1c))
rownames(datmat) <- datwide$anim1c

# Convert to numeric matrix
datmat <- matrix(
  as.numeric(datmat),
  nrow = nrow(datmat),
  dimnames = dimnames(datmat)
)

# Ensure matrix symmetry
datmat[is.na(datmat)] <- t(datmat)[is.na(datmat)]

# Save matrix
write.table(datmat, file = file.path(out_dir, "mash_distance_matrix.tsv"),
            sep = "\t", quote = FALSE)

# ============================================================================
# 1) Principal Coordinate Analysis (PCoA)
# ============================================================================

dist_obj <- as.dist(datmat)
pcoa_res <- cmdscale(dist_obj, k = 2, eig = TRUE)

pcoa_df <- as.data.frame(pcoa_res$points)
colnames(pcoa_df) <- c("PCoA1", "PCoA2")
pcoa_df$Assembly <- rownames(pcoa_df)

# Variance explained
var_exp <- round(100 * pcoa_res$eig / sum(pcoa_res$eig), 1)

# -------------------------------
# PCoA plot (Nature-style)
# -------------------------------

# Save as PNG
p_pcoa <- ggplot(pcoa_df, aes(PCoA1, PCoA2, label = Assembly)) +
  geom_point(size = 3) +
  geom_text(vjust = -0.8, size = 3) +
  theme_classic(base_size = 14) +
  labs(
    x = paste0("PCoA1 (", var_exp[1], "%)"),
    y = paste0("PCoA2 (", var_exp[2], "%)"),
    title = "PCoA based on Mash genomic distances"
  )

ggsave(
  filename = file.path(out_dir, "Mash_PCoA.png"),
  plot = p_pcoa,
  width = 7,
  height = 6,
  dpi = 300
)

# ============================================================================
# 2) Heatmap of Mash distances
# ============================================================================

# Color palette (Nature/Genetics style)
heat_colors <- colorRampPalette(
  c("#053061", "#2166ac", "#4393c3", "#92c5de",
    "#f7f7f7",
    "#f4a582", "#d6604d", "#b2182b", "#67001f")
)(100)

# Save as PNG
png(
  filename = file.path(out_dir, "Mash_distance_heatmap.png"),
  width = 1800,
  height = 1600,
  res = 300
)

pheatmap(
  datmat,
  color = heat_colors,
  clustering_distance_rows = dist_obj,
  clustering_distance_cols = dist_obj,
  clustering_method = "average",
  border_color = NA,
  fontsize = 12,
  treeheight_row = 50,
  treeheight_col = 50,
  #main = "Pairwise Mash distances between genome assemblies"
)

dev.off()

################################################################################
# End of script
################################################################################
