# -*- coding: windows-1252 -*-
#!/usr/bin/env python3
"""
visualizar_svs_nelore.py
========================
Publication-quality figures for the Nelore SV catalog.
Reads real output files from the bioinformatics pipeline and produces
7 figures as PDF + PNG (300 dpi), ready for manuscript submission.

Usage:
    python3 visualizar_svs_nelore.py

Output:  figuras/Fig1_sv_composition.pdf  ...  figuras/Fig7_ideogram.pdf
         figuras/panel_completo.pdf   (all figures in one PDF)

Dependencies:
    pip install matplotlib seaborn pandas numpy scipy --break-system-packages
"""

import os
import sys
import warnings
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.ticker as mticker
from matplotlib.gridspec import GridSpec
from matplotlib.colors import LinearSegmentedColormap
import seaborn as sns
from scipy import stats

warnings.filterwarnings("ignore")

# == Output directories =========================================================
RELATORIO_DIR = "reports"
OUTPUT_DIR    = "figuras"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# == Global aesthetics (journal-ready) =========================================
FONT_FAMILY  = "DejaVu Sans"
BASE_SIZE    = 9
TITLE_SIZE   = 10
LABEL_SIZE   = 9
TICK_SIZE    = 8
LEGEND_SIZE  = 8
DPI          = 300
FIG_FORMAT   = ["pdf", "png"]

plt.rcParams.update({
    "font.family":          FONT_FAMILY,
    "font.size":            BASE_SIZE,
    "axes.titlesize":       TITLE_SIZE,
    "axes.labelsize":       LABEL_SIZE,
    "xtick.labelsize":      TICK_SIZE,
    "ytick.labelsize":      TICK_SIZE,
    "legend.fontsize":      LEGEND_SIZE,
    "axes.spines.top":      False,
    "axes.spines.right":    False,
    "axes.linewidth":       0.8,
    "xtick.major.width":    0.8,
    "ytick.major.width":    0.8,
    "xtick.major.size":     3,
    "ytick.major.size":     3,
    "figure.dpi":           DPI,
    "savefig.dpi":          DPI,
    "savefig.bbox":         "tight",
    "savefig.pad_inches":   0.05,
    "pdf.fonttype":         42,   # embeds fonts (required by most journals)
    "ps.fonttype":          42,
})

# == Colour palette (colour-blind safe, Nature/Science style) ==================
SV_COLORS = {
    "DEL": "#E64B35",   # red
    "INS": "#4DBBD5",   # teal
    "DUP": "#00A087",   # green
    "INV": "#F39B7F",   # salmon
}
IMPACT_COLORS = {
    "HIGH":     "#C0392B",
    "MODERATE": "#E67E22",
    "LOW":      "#27AE60",
    "MODIFIER": "#95A5A6",
}
PALETTE_BLUE = LinearSegmentedColormap.from_list(
    "blue_gradient", ["#EBF5FB", "#2E86C1", "#1A5276"])

# == RefSeq -> BTA chromosome name mapping (ARS-UCD2.0) ========================
# NC_037328.1 = BTA1, NC_037329.1 = BTA2, ..., NC_037356.1 = BTA29
REFSEQ_TO_BTA = {f"NC_{37327 + i:06d}.1": f"BTA{i}" for i in range(1, 30)}

