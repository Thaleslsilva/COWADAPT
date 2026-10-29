#!/bin/bash

#SBATCH --job-name=mash_phylo
#SBATCH --output=logs/mash_phylo_%j.out
#SBATCH --error=logs/mash_phylo_%j.err
#SBATCH -c 10
#SBATCH --mem-per-cpu=4G
#SBATCH --time=2:00:00

# ==========================================
# Mash distances among assemblies (manuscript: "Pangenome graph construction")
#
# Mash v2.3, sketch size s = 100,000 and k-mer size k = 32. The resulting
# distance matrix feeds the Neighbor-Joining tree (R package ape) that defines
# the order in which assemblies enter Minigraph-Cactus, and Figure 1.
#
# Required environment variables (these inputs are not part of this repository):
#   REF_FASTA  autosome-only ARS-UCD2.0 FASTA
#   ZEB_DIR    directory with the indicine HiFi assemblies (*.fasta.gz)
#   NEL_DIR    directory with the Nelore assemblies (*.fa.gz)
# ==========================================

set -euo pipefail
mkdir -p tree logs

: "${REF_FASTA:?Set REF_FASTA to the autosome-only ARS-UCD2.0 FASTA}"
: "${ZEB_DIR:?Set ZEB_DIR to the directory with the indicine HiFi assemblies (*.fasta.gz)}"
: "${NEL_DIR:?Set NEL_DIR to the directory with the Nelore assemblies (*.fa.gz)}"
THREADS="${SLURM_CPUS_PER_TASK:-4}"

# ==========================================
# 1. Build the assembly list with short names
# ==========================================
assemblies=()

# --- Taurine assembly (reference) ---
assemblies+=("ARS-UCD2.0:${REF_FASTA}")

# --- Indicine assemblies ---
for f in "${ZEB_DIR}"/*.fasta.gz; do
    base=$(basename "$f" .fasta.gz)
    # Replace problematic characters in the name
    clean_name="${base//./_}"
    assemblies+=("$clean_name:$f")
done

# --- Nelore assemblies ---
for f in "${NEL_DIR}"/*.fa.gz; do
    base=$(basename "$f" .fa.gz)
    clean_name="${base//./_}"
    assemblies+=("$clean_name:$f")
done

# ==========================================
# 2. Create one sketch per assembly
# ==========================================
echo "[INFO] Generating sketches..."
for item in "${assemblies[@]}"; do
    name="${item%%:*}"
    infile="${item##*:}"
    outfile="tree/${name}.msh"

    if [[ ! -f "$outfile" ]]; then
        echo "  - $name"
        mash sketch -p "$THREADS" -s 100000 -k 32 -o "$outfile" "$infile"
    else
        echo "  - $name (already exists)"
    fi
done

# ==========================================
# 3. Combine sketches
# ==========================================
echo "[INFO] Combining sketches..."
combined="tree/combined_sketch.msh"
mash paste "$combined" tree/*.msh

# ==========================================
# 4. Pairwise distances
# ==========================================
echo "[INFO] Computing pairwise distances..."
dist_out="tree/combined_distance.tsv"
mash dist "$combined" "$combined" > "$dist_out"

# ==========================================
# 5. Phylogenetic tree / heatmap (NJ with ape)
# ==========================================
# The R script used for the tree and Figure 1 (phylo_tree_assembly.R) is not yet
# part of this repository (see docs/MANUSCRIPT_MAP.md).
#echo "[INFO] Generating visualization..."
#Rscript phylo_tree_assembly.R \
#    --input "$dist_out" \
#    --out_dir tree

echo "[INFO] Pipeline finished successfully."
