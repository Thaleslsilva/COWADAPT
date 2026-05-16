#!/usr/bin/env python3
# generate_final_catalog.py
# Builds the final SV catalog integrating:
#   - VEP functional annotations
#   - BovineHD tag SNPs (LD-based)
#   - SVvalidation sample support
#
# Fixes applied over the original script:
#   Fix 1 - Merge key now includes SVTYPE (CHROM + POS + SVTYPE) to avoid
#            Cartesian product inflation when two different SV types share
#            the same genomic position.
#   Fix 2 - Both tag SNP and support tables are deduplicated before merging.
#            Tags: keep the SNP with the highest r2 per SV.
#            Support: keep the row with the highest N_VALIDATED_SAMPLES per SV.
#   Fix 3 - Post-merge sanity check ensures the final row count equals the
#            input annotation count. Raises an error if inflation is detected.
#
# Usage:
#   python3 generate_final_catalog.py
#
# Input files (adjust paths below):
#   sv_annotations.tsv      - VEP annotation table (one row per SV)
#   tag_snps_per_sv.tsv     - best tag SNP per SV from LD analysis
#   suporte_por_sv.tsv      - SVvalidation sample support table
#
# Output files:
#   reports/final_nelore_sv_catalog.tsv   - complete integrated catalog
#   reports/high_interest_svs.tsv         - HIGH impact SVs with a tag SNP

import sys
import pandas as pd

# == Input paths ===============================================================
ANNOTATIONS_FILE = "/home/bt-h1/KG000421/KG000421_svs/readBased/4.func_annot_VEP/sv_annotations.tsv"
TAGS_FILE        = "reports/tag_snps_per_sv.tsv"
SUPPORT_FILE     = "/home/bt-h1/KG000421/KG000421_svs/readBased/3.SV_validation/dist/suporte_por_sv.tsv"

# == Output paths ==============================================================
CATALOG_OUT      = "reports/final_nelore_sv_catalog.tsv"
HIGH_INT_OUT     = "reports/high_interest_svs.tsv"

# == Load input tables =========================================================
print("Loading input files...")

annotations = pd.read_csv(ANNOTATIONS_FILE, sep="\t", low_memory=False)
tags        = pd.read_csv(TAGS_FILE,        sep="\t", low_memory=False)
support     = pd.read_csv(SUPPORT_FILE,     sep="\t", low_memory=False)

n_input = len(annotations)
print(f"  annotations      : {n_input:,} rows")
print(f"  tag_snps_per_sv  : {len(tags):,} rows")
print(f"  suporte_por_sv   : {len(support):,} rows")

# == FIX 1: Build merge key using CHROM + POS + SVTYPE =========================
# Using only CHROM + POS as key causes a Cartesian product when two different
# SV types (e.g. a DEL and an INS) share the same start position. Adding
# SVTYPE makes each key refer to exactly one SV event.
print("\nBuilding merge keys (CHROM + POS + SVTYPE)...")

annotations["KEY"] = (
    annotations["CHROM"].astype(str) + "_" +
    annotations["POS"].astype(str)   + "_" +
    annotations["SVTYPE"].astype(str)
)

tags["KEY"] = (
    tags["SV_CHROM"].astype(str) + "_" +
    tags["SV_POS"].astype(str)   + "_" +
    tags["SVTYPE"].astype(str)
)

# Support file uses BED coordinates (0-based START), so add 1 to match VCF POS
support["KEY"] = (
    support["CHROM"].astype(str)           + "_" +
    (support["START"] + 1).astype(str)     + "_" +
    support["SVTYPE"].astype(str)
)

# == FIX 2a: Deduplicate tags before merge =====================================
# The tag SNP file may have multiple candidate SNPs per SV (different SNP_IDs
# or duplicated rows). Keep only the best tag SNP per SV key, defined as the
# one with the highest r2.
n_tags_before = len(tags)
tags_dedup = (
    tags
    .sort_values("R2", ascending=False)
    .drop_duplicates(subset="KEY", keep="first")
    .reset_index(drop=True)
)
n_tags_after = len(tags_dedup)
print(f"\nTag SNP deduplication: {n_tags_before:,} -> {n_tags_after:,} rows "
      f"({n_tags_before - n_tags_after:,} duplicates removed)")