# == Load data =================================================================
def load_data():
    cat  = pd.read_csv(f"{RELATORIO_DIR}/final_nelore_sv_catalog.tsv", sep="\t")
    sup  = pd.read_csv(f"{RELATORIO_DIR}/support_per_sv.tsv",          sep="\t")
    tags = pd.read_csv(f"{RELATORIO_DIR}/tag_snps_per_sv.tsv",         sep="\t")

    # Strip whitespace from column names (catches invisible padding)
    cat.columns  = cat.columns.str.strip()
    sup.columns  = sup.columns.str.strip()
    tags.columns = tags.columns.str.strip()

    # Map RefSeq accessions to BTA nomenclature used throughout the script
    cat["CHROM"] = cat["CHROM"].map(REFSEQ_TO_BTA).fillna(cat["CHROM"])

    # Coerce numeric columns safely
    cat["SVLEN"]               = pd.to_numeric(cat["SVLEN"],               errors="coerce").abs()
    cat["R2"]                  = pd.to_numeric(cat["R2"],                  errors="coerce")
    cat["N_AMOSTRAS_VALIDADAS"] = pd.to_numeric(cat["N_AMOSTRAS_VALIDADAS"], errors="coerce")
    tags["R2"]                 = pd.to_numeric(tags["R2"],                 errors="coerce")
    tags["DISTANCE_BP"]        = pd.to_numeric(tags["DISTANCE_BP"],        errors="coerce")

    return cat, sup, tags


def save_fig(fig, name):
    """Save figure as PDF (vector) and PNG (300 dpi raster)."""
    for fmt in FIG_FORMAT:
        path = os.path.join(OUTPUT_DIR, f"{name}.{fmt}")
        if fmt == "png":
            # Explicit dpi and bbox for high-quality raster output
            fig.savefig(path, format=fmt, dpi=300,
                        bbox_inches="tight", pad_inches=0.05)
        else:
            # PDF keeps vector rendering (fonts embedded via rcParams)
            fig.savefig(path, format=fmt,
                        bbox_inches="tight", pad_inches=0.05)
    print(f"  [saved] {name}.pdf / .png")


# =============================================================================
# FIG 1 -> SV Type Composition  (donut + count bar)
# =============================================================================
def fig1_composition(cat):
    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.2))
    fig.suptitle("Figure 1 -> Structural Variant Composition", fontsize=TITLE_SIZE,
                 fontweight="bold", y=1.01)

    # == A: Donut ==
    ax = axes[0]
    counts = cat["SVTYPE"].value_counts().reindex(["DEL","INS","DUP","INV"]).fillna(0)
    total  = counts.sum()
    colors = [SV_COLORS[t] for t in counts.index]

    wedges, texts, autotexts = ax.pie(
        counts, labels=None, autopct="%1.1f%%",
        colors=colors, startangle=90,
        wedgeprops=dict(width=0.55, edgecolor="white", linewidth=1.2),
        pctdistance=0.78,
    )
    for at in autotexts:
        at.set_fontsize(8)
        at.set_fontweight("bold")
        at.set_color("white")

    ax.text(0, 0, f"n={int(total):,}", ha="center", va="center",
            fontsize=9, fontweight="bold", color="#2C3E50")

    legend_labels = [f"{t}  (n={int(counts[t]):,})" for t in counts.index]
    ax.legend(wedges, legend_labels, loc="lower center",
              bbox_to_anchor=(0.5, -0.18), ncol=2,
              frameon=False, fontsize=LEGEND_SIZE)
    ax.set_title("A  SV type distribution", loc="left", fontsize=LABEL_SIZE,
                 fontweight="bold")

    # == B: Horizontal bar -> count + impact breakdown ==
    ax2 = axes[1]
    sv_order  = ["DEL","INS","DUP","INV"]
    imp_order = ["HIGH","MODERATE","LOW","MODIFIER"]

    bottom = np.zeros(len(sv_order))
    for imp in imp_order:
        vals = [
            cat[(cat["SVTYPE"]==t) & (cat["IMPACT"]==imp)].shape[0]
            for t in sv_order
        ]
        bars = ax2.barh(sv_order, vals, left=bottom,
                        color=IMPACT_COLORS[imp], label=imp,
                        edgecolor="white", linewidth=0.6, height=0.6)
        bottom += np.array(vals)

    ax2.set_xlabel("Number of SVs")
    ax2.set_title("B  Functional impact by SV type", loc="left",
                  fontsize=LABEL_SIZE, fontweight="bold")
    ax2.legend(title="Impact", loc="lower right", frameon=False,
               fontsize=LEGEND_SIZE, title_fontsize=LEGEND_SIZE)
    ax2.set_xlim(0, bottom.max() * 1.15)

    # Annotate totals
    for i, t in enumerate(sv_order):
        n = cat[cat["SVTYPE"]==t].shape[0]
        ax2.text(bottom[i] + 5, i, str(n),
                 va="center", ha="left", fontsize=8, color="#2C3E50")

    fig.tight_layout()
    save_fig(fig, "Fig1_sv_composition")
    plt.close(fig)


