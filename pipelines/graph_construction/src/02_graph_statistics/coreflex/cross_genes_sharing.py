#!/usr/bin/env python3
"""
Cross candidate genes with pangenome node sharing patterns.

This script replaces the vg find step by using node_path_pairs_noREF.tsv
to assign pangenome nodes to genomic coordinates, then crosses those nodes
with the boolean presence/absence matrix.

Two path types are handled:
    CHR paths  (Gyr, Guzerat, Sindi, Tabapua):
        e.g. GIR_hap#1#chr26#0[37028621-52755946]
        -> chromosome + interval extracted directly

    PTG paths  (Nelore, assembly contigs):
        e.g. NEL_011#0#ptg002330l_1_2081515_+#0
        -> no chromosomal coordinates available without a contig anchoring file
        -> nodes from Nelore-only paths are still used for breed presence
           in the boolean matrix, but cannot be filtered by genomic position

Inputs:
    node_path_pairs_noREF.tsv  : node_id <TAB> path_name
    boolean_matrix.tsv         : node <TAB> Nelore <TAB> Gyr <TAB> ...
    candidate_genes_coords.bed : gene_id <TAB> gene_name <TAB> chrom <TAB>
                                 start <TAB> end <TAB> strand

Output:
    genes_sharing_result.tsv

Usage:
    python cross_genes_sharing.py

    python cross_genes_sharing.py \\
        --pairs    node_path_pairs_noREF.tsv \\
        --matrix   boolean_matrix.tsv \\
        --coords   candidate_genes_coords.bed \\
        --output   genes_sharing_result.tsv \\
        [--min_overlap 1]
"""

import argparse
import re
import sys
from collections import defaultdict

import pandas as pd


# ---------------------------------------------------------------------- #
# Chromosome name mapping: NC accession -> chr name used in path strings
# Chromosomes use zero-padded names: chr01, chr02, ..., chr29
# ---------------------------------------------------------------------- #
CHR_MAP = {
    "NC_037328.1": "chr01", "NC_037329.1": "chr02", "NC_037330.1": "chr03",
    "NC_037331.1": "chr04", "NC_037332.1": "chr05", "NC_037333.1": "chr06",
    "NC_037334.1": "chr07", "NC_037335.1": "chr08", "NC_037336.1": "chr09",
    "NC_037337.1": "chr10", "NC_037338.1": "chr11", "NC_037339.1": "chr12",
    "NC_037340.1": "chr13", "NC_037341.1": "chr14", "NC_037342.1": "chr15",
    "NC_037343.1": "chr16", "NC_037344.1": "chr17", "NC_037345.1": "chr18",
    "NC_037346.1": "chr19", "NC_037347.1": "chr20", "NC_037348.1": "chr21",
    "NC_037349.1": "chr22", "NC_037350.1": "chr23", "NC_037351.1": "chr24",
    "NC_037352.1": "chr25", "NC_037353.1": "chr26", "NC_037354.1": "chr27",
    "NC_037355.1": "chr28", "NC_037356.1": "chr29", "NC_024018.1": "chrX",
}

# Breed prefix in path name -> column name in boolean_matrix
BREED_PREFIX = {
    "GIR": "Gyr",
    "GUZ": "Guzerat",
    "NEL": "Nelore",
    "SIN": "Sindi",
    "TAB": "Tabapua",
}


# ---------------------------------------------------------------------- #
# Path parsing
# ---------------------------------------------------------------------- #

def parse_path(path_str):
    """
    Parse a path string and return (breed, chrom, start, end) or
    (breed, None, None, None) when no chromosomal coords are available.

    CHR path:  GIR_hap#1#chr26#0[37028621-52755946]
    PTG path:  NEL_011#0#ptg002330l_1_2081515_+#0[11-17568049]
               NEL_017#0#ptg000257l_1_4347498_+#0
    """
    prefix = path_str.split("_")[0]
    breed  = BREED_PREFIX.get(prefix, None)

    # CHR path with interval
    m = re.search(r'(chr\d+)#\d+\[(\d+)-(\d+)\]', path_str)
    if m:
        return breed, m.group(1), int(m.group(2)), int(m.group(3))

    # PTG path (with or without window) -> no chr coords
    if "ptg" in path_str:
        return breed, None, None, None

    return breed, None, None, None


# ---------------------------------------------------------------------- #
# Step 1 - Load node->path pairs and build node->intervals index
# ---------------------------------------------------------------------- #

