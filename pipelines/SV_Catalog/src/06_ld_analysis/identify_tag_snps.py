#!/usr/bin/env python3
# identify_tag_snps.py
# Filters SV-SNP pairs and identifies the best tag SNP for each SV
# Usage: python3 2.identify_tag_snps.py

import pandas as pd
import os

# -- Configuration ------------------------------------------------------------
LD_FILE        = "ld_output/ld_svs_snps.vcor"
ANNOT_FILE     = "/home/bt-h1/KG000421/KG000421_svs/readBased/4.func_annot_VEP/sv_annotations.tsv"
OUT_TAG        = "reports/tag_snps_per_sv.tsv"
OUT_SUMMARY    = "reports/tagging_summary.tsv"
MIN_R2         = 0.3  ##>> LD threshold to consider a SNP as a tag SNP
                      ##>> Grant et al. (2024) used this threshold for BovineHD
# -----------------------------------------------------------------------------

print("Loading LD file...")

# plink2 output columns:
# #CHROM_A POS_A ID_A CHROM_B POS_B ID_B UNPHASED_R2
ld = pd.read_csv(
    LD_FILE,
    sep="\t",
    comment="#",
    names=[
        "CHROM_A", "POS_A", "ID_A",
        "CHROM_B", "POS_B", "ID_B",
        "R2"
    ]
)

print(f"Total pairs: {len(ld):,}")

# -- Separate pairs where A=SV and B=SNP (or vice versa) --------------------
# SVs were named with suffixes _DEL, _INS, _DUP, _INV in the previous step
sv_suffixes = ("_DEL", "_INS", "_DUP", "_INV", "_BND", "_TRA")

def is_sv(variant_id):
    return any(variant_id.endswith(suffix) for suffix in sv_suffixes)

# Ensure A=SV and B=SNP
mask_ab = ld["ID_A"].apply(is_sv) & ~ld["ID_B"].apply(is_sv)
mask_ba = ld["ID_B"].apply(is_sv) & ~ld["ID_A"].apply(is_sv)

# Normalize:
# SV always in column "SV_ID"
# SNP always in column "SNP_ID"
pairs_ab = ld[mask_ab].rename(columns={
    "ID_A": "SV_ID",
    "CHROM_A": "SV_CHROM",
    "POS_A": "SV_POS",
    "ID_B": "SNP_ID",
    "CHROM_B": "SNP_CHROM",
    "POS_B": "SNP_POS"
})[
    ["SV_ID", "SV_CHROM", "SV_POS",
     "SNP_ID", "SNP_CHROM", "SNP_POS", "R2"]
]

pairs_ba = ld[mask_ba].rename(columns={
    "ID_B": "SV_ID",
    "CHROM_B": "SV_CHROM",
    "POS_B": "SV_POS",
    "ID_A": "SNP_ID",
    "CHROM_A": "SNP_CHROM",
    "POS_A": "SNP_POS"
})[
    ["SV_ID", "SV_CHROM", "SV_POS",
     "SNP_ID", "SNP_CHROM", "SNP_POS", "R2"]
]

pairs = pd.concat([pairs_ab, pairs_ba], ignore_index=True)

print(f"Identified SV-SNP pairs: {len(pairs):,}")

# -- Filter by minimum r2 ----------------------------------------------------
tag_pairs = pairs[pairs["R2"] >= MIN_R2].copy()

print(f"Pairs with r2 = {MIN_R2}: {len(tag_pairs):,}")

# -- For each SV: select the SNP with the highest r2 (best tag SNP) ---------
best_tag = (
    tag_pairs
    .sort_values("R2", ascending=False)
    .drop_duplicates(subset="SV_ID", keep="first")
    .reset_index(drop=True)
)

best_tag["DISTANCE_BP"] = abs(
    best_tag["SNP_POS"] - best_tag["SV_POS"]
)

best_tag["R2"] = best_tag["R2"].round(4)

print(
    f"\nSVs with at least one tag SNP "
    f"(r2 = {MIN_R2}): {len(best_tag):,}"
)

# -- Load VEP annotations and merge ------------------------------------------
annot = pd.read_csv(ANNOT_FILE, sep="\t")

# Build merge key using CHROM + POS
annot["SV_ID_KEY"] = (
    annot["CHROM"].astype(str) +
    "_" +
    annot["POS"].astype(str)
)

best_tag["SV_ID_KEY"] = (
    best_tag["SV_CHROM"].astype(str) +
    "_" +
    best_tag["SV_POS"].astype(str)
)

result = best_tag.merge(
    annot[
        [
            "SV_ID_KEY",
            "SVTYPE",
            "SVLEN",
            "Consequence",
            "SYMBOL",
            "Gene",
            "IMPACT",
            "BIOTYPE"
        ]
    ],
    on="SV_ID_KEY",
    how="left"
)

# -- Save complete tag SNP table ---------------------------------------------
result.drop(columns=["SV_ID_KEY"]).to_csv(
    OUT_TAG,
    sep="\t",
    index=False
)

print(f"\nTag SNP table saved: {OUT_TAG}")

# -- Generate summary by SV type and impact ----------------------------------
summary = result.groupby(["SVTYPE", "IMPACT"]).agg(
    N_SVs_with_tag=("SV_ID", "count"),
    mean_r2=("R2", lambda x: round(x.mean(), 3)),
    max_r2=("R2", lambda x: round(x.max(), 3)),
    mean_distance_bp=("DISTANCE_BP", lambda x: int(x.mean()))
).reset_index()

summary.to_csv(OUT_SUMMARY, sep="\t", index=False)

print("\n=== TAGGING SUMMARY ===\n")
print(summary.to_string(index=False))

# -- Global statistics --------------------------------------------------------
total_svs = len(pd.read_csv(ANNOT_FILE, sep="\t"))
svs_with_tag = len(best_tag)

pct = round(100 * svs_with_tag / total_svs, 1)

print(f"\n{'=' * 45}")
print(f"SVs in final catalog        : {total_svs:>8,}")
print(f"SVs with BovineHD tag SNP   : {svs_with_tag:>8,}  ({pct}%)")
print(f"SVs WITHOUT tag SNP         : {total_svs - svs_with_tag:>8,}  ({100 - pct}%)")
print(f"{'=' * 45}")

print(f"\nReference: Grant et al. (2024) found")
print(f"21% of SVs tagged by BovineHD SNPs in Holstein cattle.")
print(f"For Nelore, a similar or lower value is expected")
print(f"due to the lower average LD in Bos indicus populations.")