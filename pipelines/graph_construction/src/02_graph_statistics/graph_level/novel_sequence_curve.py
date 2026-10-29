### How to run
# python ~/novel_sequence_curve.py IND_pangenome_final.og ARS_UCD2
### Output
# novel_sequence_curve.tsv

import sys
import subprocess
import random
import re
import numpy as np
import pandas as pd

# Usage: python scripts/novel_sequence_curve.py IND_pangenome_final.og ARS-UCD2.0

if len(sys.argv) < 3:
    print("Error: Missing arguments.")
    print("Usage: python novel_sequence_curve.py <GRAPH.og> <REFERENCE_NAME>")
    sys.exit(1)

GRAPH = sys.argv[1]
REF = sys.argv[2]
N_PERM = 200

print(f"Extracting node lengths and paths from {GRAPH}...")
print(f"Using {REF} as the linear reference backbone...")

node_len = {}
sample_nodes = {}
ref_nodes = set()
samples = set()

# We use a single 'odgi view -g' call to extract Segments (S) and Paths (P) efficiently.
# This avoids the overhead of thousands of subprocess calls to 'odgi paths'.
cmd = f"odgi view -i {GRAPH} -g"
process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, text=True)

for line in process.stdout:
    if line.startswith("S"):
        # S \t node_id \t sequence
        parts = line.split("\t")
        node_id = parts[1]
        seq_len = len(parts[2].strip())
        node_len[node_id] = seq_len
        
    elif line.startswith("P"):
        # P \t path_name \t node1+,node2- \t *
        parts = line.split("\t")
        path_name = parts[1]
        
        # Parse based on PanSN-spec format (sample#haplotype#contig)
        sample = path_name.split("#")[0]  
        
        # Extract all node IDs from the comma-separated path string, ignoring strandedness (+/-)
        nodes_in_path = set(re.findall(r'(\d+)[+-]', parts[2]))
        
        if sample == REF:
            ref_nodes.update(nodes_in_path)
        else:
            samples.add(sample)
            if sample not in sample_nodes:
                sample_nodes[sample] = set()
            sample_nodes[sample].update(nodes_in_path)

samples = sorted(list(samples))
print(f"Detected {len(samples)} non-reference samples: {samples}")

print("Subtracting reference nodes to isolate Non-Reference (NR) sequences...")
for s in samples:
    sample_nodes[s] = sample_nodes[s] - ref_nodes

print("Running permutations to build the pangenome novel sequence curve...")
results = []

for perm in range(N_PERM):
    order = samples.copy()
    random.shuffle(order)
    
    seen = set()
    total_novel_bp = 0
    cumulative_novel_bp = []
    
    for s in order:
        # Find completely new nodes introduced by this sample that haven't been seen yet
        new_nodes = sample_nodes[s] - seen
        seen |= sample_nodes[s]
        
        # Calculate the base pair (bp) length of these new nodes
        bp = sum(node_len[n] for n in new_nodes if n in node_len)
        total_novel_bp += bp
        cumulative_novel_bp.append(total_novel_bp)
        
    results.append(cumulative_novel_bp)

print("Calculating statistics and saving to 'novel_sequence_curve.tsv'...")
results_df = pd.DataFrame(results)
mean_bp = results_df.mean(axis=0)
sd_bp = results_df.std(axis=0)

out_df = pd.DataFrame({
    "genomes": range(1, len(samples) + 1),
    "mean_bp": mean_bp,
    "sd_bp": sd_bp
})

out_df.to_csv("novel_sequence_curve.tsv", sep="\t", index=False)
print("Done! Curve data successfully generated.")