def load_node_intervals(pairs_file):
    """
    Returns:
        node_intervals : dict  node_id (str) -> list of (chrom, start, end)
        all_nodes      : set of all node_ids seen in the file
    Only CHR paths are indexed. PTG-only nodes are counted but not indexed.
    """
    print(f"[1] Parsing node path pairs: {pairs_file}")

    node_intervals = defaultdict(list)
    all_nodes      = set()
    ptg_only_nodes = set()
    total_lines    = 0

    with open(pairs_file) as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) != 2:
                continue
            node_id, path_str = parts[0].strip(), parts[1].strip()
            all_nodes.add(node_id)
            total_lines += 1

            breed, chrom, start, end = parse_path(path_str)
            if chrom is not None:
                node_intervals[node_id].append((chrom, start, end))
            else:
                ptg_only_nodes.add(node_id)

    # A node that has at least one CHR path is not PTG-only
    ptg_only_nodes -= set(node_intervals.keys())

    print(f"    Total path lines          : {total_lines:,}")
    print(f"    Nodes with CHR intervals  : {len(node_intervals):,}")
    print(f"    Nodes with PTG paths only : {len(ptg_only_nodes):,}")
    print()
    return node_intervals, all_nodes


# ---------------------------------------------------------------------- #
# Step 2 - Load boolean matrix
# ---------------------------------------------------------------------- #

def load_matrix(matrix_file):
    print(f"[2] Loading boolean matrix: {matrix_file}")
    df = pd.read_csv(matrix_file, sep="\t", dtype=str)
    df.rename(columns={df.columns[0]: "node_id"}, inplace=True)
    df["node_id"] = df["node_id"].str.strip()

    breeds = [c for c in df.columns if c != "node_id"]
    print(f"    Breeds detected: {breeds}")

    for b in breeds:
        df[b] = pd.to_numeric(df[b], errors="coerce").fillna(0).astype(int)

    df["n_breeds"] = df[breeds].sum(axis=1)
    total = len(breeds)

    def classify(n):
        if n == total:  return "core_indicine"
        elif n == 1:    return "private"
        elif n == 0:    return "absent"
        else:           return "flexible"

    df["sharing_class"] = df["n_breeds"].apply(classify)

    print(f"    {len(df):,} nodes in matrix")
    print(f"    sharing_class distribution:")
    for cls, cnt in df["sharing_class"].value_counts().items():
        print(f"        {cls:<20} {cnt:>10,}")
    print()
    return df, breeds


# ---------------------------------------------------------------------- #
# Step 3 - Load gene coordinates
# ---------------------------------------------------------------------- #

def load_coords(coords_file):
    print(f"[3] Loading gene coordinates: {coords_file}")
    df = pd.read_csv(coords_file, sep="\t", dtype=str)

    required = ["gene_id", "gene_name", "chrom", "start", "end", "strand"]
    missing  = [c for c in required if c not in df.columns]
    if missing:
        print(f"    ERROR: missing columns: {missing}")
        sys.exit(1)

    df["gene_id"] = df["gene_id"].str.strip()
    df["start"]   = df["start"].astype(int)
    df["end"]     = df["end"].astype(int)

    # Map NC accession -> zero-padded chr name
    df["chrom_chr"] = df["chrom"].map(CHR_MAP)

    unmapped = df[df["chrom_chr"].isna()]["chrom"].unique()
    if len(unmapped) > 0:
        print(f"    WARNING: chromosomes not in CHR_MAP: {list(unmapped)}")
        print(f"    Add them to CHR_MAP at the top of the script.")

    print(f"    {len(df)} genes loaded")
    print(f"    Chromosome mapping preview:")
    for _, r in df[["chrom", "chrom_chr"]].drop_duplicates().iterrows():
        print(f"        {r['chrom']} -> {r['chrom_chr']}")
    print()
    return df


# ---------------------------------------------------------------------- #
# Step 4 - Assign nodes to genes by overlap
# ---------------------------------------------------------------------- #

def nodes_for_gene(chrom_chr, gene_start, gene_end, node_intervals, min_overlap):
    """Return list of node_ids whose CHR intervals overlap the gene region."""
    if chrom_chr is None:
        return []
    matched = []
    for node_id, intervals in node_intervals.items():
        for (chrom, start, end) in intervals:
            if chrom != chrom_chr:
                continue
            overlap = min(end, gene_end) - max(start, gene_start)
            if overlap >= min_overlap:
                matched.append(node_id)
                break  # one matching interval per node is enough
    return matched


