# Installation

## System requirements

- Linux with bash and a conda/mamba installation. The heavy steps were run on a server (Cactus with 100 cores and up to 900 GB of memory; RepeatModeler about 7 h). A SLURM scheduler is assumed by `phylo_tree.sh` and `augustus/1.2.pred_parlwin.sh`.
- Disk space depends on the data; the final graph alone is 3.4 GB compressed.

## Create the environment

```bash
git clone https://github.com/Thaleslsilva/COWADAPT.git
cd COWADAPT/pipelines/graph_construction

conda env create -f environment.yml
conda activate graph_construction
```

> `environment.yml` lists the tools without pinned versions and has **not** been solved on a clean machine. If a package cannot be resolved together with the others, install it in a separate environment. Minigraph-Cactus is easiest from the official release or container (see the Cactus documentation).

If you only need the Python packages: `pip install -r requirements.txt`.

## Versions used in the manuscript

| Tool | Version |
|------|---------|
| Minigraph-Cactus | 2.9.8 |
| Mash | 2.3 |
| BCFtools | 1.22 |
| vcfbub | 0.1.0 |
| CD-HIT-EST | 4.8.1 |
| RepeatModeler | 2.0.7 |
| RepeatMasker | 4.2.2 (RMBlast 2.14.1+) |
| DIAMOND | 2.1.8 |
| Augustus | 3.5.0 |
| eggNOG-mapper | 2.1.13 (eggNOG 5.0) |
| R packages | ape 5.4, clusterProfiler 4.18.0, org.Bt.eg.db 3.22.0 |

Versions of `vg`, `vcfwave`, ODGI, PLINK and Snakemake are not stated in the manuscript; `TODO(author)` to add them here.

## Verify

```bash
bash -n src/03_sv_discovery/par_run.sh          # syntax check
cd src/02_graph_statistics/graph_level
python -c "from config_loader import load_config; print(load_config())"
```
