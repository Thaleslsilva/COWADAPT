import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import random
from collections import defaultdict

from config_loader import load_config

def run_pangenome_simulation(input_file, ref_name=None, n_permutations=100):
    """
    Simulates pangenome expansion and core-genome decay through permutations.
    """
    if ref_name is None:
        ref_name = load_config()["REF"]

    # 1. Load data
    print("Loading node membership data...")
    data = pd.read_csv(input_file, sep='\t', names=['path', 'node'])
    
    # Extract sample name (assuming format Sample#0#...)
    data['sample'] = data['path'].apply(lambda x: x.split('#')[0])
    
    # Identify unique indicine samples (excluding reference backbone)
    all_samples = data['sample'].unique().tolist()
    indicine_samples = [s for s in all_samples if ref_name not in s]
    num_indicine = len(indicine_samples)
    
    # Map nodes to the set of samples they belong to
    node_map = data.groupby('node')['sample'].apply(set).to_dict()
    ref_nodes = {node for node, samples in node_map.items() if ref_name in samples}
    
    # 2. Simulation
    pan_results = defaultdict(list)
    core_results = defaultdict(list)
    novel_results = defaultdict(list)

    print(f"Starting {n_permutations} permutations for {num_indicine} genomes...")
    for p in range(n_permutations):
        random.shuffle(indicine_samples)
        current_pan = set()
        current_core = set()
        
        for i in range(1, num_indicine + 1):
            subset = indicine_samples[:i]
            
            # Nodes present in AT LEAST ONE of the subset (Pan-genome)
            pan_nodes = {node for node, samples in node_map.items() if not samples.isdisjoint(subset)}
            
            # Nodes present in ALL of the subset (Core-genome)
            # Optimization: only check nodes already in pan
            core_nodes = {node for node in pan_nodes if set(subset).issubset(node_map[node])}
            
            # Novel nodes: in Pan but NOT in reference backbone
            novel_nodes = pan_nodes - ref_nodes
            
            pan_results[i].append(len(pan_nodes))
            core_results[i].append(len(core_nodes))
            novel_results[i].append(len(novel_nodes))

    # 3. Calculate Means and Standard Deviations
    x = list(range(1, num_indicine + 1))
    pan_mean = [np.mean(pan_results[i]) for i in x]
    core_mean = [np.mean(core_results[i]) for i in x]
    novel_mean = [np.mean(novel_results[i]) for i in x]
    
    # 4. Generate Composite Plot
    fig, ax = plt.subplots(figsize=(10, 7))
    
    # Pan-genome curve (Increasing)
    ax.plot(x, pan_mean, 'o-', color='navy', label='Pan-genome (Total Nodes)', linewidth=2)
    
    # Novel sequences curve (Increasing - relative to ARS-UCD2.0)
    ax.plot(x, novel_mean, 's--', color='darkgreen', label='Novel Nodes (vs ARS-UCD2.0)', alpha=0.7)
    
    # Core-genome curve (Decreasing)
    ax.plot(x, core_mean, 'o-', color='crimson', label='Core-genome (100% Identity)', linewidth=2)
    
    ax.set_title('Indicine Pangenome Expansion & Core Decay (COWADAPT Project)', fontsize=14)
    ax.set_xlabel('Number of Indicine Genomes Added', fontsize=12)
    ax.set_ylabel('Number of Nodes', fontsize=12)
    ax.set_xticks(x)
    ax.grid(axis='y', linestyle='--', alpha=0.6)
    ax.legend(loc='center right')
    
    plt.tight_layout()
    plt.savefig('cowadapt_pangenome_composite_plot.png', dpi=300)
    print("Analysis complete. Plot saved as cowadapt_pangenome_composite_plot.png")

# Execute
run_pangenome_simulation('IND_analysis/ODGI/node_membership.tsv', n_permutations=100)