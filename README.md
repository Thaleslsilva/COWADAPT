# COWADAPT

> **Genomic Adaptation in Indicine Cattle: A Multi-Assembly Graph Approach**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen)]()
[![Collaboration](https://img.shields.io/badge/Collaboration-USP%20%26%20ETH%20Zurich-blue)]()
[![Focus](https://img.shields.io/badge/Focus-Zebu%20Genomics-orange)]()
[![Language](https://img.shields.io/badge/Language-English-lightgrey)]()

![Capa](https://github.com/Thaleslsilva/COWADAPT/blob/main/cowadapt.png)

---

## Table of Contents

- [Project Overview](#project-overview)
- [Scientific Background](#scientific-background)
- [The Problem: Limitations of a Single Reference Genome](#the-problem-limitations-of-a-single-reference-genome)
- [Our Solution: The Multi-Assembly Graph](#our-solution-the-multi-assembly-graph)
- [Key Research Objectives](#key-research-objectives)
- [Methodology](#methodology)
- [Traits of Interest](#traits-of-interest)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Collaboration](#collaboration)
- [How to Contribute](#how-to-contribute)
- [Citation](#citation)
- [Contact and Support](#contact-and-support)
- [License](#license)
- [Funding](#funding)

---

## Project Overview

**COWADAPT** is a deep genomic investigation designed to identify and characterize the genetic variants that confer adaptability in cattle — with a particular focus on **zebu breeds** (e.g., *Bos indicus*, Nellore) that thrive in tropical and otherwise adverse environments.

The project addresses a fundamental limitation in current livestock genomic studies: the reliance on a single reference genome derived from a **Hereford cow** (*Bos taurus*), which fails to capture the extensive genetic diversity present in zebu populations. This bias hinders the discovery of crucial variants — especially **structural variants (SVs)** — that underlie key adaptive traits.

COWADAPT proposes a paradigm shift: the construction and use of a **multi-assembly graph** — an advanced pangenome-like reference structure — that integrates multiple high-quality genome assemblies from diverse zebu breeds. This approach enables a more complete and unbiased characterization of genomic variation, paving the way for a deeper understanding of tropical adaptation in cattle.

[![Decoding the Zebu Pangenome](https://youtu.be/ZnCf_NvcKpg?si=UzBAgTWUfyDy_Gxv)](https://youtu.be/ZnCf_NvcKpg?si=UzBAgTWUfyDy_Gxv)

---

## Scientific Background

Zebu cattle (*Bos indicus*) have been selectively shaped over thousands of years to survive and thrive in hot, humid, and disease-endemic environments. Breeds such as **Nellore** (the most numerous *Bos indicus* breed globally), Gir, and Brahman exhibit remarkable phenotypic traits associated with:

- **Thermoregulation** — tolerance to high ambient temperatures
- **Disease resistance** — particularly to tick-borne diseases and tropical pathogens
- **Feed efficiency** — ability to maintain productivity on low-quality forages
- **Reproductive performance** — under nutritional and thermal stress

Despite their economic and ecological importance, zebu genomes are significantly **under-represented** in current reference panels and genomic tools. The genetic basis of their adaptive superiority remains poorly understood, partly because the standard reference genome (ARS-UCD1.2, from a Hereford cow) was not built to capture *Bos indicus*-specific variation.

---

## The Problem: Limitations of a Single Reference Genome

Current livestock genomics relies almost entirely on a **linear reference genome** derived from a single individual of a European *Bos taurus* breed (Hereford). This creates several critical issues:

1. **Reference bias** — reads from zebu individuals map poorly to the Hereford reference, inflating false-negative and false-positive variant calls.
2. **Structural variant blindness** — large-scale genomic rearrangements (insertions, deletions, inversions, copy number variants) that are present in *Bos indicus* but absent from the Hereford reference are invisible to standard pipelines.
3. **Missing genetic content** — entire genomic regions unique to zebu breeds (novel sequences not present in the Hereford assembly) are simply not detectable.
4. **Population stratification artifacts** — analyses conflate true adaptive signals with mapping artifacts caused by deep phylogenetic divergence between *B. taurus* and *B. indicus* (~500,000 years of separation).

These limitations directly impede the discovery of the variants most likely to be functionally important for adaptation — the very variants COWADAPT seeks to find.

---

## Our Solution: The Multi-Assembly Graph

COWADAPT constructs a **multi-assembly pangenome graph** — a reference structure that integrates multiple high-quality genome assemblies from key zebu breeds into a single, unified graph-based representation.

### What is a Multi-Assembly Graph?

Unlike a linear reference (a single sequence), a **pangenome graph** encodes the full spectrum of genomic variation across multiple individuals or populations as a network of nodes and edges. Each path through the graph represents one genome, and shared sequences are represented only once, while divergent sequences branch off and reconnect.

### Advantages of This Approach

- **Captures *Bos indicus*-specific sequences** absent from the Hereford reference
- **Reduces reference bias** by enabling reads to align to the most appropriate haplotype
- **Enables discovery of structural variants** that are invisible to linear-reference pipelines
- **Improves genotyping accuracy** across diverse zebu breeds
- **Serves as a methodological model** for other livestock species with divergent subpopulations

---

## Key Research Objectives

1. **Build a high-quality multi-assembly pangenome graph** integrating zebu breed genomes (Nellore, Gir, Brahman, and others)
2. **Systematically characterize structural variants (SVs)** across the graph, with focus on SVs private to *Bos indicus* lineages
3. **Perform genome-wide association studies (GWAS)** using the graph as a reference to identify loci associated with adaptive traits
4. **Annotate and functionally interpret** candidate variants using gene expression data, regulatory element databases, and comparative genomics
5. **Develop and share bioinformatic tools and pipelines** enabling the broader community to apply this approach to other species

---

## Methodology

### Phase 1 — Data Collection and Quality Control
- Acquisition of high-quality, long-read genome assemblies (PacBio HiFi / ONT) from target zebu breeds
- Short-read whole-genome sequencing (WGS) data for large population panels
- Phenotypic data for traits of interest (heat tolerance, disease resistance, etc.)

### Phase 2 — Multi-Assembly Graph Construction
- Assembly of individual genomes using state-of-the-art assemblers (e.g., Hifiasm)
- Graph construction using tools such as **Minigraph-Cactus** or **Minigraph**
- Quality assessment and graph annotation

### Phase 3 — Variant Calling and Genotyping
- Long-read alignment to the pangenome graph (e.g., using **vg giraffe**)
- Structural variant calling and genotyping across the population panel
- Comparison with linear-reference-based results to quantify improvements

### Phase 4 — Association Analysis
- Graph-based GWAS for adaptive traits
- Selection sweep analysis to identify signatures of positive selection
- Haplotype analysis of candidate regions

### Phase 5 — Functional Interpretation
- Gene annotation of candidate regions
- Integration with transcriptomic (RNA-seq) data
- Comparison with known adaptive loci in related species

For detailed methods, see [docs/METHODOLOGY.md](docs/METHODOLOGY.md).

---

## Traits of Interest

| Trait | Category | Relevance |
|---|---|---|
| Heat tolerance | Thermoregulation | Critical for tropical environments |
| Tick resistance | Disease resistance | Major economic and welfare impact |
| Feed conversion efficiency | Metabolism | Performance on low-quality forages |
| Reproductive performance under stress | Physiology | Productivity in tropical systems |
| Coat characteristics | Thermoregulation | Related to solar radiation management |

---

## Installation

### Requirements

- Linux or macOS
- Bash 4.0+
- Python 3.8+
- Conda (recommended) or pip

### Quick Setup

```bash
# 1. Clone the repository
git clone https://github.com/Thaleslsilva/COWADAPT.git
cd COWADAPT

# 2. Set up the SV Catalog pipeline environment
cd pipelines/SV_Catalog
bash src/utils/setup_reference_data.sh

# 3. Edit the central configuration file with your data paths
nano config/pipeline.config
```

For full installation instructions (dependencies, HPC setup, reference data), see [docs/INSTALLATION.md](docs/INSTALLATION.md).

---

## Quick Start

```bash
# Initialize the pipeline and validate your environment
bash pipelines/SV_Catalog/src/utils/init_pipeline.sh

# Step 1: Call structural variants with Sniffles2
bash pipelines/SV_Catalog/src/01_sv_calling/run_sniffles2_calling.sh

# Step 2: Call structural variants with SVIM (second caller)
bash pipelines/SV_Catalog/src/01_sv_calling/run_svim_calling.sh

# Step 3: Merge calls from both callers using SURVIVOR
bash pipelines/SV_Catalog/src/02_sv_merge/run_survivor_merge.sh

# Continue through steps 03-07 — see docs/USAGE.md for the full walkthrough
```

For step-by-step usage instructions and examples, see:
- [docs/USAGE.md](docs/USAGE.md) — practical usage guide
- [examples/](examples/) — self-contained runnable examples
- [pipelines/SV_Catalog/docs/USAGE.md](pipelines/SV_Catalog/docs/USAGE.md) — detailed pipeline documentation

---

## Repository Structure

```
COWADAPT/
├── README.md                         # Project overview (this file)
├── CONTRIBUTING.md                   # Contribution guidelines
├── CHANGELOG.md                      # Version history
├── LICENSE                           # MIT License
├── .gitignore                        # Git ignore rules
├── docs/                             # Project-level documentation
│   ├── INSTALLATION.md               # Setup and requirements
│   ├── USAGE.md                      # Usage guide and examples
│   ├── METHODOLOGY.md                # Detailed methods and protocols
│   ├── background.md                 # Extended scientific background
│   └── glossary.md                   # Key terms and definitions
├── pipelines/                        # Bioinformatic pipelines and scripts
│   ├── genome_assembly/              # De novo genome assembly (HiFiasm, Purge Dups)
│   ├── quality_control/              # Long-read QC (NanoComp, Porechop, Seqkit)
│   ├── sequence_alignment/           # Read alignment (Minimap2)
│   ├── variant_calling/              # SV and SNP calling workflows
│   ├── graph_construction/           # Pangenome graph construction
│   └── SV_Catalog/                   # Main 7-step SV catalog pipeline
│       ├── config/pipeline.config    # Central configuration file
│       ├── src/                      # Pipeline source scripts (steps 01-07)
│       └── docs/                     # Pipeline-specific documentation
├── examples/                         # Self-contained runnable examples
├── data/                             # Data manifests and metadata (no raw data)
└── results/                          # Summary outputs, figures, and tables
```

---

## Collaboration

COWADAPT is a joint research initiative between:

| Institution | Country | Role |
|---|---|---|
| **USP** (University of Sao Paulo) | Brazil | Host institution; zebu breed expertise, phenotypic data, population genomics |
| **ETH Zurich** (Swiss Federal Institute of Technology) | Switzerland | Lead coordination, bioinformatics, pangenomics |

This collaboration combines deep knowledge of zebu cattle biology and extensive biological resources from USP — Brazil's largest public university and one of the world's leading research institutions — with cutting-edge computational genomics expertise from ETH Zurich.

---

## How to Contribute

We welcome contributions from the community! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before getting started.

- **Report issues** — Found a bug or inconsistency? Open an [Issue](../../issues)
- **Suggest improvements** — Have an idea? Start a [Discussion](../../discussions)
- **Submit code** — Fork the repository, create a feature branch, and submit a Pull Request
- **Improve documentation** — Help us make the docs clearer and more comprehensive

---

## Citation

If you use data, code, or findings from COWADAPT in your research, please cite:

```bibtex
@misc{cowadapt2021,
  title   = {COWADAPT: Genetic variants for cattle adaptability to harsh environments uncovered through a bovine multi-assembly graph},
  author  = {COWADAPT Consortium (USP and ETH Zurich)},
  year    = {2021},
  url     = {https://github.com/Thaleslsilva/COWADAPT}
}
```

> Full citation details will be updated upon publication.

---

## Contact and Support

For questions, bug reports, or collaboration inquiries:

- **GitHub Issues** — [Open an issue](https://github.com/Thaleslsilva/COWADAPT/issues) for bugs or feature requests
- **GitHub Discussions** — [Start a discussion](https://github.com/Thaleslsilva/COWADAPT/discussions) for questions and ideas
- **Repository maintainer** — Thales de Lima Silva ([@Thaleslsilva](https://github.com/Thaleslsilva))
- **Institutional contacts:**
  - VNP - FMVZ/USP, University of Sao Paulo, Brazil
  - Animal Genomics Group, ETH Zurich, Switzerland

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## Funding

This project is financially supported by Sao Paulo Research Foundation (FAPESP - Grants #2021/03101-9, #2023/06637-2 and #2024/18544-1).

---

<p align="center">
  <em>COWADAPT — 2026</em><br>
  <em>VNP - FMVZ/USP & Animal Genomics | ETH Zurich</em>
</p>