# =============================================================================
# FIG 2 -> SV Size Distribution by Type
# =============================================================================
def fig2_size_distribution(cat):
    fig, axes = plt.subplots(2, 2, figsize=(7.2, 5.5))
    fig.suptitle("Figure 2 -> SV Size Distribution by Type",
                 fontsize=TITLE_SIZE, fontweight="bold", y=1.01)

    sv_order = ["DEL","INS","DUP","INV"]
    bins = np.logspace(np.log10(50), np.log10(2_000_000), 40)

    for ax, svtype in zip(axes.flat, sv_order):
        data = cat.loc[cat["SVTYPE"] == svtype, "SVLEN"].dropna()
        data = data[data >= 50]

        ax.hist(data, bins=bins, color=SV_COLORS[svtype],
                edgecolor="white", linewidth=0.5, alpha=0.85)
        ax.set_xscale("log")

        # Median line
        med = data.median()
        ax.axvline(med, color="#2C3E50", lw=1.2, ls="--", alpha=0.8)
        ax.text(med * 1.15, ax.get_ylim()[1] * 0.88,
                f"Median\n{med/1000:.1f} kb", fontsize=7, color="#2C3E50")

        ax.set_title(f"{svtype}  (n={len(data):,})", loc="left",
                     fontsize=LABEL_SIZE, fontweight="bold",
                     color=SV_COLORS[svtype])
        ax.set_xlabel("SV length (bp)")
        ax.set_ylabel("Count")
        ax.xaxis.set_major_formatter(
            mticker.FuncFormatter(
                lambda x, _: f"{int(x/1000)}kb" if x >= 1000 else f"{int(x)}bp"))

    fig.tight_layout()
    save_fig(fig, "Fig2_size_distribution")
    plt.close(fig)


# =============================================================================
# FIG 3 -> Sample Support (validation depth)
# =============================================================================
def fig3_sample_support(cat):
    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.4))
    fig.suptitle("Figure 3 -> Validation Support Across Animals",
                 fontsize=TITLE_SIZE, fontweight="bold", y=1.01)

    # == A: histogram of N_AMOSTRAS_VALIDADAS ==
    ax = axes[0]
    n   = cat["N_AMOSTRAS_VALIDADAS"].dropna().astype(int)
    bins = np.arange(0.5, 21.5, 1)
    ax.hist(n, bins=bins, color="#4DBBD5", edgecolor="white", linewidth=0.6)
    ax.axvline(n.median(), color="#E64B35", lw=1.5, ls="--",
               label=f"Median = {n.median():.0f}")
    ax.set_xlabel("Number of animals supporting SV")
    ax.set_ylabel("Number of SVs")
    ax.set_title("A  Distribution of validation support", loc="left",
                 fontsize=LABEL_SIZE, fontweight="bold")
    ax.legend(frameon=False)
    ax.set_xlim(0, 21)

    # == B: support breakdown by SV type (boxplot) ==
    ax2 = axes[1]
    sv_order = ["DEL","INS","DUP","INV"]
    data_by_type = [
        cat.loc[cat["SVTYPE"]==t, "N_AMOSTRAS_VALIDADAS"].dropna()
        for t in sv_order
    ]
    bp = ax2.boxplot(data_by_type, patch_artist=True, notch=False,
                     widths=0.55, showfliers=True,
                     flierprops=dict(marker="o", markersize=2,
                                     alpha=0.4, linestyle="none"))
    for patch, svtype in zip(bp["boxes"], sv_order):
        patch.set_facecolor(SV_COLORS[svtype])
        patch.set_alpha(0.75)
    for median in bp["medians"]:
        median.set_color("#2C3E50")
        median.set_linewidth(1.5)

    ax2.set_xticks(range(1, len(sv_order)+1))
    ax2.set_xticklabels(sv_order)
    ax2.set_ylabel("Number of animals supporting SV")
    ax2.set_title("B  Support by SV type", loc="left",
                  fontsize=LABEL_SIZE, fontweight="bold")
    ax2.set_ylim(0, 22)

    fig.tight_layout()
    save_fig(fig, "Fig3_sample_support")
    plt.close(fig)


