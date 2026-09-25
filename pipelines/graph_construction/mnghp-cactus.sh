#!/bin/bash

####################################################################################################
### COWADAPT PROJECT - Indicine Pangenome Construction (Local Server Implementation)
### Adapted for local execution
### Goal: Build a pangenome graph integrating indicine reference-quality assemblies
####################################################################################################

##### Setting up the Cactus environment #####
# >git clone https://github.com/ComparativeGenomicsToolkit/cactus.git --recursive
# >cd cactus
# >virtualenv -p python3 cactus_env
# >echo "export PATH=$(pwd)/bin:\$PATH" >> cactus_env/bin/activate
# >echo "export PYTHONPATH=$(pwd)/lib:\$PYTHONPATH" >> cactus_env/bin/activate
# >source cactus_env/bin/activate
# >python3 -m pip install -U setuptools pip wheel
# >python3 -m pip install -U .
# >python3 -m pip install -U -r ./toil-requirement.txt

##### To run Cactus, enter the folder and activate the environment #####
# > cd cactus
# > source cactus_env/bin/activate


set -euo pipefail

source "$(dirname "$0")/config.env"

# === ENVIRONMENT & PATHS ===
# Define the number of cores and memory available on your local server
CORES=$DEFAULT_THREADS
MEMORY_LIMIT="900G"
GFA="IND_ini.gfa"
PAF="IND_mappings.paf"
# REF comes from config.env; ensure it matches the ID used in seqFile.txt
SEQ_FILE="seqFile_26.txt"
OUTPUT_DIR="resIND_pangenome"

# === WORKFLOW STEPS ===

###############
### Step 1 ###
#############
echo "Starting Step 1: cactus-minigraph (Building the initial SV graph)..."

# Generates a graph containing the reference plus all structural variants >50bp
if [ -d jobStore_minigraph ]; then rm -rf jobStore_minigraph; fi
#cactus-minigraph jobStore_minigraph $SEQ_FILE $GFA --reference $REF

echo "Step 1 Completed."


###############
### Step 2 ###
#############
echo "Starting Step 2: cactus-graphmap (Mapping assemblies to the graph)..."

# Aligns each assembly to the minigraph to prepare for base-level alignment
if [ -d jobStore_graphmap ]; then rm -rf jobStore_graphmap; fi
#cactus-graphmap jobStore_graphmap $SEQ_FILE $GFA $PAF --reference $REF --outputFasta _MINIGRAPH_

echo "Step 2 Completed."


###############
### Step 3 ###
#############
echo "Starting Step 3: cactus-graphmap-split (Splitting graph into chromosomes)..."

# Segments the graph per chromosome to enable parallel alignment
if [ -d jobStore_split ]; then rm -rf jobStore_split; fi
#cactus-graphmap-split jobStore_split $SEQ_FILE $GFA $PAF --reference $REF --outDir chrom_splits

echo "Step 3 Completed."


###############
### Step 4 ###
#############
echo "Starting Step 4: cactus-align (Refining alignment at base level)..."

# Generates high-resolution HAL alignment (this is the most resource-intensive part)
if [ -d jobStore_align ]; then rm -rf jobStore_align; fi
#cactus-align --maxCores $CORES --maxMemory 950G jobStore_align $SEQ_FILE $PAF IND_outHal --reference $REF --pangenome --outVG

echo "Step 4 Completed."


###############
### Step 5 ###
#############
echo "Starting Step 5: cactus-graphmap-join (Finalizing pangenome graph and indexes)..."

# Consolidates results into GFA/VG formats and creates indexes for 'vg giraffe'
if [ -d jobStore_join ]; then rm -rf jobStore_join; fi
cactus-graphmap-join --maxCores $CORES --maxMemory 900G jobStore_join \
   --vg IND_outHal.vg \
   --hal IND_outHal \
   --outDir out_IND \
   --outName IND_final \
   --reference $REF \
   --indexCores 65 \
   --giraffe clip \
   --vcf \
   --gfa \
   --odgi \
   --gbz \
   --xg \
   --chrom-vg \
   --chrom-og \
   --viz \
   --draw
   
#cactus-graphmap-join --maxCores $CORES --maxMemory 900G jobStore_join \
#   --vg IND_outHal.vg \
#   --hal IND_outHal \
#   --outDir $OUTPUT_DIR \
#   --outName IND_pangenome_final \
#   --reference $REF \
#   --odgi \
#   --gbz \
#   --chrom-og clip \
#   --xg

echo "Step 5 Completed. Pangenome resources are available in: $OUTPUT_DIR"