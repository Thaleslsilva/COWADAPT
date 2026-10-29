#!/usr/bin/env bash

###############################################################################
# Core Genome Calculation from ODGI Pangenome Graph
#
# Description:
# This script computes the total length (in base pairs) of the core genome,
# defined as the sequence present in ALL haplotypes in a pangenome graph.
# In my graph:
#  > _hap#1/#2 = real haplotypes
#  > #0 = haploid assemblies (not diploid)
#  > multiple paths -> multiple individuals
# This script calculates core genome (present in ALL real haplotypes)
# using this correctly - without fragmentation bias.
#
# It correctly accounts for:
#   - Diploid samples with explicit haplotypes (e.g., *_hap#1, *_hap#2)
#   - Haploid assemblies (e.g., NEL_XXX, reference)
#   - Fragmented paths (multiple paths per haplotype)
#
# The pipeline:
#   - Removes multipath bias
#   - Corrects fragmented assemblies
#   - Works in graph space (non-linear)
#   - Counts each sequence only once
#   - Respects diploid + haploid biology
#
# Requirements:
#   - odgi (tested with v0.9.4)
#   - awk, sort, uniq
#
# Inputs:
#   - ODGI graph (.og)
#   - Path list (all_paths.txt)
#
# Output:
#   - Core genome size (bp)
#
###############################################################################

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/config/pipeline.config"

#######################################
# User-defined variables
#######################################

GRAPH="IND_pangenome_final.sorted.og"
PATHS="IND_analysis/ODGI/all_paths.txt"
THREADS=$DEFAULT_THREADS
PREFIX="core_analysis"

#######################################
# Step 0 - Create working directory
#######################################

mkdir -p ${PREFIX}
cd ${PREFIX}

#######################################
# Step 1 - Build path -> haplotype map
#
# Rules:
#   - If path contains "_hap", use sample + hap index
#   - Otherwise, treat as haploid genome (use sample name)
#######################################

echo "[Step 1] Building path to haplotype mapping..."

awk -F'#' '
{
  if ($1 ~ /_hap/) {
    hap = $1 "#" $2
  } else {
    hap = $1
  }
  print $0 "\t" hap
}
' ../${PATHS} > path_to_haplotype.tsv

#######################################
# Step 2 - Count total haplotypes
#######################################

echo "[Step 2] Counting total haplotypes..."

cut -f2 path_to_haplotype.tsv | sort | uniq > haplotypes.txt
N_HAPS=$(wc -l < haplotypes.txt)

echo "Total haplotypes detected: ${N_HAPS}"

#######################################
# Step 3 - Compute node -> haplotype counts
#
# Strategy:
#   - Extract (node_id, path_name)
#   - Convert path_name -> haplotype
#   - Remove duplicate (node, haplotype)
#   - Count unique haplotypes per node
#######################################

echo "[Step 3] Computing node-to-haplotype coverage..."

odgi paths -i ../${GRAPH} -N -t ${THREADS} | \
awk '
NR==FNR {
  map[$1] = $2
  next
}
{
  hap = map[$2]
  key = $1 "\t" hap

  if (!(key in seen)) {
    seen[key] = 1
    count[$1]++
  }
}
END {
  for (node in count) {
    print node, count[node]
  }
}
' path_to_haplotype.tsv - > node_haplotype_count.tsv

#######################################
# Step 4 - Identify core nodes
#
# Core nodes = nodes present in ALL haplotypes
#######################################

echo "[Step 4] Identifying core nodes..."

awk -v N=${N_HAPS} '$2 == N {print $1}' node_haplotype_count.tsv > core_nodes.txt

CORE_NODES_COUNT=$(wc -l < core_nodes.txt)
echo "Number of core nodes: ${CORE_NODES_COUNT}"

#######################################
# Step 5 - Extract node lengths
#######################################

echo "[Step 5] Extracting node lengths..."

odgi view -i ../${GRAPH} -g | \
awk '$1=="S" {print $2 "\t" length($3)}' > node_length.tsv

#######################################
# Step 6 - Compute total core genome size
#######################################

echo "[Step 6] Computing total core genome length..."

awk '
NR==FNR {
  core[$1] = 1
  next
}
{
  if ($1 in core) {
    sum += $2
  }
}
END {
  print "Core genome size (bp):", sum
}
' core_nodes.txt node_length.tsv > core_genome_size.txt

#######################################
# Final output
#######################################

echo "[Done] Core genome calculation completed."
cat core_genome_size.txt

###############################################################################
# End of script
###############################################################################