# =============================================================================
# FIG 4 -> r^2 Distribution and Tag SNP Characteristics
# =============================================================================
def fig4_ld_tagging(cat, tags):
    fig, axes = plt.subplots(1, 3, figsize=(10.5, 3.6))
    fig.suptitle("Figure 4 -> LD-based Tagging: BovineHD SNPs x SVs",
                 fontsize=TITLE_SIZE, fontweight="bold", y=1.01)

    tagged   = cat[cat["HAS_TAG_SNP"] == True]
    untagged = cat[cat["HAS_TAG_SNP"] == False]

    # == A: r^2 histogram for tagged SVs ==
    ax = axes[0]
    r2_vals = tags["R2"].dropna()
    ax.hist(r2_vals, bins=30, color="#00A087", edgecolor="white", linewidth=0.5)
    ax.axvline(0.3,  color="#E64B35",  lw=1.2, ls="--", label="r^2=0.30 (threshold)")
    ax.axvline(0.8,  color="#F39B7F",  lw=1.2, ls=":",  label="r^2=0.80 (strong LD)")
    ax.set_xlabel("r^2 (SNP-SV linkage disequilibrium)")
    ax.set_ylabel("Number of SV-SNP pairs")
    ax.set_title("A  r^2 distribution", loc="left",
                 fontsize=LABEL_SIZE, fontweight="bold")
    ax.legend(frameon=False, fontsize=7)

    # == B: % tagged by SV type ==
    ax2 = axes[1]
    sv_order = ["DEL","INS","DUP","INV"]
    pct_tagged = []
    for t in sv_order:
        total = cat[cat["SVTYPE"]==t].shape[0]
        n_tag = cat[(cat["SVTYPE"]==t) & (cat["HAS_TAG_SNP"]==True)].shape[0]
        pct_tagged.append(100 * n_tag / total if total else 0)

    bars = ax2.bar(sv_order, pct_tagged,
                   color=[SV_COLORS[t] for t in sv_order],
                   edgecolor="white", linewidth=0.8, width=0.6)
    ax2.axhline(100 * tagged.shape[0] / cat.shape[0],
                color="#2C3E50", lw=1.2, ls="--", alpha=0.7,
                label=f"Overall: {100*tagged.shape[0]/cat.shape[0]:.1f}%")
    for bar, pct in zip(bars, pct_tagged):
        ax2.text(bar.get_x() + bar.get_width()/2,
                 bar.get_height() + 0.4,
                 f"{pct:.1f}%", ha="center", va="bottom", fontsize=8)
    ax2.set_ylabel("SVs with tag SNP (%)")
    ax2.set_title("B  Tagging rate by SV type", loc="left",
                  fontsize=LABEL_SIZE, fontweight="bold")
    ax2.legend(frameon=False, fontsize=7)
    ax2.set_ylim(0, max(pct_tagged) * 1.3)

    # == C: physical distance SNP-SV for tagged SVs ==
    ax3 = axes[2]
    dist = tags["DISTANCE_BP"].dropna() / 1000   # to kb
    ax3.hist(dist, bins=35, color="#4DBBD5", edgecolor="white", linewidth=0.5)
    ax3.axvline(dist.median(), color="#E64B35", lw=1.5, ls="--",
                label=f"Median = {dist.median():.0f} kb")
    ax3.set_xlabel("Distance between tag SNP and SV (kb)")
    ax3.set_ylabel("Count")
    ax3.set_title("C  Physical distance of tag SNPs", loc="left",
                  fontsize=LABEL_SIZE, fontweight="bold")
    ax3.legend(frameon=False)

    fig.tight_layout()
    save_fig(fig, "Fig4_ld_tagging")
    plt.close(fig)


