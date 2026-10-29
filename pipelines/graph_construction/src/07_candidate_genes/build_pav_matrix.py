# Build the PAV matrix using Python
# Run: python3 build_pav_matrix.py [path/to/IND_pangenome_final.sorted.gfa]

import sys
import re
from collections import defaultdict

# Input GFA: first CLI argument, or the default file name in the current directory
GFA_FILE = sys.argv[1] if len(sys.argv) > 1 else "IND_pangenome_final.sorted.gfa"
OUTPUT   = "nrui_pav_matrix.tsv"

# IDs of your candidate genes
# These are the sequence IDs from the FASTA used in Augustus
# You need to map: Augustus gene (g342) -> FASTA sequence ID
# Check the FASTA header to confirm the format

candidate_genes = {
    "g342": "HSPA1A",
    "g343": "HSPA1A_2",
    "g344": "HSPA1A_3",
    "g323": "TNFAIP2",
    "g326": "TNFAIP2_2",
    "g383": "FCGR2B",
    "g266": "SIGLEC5",
    "g349": "MICB",
    "g114": "IFNA5",
    "g117": "IFNB1",
    "g112": "IFNW1",
    "g113": "IFNW1_2",
    "g391": "CD3G",
    "g248": "IGLL1",
    "g153": "IFITM3",
    "g12":  "MUC4",
    "g101": "MUC16",
}

print("Reading GFA...")
node_samples = defaultdict(set)  # node -> set of samples
samples_all  = set()

with open(GFA_FILE) as f:
    for line in f:
        line = line.strip()

        # P lines (paths) - classic minigraph or vg format
        if line.startswith("P"):
            parts = line.split("\t")
            if len(parts) >= 3:
                sample = parts[1]
                samples_all.add(sample)
                nodes_in_path = re.findall(r'(\d+)[+-]', parts[2])
                for node in nodes_in_path:
                    node_samples[node].add(sample)

        # W lines (walks) - HPRC or GBZ format
        elif line.startswith("W"):
            parts = line.split("\t")
            if len(parts) >= 7:
                sample = parts[1]
                hap    = parts[2]
                key    = f"{sample}_{hap}"
                samples_all.add(key)
                walk = parts[6]
                nodes_in_walk = re.findall(r'[><](\d+)', walk)
                for node in nodes_in_walk:
                    node_samples[node].add(key)

print(f"Samples found: {sorted(samples_all)}")
print(f"Total nodes with paths: {len(node_samples)}")

# Write PAV matrix
samples_sorted = sorted(samples_all)
with open(OUTPUT, "w") as out:
    header = "node_id\t" + "\t".join(samples_sorted)
    out.write(header + "\n")
    for node, samples in node_samples.items():
        row = [node] + ["1" if s in samples else "0"
                        for s in samples_sorted]
        out.write("\t".join(row) + "\n")

print(f"\nPAV matrix saved: {OUTPUT}")
print(f"Dimensions: {len(node_samples)} nodes x {len(samples_sorted)} samples")
