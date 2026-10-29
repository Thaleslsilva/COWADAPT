# Usage

Step-by-step guide for running the analyses. Read [MANUSCRIPT_MAP.md](MANUSCRIPT_MAP.md) first to see which manuscript section each step supports and what is still pending.

## Before you start

- Install the tools: [install_guides/INSTALLATION.md](install_guides/INSTALLATION.md).
- Get the inputs: [DATA_SOURCES.md](DATA_SOURCES.md).
- Many scripts are runbooks that use **paths relative to the directory they were run from**. The layout used for the analyses was:

```
<workdir>/
  post_pangenome/                        # step 02: graph files live here
    IND_pangenome_final.{og,sorted.og,sorted.gfa}
    scripts/                             # cwd of the graph_level scripts
    IND_analysis/coreFlex_analysis/      # cwd of the coreflex scripts
  vg_deconstruct/
    snmk_out/                            # cwd of step 03 (per-chromosome folders)
    PCA_analysis/   SV_analysis/         # cwd of step 04
    func_valid/                          # cwd of steps 05-06
```

Copy or symlink the scripts into this layout (or run them from the matching directories with the full path to the script) and check the first lines of each script for the files it expects.

Shared settings (reference ID, graph prefix, default threads) are read from `config/pipeline.config`.

## Starting from the published graph

The final graph is on Zenodo (`IND_pangenome_final.gfa.gz`). To skip step 01, download it into `post_pangenome/` and decompress it. Steps 02 onward need the graph in ODGI format (`.og`); the scripts in `graph_level/2.odgi_pipeline.sh` expect `IND_pangenome_final.og` one directory above `scripts/`.

## Step 00: data preparation

```bash
# Contig filtering/renaming to the PanSN convention (sample#haplotype#contig)
bash src/00_data_preparation/filter_COW.sh            # run in the folder with COWADAPT_*.fasta
bash src/00_data_preparation/filter_rename_BRA.sh     # run in the folder with the *.fasta of the other breeds
python src/00_data_preparation/reconstruct_pansn.py in.fasta.gz out.fasta.gz [gap_size] [threads]

# Mash distances (SLURM; set REF_FASTA, ZEB_DIR, NEL_DIR first)
sbatch src/00_data_preparation/phylo_tree.sh
```

## Step 01: graph construction

```bash
bash src/01_graph_construction/mnghp-cactus.sh
```

Requires the Cactus `seqFile` (`SEQ_FILE` in the script; Pending in this repository). Steps 1-4 are commented out in the script; uncomment them to run the full pipeline. Resources set in the script: `CORES` from `DEFAULT_THREADS`, `--maxMemory 900G`; adjust to your machine.

## Step 02: graph statistics

Run from `post_pangenome/scripts/` unless noted:

```bash
bash <repo>/src/02_graph_statistics/graph_level/2.odgi_pipeline.sh        # sort, depth, similarity, GFA export
bash <repo>/src/02_graph_statistics/graph_level/1.postGraph_wrkflw.sh     # graph size, NR sequence, intersections
bash <repo>/src/02_graph_statistics/graph_level/3.CoreFlex_analysis.sh    # core genome size

# from post_pangenome/IND_analysis/coreFlex_analysis/
bash <repo>/src/02_graph_statistics/coreflex/1.core_acessory_anl.sh       # core/accessory/private partition
bash <repo>/src/02_graph_statistics/coreflex/3.breed_intersections.sh
python <repo>/src/02_graph_statistics/coreflex/4.breed_intersections_plot.py
```

`graph_level/pan_core_curve.py` and `novel_sequence_curve.py` produce the pan/core and novel-sequence curves.

## Step 03: SV discovery

```bash
cp config/vg_deconstruct.template.yaml config/vg_deconstruct.yaml   # then edit
# ARS_autoss.txt: one reference path name per line (e.g. ARS_UCD2#0#NC_037328.1)
bash src/03_sv_discovery/par_run.sh          # one Snakemake run per chromosome (vg_deconstruct.smk)

# from vg_deconstruct/snmk_out/
bash <repo>/src/03_sv_discovery/1_bgzip_vcfs.sh
bash <repo>/src/03_sv_discovery/2_concat_SV.vcf.sh
bash <repo>/src/03_sv_discovery/3_concat_small.vcf.sh
bash <repo>/src/03_sv_discovery/4_count_BiMulti_INS_DEL.sh
```

Per chromosome: `vg deconstruct`, `vcfbub`, `vcfwave`, `bcftools norm`, then a split into SVs (|ILEN| >= 50 bp) and small variants.

## Step 04: SV analysis

From `vg_deconstruct/PCA_analysis/` and `vg_deconstruct/SV_analysis/` (both read `../snmk_out/SV.vcf.gz`):

```bash
bash <repo>/src/04_sv_analysis/1.PCA_prepare.sh
python <repo>/src/04_sv_analysis/upset.py
python <repo>/src/04_sv_analysis/ins_exclusivas.py
```

## Step 05: NR sequences

From `vg_deconstruct/func_valid/`, in numeric order:

```bash
bash <repo>/src/05_nr_sequences/1.extINS_INDpang.sh        # NR insertions -> FASTA
bash <repo>/src/05_nr_sequences/2.clust_anot_genot.sh      # CD-HIT-EST clustering, header cleanup
bash <repo>/src/05_nr_sequences/3.build_database.sh        # RepeatModeler (about 7 h on the manuscript data)
bash <repo>/src/05_nr_sequences/4.1.mask_repeats.sh        # RepeatMasker and non-repetitive regions
bash <repo>/src/05_nr_sequences/4.2.checklist_QC.sh
# in repeatmasker_out/denovo/:
bash <repo>/src/05_nr_sequences/1.extc_nruis.sh
python <repo>/src/05_nr_sequences/2.family_anl.py
```

## Step 06: functional annotation

```bash
bash <repo>/src/06_functional_annotation/5.1.prep_prot_db.sh          # protein database + DIAMOND index
bash <repo>/src/06_functional_annotation/5.2.AbInitio_Homology.sh     # DIAMOND BLASTx
python <repo>/src/06_functional_annotation/blastx/2.hits_anott.py     # filters and best hits
bash <repo>/src/06_functional_annotation/augustus/1.1.pred_indvSeq.sh
python <repo>/src/06_functional_annotation/augustus/3.augustus_filter.py
bash <repo>/src/06_functional_annotation/augustus/4.Ext_prot_intgBLASTx.sh
python <repo>/src/06_functional_annotation/augustus/protein.py
python <repo>/src/06_functional_annotation/augustus/5.integ_BLASTx_Aug.py
bash <repo>/src/06_functional_annotation/6.1.GO_KEGG.sh               # eggNOG-mapper
```

GO/KEGG enrichment in R is Pending.

## Step 07: candidate genes

```bash
python src/07_candidate_genes/build_pav_matrix.py path/to/IND_pangenome_final.sorted.gfa
```

`cand_genes.sh` is a runbook describing how each candidate was evaluated; the R screening is Pending.

## Known issues

- `coreflex/1.core_acessory_anl.sh`, step 9: the density loop reads `../nodes_${TYPE}.txt`, which does not match the files written in step 5 (`{core,accessory,private}_nodes.txt`). The experimental Snakemake version uses the correct file names.
- `graph_level/1.postGraph_wrkflw.sh`: the last command calls `get_nel_v2.sh`, which is not in this repository (the line is commented out).
- `05_nr_sequences/4.1.mask_repeats.sh` mixes commands that were run at different times; read it as a runbook rather than executing it end to end.
