pan_IND_artigo
Scripts for building and analyzing an Indicine/Nelore cattle pangenome, developed for the COWADAPT project article.
Overview
The pipeline builds a pangenome graph from Indicine reference-quality assemblies (Nelore, Gir, Guzerat, Sindi, Tabapua) plus the ARS-UCD2.0 taurine reference, then analyzes it for structural variation, core/accessory/private genome content, and candidate genes under selection.
Execution order
`mnghp-cactus.sh` - Builds the pangenome graph with Cactus (minigraph -> graphmap -> graphmap-split -> align -> graphmap-join). Produces the final GFA/VG/GBZ/ODGI graph outputs.
`resIND\_pangenome/` - Post-graph analysis:
`scripts/` - ODGI-based statistics, node/edge intersections between samples, novel sequence relative to the reference, pan/core genome curves. The ODGI graph rules and the core genome calculation are also available as a Snakemake pipeline: `scripts/Snakefile`.
`IND\_analysis/coreFlex\_analysis/` - Core/accessory/private genome partitioning and per-breed intersection analysis. The core/accessory/private partitioning and per-chromosome density steps are also available as a Snakemake pipeline (parallelized per chromosome): `IND\_analysis/coreFlex\_analysis/Snakefile`.
`vg\_deconstruct/` - Downstream analysis of the graph:
`snmk\_out/` and `vg\_deconstruct.py` (Snakemake) - SV calling with `vg deconstruct`, VCF normalization and concatenation.
`SV\_analysis/` - SV set analysis and UpSet plots across breeds.
`PCA\_analysis/` - PCA on the called variants (PLINK2).
`func\_valid/` - Functional validation of non-reference insertions (NRUIs): repeat masking (RepeatModeler/RepeatMasker), gene prediction (Augustus), homology search (DIAMOND BLASTx), and GO/KEGG annotation (eggNOG-mapper).
`new\_data/` - FASTA preparation (filtering/renaming contigs to PanSN naming) and upload of assembly data to Zenodo.
Environment setup
Install the required tools and Python packages via conda:
```bash
conda env create -f environment.yml
conda activate pan\_ind\_artigo
```
Or, if you only need the Python dependencies (the bioinformatics tools - cactus, odgi, vg, augustus, blast, repeatmasker - must still be installed separately):
```bash
pip install -r requirements.txt
```
Configuration
Shared pipeline parameters (reference genome ID, sample list, pangenome prefix, default thread count, base directory) live in `config.env`. Shell scripts `source` this file; Python scripts use `resIND\_pangenome/scripts/config\_loader.py`. Edit `config.env` to adapt the pipeline to a different run without touching individual scripts.
A script-specific override that differs from the shared default for a real reason (e.g. a lower thread count for a memory-constrained tool) is kept hardcoded in that script rather than added to `config.env`.
The two Snakemake pipelines under `resIND\_pangenome/` (see above) use their own native config file, `resIND\_pangenome/config.yaml`, instead of `config.env`.
Data and Zenodo upload
Raw and processed FASTA assemblies used to build the pangenome are prepared in `new\_data/` and uploaded to Zenodo via `new\_data/up\_Zenodo.sh`. That script requires two environment variables to be exported before running:
```bash
export ZENODO\_TOKEN=your\_token\_here
export ZENODO\_BUCKET\_ID=your\_bucket\_id\_here
bash new\_data/up\_Zenodo.sh
```
Never commit a Zenodo token to a script or to version control.
Notes
`desktop.ini` files scattered through the tree are Google Drive sync artifacts, not part of the pipeline; they can be ignored (and should be added to `.gitignore` once this folder is placed under version control).
Some scripts still contain known execution issues carried over from prior runs (e.g. a stray error message left in `resIND\_pangenome/scripts/2.odgi\_pipeline.sh`); these were fixed as of the Phase 2 bugfix pass. The corresponding Snakemake rules in `resIND\_pangenome/scripts/Snakefile` and `resIND\_pangenome/IND\_analysis/coreFlex\_analysis/Snakefile` reflect the corrected behavior.
