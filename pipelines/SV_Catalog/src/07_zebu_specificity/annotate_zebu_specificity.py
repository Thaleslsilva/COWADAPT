# -*- coding: cp1252 -*-
# sv_zebu_specificity.py
#
# Intersects structural variants (VCF) with zebu-specific SNPs from
# Kasarapu et al. (2017) remapped to ARS-UCD1.2.
#
# For each SV, reports:
#   - Overlapping SNPmap entries within a configurable flanking window
#   - Indicine/Taurine posterior probabilities of overlapping genes
#   - Zebu-specificity classification (Pr_Indicina > threshold)
#   - Count of zebu-specific vs taurine-specific SNPs in the SV region
#
# Input:
#   SNPmap_IND_TAU_ARS.txt       - remapped SNP map (ARS-UCD1.2)
#   svs_final_validadas_ren.vcf  - SV calls (CHROM numeric, ARS-UCD1.2 coords)
#
# Output:
#   sv_zebu_specificity.txt  - one line per SV with zebu annotation
#   sv_zebu_hits.txt         - one line per SV x SNP overlap (long format)
#
# Usage:
#   python sv_zebu_specificity.py --vcf your_svs.vcf \
#          --snpmap SNPmap_IND_TAU_ARS.txt \
#          --flank 1000 --threshold 0.95
#
# Author: generated for Thales Silva
# Date: 2026-05-15

import argparse
import sys
from collections import defaultdict


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Annotate SVs with Bos indicus specificity from Kasarapu et al. (2017)")

    parser.add_argument("--vcf",      required=True,
                        help="Input VCF file with SVs (ARS-UCD1.2 coordinates)")
    parser.add_argument("--snpmap",   required=True,
                        help="SNPmap_IND_TAU_ARS.txt (remapped to ARS-UCD1.2)")
    parser.add_argument("--out",      default="sv_zebu_specificity.txt",
                        help="Output summary file (default: sv_zebu_specificity.txt)")
    parser.add_argument("--out_hits", default="sv_zebu_hits.txt",
                        help="Output hits file, long format (default: sv_zebu_hits.txt)")
    parser.add_argument("--flank",    type=int, default=1000,
                        help="Flanking window in bp around SV boundaries (default: 1000)")
    parser.add_argument("--threshold", type=float, default=0.5,
                        help="Pr(Indicina) threshold to classify a SNP as zebu-specific "
                             "(default: 0.5; use 0.95 for top-ranked)")

    return parser.parse_args()


# ---------------------------------------------------------------------------
# Load SNPmap into a per-chromosome list for fast window queries
# ---------------------------------------------------------------------------

def load_snpmap(filepath):
    """
    Returns dict: {chr -> [(pos_ars, gene, pr_ind, pr_tau), ...]}
    Sorted by position for binary search.
    """
    snpmap = defaultdict(list)
    n = 0

    with open(filepath, "r") as fh:
        header = fh.readline()  # skip header

        for line in fh:
            line = line.rstrip("\r\n")
            if not line:
                continue

            parts = line.split("\t")
            # Gene  ChrUMD  PosUMD  Indicine  Taurine  ChrARS  PosARS
            if len(parts) < 7:
                continue

            gene    = parts[0]
            chr_ars = parts[5]
            pos_ars = parts[6]
            pr_ind  = parts[3]
            pr_tau  = parts[4]

            # Skip unmapped entries
            if chr_ars == "NA" or pos_ars == "NA":
                continue

            try:
                pos_ars = int(pos_ars)
                pr_ind  = float(pr_ind)
                pr_tau  = float(pr_tau)
            except ValueError:
                continue

            snpmap[chr_ars].append((pos_ars, gene, pr_ind, pr_tau))
            n += 1

    # Sort each chromosome by position
    for chrom in snpmap:
        snpmap[chrom].sort(key=lambda x: x[0])

    print("[SNPmap] Loaded {:,} entries across {} chromosomes".format(
        n, len(snpmap)))
    return snpmap


# ---------------------------------------------------------------------------
# Binary search: find SNPs within [start, end] window
# ---------------------------------------------------------------------------

def query_window(snpmap_chr, start, end):
    """
    Returns all SNPmap entries where pos falls within [start, end].
    snpmap_chr is a sorted list of (pos, gene, pr_ind, pr_tau).
    Uses binary search for left boundary.
    """
    if not snpmap_chr:
        return []

    # Binary search for leftmost position >= start
    lo, hi = 0, len(snpmap_chr)
    while lo < hi:
        mid = (lo + hi) // 2
        if snpmap_chr[mid][0] < start:
            lo = mid + 1
        else:
            hi = mid

    # Collect all entries up to end
    hits = []
    i = lo
    while i < len(snpmap_chr) and snpmap_chr[i][0] <= end:
        hits.append(snpmap_chr[i])
        i += 1

    return hits


# ---------------------------------------------------------------------------
# Parse INFO field from VCF
# ---------------------------------------------------------------------------

