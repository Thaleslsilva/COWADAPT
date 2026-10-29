### Command
# python scripts/get_true_nelore_intersections.py IND_pangenome_final.gfa ARS_UCD2

import sys
import gzip
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

# Logic: 
# 1 bit per target sample
# 1 bit for Reference
# 1 bit for ALL other breeds found in the GFA (to ensure true exclusivity)

def parse_gfa(gfa_file, ref_prefix, target_samples):
    opener = gzip.open if gfa_file.endswith(".gz") else open
    
    # Map target samples to bits 0 to N-1
    sample_index = {s: i for i, s in enumerate(target_samples)}
    num_targets = len(target_samples)
    
    REF_BIT = 1 << num_targets
    OTHER_BIT = 1 << (num_targets + 1)
    
    node_lengths = {}
    node_mask = defaultdict(int)
    
    print(f"Reading GFA: {gfa_file}")
    with opener(gfa_file, "rt") as f:
        for line in f:
            if line.startswith("S"):
                parts = line.split('\t')
                node_lengths[parts[1]] = len(parts[2])
            
            elif line.startswith("W"):
                parts = line.split('\t')
                sample = parts[1]
                
                # Determine which bit to flip
                if sample == ref_prefix:
                    bit = REF_BIT
                elif sample in sample_index:
                    bit = 1 << sample_index[sample]
                else:
                    bit = OTHER_BIT # Node is shared with a breed outside our target list
                
                nodes = parts[6].replace('>', ' ').replace('<', ' ').split()
                for n in nodes:
                    node_mask[n] |= bit
            
            elif line.startswith("P"):
                parts = line.split('\t')
                sample = parts[1].split('#')[0]
                
                if sample == ref_prefix:
                    bit = REF_BIT
                elif sample in sample_index:
                    bit = 1 << sample_index[sample]
                else:
                    bit = OTHER_BIT
                
                nodes = parts[2].replace('+', '').replace('-', '').split(',')
                for n in nodes:
                    node_mask[n] |= bit
                    
    return node_lengths, node_mask, sample_index, REF_BIT, OTHER_BIT

def process_chunk(chunk, lengths, REF_BIT, OTHER_BIT):
    local_map = defaultdict(lambda: [0, 0])
    for node_id, mask in chunk:
        # FILTER 1: Node must NOT be in Reference
        # FILTER 2: Node must NOT be in any other breed (Gir, Guz, etc.)
        if (mask & REF_BIT) or (mask & OTHER_BIT):
            continue
        
        # If it passed, it only contains target Nelore samples
        # The length of the node is added to its specific intersection mask
        length = lengths.get(node_id, 0)
        local_map[mask][0] += 1
        local_map[mask][1] += length
    return local_map

def decode_mask(mask, sample_index):
    # Reverse the index to get names from bits
    inv_index = {v: k for k, v in sample_index.items()}
    present = []
    for i in range(len(sample_index)):
        if (mask >> i) & 1:
            present.append(inv_index[i])
    return ",".join(sorted(present))

def main(gfa_file, ref_prefix, target_samples, threads=100):
    # Phase 1: Map everything
    node_lengths, node_mask, sample_index, REF_BIT, OTHER_BIT = parse_gfa(
        gfa_file, ref_prefix, target_samples
    )
    
    # Phase 2: Parallel processing of intersections
    items = list(node_mask.items())
    chunk_size = len(items) // threads + 1
    chunks = [items[i:i+chunk_size] for i in range(0, len(items), chunk_size)]
    
    print(f"Calculating true intersections using {threads} threads...")
    with ThreadPoolExecutor(max_workers=threads) as exe:
        results = list(exe.map(
            process_chunk, 
            chunks, 
            [node_lengths]*len(chunks), 
            [REF_BIT]*len(chunks), 
            [OTHER_BIT]*len(chunks)
        ))
    
    # Merge results
    final_map = defaultdict(lambda: [0, 0])
    for res in results:
        for mask, stats in res.items():
            final_map[mask][0] += stats[0]
            final_map[mask][1] += stats[1]
    
    # Phase 3: Write Output
    output_file = "nelore_true_intersections.tsv"
    print(f"Writing results to {output_file}")
    with open(output_file, "w") as out:
        out.write("samples\tnodes\tlength_bp\n")
        # Sort by number of samples in intersection (descending)
        sorted_masks = sorted(
            final_map.items(), 
            key=lambda x: (bin(x[0]).count("1"), x[1][1]), 
            reverse=True
        )
        for mask, stats in sorted_masks:
            names = decode_mask(mask, sample_index)
            out.write(f"{names}\t{stats[0]}\t{stats[1]}\n")

if __name__ == "__main__":
    # Your Nelore IDs
    nelore_list = ['NEL_019', 'NEL_020', 'NEL_011', 'NEL_005', 'NEL_010', 'NEL_017']
    
    if len(sys.argv) < 3:
        print("Usage: python get_true_nelore_intersections.py <graph.gfa> <ref_prefix>")
    else:
        main(sys.argv[1], sys.argv[2], nelore_list)