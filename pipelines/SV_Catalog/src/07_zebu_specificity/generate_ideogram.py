#!/usr/bin/env python3
# fig7B_indicine_ideogram.py
# Generates Fig 7B: chromosomal ideogram with indicine-specific tag SNPs
# (Kasarapu et al. 2017) overlaid on the Nelore SV catalog.
#
# Parameters to adjust are grouped in the PARAMETERS section below.
#
# Usage:
#   python3 fig7B_indicine_ideogram.py
#
# Input files (adjust paths in the PARAMETERS section):
#   sv_annotations.tsv      - VEP annotation table (one row per SV)
#   tag_snps_per_sv.tsv     - BovineHD tag SNPs (used only to get SV positions)
#   SNPmap_IND.txt          - Indicine SNP map from Kasarapu et al. 2017
#
# Output:
#   Fig7B_indicine_ideogram.pdf / .png

import warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# ==============================================================================
# PARAMETERS -- adjust here
# ==============================================================================

# Input file paths
ANNOTATIONS_FILE = "/home/bt-h1/KG000421/KG000421_svs/readBased/4.func_annot_VEP/sv_annotations.tsv"
TAGS_FILE        = "/home/bt-h1/KG000421/KG000421_svs/readBased/6.LD_snpBovHD_svs/reports/tag_snps_per_sv.tsv"
SNP_IND_FILE     = "snps_chip/SNPmap_IND.txt"

# Output file paths (extensions .pdf and .png are both saved)
OUTPUT_BASE      = "Fig7B_indicine_ideogram"

# Indicine posterior probability threshold (Kasarapu et al.)
# A SNP is considered indicine-specific if Indicine >= this value.
# Options to test:
#   0.5  -> 1,652 SNPs (broad definition, Pr(Bos indicus) > chance)
#   0.7  ->   565 SNPs (moderate stringency)
#   0.9  ->    93 SNPs (high stringency, strongly indicine)
#   0.95 ->    64 SNPs (very stringent)
INDICINE_THRESHOLD = 0.5

# Maximum distance (bp) between a SV and an indicine SNP to consider
# the SV as "tagged". Equivalent to the LD window used in the analysis.
# Options to test:
#   100_000  ->  100 kb (tight window, high specificity)
#   500_000  ->  500 kb (default, matches LD analysis window)
#   1_000_000 -> 1 Mb  (permissive)
WINDOW_BP = 500_000

# SV density bin size (bp). Controls the colour gradient resolution.
# Smaller values = finer resolution but noisier appearance.
BIN_BP = 5_000_000    # 5 Mb

# Density colour scale saturation point (SVs per bin).
# Bins with >= this many SVs get the darkest colour.
# Increase if your data has hotspots with very high SV counts.
DENSITY_MAX = 500

# Figure size in inches (width, height)
FIG_SIZE = (16, 9)

# Output resolution in DPI (300 for publication, 150 for draft)
DPI = 1200

# ==============================================================================
# NC accession -> BTA chromosome number mapping (ARS-UCD2.0, autosomes 1-29)
# ==============================================================================
NC_TO_BTA = {
    'NC_037328.1':  1, 'NC_037329.1':  2, 'NC_037330.1':  3,
    'NC_037331.1':  4, 'NC_037332.1':  5, 'NC_037333.1':  6,
    'NC_037334.1':  7, 'NC_037335.1':  8, 'NC_037336.1':  9,
    'NC_037337.1': 10, 'NC_037338.1': 11, 'NC_037339.1': 12,
    'NC_037340.1': 13, 'NC_037341.1': 14, 'NC_037342.1': 15,
    'NC_037343.1': 16, 'NC_037344.1': 17, 'NC_037345.1': 18,
    'NC_037346.1': 19, 'NC_037347.1': 20, 'NC_037348.1': 21,
    'NC_037349.1': 22, 'NC_037350.1': 23, 'NC_037351.1': 24,
    'NC_037352.1': 25, 'NC_037353.1': 26, 'NC_037354.1': 27,
    'NC_037355.1': 28, 'NC_037356.1': 29,
}

# ARS-UCD2.0 chromosome sizes (bp)
CHROM_SIZES = {
    1:  158534110, 2:  136231102, 3:  121005158, 4:  120000601,
    5:  120089555, 6:  117806340, 7:  110682743, 8:  113319770,
    9:  105708250, 10: 103308737, 11: 106982472, 12:  87216183,
    13:  83472345, 14:  82403005, 15:  85007780, 16:  81013979,
    17:  73167244, 18:  65820629, 19:  63449741, 20:  71974595,
    21:  69862954, 22:  61435874, 23:  52530064, 24:  62317255,
    25:  42350435, 26:  51992305, 27:  45612108, 28:  46982305,
    29:  51098607,
}

CHROMS = list(range(1, 30))
MAX_MB = max(CHROM_SIZES.values()) / 1e6
BAR_H  = 0.45

