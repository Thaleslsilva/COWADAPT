# 08_figures

Figure scripts of the manuscript.

| Item | Script | Status |
|------|--------|--------|
| Figure 1: Mash distance heatmap (and PCoA) | `mash_distances.R` | Included. Usage: `Rscript mash_distances.R <combined_distance.tsv> [out_dir]` |
| Figure 2: sharing among breeds | `../02_graph_statistics/coreflex/4.breed_intersections_plot.py` | Included (see [MANUSCRIPT_MAP](../../docs/MANUSCRIPT_MAP.md)) |
| Figure 3: SVs and breed-private insertions | `../04_sv_analysis/upset.py` | Included (see [MANUSCRIPT_MAP](../../docs/MANUSCRIPT_MAP.md)) |
| Figure 4: PCA | PCA plotting script (R); eigenvectors come from `../04_sv_analysis/1.PCA_prepare.sh` | Pending |
| Figure 5: GO enrichment | clusterProfiler script (R); input is the eggNOG-mapper output of step 06 | Pending |
| Figure 6: candidate genes | candidate screening script (R); input from step 06 and `../07_candidate_genes` | Pending |

Also pending outside this folder: the Cactus `seqFile` and guide tree (step 01).