# =============================================================================
# FIG 5 -> Functional Annotation Summary
# =============================================================================
def fig5_functional_annotation(cat):
    fig, axes = plt.subplots(1, 2, figsize=(10.0, 4.0))
    fig.suptitle("Figure 5 -> Functional Annotation (VEP)",
                 fontsize=TITLE_SIZE, fontweight="bold", y=1.01)

    # == A: Consequence types (top 9 horizontal bar) ==
    ax = axes[0]
    conseq_counts = (cat["Consequence"].value_counts().head(9)
                     .sort_values(ascending=True))
    colors_bar = plt.cm.RdYlGn_r(np.linspace(0.15, 0.85, len(conseq_counts)))

    bars = ax.barh(conseq_counts.index, conseq_counts.values,
                   color=colors_bar, edgecolor="white", linewidth=0.5, height=0.7)
    for bar, val in zip(bars, conseq_counts.values):
        ax.text(bar.get_width() + 3, bar.get_y() + bar.get_height()/2,
                str(val), va="center", ha="left", fontsize=7.5)
    ax.set_xlabel("Number of SVs")
    ax.set_title("A  Predicted consequence (VEP)", loc="left",
                 fontsize=LABEL_SIZE, fontweight="bold")
    ax.set_xlim(0, conseq_counts.max() * 1.2)
    ytick_labels = [l.replace("_", " ").replace("variant","var.").title()
                    for l in conseq_counts.index]
    ax.set_yticklabels(ytick_labels, fontsize=7.5)

    # == B: Impact x SV type heatmap (proportion) ==
    ax2 = axes[1]
    sv_order  = ["DEL","INS","DUP","INV"]
    imp_order = ["HIGH","MODERATE","LOW","MODIFIER"]
    matrix    = pd.DataFrame(index=imp_order, columns=sv_order, dtype=float)

    for imp in imp_order:
        for t in sv_order:
            n_tot = cat[cat["SVTYPE"]==t].shape[0]
            n_imp = cat[(cat["SVTYPE"]==t) & (cat["IMPACT"]==imp)].shape[0]
            matrix.loc[imp, t] = 100 * n_imp / n_tot if n_tot else 0

    matrix = matrix.astype(float)
    sns.heatmap(matrix, ax=ax2, annot=True, fmt=".1f",
                cmap="YlOrRd", linewidths=0.5, linecolor="white",
                cbar_kws={"label":"% of SVs in type", "shrink":0.8},
                annot_kws={"size": 8})
    ax2.set_xlabel("SV type")
    ax2.set_ylabel("Functional impact")
    ax2.set_title("B  Impact x SV type (% within type)", loc="left",
                  fontsize=LABEL_SIZE, fontweight="bold")
    ax2.tick_params(axis="x", rotation=0)
    ax2.tick_params(axis="y", rotation=0)

    fig.tight_layout()
    save_fig(fig, "Fig5_functional_annotation")
    plt.close(fig)