# ==============================================================================
# Figure aesthetics
# ==============================================================================
plt.rcParams.update({
    "font.family":       "DejaVu Sans",
    "font.size":          8,
    "axes.titlesize":     12,
    "axes.labelsize":     12,
    "xtick.labelsize":    12,
    "ytick.labelsize":    12,
    "axes.spines.top":    False,
    "axes.spines.right":  False,
    "axes.linewidth":     0.7,
    "xtick.major.width":  0.7,
    "ytick.major.width":  0.7,
    "xtick.major.size":   3,
    "ytick.major.size":   3,
    "pdf.fonttype":       42,
    "ps.fonttype":        42,
    "savefig.dpi":        DPI,
    "savefig.bbox":       "tight",
    "savefig.pad_inches": 0.05,
})

# ==============================================================================
# Load data
# ==============================================================================
print("=" * 60)
print("  Fig 7B -- Indicine-specific tag SNP ideogram")
print("=" * 60)
print(f"\nParameters:")
print(f"  Indicine threshold : >= {INDICINE_THRESHOLD}")
print(f"  Tag window         : +/- {WINDOW_BP/1000:.0f} kb")
print(f"  Density bin size   : {BIN_BP/1e6:.0f} Mb")
print()

print("Loading input files...")
ann     = pd.read_csv(ANNOTATIONS_FILE, sep="\t", low_memory=False)
tags    = pd.read_csv(TAGS_FILE,        sep="\t", low_memory=False)
snp_ind = pd.read_csv(SNP_IND_FILE,     sep="\t")

print(f"  SVs loaded         : {len(ann):,}")
print(f"  Indicine SNPs (all): {len(snp_ind):,}")

# Map NC accessions to BTA integers
ann["BTA"] = ann["CHROM"].map(NC_TO_BTA)

n_unmapped = ann["BTA"].isna().sum()
if n_unmapped > 0:
    print(f"  [WARNING] {n_unmapped} SVs could not be mapped to a BTA chromosome")

# ==============================================================================
# Filter indicine-specific SNPs
# ==============================================================================
snp_filt = snp_ind[snp_ind["Indicine"] >= INDICINE_THRESHOLD].copy()
snp_filt["BTA"] = snp_filt["Chromosome"].astype(int)

