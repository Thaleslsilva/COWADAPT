# 08_figures

Figure scripts of the manuscript. **Pending**: they are not yet part of this repository.

| Item | Needed script | Where the data comes from |
|------|---------------|---------------------------|
| Figure 1: Mash distance heatmap and NJ tree | `phylo_tree_assembly.R` | `src/00_data_preparation/phylo_tree.sh` (`tree/combined_distance.tsv`) |
| Figure 4: PCA | PCA plotting script (R) | eigenvectors from `src/04_sv_analysis/1.PCA_prepare.sh` |
| Figure 5: GO enrichment | clusterProfiler script (R) | eggNOG-mapper annotations from step 06 |
| Figure 6: candidate genes | candidate screening script (R) | step 06 and `src/07_candidate_genes` |

Figures 2 and 3 are produced by `src/02_graph_statistics/coreflex/4.breed_intersections_plot.py` and `src/04_sv_analysis/upset.py` (see [../../docs/MANUSCRIPT_MAP.md](../../docs/MANUSCRIPT_MAP.md)).

Also pending outside this folder: the Cactus `seqFile` and guide tree (step 01) and the R GO/KEGG and candidate-gene scripts (steps 06 and 07).
