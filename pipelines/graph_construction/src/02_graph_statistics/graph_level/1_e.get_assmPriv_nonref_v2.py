import sys
import gzip
from collections import defaultdict

def get_private_nonref_stats(gfa_file, ref_prefix, target_assembly, output_bed):
    """
    Identifies nodes present ONLY in the target assembly and generates a BED file
    mapping their coordinates within the target assembly's paths/contigs.
    """
    node_lengths = {}
    node_membership = defaultdict(set)
    # Dictionary to store (chrom, start, end) for nodes in the target assembly
    # Structure: {node_id: [(chrom, start, end), ...]}
    target_coordinates = defaultdict(list)
    all_samples = set()
    
    print(f"Phase 1: Streaming GFA to map node membership, lengths, and target coordinates...")
    opener = gzip.open if gfa_file.endswith('.gz') else open
    
    with opener(gfa_file, 'rt') as f:
        for line in f:
            # Segment (S): Store length
            if line.startswith('S'):
                parts = line.split('\t')
                node_id = parts[1]
                # Length is based on the sequence string length
                node_lengths[node_id] = len(parts[2])
            
            # Walk (W) - GFA 1.1 (Minigraph-Cactus standard)
            elif line.startswith('W'):
                parts = line.split('\t')
                sample = parts[1]
                chrom = parts[3] # Contig/Chromosome name
                all_samples.add(sample)
                
                # We only need to track coordinates for the target assembly
                is_target = (sample == target_assembly)
                
                # Parse nodes and calculate cumulative coordinates
                raw_walk = parts[6].replace('>', ' ').replace('<', ' ').split()
                
                current_offset = 0
                for node in raw_walk:
                    node_membership[node].add(sample)
                    length = node_lengths.get(node, 0)
                    
                    if is_target:
                        # Store start and end (0-based start, 1-based end per BED format)
                        target_coordinates[node].append((chrom, current_offset, current_offset + length))
                    
                    current_offset += length
            
            # Path (P) - GFA 1.0
            elif line.startswith('P'):
                parts = line.split('\t')
                # Assuming PanSN naming: Sample#Haplotype#Contig
                path_info = parts[1].split('#')
                sample = path_info[0]
                chrom = path_info[-1] if len(path_info) > 1 else parts[1]
                
                all_samples.add(sample)
                is_target = (sample == target_assembly)
                
                nodes = parts[2].replace('+', '').replace('-', '').split(',')
                
                current_offset = 0
                for node in nodes:
                    node_membership[node].add(sample)
                    length = node_lengths.get(node, 0)
                    
                    if is_target:
                        target_coordinates[node].append((chrom, current_offset, current_offset + length))
                    
                    current_offset += length

    print(f"Phase 2: Calculating statistics and exporting private nodes...")
    
    private_nr_count = 0
    private_nr_bp = 0
    
    with open(output_bed, 'w') as bed_out:
        # Filter nodes
        for node, members in node_membership.items():
            # Condition: node is in target AND only target sample has it
            if target_assembly in members and len(members) == 1:
                # 1. Print the node ID for FASTA extraction logs
                print(node)
                
                length = node_lengths.get(node, 0)
                private_nr_count += 1
                private_nr_bp += length
                
                # 2. Write to BED file (can have multiple locations if node is repeated)
                if node in target_coordinates:
                    for chrom, start, end in target_coordinates[node]:
                        bed_out.write(f"{chrom}\t{start}\t{end}\t{node}\n")

    print("\n" + "="*45)
    print(f"RESULTS FOR PRIVATE NON-REF ANALYSIS")
    print(f"Target Assembly: {target_assembly}")
    print(f"Reference used for context: {ref_prefix}")
    print(f"BED file generated: {output_bed}")
    print("-" * 45)
    print(f"Private NR Node Count: {private_nr_count}")
    print(f"Total Private NR Length: {private_nr_bp / 1e6:.2f} Mb ({private_nr_bp} bp)")
    print("="*45)

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python get_private_nonref.py <graph.gfa> <ref_prefix> <target_prefix> <output.bed>")
    else:
        # Arguments: gfa, reference, target, output_bed
        get_private_nonref_stats(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])