#!/usr/bin/env python3

import sys
import re

gfa_file = sys.argv[1]
reference_name = sys.argv[2]

node_len = {}
ref_nodes = set()

with open(gfa_file) as f:
    for line in f:
        if line.startswith("S"):
            parts = line.strip().split("\t")
            node_id = parts[1]
            seq = parts[2]
            node_len[node_id] = len(seq)

        elif line.startswith("P"):
            parts = line.strip().split("\t")
            path_name = parts[1]

            if reference_name in path_name:
                nodes = parts[2].split(",")
                for n in nodes:
                    ref_nodes.add(re.sub("[+-]$", "", n))

        elif line.startswith("W"):  # support for GFA1.1
            parts = line.strip().split("\t")
            path_name = parts[1]

            if reference_name in path_name:
                nodes = re.findall(r"[><]([0-9]+)", parts[6])
                ref_nodes.update(nodes)

# sum of nodes outside the reference
novel_length = 0
for node, length in node_len.items():
    if node not in ref_nodes:
        novel_length += length

print("Total nodes:", len(node_len))
print("Nodes in reference path:", len(ref_nodes))
print("Novel nodes:", len(node_len) - len(ref_nodes))
print("Novel sequence relative to reference (bp):", novel_length)
print("Novel sequence relative to reference (Mb):", novel_length / 1e6)