def parse_info(info_str):
    """Returns dict of INFO key=value pairs."""
    info = {}
    for field in info_str.split(";"):
        if "=" in field:
            k, v = field.split("=", 1)
            info[k] = v
        else:
            info[field] = True
    return info


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    args = parse_args()
    flank     = args.flank
    threshold = args.threshold

    # Load SNPmap
    snpmap = load_snpmap(args.snpmap)

    # Output headers
    summary_header = (
        "SV_ID\tCHROM\tPOS\tEND\tSVTYPE\tSVLEN\tSUPP\t"
        "N_SNPs_overlap\tN_zebu_SNPs\tN_taurine_SNPs\t"
        "Zebu_fraction\tMean_Pr_Indicina\tMax_Pr_Indicina\t"
        "Zebu_classification\t"
        "Genes_zebu\tGenes_taurine\tGenes_all\n"
    )

    hits_header = (
        "SV_ID\tCHROM\tSV_POS\tSV_END\tSVTYPE\t"
        "Gene\tSNP_Pos_ARS\tPr_Indicina\tPr_Taurina\t"
        "Zebu_specific\n"
    )

    n_sv_total    = 0
    n_sv_with_hit = 0
    n_sv_zebu     = 0

    with open(args.vcf, "r") as vcf_fh, \
         open(args.out, "w") as out_fh, \
         open(args.out_hits, "w") as hits_fh:

        out_fh.write(summary_header)
        hits_fh.write(hits_header)

        for raw_line in vcf_fh:
            line = raw_line.rstrip("\r\n")

            # Skip VCF header lines
            if line.startswith("#"):
                continue

            parts = line.split("\t")
            if len(parts) < 8:
                continue

            chrom    = parts[0]
            pos      = int(parts[1])
            sv_id    = parts[2]
            ref      = parts[3]
            alt      = parts[4]
            qual     = parts[5]
            filt     = parts[6]
            info_str = parts[7]

            info = parse_info(info_str)

            svtype = info.get("SVTYPE", "UNK")
            svlen  = info.get("SVLEN",  "NA")
            supp   = info.get("SUPP",   "NA")

            # Get END position: prefer INFO END, fallback to POS + abs(SVLEN)
            if "END" in info:
                try:
                    end = int(info["END"])
                except ValueError:
                    end = pos
            elif svlen != "NA":
                try:
                    end = pos + abs(int(svlen))
                except ValueError:
                    end = pos
            else:
                end = pos

            n_sv_total += 1

            # Query SNPmap with flanking window
            win_start = max(0, pos - flank)
            win_end   = end + flank

            chr_hits = snpmap.get(chrom, [])
            hits = query_window(chr_hits, win_start, win_end)

            # Classify hits
            zebu_hits    = [h for h in hits if h[2] >= threshold]
            taurine_hits = [h for h in hits if h[2] <  threshold]

            n_hits    = len(hits)
            n_zebu    = len(zebu_hits)
            n_taurine = len(taurine_hits)

            # Summary stats
            if n_hits > 0:
                n_sv_with_hit += 1
                pr_ind_values  = [h[2] for h in hits]
                mean_pr_ind    = sum(pr_ind_values) / n_hits
                max_pr_ind     = max(pr_ind_values)
                zebu_fraction  = n_zebu / n_hits

                genes_zebu    = ",".join(sorted(set(h[1] for h in zebu_hits)))    or "."
                genes_taurine = ",".join(sorted(set(h[1] for h in taurine_hits))) or "."
                genes_all     = ",".join(sorted(set(h[1] for h in hits)))

                # Classification label
                if zebu_fraction >= 0.75:
                    classif = "Zebu-enriched"
                    n_sv_zebu += 1
                elif zebu_fraction <= 0.25:
                    classif = "Taurine-enriched"
                else:
                    classif = "Mixed"
            else:
                mean_pr_ind   = "NA"
                max_pr_ind    = "NA"
                zebu_fraction = "NA"
                genes_zebu    = "."
                genes_taurine = "."
                genes_all     = "."
                classif       = "No_overlap"

            # Write summary line
            out_fh.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(
                sv_id, chrom, pos, end, svtype, svlen, supp,
                n_hits, n_zebu, n_taurine,
                "{:.4f}".format(zebu_fraction) if zebu_fraction != "NA" else "NA",
                "{:.4f}".format(mean_pr_ind)   if mean_pr_ind   != "NA" else "NA",
                "{:.4f}".format(max_pr_ind)    if max_pr_ind    != "NA" else "NA",
                classif,
                genes_zebu, genes_taurine, genes_all
            ))

            # Write hits (long format)
            for pos_snp, gene, pr_ind, pr_tau in hits:
                is_zebu = "Yes" if pr_ind >= threshold else "No"
                hits_fh.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:.6f}\t{:.6f}\t{}\n".format(
                    sv_id, chrom, pos, end, svtype,
                    gene, pos_snp, pr_ind, pr_tau, is_zebu
                ))

    # Final report
    print("\n[Results]")
    print("  Total SVs processed    : {:,}".format(n_sv_total))
    print("  SVs with SNP overlap   : {:,} ({:.1f}%)".format(
        n_sv_with_hit, 100 * n_sv_with_hit / n_sv_total if n_sv_total else 0))
    print("  SVs Zebu-enriched      : {:,} ({:.1f}% of those with overlap)".format(
        n_sv_zebu,
        100 * n_sv_zebu / n_sv_with_hit if n_sv_with_hit else 0))
    print("  Pr(Indicina) threshold : >= {:.2f}".format(threshold))
    print("  Flanking window        : +/- {:,} bp".format(flank))
    print("\n[Output]")
    print("  Summary : {}".format(args.out))
    print("  Hits    : {}".format(args.out_hits))


if __name__ == "__main__":
    main()