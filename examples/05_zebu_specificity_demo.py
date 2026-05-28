#!/usr/bin/env python3
"""
Demonstrates zebu-specificity classification of structural variants.

Usage:
    python examples/05_zebu_specificity_demo.py

Each SV is classified based on the mean Pr(Indicina) of overlapping SNPs
from the Kasarapu et al. (2017) zebu ancestry SNP map.

Classification thresholds:
  Pr(Indicina) >= 0.95  -> Indicine-specific
  Pr(Indicina) <  0.05  -> Taurine-specific
  Otherwise             -> Mixed/Admixed
  No overlapping SNPs   -> No SNP data
"""

INDICINE_THRESHOLD = 0.95
TAURINE_THRESHOLD = 0.05


SYNTHETIC_SVS = [
    {"sv_id": "DEL_chr1_100000", "svtype": "DEL", "chrom": "1", "pos": 100000},
    {"sv_id": "INS_chr2_500000", "svtype": "INS", "chrom": "2", "pos": 500000},
    {"sv_id": "DUP_chr5_250000", "svtype": "DUP", "chrom": "5", "pos": 250000},
    {"sv_id": "INV_chr10_800000", "svtype": "INV", "chrom": "10", "pos": 800000},
    {"sv_id": "DEL_chr15_300000", "svtype": "DEL", "chrom": "15", "pos": 300000},
]

SYNTHETIC_SNP_MAP = [
    {"snp_id": "SNP_1_99500",   "chrom": "1",  "pos": 99500,  "pr_indicina": 0.97},
    {"snp_id": "SNP_1_100500",  "chrom": "1",  "pos": 100500, "pr_indicina": 0.95},
    {"snp_id": "SNP_2_499000",  "chrom": "2",  "pos": 499000, "pr_indicina": 0.48},
    {"snp_id": "SNP_2_500800",  "chrom": "2",  "pos": 500800, "pr_indicina": 0.52},
    {"snp_id": "SNP_10_799500", "chrom": "10", "pos": 799500, "pr_indicina": 0.02},
    {"snp_id": "SNP_10_800500", "chrom": "10", "pos": 800500, "pr_indicina": 0.03},
]

WINDOW_BP = 1000


def find_overlapping_snps(sv, snp_map, window=WINDOW_BP):
    """Return SNPs within `window` bp of the SV breakpoint."""
    return [
        snp for snp in snp_map
        if snp["chrom"] == sv["chrom"]
        and abs(snp["pos"] - sv["pos"]) <= window
    ]


def classify_sv(mean_pr_indicina):
    """Classify SV by zebu ancestry based on mean Pr(Indicina)."""
    if mean_pr_indicina >= INDICINE_THRESHOLD:
        return "Indicine-specific"
    elif mean_pr_indicina < TAURINE_THRESHOLD:
        return "Taurine-specific"
    else:
        return "Mixed/Admixed"


def main():
    print("=== COWADAPT Example: Zebu-Specificity Classification ===")
    print(f"Window: +/- {WINDOW_BP} bp from SV breakpoint")
    print(f"Indicine-specific threshold: Pr(Indicina) >= {INDICINE_THRESHOLD}")
    print(f"Taurine-specific threshold:  Pr(Indicina) <  {TAURINE_THRESHOLD}")
    print()

    results = []
    for sv in SYNTHETIC_SVS:
        overlapping = find_overlapping_snps(sv, SYNTHETIC_SNP_MAP)

        if not overlapping:
            results.append({**sv, "n_snps": 0, "mean_pr": None, "classification": "No SNP data"})
            continue

        mean_pr = sum(s["pr_indicina"] for s in overlapping) / len(overlapping)
        classification = classify_sv(mean_pr)
        results.append({**sv, "n_snps": len(overlapping), "mean_pr": mean_pr, "classification": classification})

    header = f"{'SV ID':<25} {'Type':<6} {'N SNPs':>7} {'Mean Pr(I)':>10}  Classification"
    print(header)
    print("-" * 70)
    for r in results:
        mean_str = f"{r['mean_pr']:.3f}" if r["mean_pr"] is not None else "N/A"
        print(f"{r['sv_id']:<25} {r['svtype']:<6} {r['n_snps']:>7} {mean_str:>10}  {r['classification']}")

    print()
    counts = {}
    for r in results:
        counts[r["classification"]] = counts.get(r["classification"], 0) + 1
    print("Summary:")
    for classification, count in sorted(counts.items()):
        print(f"  {classification}: {count}")

    print()
    print("In the full pipeline, run:")
    print("  python pipelines/SV_Catalog/src/07_zebu_specificity/annotate_zebu_specificity.py \\")
    print("    --catalog results/catalog/final_nelore_sv_catalog.tsv \\")
    print("    --snpmap data/reference/zebu_snpmap_kasarapu2017.txt \\")
    print("    --output results/zebu/sv_zebu_specificity.txt")


if __name__ == "__main__":
    main()
