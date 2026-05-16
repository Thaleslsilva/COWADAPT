# -*- coding: cp1252 -*-
# summarize_sv_zebu.py
#
# Diagnostic summary of sv_zebu_specificity.txt output.
# Reports distributions by SVTYPE, classification, chromosome,
# and flags top zebu-enriched SVs.
#
# Usage:
#   python summarize_sv_zebu.py --summary sv_zebu_specificity.txt \
#                               --hits sv_zebu_hits.txt \
#                               --out sv_zebu_summary_report.txt
#
# Author: generated for Thales Silva
# Date: 2026-05-15

import argparse
import sys
from collections import defaultdict, Counter

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary",  required=True, help="sv_zebu_specificity.txt")
    parser.add_argument("--hits",     required=True, help="sv_zebu_hits.txt")
    parser.add_argument("--out",      default="sv_zebu_summary_report.txt",
                        help="Output report file (default: sv_zebu_summary_report.txt)")
    parser.add_argument("--top",      type=int, default=20,
                        help="Number of top zebu SVs to report (default: 20)")
    parser.add_argument("--min_snps", type=int, default=1,
                        help="Min N_SNPs_overlap to include in zebu ranking (default: 1)")
    return parser.parse_args()


# Global file handle — set in main() so all write() calls go to the same file
_out_fh = None


def write(text=""):
    """Write a line to both the output file and stdout."""
    print(text)
    if _out_fh is not None:
        _out_fh.write(text + "\n")


def load_summary(filepath):
    rows = []
    with open(filepath, "r") as fh:
        header = fh.readline().rstrip().split("\t")
        for line in fh:
            line = line.rstrip("\r\n")
            if not line:
                continue
            parts = line.split("\t")
            row = dict(zip(header, parts))
            rows.append(row)
    return header, rows


def safe_float(v):
    try:
        return float(v)
    except (ValueError, TypeError):
        return None


def safe_int(v):
    try:
        return int(v)
    except (ValueError, TypeError):
        return None


def print_section(title):
    write("\n" + "=" * 60)
    write("  " + title)
    write("=" * 60)