# == FIX 2b: Deduplicate support table before merge ============================
# The support file contains all SVs evaluated by SVvalidation, including those
# with zero validated samples. Duplicate keys arise when two SV callers
# independently reported the same event. Keep the row with the highest
# N_AMOSTRAS_VALIDADAS per key, which represents the most supported evidence.
n_sup_before = len(support)
support_dedup = (
    support
    .sort_values("N_AMOSTRAS_VALIDADAS", ascending=False)
    .drop_duplicates(subset="KEY", keep="first")
    .reset_index(drop=True)
)
n_sup_after = len(support_dedup)
print(f"Support deduplication: {n_sup_before:,} -> {n_sup_after:,} rows "
      f"({n_sup_before - n_sup_after:,} duplicates removed)")

# == Merge 1: annotations LEFT JOIN tags ======================================
print("\nMerging annotations with tag SNPs...")
catalog = annotations.merge(
    tags_dedup[["KEY", "SNP_ID", "SNP_CHROM", "SNP_POS", "R2", "DISTANCE_BP"]],
    on="KEY",
    how="left"
)

# == FIX 3 (partial): check row count after first merge =======================
if len(catalog) != n_input:
    print(f"\n[ERROR] Merge 1 inflated rows: {n_input:,} -> {len(catalog):,}. "
          f"Inspect duplicate KEYs in tag_snps_per_sv.tsv.")
    sys.exit(1)
print(f"  Row count after merge 1 : {len(catalog):,}  [OK]")

# == Merge 2: result LEFT JOIN support ========================================
print("Merging with sample support data...")
catalog = catalog.merge(
    support_dedup[["KEY", "N_AMOSTRAS_VALIDADAS", "AMOSTRAS"]],
    on="KEY",
    how="left"
)

# == FIX 3: final sanity check =================================================
# The final row count must equal the input annotation count.
# Any inflation means a duplicate KEY survived deduplication.
if len(catalog) != n_input:
    print(f"\n[ERROR] Merge 2 inflated rows: {n_input:,} -> {len(catalog):,}. "
          f"Inspect duplicate KEYs in suporte_por_sv.tsv.")
    sys.exit(1)
print(f"  Row count after merge 2 : {len(catalog):,}  [OK]")

# == Post-merge cleanup ========================================================
# Flag column: does the SV have a BovineHD tag SNP?
catalog["HAS_TAG_SNP"] = catalog["SNP_ID"].notna()

# Report SVs that did not match any row in the support file
n_no_support = catalog["N_AMOSTRAS_VALIDADAS"].isna().sum()
if n_no_support > 0:
    print(f"\n[WARNING] {n_no_support} SVs had no matching row in the support "
          f"file. These will have NaN in N_AMOSTRAS_VALIDADAS. This is expected "
          f"if those SVs were not present in the SVvalidation input BED.")

# Remove the internal merge key from the output
catalog = (
    catalog
    .drop(columns=["KEY"])
    .sort_values(["CHROM", "POS"])
    .reset_index(drop=True)
)

# == Save final catalog ========================================================
catalog.to_csv(CATALOG_OUT, sep="\t", index=False)

print(f"\nFinal catalog saved: {CATALOG_OUT}")
print(f"  Total SVs            : {len(catalog):,}")
print(f"  With tag SNP         : {catalog['HAS_TAG_SNP'].sum():,} "
      f"({100 * catalog['HAS_TAG_SNP'].mean():.1f}%)")
print(f"  With HIGH impact     : {(catalog['IMPACT'] == 'HIGH').sum():,}")
print(f"  With MODERATE impact : {(catalog['IMPACT'] == 'MODERATE').sum():,}")
print(f"  N_AMOSTRAS matched   : {catalog['N_AMOSTRAS_VALIDADAS'].notna().sum():,}")
print(f"  N_AMOSTRAS missing   : {catalog['N_AMOSTRAS_VALIDADAS'].isna().sum():,}")

# == High-interest subset: HIGH impact + has tag SNP ==========================
high_interest = catalog[
    (catalog["IMPACT"] == "HIGH") &
    (catalog["HAS_TAG_SNP"] == True)
].copy()

high_interest.to_csv(HIGH_INT_OUT, sep="\t", index=False)

print(f"\nHigh-interest SVs (HIGH impact + tag SNP): {len(high_interest):,}")
print(f"Saved to: {HIGH_INT_OUT}")

# == Summary by SV type ========================================================
print("\nSummary by SV type:")
summary = (
    catalog
    .groupby("SVTYPE")
    .agg(
        N_SVs=("SVTYPE", "count"),
        N_with_tag=("HAS_TAG_SNP", "sum"),
        N_HIGH=("IMPACT", lambda x: (x == "HIGH").sum()),
        Mean_r2=("R2", lambda x: round(x.mean(), 3))
    )
    .reset_index()
)
summary["Pct_tagged"] = (100 * summary["N_with_tag"] / summary["N_SVs"]).round(1)
print(summary.to_string(index=False))