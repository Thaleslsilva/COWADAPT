import pandas as pd

# Load results
cols = ["qseqid","sseqid","pident","length","mismatch","gapopen",
        "qstart","qend","sstart","send","evalue","bitscore",
        "qlen","slen","stitle"]

df = pd.read_csv("nruis_blastx_results.tsv", sep="\t",
                 names=cols, comment="#")

print(f"Total raw hits: {len(df)}")
print(f"Unique queries with a hit: {df['qseqid'].nunique()}")

# --- Filter 1: E-value ---
df = df[df["evalue"] <= 1e-5]
print(f"\nAfter e-value <= 1e-5 filter: {len(df)} hits")

# --- Filter 2: Minimum identity ---
# 30% is the conservative threshold for divergent proteins (Indicine vs. taurine database)
# Use 25% to capture more hits from highly divergent genes
df = df[df["pident"] >= 30]
print(f"After identity >= 30% filter: {len(df)} hits")

# --- Filter 3: Alignment length ---
# Minimum of 50 aligned aa (= 150 bp of CDS) to have biological signal
df = df[df["length"] >= 50]
print(f"After length >= 50 aa filter: {len(df)} hits")

# --- Filter 4: Query coverage ---
df["qcov"] = df["length"] * 3 / df["qlen"] * 100  # nt approximation
df = df[df["qcov"] >= 20]
print(f"After query coverage >= 20% filter: {len(df)} hits")

# --- Keep only the best hit per query ---
df_best = df.sort_values("bitscore", ascending=False)\
             .drop_duplicates(subset="qseqid", keep="first")

print(f"\nUnique hits (best per query): {len(df_best)}")

# --- Save ---
df.to_csv("nruis_blastx_filtered_all.tsv", sep="\t", index=False)
df_best.to_csv("nruis_blastx_best_hits.tsv", sep="\t", index=False)

# --- Summary by functional category (keywords in the protein title) ---
keywords = {
    "immune": ["immune", "immunoglobulin", "MHC", "BOLA", "interferon",
               "lectin", "antigen", "leukocyte", "antibody", "toll"],
    "metabolism": ["lipid", "fatty acid", "apolipoprotein", "metabol",
                   "oxidoreduct"],
    "heat_stress": ["heat shock", "chaperone", "HSP", "stress"],
    "cytoskeleton": ["actin", "myosin", "tubulin", "cytoskeleton"],
    "signaling": ["kinase", "phosphatase", "GTPase", "receptor", "signal"],
    "parasite_resistance": ["tick", "parasite", "trypan", "helminth"],
    "unknown": []
}

df_best["category"] = "other"
for cat, kws in keywords.items():
    if not kws:
        continue
    mask = df_best["stitle"].str.lower().str.contains(
        "|".join(kws), na=False
    )
    df_best.loc[mask, "category"] = cat

cat_summary = df_best["category"].value_counts()
print("\n=== Distribution by functional category ===")
print(cat_summary.to_string())