print(f"\nIndicine SNPs after filtering (>= {INDICINE_THRESHOLD}): {len(snp_filt):,}")
print("  Distribution per chromosome:")
chr_counts = snp_filt.groupby("BTA").size()
for bta in CHROMS:
    n = chr_counts.get(bta, 0)
    bar = "#" * (n // 5)
    print(f"    BTA{bta:2d}: {n:4d}  {bar}")

# ==============================================================================
# Tag SVs: find nearest indicine SNP within WINDOW_BP on the same chromosome
# ==============================================================================
print(f"\nTagging SVs (window = {WINDOW_BP/1000:.0f} kb)...")

# Index indicine SNP positions by chromosome for fast lookup
ind_by_chr = {
    c: grp["SNP_Position"].values
    for c, grp in snp_filt.groupby("BTA")
}

tagged     = []
tag_pos    = []
tag_r_ind  = []   # Indicine score of the nearest SNP (for optional colouring)

for _, row in ann.iterrows():
    bta = row["BTA"]
    pos = row["POS"]

    if pd.isna(bta) or int(bta) not in ind_by_chr:
        tagged.append(False)
        tag_pos.append(np.nan)
        tag_r_ind.append(np.nan)
        continue

    positions = ind_by_chr[int(bta)]
    dists     = np.abs(positions - pos)
    min_idx   = dists.argmin()
    min_dist  = dists[min_idx]

    if min_dist <= WINDOW_BP:
        tagged.append(True)
        tag_pos.append(float(positions[min_idx]))
        # Retrieve the Indicine score for that SNP
        mask = (snp_filt["BTA"] == int(bta)) & \
               (snp_filt["SNP_Position"] == positions[min_idx])
        ind_score = snp_filt.loc[mask, "Indicine"].values
        tag_r_ind.append(float(ind_score[0]) if len(ind_score) > 0 else np.nan)
    else:
        tagged.append(False)
        tag_pos.append(np.nan)
        tag_r_ind.append(np.nan)

ann["HAS_TAG_IND"] = tagged
ann["TAG_POS_IND"] = tag_pos
ann["TAG_IND_SCR"] = tag_r_ind

n_tagged = ann["HAS_TAG_IND"].sum()
pct      = 100 * n_tagged / len(ann)
print(f"\nResult: {n_tagged:,} SVs tagged ({pct:.1f}%)")
print("  Tagged SVs per chromosome:")
for bta in CHROMS:
    sub  = ann[ann["BTA"] == bta]
    n_sv = len(sub)
    n_tg = sub["HAS_TAG_IND"].sum()
    pct_c = 100 * n_tg / n_sv if n_sv else 0
    bar   = "#" * (n_tg // 100)
    print(f"    BTA{bta:2d}: {n_tg:5,} / {n_sv:5,}  ({pct_c:4.1f}%)  {bar}")

# ==============================================================================
# Draw ideogram
# ==============================================================================
print("\nRendering figure...")

fig, ax = plt.subplots(figsize=FIG_SIZE)

for idx, bta in enumerate(CHROMS):
    size = CHROM_SIZES[bta]
    y    = idx

    # Chromosome backbone
    ax.barh(y, size / 1e6, left=0, height=BAR_H,
            color="#D5D8DC", edgecolor="#AAB7B8",
            linewidth=0.35, zorder=1)

    sub = ann[ann["BTA"] == bta]
    if sub.empty:
        continue

    # SV density bins coloured by count
    n_bins    = max(1, int(size // BIN_BP))
    bin_edges = np.linspace(0, size, n_bins + 1)
    for b in range(n_bins):
        bstart = bin_edges[b]
        bend   = bin_edges[b + 1]
        n_sv   = sub[(sub["POS"] >= bstart) & (sub["POS"] < bend)].shape[0]
        if n_sv == 0:
            continue
        intensity = min(n_sv / DENSITY_MAX, 1.0)
        color     = plt.cm.YlOrRd(0.15 + intensity * 0.80)
        ax.barh(y, (bend - bstart) / 1e6, left=bstart / 1e6,
                height=BAR_H * 0.85, color=color,
                edgecolor="none", zorder=2, alpha=0.92)

    # Indicine tag SNPs -- blue dots above chromosome bar
    tagged_sub = sub[sub["HAS_TAG_IND"] == True]
    valid_pos  = tagged_sub["TAG_POS_IND"].dropna()
    if not valid_pos.empty:
        ax.scatter(
            valid_pos / 1e6,
            [y + BAR_H * 0.72] * len(valid_pos),
            color="#2980B9", s=15, zorder=4,
            alpha=0.75, edgecolors="none"
        )

    # HIGH impact SVs -- red triangles below chromosome bar
    high = sub[sub["IMPACT"] == "HIGH"]
    if not high.empty:
        ax.scatter(
            high["POS"] / 1e6,
            [y - BAR_H * 0.72] * len(high),
            color="#C0392B", marker="v", s=20,
            zorder=4, alpha=0.85, edgecolors="none"
        )

# Axes formatting
ax.set_yticks(range(len(CHROMS)))
ax.set_yticklabels([str(c) for c in CHROMS], fontsize=11)
ax.set_ylabel("Chromosome")
ax.set_xlabel("Position (Mb)")
ax.set_xlim(-2, MAX_MB + 2)
ax.set_ylim(-0.85, len(CHROMS) - 0.15)
ax.invert_yaxis()
ax.spines["left"].set_visible(False)
ax.tick_params(left=False)

#ax.set_title(
#    f"Figure 7B -- Chromosomal Distribution of Structural Variants\n"
#    f"Tag SNP panel: Indicine-specific (Kasarapu et al. 2017, "
#    f"Indicine >= {INDICINE_THRESHOLD}, window = {WINDOW_BP/1000:.0f} kb)\n"
#    f"{n_tagged:,} SVs tagged ({pct:.1f}%)",
#    fontsize=9, fontweight="bold", loc="left", pad=6
#)

# Colour bar for SV density
sm = plt.cm.ScalarMappable(
    cmap="YlOrRd",
    norm=plt.Normalize(vmin=0, vmax=DENSITY_MAX)
)
sm.set_array([])
cbar = fig.colorbar(sm, ax=ax, orientation="vertical",
                    fraction=0.012, pad=0.01, shrink=0.6)
cbar.set_label(f"SVs per {BIN_BP/1e6:.0f} Mb bin", fontsize=12)
cbar.ax.tick_params(labelsize=10)

# Legend
legend_elements = [
    #mpatches.Patch(color="#D5D8DC", label="Chromosome"),
    #mpatches.Patch(color=plt.cm.YlOrRd(0.7), label="SV density"),
    plt.Line2D([0], [0], marker="o", color="w",
               markerfacecolor="#2980B9", markersize=10,
               label=f"Indicine tag SNP (>= {INDICINE_THRESHOLD})"),
    plt.Line2D([0], [0], marker="v", color="w",
               markerfacecolor="#C0392B", markersize=10,
               label="HIGH impact SV"),
]
ax.legend(handles=legend_elements, loc="lower right",
          frameon=True, framealpha=0.92,
          fontsize=11, edgecolor="#AAB7B8")

# ==============================================================================
# Save
# ==============================================================================
for ext in ["pdf", "png"]:
    path = f"{OUTPUT_BASE}.{ext}"
    fig.savefig(path, format=ext)
    print(f"Saved: {path}")

plt.close(fig)
print("\nDone.")