# =============================================================================
# FIG 6 -> r^2 vs Distance Scatter + r^2 by Impact
# =============================================================================
def fig6_r2_vs_distance(cat, tags):
    fig, axes = plt.subplots(1, 2, figsize=(9.0, 4.0))
    fig.suptitle("Figure 6 -> Tag SNP Quality: r^2 vs. Physical Distance",
                 fontsize=TITLE_SIZE, fontweight="bold", y=1.01)

    # == A: scatter r^2 vs distance, coloured by SV type ==
    ax = axes[0]
    for svtype in ["DEL","INS","DUP","INV"]:
        sub = tags[tags["SVTYPE"]==svtype]
        ax.scatter(sub["DISTANCE_BP"]/1000, sub["R2"],
                   color=SV_COLORS[svtype], alpha=0.55, s=18,
                   label=svtype, edgecolors="none")

    # Regression line
    x = tags["DISTANCE_BP"].dropna() / 1000
    y = tags["R2"].dropna()
    idx = x.index.intersection(y.index)
    if len(idx) > 5:
        slope, intercept, r, p, _ = stats.linregress(x[idx], y[idx])
        xfit = np.linspace(x.min(), x.max(), 200)
        ax.plot(xfit, slope * xfit + intercept,
                color="#2C3E50", lw=1.2, ls="--", alpha=0.7,
                label=f"r={r:.2f}, p={p:.2e}")

    ax.axhline(0.3, color="grey", lw=0.8, ls=":", alpha=0.7)
    ax.axhline(0.8, color="grey", lw=0.8, ls=":", alpha=0.7)
    ax.set_xlabel("Distance from SV to tag SNP (kb)")
    ax.set_ylabel("r^2 (LD)")
    ax.set_title("A  r^2 x physical distance", loc="left",
                 fontsize=LABEL_SIZE, fontweight="bold")
    ax.legend(frameon=False, markerscale=1.4, fontsize=7)
    ax.set_ylim(0, 1.05)

    # == B: r^2 distribution by functional impact ==
    ax2 = axes[1]
    imp_order  = ["HIGH","MODERATE","LOW","MODIFIER"]
    tagged_cat = cat[cat["HAS_TAG_SNP"]==True].copy()

    data_by_impact = [
        tagged_cat.loc[tagged_cat["IMPACT"]==imp, "R2"].dropna()
        for imp in imp_order
    ]
    # Filter out empty groups before passing to violinplot
    valid = [(d, imp) for d, imp in zip(data_by_impact, imp_order) if len(d) > 0]
    data_vals, imp_labels = zip(*valid) if valid else ([], [])

    vp = ax2.violinplot(data_vals, positions=range(len(imp_labels)),
                        showmedians=True, showextrema=False)
    for i, (body, imp) in enumerate(zip(vp["bodies"], imp_labels)):
        body.set_facecolor(IMPACT_COLORS[imp])
        body.set_alpha(0.7)
        body.set_edgecolor("white")
    vp["cmedians"].set_color("#2C3E50")
    vp["cmedians"].set_linewidth(2)

    ax2.set_xticks(range(len(imp_labels)))
    ax2.set_xticklabels(imp_labels, fontsize=8)
    ax2.set_ylabel("r^2 (LD with best tag SNP)")
    ax2.set_title("B  r^2 by functional impact", loc="left",
                  fontsize=LABEL_SIZE, fontweight="bold")
    ax2.set_ylim(0, 1.05)
    ax2.axhline(0.3, color="grey", lw=0.8, ls=":", alpha=0.7, label="r^2=0.30")
    ax2.legend(frameon=False, fontsize=7)

    fig.tight_layout()
    save_fig(fig, "Fig6_r2_vs_distance")
    plt.close(fig)


