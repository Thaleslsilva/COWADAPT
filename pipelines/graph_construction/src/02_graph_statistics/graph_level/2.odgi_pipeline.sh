#!/usr/bin/env bash

############################################################
# PANGENOME NODE/EDGE MATRIX PIPELINE
#
# Input:
#   IND_pangenome_final.full.og
#
# Output:
#   IND_pangenome_final.compact.og
#   assemblies.txt
#   node_matrix.tsv
#   edge_matrix.tsv
#
# Requirements:
#   odgi
#
# Author: Thales de Lima Silva
############################################################

# SUMMARY
# | command            | use                                    |
# | ------------------ | --------------------------------------- |
# | `odgi depth`       | per-node coverage                      |
# | `odgi pav`         | presence/absence of variants           |
# | `odgi similarity`  | similarity matrix between genomes      |
# | `odgi paths`       | path analysis                          |
# | `odgi stepindex`   | step indexing                          |
# | `odgi untangle`    | projection onto the reference genome   |




set -e
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/config/pipeline.config"

########################################
# PARAMETERS
########################################

THREADS=$DEFAULT_THREADS
PREFIX=$PANGENOME_PREFIX

LOG="pipeline_odgi.log"

########################################
# LOG FUNCTION
########################################

log(){
    echo "[$(date '+%F %T')] $1" | tee -a $LOG
}

########################################
# START
########################################

log "Starting ODGI pangenome pipeline"

########################################
# 1. SORT GRAPH
########################################

log "Sorting graph (path guided)"

#odgi sort -i ../${PREFIX}.og -o ${PREFIX}.sorted.og -t $THREADS -P

log "Graph sorted"

########################################
# 2. GRAPH STATISTICS
########################################

log "Computing graph statistics"

#odgi stats -i ${PREFIX}.sorted.og -S > graph_stats.txt

########################################
# 3. EXTRACT PATH LIST
########################################

log "Extracting assembly/path list"

#odgi paths -i ${PREFIX}.sorted.og -L > path_id.tsv

# To see which path corresponds to number 1, 2, 3, etc. (prefixing the index):
# awk '{print NR, $0}' path_id.tsv | head
#odgi paths -i ${PREFIX}.sorted.og -L | awk '{print NR, $0}' | head

log "Assemblies exported"

########################################
# 4. NODE PRESENCE MATRIX (SPARSE)
########################################

log "Computing node presence matrix"

#odgi matrix -i ${PREFIX}.sorted.og -t $THREADS > node_matrix.tsv

# What odgi matrix produces:
# % This is the header, followed by the dimensions (rows columns total_connections)
#104851124 104851124 285327276
#1   	   2	     1
#1         826632    1
#826632    1         1
#2         826682    1
#826682    2         1
# Interpretation:
# Node 1 connects to node 2 (or Path 2 passes through node 1, depending on the parameter used)

### Node depth (used more often than matrix)
odgi depth -i ${PREFIX}.sorted.og -t $THREADS > node_depth.tsv
### Depth tends to work better for a large pangenome (like this one).
### Odgi matrix produces huge files, whereas depth produces something like:
#path	                start	end	        mean.depth
#ARS_UCD2#0#NC_037352.1	0	42350435	14.0296
#GIR_hap#1#chr25#0	0	43169832	13.7878
#GUZ_hap#1#chr25#0	0	48374928	12.4023
#GUZ_hap#1#chr28#0	0	51528474	12.0325


### Graph connectivity distribution; helps identify SV hotspots and highly branched regions
### This command produces the same output as Node depth
#odgi degree -i ${PREFIX}.sorted.og -t 100 > conect_dist.tsv 

log "Node matrix exported"

### Computes presence/absence variants directly.
odgi pav -i IND_pangenome_final.sorted.og -t 100 > pav.tsv
# This detects regions that are: a) present in a subset of genomes; b) absent in others
# Very useful for: 1) SV analysis, 2) population genomics, 3) adaptation studies
# NOTE: this command was originally run without -b/--bed-file and failed with:
# ** [odgi::pav] error: please specify path ranges via -b/--bed-file.

### Similarity between genomes
odgi similarity -i IND_pangenome_final.sorted.og -t 100 > genome_similarity.tsv
# This produces a sparse matrix: pathA pathB similarity

### Can substantially improve the graph
odgi normalize -i graph.sorted.og -o graph.norm.og  #or >odgi unchop
#This can reduce the node count depending on fragmentation


########################################
# 5. EDGE MATRIX
########################################

log "Computing edge matrix"

#odgi matrix -i ${PREFIX}.sorted.og -e -t $THREADS > edge_matrix.tsv
#odgi matrix -i ${PREFIX}.sorted.og -e -t 100 -P > edge_matrixP.tsv

# What odgi matrix produces:
# % This is the header, followed by the dimensions (rows columns total_entries)
#104851124 104851124 285327276
#1   	   2	     1
#1         826632    1
#826632    1         1
#2         826682    1
#826682    2         1
# Interpretation:
# Node 1 connects to node 2 (or Path 2 passes through node 1, depending on the parameter used)

log "Edge matrix exported"



########################################
# 6. EXPORT GFA (OPTIONAL)
########################################

log "Exporting compact GFA"

#Extract node metadata (chr/position)
odgi view -i ${PREFIX}.sorted.og -g > compact_graph.gfa

#then
grep "^S" compact_graph.gfa > nodes.tsv

#This keeps the fields:
#SN:Z:chr
#SO:i:pos
#SR:i:rank

log "Pipeline finished successfully"