def main():
    global _out_fh
    args = parse_args()

    _out_fh = open(args.out, "w")

    header, rows = load_summary(args.summary)
    n_total = len(rows)

    # ---------------------------------------------------------------
    # 1. Overall counts
    # ---------------------------------------------------------------
    print_section("1. Overview")
    classif_counts = Counter(r.get("Zebu_classification", "NA") for r in rows)
    write("Total SVs: {:,}".format(n_total))
    for k in ["Zebu-enriched", "Mixed", "Taurine-enriched", "No_overlap"]:
        n = classif_counts.get(k, 0)
        pct = 100 * n / n_total if n_total else 0
        write("  {:<20} {:>7,}  ({:.2f}%)".format(k, n, pct))

    # ---------------------------------------------------------------
    # 2. By SVTYPE
    # ---------------------------------------------------------------
    print_section("2. Classification by SVTYPE")
    by_type = defaultdict(Counter)
    for r in rows:
        svtype = r.get("SVTYPE", "UNK")
        classif = r.get("Zebu_classification", "NA")
        by_type[svtype][classif] += 1

    labels = ["Zebu-enriched", "Mixed", "Taurine-enriched", "No_overlap"]
    header_line = "{:<12}".format("SVTYPE") + "".join("{:>18}".format(l) for l in labels) + "  {:>8}".format("Total")
    write(header_line)
    write("-" * len(header_line))
    for svtype in sorted(by_type.keys()):
        counts = by_type[svtype]
        total_type = sum(counts.values())
        row_str = "{:<12}".format(svtype)
        for l in labels:
            row_str += "{:>18}".format(counts.get(l, 0))
        row_str += "  {:>8,}".format(total_type)
        write(row_str)

    # ---------------------------------------------------------------
    # 3. By chromosome (SVs with overlap only)
    # ---------------------------------------------------------------
    print_section("3. SVs with SNP overlap by chromosome")
    by_chr = defaultdict(Counter)
    for r in rows:
        if r.get("Zebu_classification") == "No_overlap":
            continue
        chrom = r.get("CHROM", "NA")
        classif = r.get("Zebu_classification", "NA")
        by_chr[chrom][classif] += 1

    def chr_sort_key(c):
        try:
            return (0, int(c))
        except ValueError:
            return (1, c)

    write("{:<8}  {:>14}  {:>8}  {:>16}  {:>12}".format(
        "CHROM", "Zebu-enriched", "Mixed", "Taurine-enriched", "Total_overlap"))
    write("-" * 65)
    for chrom in sorted(by_chr.keys(), key=chr_sort_key):
        counts = by_chr[chrom]
        total_chr = sum(counts.values())
        write("{:<8}  {:>14}  {:>8}  {:>16}  {:>12}".format(
            chrom,
            counts.get("Zebu-enriched", 0),
            counts.get("Mixed", 0),
            counts.get("Taurine-enriched", 0),
            total_chr))

    # ---------------------------------------------------------------
    # 4. SVLEN distribution for zebu-enriched SVs
    # ---------------------------------------------------------------
    print_section("4. SVLEN distribution - Zebu-enriched SVs")
    zebu_svs = [r for r in rows if r.get("Zebu_classification") == "Zebu-enriched"]
    zebu_svs = [r for r in zebu_svs if safe_int(r.get("N_SNPs_overlap")) >= args.min_snps]

    if zebu_svs:
        lens = [abs(safe_int(r.get("SVLEN", 0)) or 0) for r in zebu_svs]
        lens_valid = [l for l in lens if l > 0]
        if lens_valid:
            lens_valid.sort()
            n = len(lens_valid)
            write("  N zebu SVs   : {:,}".format(n))
            write("  Min SVLEN    : {:,} bp".format(min(lens_valid)))
            write("  Median SVLEN : {:,} bp".format(lens_valid[n // 2]))
            write("  Max SVLEN    : {:,} bp".format(max(lens_valid)))
            write("  Mean SVLEN   : {:,.0f} bp".format(sum(lens_valid) / n))

            # Bin by size
            bins = [(50, 500), (500, 5000), (5000, 50000), (50000, 10**9)]
            labels_b = ["50-500 bp", "500-5kb", "5-50kb", ">50kb"]
            write("\n  Size distribution:")
            for (lo, hi), lbl in zip(bins, labels_b):
                count = sum(1 for l in lens_valid if lo <= l < hi)
                write("    {:<12} : {:>4}".format(lbl, count))
    else:
        write("  No zebu-enriched SVs found with min_snps >= {}".format(args.min_snps))

    # ---------------------------------------------------------------
    # 5. Top zebu-enriched SVs ranked by Max_Pr_Indicina
    # ---------------------------------------------------------------
    print_section("5. Top {} zebu-enriched SVs (ranked by Max_Pr_Indicina)".format(args.top))

    ranked = []
    for r in zebu_svs:
        max_pr = safe_float(r.get("Max_Pr_Indicina"))
        mean_pr = safe_float(r.get("Mean_Pr_Indicina"))
        n_zebu = safe_int(r.get("N_zebu_SNPs"))
        n_snps = safe_int(r.get("N_SNPs_overlap"))
        if max_pr is not None:
            ranked.append((max_pr, mean_pr or 0, n_zebu or 0, n_snps or 0, r))

    ranked.sort(key=lambda x: (-x[0], -x[1], -x[2]))

    write("{:<22}  {:>5}  {:>6}  {:>8}  {:>8}  {:>9}  {:>9}  {:>10}  {}".format(
        "SV_ID", "CHR", "SVTYPE", "POS", "END",
        "MaxPr_Ind", "MeanPr_Ind", "N_zebu/tot", "Genes_zebu"))
    write("-" * 130)

    for i, (max_pr, mean_pr, n_zebu, n_snps, r) in enumerate(ranked[:args.top]):
        genes_z = r.get("Genes_zebu", ".")
        genes_display = (genes_z[:40] + "...") if len(genes_z) > 40 else genes_z
        write("{:<22}  {:>5}  {:>6}  {:>8}  {:>8}  {:>9.4f}  {:>9.4f}  {:>10}  {}".format(
            r.get("SV_ID", "NA"),
            r.get("CHROM", "NA"),
            r.get("SVTYPE", "NA"),
            r.get("POS", "NA"),
            r.get("END", "NA"),
            max_pr,
            mean_pr,
            "{}/{}".format(n_zebu, n_snps),
            genes_display
        ))

    # ---------------------------------------------------------------
    # 6. Gene frequency in hits file (zebu-specific SNPs only)
    # ---------------------------------------------------------------
    print_section("6. Most frequent zebu-specific genes across all SVs")
    gene_sv_count = defaultdict(set)  # gene -> set of SV_IDs

    try:
        with open(args.hits, "r") as fh:
            fh.readline()  # skip header
            for line in fh:
                parts = line.rstrip().split("\t")
                if len(parts) < 10:
                    continue
                sv_id    = parts[0]
                gene     = parts[5]
                is_zebu  = parts[9]
                if is_zebu == "Yes":
                    gene_sv_count[gene].add(sv_id)
    except FileNotFoundError:
        write("  (hits file not found)")
        _out_fh.close()
        return

    top_genes = sorted(gene_sv_count.items(), key=lambda x: -len(x[1]))
    write("{:<20}  {:>10}".format("Gene", "N_SVs_overlapping"))
    write("-" * 35)
    for gene, sv_ids in top_genes[:25]:
        write("{:<20}  {:>10}".format(gene, len(sv_ids)))

    write("\nDone.")
    _out_fh.close()
    print("\n[Output] Report saved to: {}".format(args.out))


if __name__ == "__main__":
    main()