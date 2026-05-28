#!/usr/bin/env python3
"""
Demonstrates tag SNP identification from a precomputed SV-SNP LD table.

Usage:
    python examples/04_tag_snp_demo.py

This example creates a synthetic LD table and finds the best tag SNP
for each SV using an r-squared threshold of 0.3.
"""

import csv
import io
from collections import defaultdict


R2_THRESHOLD = 0.3


SYNTHETIC_LD_TABLE = """\
SV_ID,SNP_ID,CHROM,SV_POS,SNP_POS,R2
DEL_chr1_100000,BTA-12345,1,100000,99500,0.82
DEL_chr1_100000,BTA-12346,1,100000,100800,0.61
DEL_chr1_100000,BTA-12347,1,100000,101200,0.28
INS_chr2_500000,BTA-54321,2,500000,499200,0.71
INS_chr2_500000,BTA-54322,2,500000,500500,0.45
DUP_chr5_250000,BTA-99999,5,250000,251000,0.18
INV_chr10_800000,BTA-77777,10,800000,799000,0.95
INV_chr10_800000,BTA-77778,10,800000,801000,0.88
"""


def find_best_tag_snps(ld_table_text, r2_threshold=0.3):
    """Return the best tag SNP per SV based on highest r-squared above threshold."""
    best_tags = {}
    reader = csv.DictReader(io.StringIO(ld_table_text))

    for row in reader:
        sv_id = row["SV_ID"]
        r2 = float(row["R2"])

        if r2 < r2_threshold:
            continue

        if sv_id not in best_tags or r2 > float(best_tags[sv_id]["R2"]):
            best_tags[sv_id] = row

    return best_tags


def main():
    print("=== COWADAPT Example: Tag SNP Identification ===")
    print(f"r-squared threshold: {R2_THRESHOLD}")
    print()

    best_tags = find_best_tag_snps(SYNTHETIC_LD_TABLE, R2_THRESHOLD)

    all_sv_ids = set()
    reader = csv.DictReader(io.StringIO(SYNTHETIC_LD_TABLE))
    for row in reader:
        all_sv_ids.add(row["SV_ID"])

    svs_with_tags = len(best_tags)
    svs_without_tags = len(all_sv_ids) - svs_with_tags

    print(f"Total SVs in table:         {len(all_sv_ids)}")
    print(f"SVs with tag SNP (r2>={R2_THRESHOLD}): {svs_with_tags}")
    print(f"SVs without tag SNP:        {svs_without_tags}")
    print()
    print(f"{'SV ID':<25} {'Best Tag SNP':<15} {'R2':>6}")
    print("-" * 50)

    for sv_id in sorted(all_sv_ids):
        if sv_id in best_tags:
            tag = best_tags[sv_id]
            print(f"{sv_id:<25} {tag['SNP_ID']:<15} {float(tag['R2']):>6.3f}")
        else:
            print(f"{sv_id:<25} {'No tag SNP':<15} {'N/A':>6}")

    print()
    print("In the full pipeline, run:")
    print("  python pipelines/SV_Catalog/src/06_ld_analysis/identify_tag_snps.py \\")
    print("    --ld-file results/ld_analysis/sv_snp.ld \\")
    print("    --output results/ld_analysis/tag_snps_per_sv.tsv")


if __name__ == "__main__":
    main()
