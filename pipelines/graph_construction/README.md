# graph_construction: Indicine Pangenome Graph

Companion code for the manuscript *"Unveiling the structural genomic landscape of indicine cattle using a multi-assembly pangenome graph"* (under review).

The pipeline builds a multi-assembly pangenome graph from thirteen long-read indicine assemblies (Guzerat, Gyr, Nelore, Sindi, Tabapua) anchored on the ARS-UCD2.0 taurine reference. It then characterizes the graph, deconstructs it into structural variants (SVs), extracts and annotates the non-reference (NR) insertion sequences, and screens them for candidate genes.

> **Status.** The scripts in `src/` are the ones used to run the analyses, cleaned up and translated to English. Several of them are step-by-step runbooks (commented alternatives are kept on purpose). Items that are not yet in this folder are listed as *Pending* in [docs/MANUSCRIPT_MAP.md](docs/MANUSCRIPT_MAP.md).

## Workflow

| Step | Folder | What it does | Main tools |
|------|--------|--------------|------------|
| 00 | `src/00_data_preparation` | PanSN contig renaming, Mash distances (guide tree input) | Mash, awk, samtools |
| 01 | `src/01_graph_construction` | Minigraph-Cactus graph construction | Cactus |
| 02 | `src/02_graph_statistics` | Graph size, NR sequence, sample intersections, core/accessory/private genome, per-breed sharing | ODGI, awk, Python |
| 03 | `src/03_sv_discovery` | Graph deconstruction to VCF and SV/small-variant split | vg, vcfbub, vcfwave, BCFtools, Snakemake |
| 04 | `src/04_sv_analysis` | PCA, breed-level UpSet plots, breed-private insertions | PLINK, pysam, upsetplot |
| 05 | `src/05_nr_sequences` | NR insertion extraction, clustering, repeat masking, non-repetitive blocks | CD-HIT, RepeatModeler, RepeatMasker, bedtools |
| 06 | `src/06_functional_annotation` | Homology search, ab initio gene models, GO/KEGG annotation | DIAMOND, Augustus, eggNOG-mapper |
| 07 | `src/07_candidate_genes` | Presence/absence matrix and candidate gene screen | Python (R pending) |
| 08 | `src/08_figures` | Figure scripts | Pending |

`src/utils/` holds helpers (Zenodo upload). Step-by-step instructions are in [docs/USAGE.md](docs/USAGE.md) and the data flow is in [docs/PIPELINE_OVERVIEW.md](docs/PIPELINE_OVERVIEW.md).

## Quick start

```bash
# 1. Environment (see docs/install_guides/INSTALLATION.md for details and caveats)
conda env create -f environment.yml
conda activate graph_construction

# 2. Review the shared parameters
cat config/pipeline.config

# 3. Get the data (assemblies and the final graph are on Zenodo, see docs/DATA_SOURCES.md)
#    To skip graph construction, download IND_pangenome_final.gfa.gz and start at step 02.
```

Then follow [docs/USAGE.md](docs/USAGE.md). Scripts use relative paths that assume the working-directory layout described there.

## Configuration

| File | Used by |
|------|---------|
| `config/pipeline.config` | Shell scripts (`source`) and Python scripts (`config_loader.py`): reference ID, sample list, graph prefix, default threads |
| `config/workflow.yaml` | Experimental Snakemake pipelines in `src/02_graph_statistics/snakemake/` |
| `config/vg_deconstruct.template.yaml` | Template for the step 03 Snakemake configuration |
| `config/samples.tsv` | Metadata of the 13 assemblies plus the reference, with the matching Zenodo file names |

A tool-specific setting that differs from the shared default for a reason (for example a lower thread count for a memory-hungry tool) is kept inside that script.

## Data

Assemblies and the final graph: Zenodo record [10.5281/zenodo.21535203](https://doi.org/10.5281/zenodo.21535203). Sources of all other inputs are in [docs/DATA_SOURCES.md](docs/DATA_SOURCES.md).

## Experimental Snakemake pipelines

`src/02_graph_statistics/snakemake/` contains Snakemake versions of the ODGI and core/accessory/private analyses. They were validated with `snakemake -n` only and were **not** used to generate the manuscript results; the shell scripts are the reference implementation. See the README in that folder.

## Citation

Please cite the manuscript once published. Until then, cite this repository: https://github.com/Thaleslsilva/COWADAPT.

## License

MIT, as the rest of the COWADAPT repository (see the top-level `LICENSE`).

## Support

Open an issue at https://github.com/Thaleslsilva/COWADAPT/issues.