def cross_genes(node_intervals, matrix_df, breeds, gene_coords, min_overlap):
    print(f"[4] Assigning nodes to genes (min_overlap = {min_overlap} bp) ...")

    matrix_idx = matrix_df.set_index("node_id")
    results    = []

    for _, row in gene_coords.iterrows():
        gene_id   = str(row["gene_id"])
        gene_name = str(row["gene_name"])
        chrom     = str(row["chrom"])
        chrom_chr = row["chrom_chr"]
        g_start   = int(row["start"])
        g_end     = int(row["end"])
        strand    = str(row["strand"])

        matched_nodes = nodes_for_gene(chrom_chr, g_start, g_end,
                                       node_intervals, min_overlap)

        base = {
            "gene_id":             gene_id,
            "gene_name":           gene_name,
            "chrom":               chrom,
            "start":               g_start,
            "end":                 g_end,
            "strand":              strand,
            "n_nodes_overlapping": len(matched_nodes),
            "n_nodes_in_matrix":   0,
            "dominant_sharing":    "no_overlap",
            "nodes_core":          0,
            "nodes_flexible":      0,
            "nodes_private":       0,
            "nodes_absent":        0,
        }
        base.update({b: 0 for b in breeds})

        if not matched_nodes:
            base["dominant_sharing"] = "no_overlap" if chrom_chr else "chrom_not_mapped"
            results.append(base)
            print(f"  {gene_id} ({gene_name}): 0 nodes overlapping [{chrom} -> {chrom_chr}]")
            continue

        in_matrix = [n for n in matched_nodes if n in matrix_idx.index]
        base["n_nodes_overlapping"] = len(matched_nodes)
        base["n_nodes_in_matrix"]   = len(in_matrix)

        if not in_matrix:
            base["dominant_sharing"] = "nodes_not_in_matrix"
            results.append(base)
            print(f"  {gene_id} ({gene_name}): {len(matched_nodes)} nodes overlapping, "
                  f"0 in matrix")
            continue

        sub        = matrix_idx.loc[in_matrix]
        dominant   = sub["sharing_class"].mode().iloc[0]
        n_core     = int((sub["sharing_class"] == "core_indicine").sum())
        n_flexible = int((sub["sharing_class"] == "flexible").sum())
        n_private  = int((sub["sharing_class"] == "private").sum())
        n_absent   = int((sub["sharing_class"] == "absent").sum())

        breed_presence = {}
        for b in breeds:
            breed_presence[b] = int(sub[b].max()) if b in sub.columns else -1

        record = {
            "gene_id":             gene_id,
            "gene_name":           gene_name,
            "chrom":               chrom,
            "start":               g_start,
            "end":                 g_end,
            "strand":              strand,
            "n_nodes_overlapping": len(matched_nodes),
            "n_nodes_in_matrix":   len(in_matrix),
            "dominant_sharing":    dominant,
            "nodes_core":          n_core,
            "nodes_flexible":      n_flexible,
            "nodes_private":       n_private,
            "nodes_absent":        n_absent,
        }
        record.update(breed_presence)
        results.append(record)

        print(f"  {gene_id} ({gene_name}): {len(matched_nodes)} overlapping, "
              f"{len(in_matrix)} in matrix -> {dominant} "
              f"[core={n_core} flex={n_flexible} priv={n_private}]")

    return results


# ---------------------------------------------------------------------- #
# Step 5 - Save and report
# ---------------------------------------------------------------------- #

def save_and_report(results, breeds, output_file):
    if not results:
        print("\nERROR: no results generated.")
        sys.exit(1)

    col_order = (
        ["gene_id", "gene_name", "chrom", "start", "end", "strand",
         "n_nodes_overlapping", "n_nodes_in_matrix",
         "dominant_sharing", "nodes_core", "nodes_flexible",
         "nodes_private", "nodes_absent"]
        + breeds
    )
    final     = pd.DataFrame(results)
    col_order = [c for c in col_order if c in final.columns]
    final     = final[col_order]
    final.to_csv(output_file, sep="\t", index=False)

    print(f"\n{'='*60}")
    print(f"Genes processed : {len(final)}")
    print(f"\nDominant sharing distribution:")
    print(final["dominant_sharing"].value_counts().to_string())
    print(f"\nPreview:")
    preview = ["gene_id", "gene_name", "dominant_sharing",
               "nodes_core", "nodes_flexible", "nodes_private"] + breeds
    preview = [c for c in preview if c in final.columns]
    print(final[preview].to_string(index=False))
    print(f"\nOutput saved to: {output_file}")


# ---------------------------------------------------------------------- #
# Main
# ---------------------------------------------------------------------- #

def main():
    parser = argparse.ArgumentParser(
        description="Cross candidate genes with pangenome sharing pattern "
                    "using node_path_pairs instead of vg find."
    )
    parser.add_argument("--pairs",       default="node_path_pairs_noREF.tsv")
    parser.add_argument("--matrix",      default="boolean_matrix.tsv")
    parser.add_argument("--coords",      default="candidate_genes_coords.bed")
    parser.add_argument("--output",      default="genes_sharing_result.tsv")
    parser.add_argument("--min_overlap", default=1, type=int,
                        help="Minimum bp overlap between node interval "
                             "and gene window (default: 1)")
    args = parser.parse_args()

    print(f"Pairs       : {args.pairs}")
    print(f"Matrix      : {args.matrix}")
    print(f"Coords      : {args.coords}")
    print(f"Output      : {args.output}")
    print(f"Min overlap : {args.min_overlap} bp\n")

    node_intervals, _ = load_node_intervals(args.pairs)
    matrix_df, breeds = load_matrix(args.matrix)
    gene_coords        = load_coords(args.coords)

    results = cross_genes(node_intervals, matrix_df, breeds,
                          gene_coords, args.min_overlap)

    save_and_report(results, breeds, args.output)


if __name__ == "__main__":
    main()