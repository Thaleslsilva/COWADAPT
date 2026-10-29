# Manuscript map: Methods, Results and Figures to code

Traceability between the manuscript and this folder. **Status** values:

- **Included**: script(s) in `src/`.
- **Other pipeline**: covered by another folder of the COWADAPT repository.
- **Command only**: documented here, no script in this folder.
- **Pending**: script not yet added to this folder.

Items tagged `TODO(author)` need a decision before the repository is final.

Tool versions are the ones reported in the manuscript.

## Methods

| Manuscript section | Tool (version) | Code | Status |
|--------------------|----------------|------|--------|
| De novo assemblies: read QC | Filtlong 0.3.0, Seqkit 2.10.0, Porechop 0.2.4 | [`../../quality_control`](../../quality_control) (Porechop, Seqkit, NanoComp) | Other pipeline; Filtlong `TODO(author)` |
| De novo assemblies: assembly | Hifiasm 0.21.0-r686 | [`../../genome_assembly`](../../genome_assembly) | Other pipeline |
| De novo assemblies: polishing, scaffolding, QC | Minimap2 2.30-r1287, Medaka 1.7.2, RagTag 2.1.0, BUSCO 6.0.0 (`mammalia_odb10`) | | Command only `TODO(author)` |
| PanSN naming of assemblies | awk, samtools, bgzip/pbgzip | `src/00_data_preparation/filter_COW.sh`, `filter_rename_BRA.sh`, `reconstruct_pansn.py` | Included |
| Pangenome graph: genetic distance and guide tree | Mash 2.3 (`-s 100000 -k 32`), R `ape` 5.4 (NJ) | `src/00_data_preparation/phylo_tree.sh` (Mash); `phylo_tree_assembly.R` (tree) | Mash included; NJ script Pending |
| Pangenome graph: construction | Minigraph-Cactus 2.9.8 | `src/01_graph_construction/mnghp-cactus.sh`; Cactus `seqFile` and guide tree | Script included; `seqFile` Pending |
| SV discovery from the graph | vg deconstruct, vcfbub 0.1.0, vcfwave, BCFtools 1.22 | `src/03_sv_discovery/vg_deconstruct.smk`, `par_run.sh`, `1_bgzip_vcfs.sh`, `2_concat_SV.vcf.sh`, `3_concat_small.vcf.sh` | Included (YAML values `TODO(author)`, see `config/vg_deconstruct.template.yaml`) |
| NR sequence extraction and PCA | PLINK 1.9 (manuscript) | `src/05_nr_sequences/1.extINS_INDpang.sh` (insertions); `src/04_sv_analysis/1.PCA_prepare.sh` (PCA) | Included; PLINK version `TODO(author)` (the script calls `plink2`); minimum insertion size in `1.extINS_INDpang.sh` is 100 bp `TODO(author)` |
| NR clustering and repeat masking | CD-HIT-EST 4.8.1, RepeatModeler 2.0.7, RepeatMasker 4.2.2, RMBlast 2.14.1+ | `src/05_nr_sequences/2.clust_anot_genot.sh`, `3.build_database.sh`, `4.1.mask_repeats.sh`, `1.extc_nruis.sh`, `4.2.checklist_QC.sh`, `2.family_anl.py` | Included |
| DIAMOND BLASTx | DIAMOND 2.1.8 | `src/06_functional_annotation/5.1.prep_prot_db.sh`, `5.2.AbInitio_Homology.sh`, `blastx/1.check_output.sh`, `blastx/2.hits_anott.py`, `blastx/3.nrui_blastx_integration.py` | Included; protein database definition `TODO(author)` |
| Ab initio gene prediction | Augustus 3.5.0 (human model) | `src/06_functional_annotation/augustus/1.1.pred_indvSeq.sh`, `2.check_res.sh`, `3.augustus_filter.py`, `4.Ext_prot_intgBLASTx.sh`, `protein.py`, `5.integ_BLASTx_Aug.py` (`1.2.pred_parlwin.sh` is an alternative windowed mode with the `Bos_taurus_refseq` model) | Included |
| Functional annotation | eggNOG-mapper 2.1.13 (eggNOG 5.0) | `src/06_functional_annotation/6.1.GO_KEGG.sh`, `blastx/4.uniprot_go_fetch.py` | Included |
| GO/KEGG enrichment | clusterProfiler 4.18.0, org.Bt.eg.db 3.22.0 (R) | | Pending |
| Candidate gene identification | R pipeline | `src/07_candidate_genes/build_pav_matrix.py`, `cand_genes.sh` (runbook); R screening | Python/runbook included; R Pending |

## Results and figures

| Result | Code | Status |
|--------|------|--------|
| Assembly metrics (Table 1) | `config/samples.tsv` | Included (metrics as reported) |
| Figure 1: Mash distance heatmap | `phylo_tree.sh` + `phylo_tree_assembly.R` | R Pending |
| Graph size, NR nodes and sequence | `src/02_graph_statistics/graph_level/1.postGraph_wrkflw.sh` and `1_a` to `1_e` scripts | Included |
| Core, accessory and private genome | `graph_level/3.CoreFlex_analysis.sh`, `coreflex/1.core_acessory_anl.sh` | Included |
| Sharing among breeds (Figure 2) | `coreflex/3.breed_intersections.sh`, `4.breed_intersections_plot.py` | Included `TODO(author)`: confirm figure number |
| SV catalog and breed-private insertions (Figure 3) | `src/03_sv_discovery/4_count_BiMulti_INS_DEL.sh`, `src/04_sv_analysis/upset.py`, `ins_exclusivas.py` | Included `TODO(author)`: confirm figure number |
| PCA (Figure 4) | `src/04_sv_analysis/1.PCA_prepare.sh` (eigenvectors) | Plot script Pending |
| Repeat composition | `src/05_nr_sequences/4.2.checklist_QC.sh`, `2.family_anl.py` | Included |
| Gene models and dual support | `augustus/3.augustus_filter.py`, `augustus/5.integ_BLASTx_Aug.py`, `blastx/2.hits_anott.py` | Included |
| GO/KEGG enrichment (Figure 5) | R | Pending |
| Candidate genes (Figure 6, Supplementary table) | R | Pending |
| Pan/core and novel-sequence curves | `graph_level/pan_core_curve.py`, `novel_sequence_curve.py` | Included `TODO(author)`: confirm whether a figure uses them |

## Not covered

Everything marked Pending or `TODO(author)` above. The Cactus `seqFile`, the R scripts and the figure scripts are tracked in `src/08_figures/README.md`.