# =============================================================================
# FIG 7 -> Chromosomal Ideogram (SV density + tagged SVs)
# =============================================================================
def fig7_ideogram(cat):
    # ARS-UCD2.0 chromosome sizes (bp) -> autosomes BTA1-BTA29
    chrom_sizes = {
        f"BTA{i}": s for i, s in enumerate([
            158534110, 136231102, 121005158, 120000601, 120089555,
            117806340, 110682743, 113319770, 105708250, 103308737,
            106982472,  87216183,  83472345,  82403005,  85007780,
             81013979,  73167244,  65820629,  63449741,  71974595,
             69862954,  61435874,  52530064,  62317255,  42350435,
             51992305,  45612108,  46982305,  51098607
        ], 1)
    }

    # Work on a local copy to avoid modifying the shared DataFrame
    # CHROM was already mapped to BTA notation in load_data()
    cat = cat.copy()

    chroms   = [f"BTA{i}" for i in range(1, 30)]
    max_size = max(chrom_sizes.values())
    n_chroms = len(chroms)

    fig, ax = plt.subplots(figsize=(14, 5.5))
    fig.suptitle("Figure 7 -> Chromosomal Distribution of Structural Variants",
                 fontsize=TITLE_SIZE, fontweight="bold", y=1.01)

    bar_h  = 0.55
    bin_mb = 5_000_000  # 5 Mb bins for density

    for idx, chrom in enumerate(chroms):
        size = chrom_sizes[chrom]
        y    = idx

        # Chromosome backbone (grey bar)
        ax.barh(y, size / 1e6, left=0, height=bar_h,
                color="#D5D8DC", edgecolor="#AAB7B8", linewidth=0.4, zorder=1)

        chrom_svs = cat[cat["CHROM"] == chrom]
        if chrom_svs.empty:
            continue

        # Density bins coloured by SV count per 5 Mb window
        n_bins    = max(1, int(size // bin_mb))
        bin_edges = np.linspace(0, size, n_bins + 1)
        for b in range(n_bins):
            bstart = bin_edges[b]
            bend   = bin_edges[b + 1]
            n_sv   = chrom_svs[
                (chrom_svs["POS"] >= bstart) & (chrom_svs["POS"] < bend)
            ].shape[0]
            if n_sv == 0:
                continue
            intensity = min(n_sv / 500, 1.0)   # colour saturates at 500 SVs/bin
            color = plt.cm.YlOrRd(0.2 + intensity * 0.75)
            ax.barh(y, (bend - bstart) / 1e6, left=bstart / 1e6,
                    height=bar_h * 0.85, color=color,
                    edgecolor="none", zorder=2, alpha=0.9)

        # Tag SNPs -> blue dots above chromosome bar
        tagged = chrom_svs[chrom_svs["HAS_TAG_SNP"] == True]
        if not tagged.empty:
            ax.scatter(tagged["POS"] / 1e6,
                       [y + bar_h * 0.72] * len(tagged),
                       color="#2980B9", s=6, zorder=4,
                       alpha=0.75, edgecolors="none")

        # HIGH impact SVs -> red triangles below chromosome bar
        high = chrom_svs[chrom_svs["IMPACT"] == "HIGH"]
        if not high.empty:
            ax.scatter(high["POS"] / 1e6,
                       [y - bar_h * 0.72] * len(high),
                       color="#C0392B", marker="v", s=10, zorder=4,
                       alpha=0.85, edgecolors="none")

    # Y-axis: show numeric chromosome labels (1-29), not BTA prefix
    ax.set_yticks(range(n_chroms))
    ax.set_yticklabels([c.replace("BTA", "") for c in chroms], fontsize=7.5)
    ax.set_ylabel("Chromosome")
    ax.set_xlabel("Position (Mb)")
    ax.set_xlim(-2, max_size / 1e6 + 2)
    ax.set_ylim(-0.8, n_chroms - 0.2)
    ax.invert_yaxis()
    ax.spines["left"].set_visible(False)
    ax.tick_params(left=False)

    # Colour bar for SV density
    sm = plt.cm.ScalarMappable(cmap="YlOrRd",
                                norm=plt.Normalize(vmin=0, vmax=500))
    sm.set_array([])
    cbar = fig.colorbar(sm, ax=ax, orientation="vertical",
                        fraction=0.012, pad=0.01, shrink=0.6)
    cbar.set_label("SVs per 5 Mb bin", fontsize=7.5)
    cbar.ax.tick_params(labelsize=7)

    # Legend
    legend_elements = [
        mpatches.Patch(color="#D5D8DC", label="Chromosome"),
        mpatches.Patch(color=plt.cm.YlOrRd(0.7), label="SV density"),
        plt.Line2D([0], [0], marker="o", color="w", markerfacecolor="#2980B9",
                   markersize=5, label="Tag SNP"),
        plt.Line2D([0], [0], marker="v", color="w", markerfacecolor="#C0392B",
                   markersize=5, label="HIGH impact SV"),
    ]
    ax.legend(handles=legend_elements, loc="lower right",
              frameon=True, framealpha=0.9, fontsize=7.5,
              edgecolor="#AAB7B8")

    fig.tight_layout()
    save_fig(fig, "Fig7_ideogram")
    plt.close(fig)


# =============================================================================
# PANEL -> all figures in one PDF (Extended Data style)
# =============================================================================
def build_panel():
    fig_files = [
        "Fig1_sv_composition.pdf",
        "Fig2_size_distribution.pdf",
        "Fig3_sample_support.pdf",
        "Fig4_ld_tagging.pdf",
        "Fig5_functional_annotation.pdf",
        "Fig6_r2_vs_distance.pdf",
        "Fig7_ideogram.pdf",
    ]
    pdf_path  = os.path.join(OUTPUT_DIR, "panel_completo.pdf")
    merge_cmd = (
        "pdfunite "
        + " ".join(os.path.join(OUTPUT_DIR, f) for f in fig_files)
        + f" {pdf_path}"
    )
    print(f"\n  To merge all figures into one PDF, run:\n  {merge_cmd}")


# =============================================================================
# MAIN
# =============================================================================
def main():
    print("=" * 52)
    print("  Nelore SV Catalog -> Publication Figures")
    print("=" * 52)

    # Check input files
    required = [
        f"{RELATORIO_DIR}/final_nelore_sv_catalog.tsv",
        f"{RELATORIO_DIR}/support_per_sv.tsv",
        f"{RELATORIO_DIR}/tag_snps_per_sv.tsv",
    ]
    missing = [f for f in required if not os.path.isfile(f)]
    if missing:
        print("\n[ERROR] Missing input files:")
        for f in missing:
            print(f"  {f}")
        sys.exit(1)

    print("\nLoading data...")
    cat, sup, tags = load_data()
    print(f"  Catalog    : {len(cat):,} SVs")
    print(f"  Tagged SVs : {cat['HAS_TAG_SNP'].sum():,} "
          f"({100 * cat['HAS_TAG_SNP'].mean():.1f}%)")
    print(f"  Tag SNPs   : {len(tags):,} pairs")

    print("\nGenerating figures...")
    fig1_composition(cat)
    fig2_size_distribution(cat)
    fig3_sample_support(cat)
    fig4_ld_tagging(cat, tags)
    fig5_functional_annotation(cat)
    fig6_r2_vs_distance(cat, tags)
    fig7_ideogram(cat)
    build_panel()

    print("\n" + "=" * 52)
    print(f"  All figures saved to:  {OUTPUT_DIR}/")
    print("=" * 52)
    print("\nFigure summary:")
    figs = {
        "Fig1_sv_composition":       "SV type donut + impact stacked bar",
        "Fig2_size_distribution":    "SV size histograms by type (log scale)",
        "Fig3_sample_support":       "Validation support across animals",
        "Fig4_ld_tagging":           "r^2 distribution + tagging rate + distance",
        "Fig5_functional_annotation":"VEP consequence + impact heatmap",
        "Fig6_r2_vs_distance":       "r^2 vs distance scatter + violin by impact",
        "Fig7_ideogram":             "Chromosomal ideogram with SV density",
    }
    for name, desc in figs.items():
        print(f"  {name}.pdf  ->  {desc}")


if __name__ == "__main__":
    main()
