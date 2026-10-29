import sys
import gzip

def get_stats(gfa_file, ref_prefix, target_prefix):
    """
    Parses a GFA file to count nodes and total bp present in target 
    but absent in reference. Works with P-lines (GFA 1.0) and W-lines (GFA 1.1).
    """
    ref_nodes = set()
    target_nodes = set()
    node_lengths = {}
    
    print(f"Processing {gfa_file}...")
    
    # Use gzip if the file ends in .gz
    opener = gzip.open if gfa_file.endswith('.gz') else open
    
    with opener(gfa_file, 'rt') as f:
        for line in f:
            if line.startswith('S'): # Segment/Node line
                parts = line.split('\t')
                node_id = parts[1]
                # Length of the sequence in field 2
                node_lengths[node_id] = len(parts[2])
                
            elif line.startswith('P'): # Path line (GFA 1.0)
                parts = line.split('\t')
                path_name = parts[1]
                nodes = parts[2].replace('+', '').replace('-', '').split(',')
                if path_name.startswith(ref_prefix):
                    ref_nodes.update(nodes)
                elif path_name.startswith(target_prefix):
                    target_nodes.update(nodes)
                    
            elif line.startswith('W'): # Walk line (GFA 1.1 / Minigraph-Cactus)
                parts = line.split('\t')
                # Walk format: W [sample] [hap] [contig] [start] [end] [nodes]
                sample_name = parts[1]
                nodes = parts[6].replace('>', ' ').replace('<', ' ').split()
                if sample_name.startswith(ref_prefix):
                    ref_nodes.update(nodes)
                elif sample_name.startswith(target_prefix):
                    target_nodes.update(nodes)

    # Calculate Non-Reference (present in target, not in ref)
    non_ref_nodes = target_nodes - ref_nodes
    total_count = len(non_ref_nodes)
    total_bp = sum(node_lengths.get(nid, 0) for nid in non_ref_nodes)

    print("\n" + "="*40)
    print(f"Assembly: {target_prefix}")
    print(f"Non-Reference Node Count: {total_count}")
    print(f"Total Non-Reference Length: {total_bp / 1e6:.2f} Mb ({total_bp} bp)")
    print("="*40)

if __name__ == "__main__":
    # Usage: python script.py <gfa> <ref_name> <target_name>
    # Example: python get_assembly_nonref.py IND_pangenome_final.gfa UCD Nelore_005
    if len(sys.argv) < 4:
        print("Usage: python get_assembly_nonref.py <graph.gfa> <ref_prefix> <target_prefix>")
    else:
        get_stats(sys.argv[1], sys.argv[2], sys.argv[3])