#!/usr/bin/env bash

###############################################################################
# Pangenome Core/Accessory Analysis Pipeline (All Chromosomes)
#
# Description:
# This script computes:
#   - Node haplotype frequencies (PAV spectrum)
#   - Core / accessory / private genome partitions
#   - Projection of nodes onto reference chromosomes
#   - Genome-wide density (binned) for each category
#
# Requirements:
#   - odgi (v0.9.4)
#   - awk, sort, uniq
#
# Inputs:
#   - ODGI graph (.og)
#   - all_paths.txt
#
# Outputs:
#   - pav_spectrum.tsv
#   - core_nodes.txt / accessory_nodes.txt / private_nodes.txt
#   - per-chromosome density files
#
###############################################################################

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/config/pipeline.config"

#######################################
# User parameters
#######################################

GRAPH="../../IND_pangenome_final.sorted.og"
PATHS="../path_id.tsv"
THREADS=$DEFAULT_THREADS
PREFIX="core_flexible_anl"
BIN_SIZE=1000000   # 1 Mb bins

mkdir -p ${PREFIX}
cd ${PREFIX}

#######################################
# Step 1 - Build path -> haplotype map
#######################################

echo "[1/8] Building haplotype map..."

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
# Step 2 - Count haplotypes
#######################################

echo "[2/8] Counting haplotypes..."

cut -f2 path_to_haplotype.tsv | sort | uniq > haplotypes.txt
N_HAPS=$(wc -l < haplotypes.txt)

echo "Total haplotypes: ${N_HAPS}"

#######################################
# Step 3 - Node -> haplotype counts
#######################################

echo "[3/8] Computing node frequencies..."

odgi paths -i ../${GRAPH} -N -t ${THREADS} | \
awk '
NR==FNR {map[$1]=$2; next}
{
  hap = map[$2]
  key = $1 "\t" hap
  if (!(key in seen)) {
    seen[key]=1
    count[$1]++
  }
}
END {
  for (n in count) print n, count[n]
}
' path_to_haplotype.tsv - > node_haplotype_count.tsv

#######################################
# Step 4 - PAV spectrum
#######################################

echo "[4/8] Building PAV spectrum..."

awk '{freq[$2]++} END {
  for (f in freq) print f, freq[f]
}' node_haplotype_count.tsv | sort -n > pav_spectrum.tsv

#######################################
# Step 5 - Define genome partitions
#######################################

echo "[5/8] Classifying nodes..."

awk -v N=$N_HAPS '
{
  if ($2 == N) print $1 > "core_nodes.txt"
  else if ($2 == 1) print $1 > "private_nodes.txt"
  else print $1 > "accessory_nodes.txt"
}
' node_haplotype_count.tsv

#######################################
# Step 6 - Extract node lengths
#######################################

echo "[6/8] Extracting node lengths..."

odgi view -i ../${GRAPH} -g | \
awk '$1=="S"{print $2 "\t" length($3)}' > node_length.tsv

#######################################
# Step 7 - Get reference paths (chromosomes)
#######################################

echo "[7/8] Detecting reference chromosomes..."

#odgi paths -i ../${GRAPH} -L | grep "ARS_UCD2" > ref_paths.txt

#######################################
# STEP 8 - Extract reference paths
#######################################

echo "[8/9] Processing chromosomes..."

mkdir -p density tmp

grep "^P" ../../../IND_pangenome_final.sorted.gfa | grep "ARS_UCD2" > ref_paths.gfa

#######################################
# Step 9 - Process each chromosome
#######################################

while read LINE; do

  REF=$(echo "$LINE" | cut -f2)

  echo "Processing ${REF}"

  SAFE=$(echo ${REF} | sed 's/[^a-zA-Z0-9]/_/g')

  ###################################
  # Extract nodes in order
  ###################################

  echo "$LINE" | awk '
  {
    split($3, nodes, ",");
    for (i=1; i<=length(nodes); i++) {
      gsub(/[+-]/, "", nodes[i]);
      print nodes[i];
    }
  }' > tmp/${SAFE}.nodes

  ###################################
  # Convert to genomic positions
  ###################################

  awk 'NR==FNR {len[$1]=$2; next}
  {
    pos += len[$1];
    print $1 "\t" pos;
  }' ../node_length.tsv tmp/${SAFE}.nodes \
  > tmp/${SAFE}.pos.tsv

  ###################################
  # Compute densities
  ###################################

  for TYPE in core accessory private; do

    awk -v BIN=${BIN_SIZE} '
    NR==FNR {set[$1]; next}
    ($1 in set) {
      bin = int($2 / BIN);
      count[bin]++;
    }
    END {
      for (b in count)
        print b*BIN "\t" count[b];
    }
    ' ../nodes_${TYPE}.txt tmp/${SAFE}.pos.tsv \
    | sort -n > density/${SAFE}.${TYPE}.tsv

  done

done < ref_paths.gfa

#######################################
# DONE
#######################################

echo "[9/9] Pipeline finished."