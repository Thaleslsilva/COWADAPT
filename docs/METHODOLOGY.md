# Methodology

Detailed description of the methods and protocols used in the COWADAPT project.

---

## Table of Contents

1. [Overview](#overview)
2. [Phase 1: Data Collection and Quality Control](#phase-1-data-collection-and-quality-control)
3. [Phase 2: Genome Assembly](#phase-2-genome-assembly)
4. [Phase 3: Multi-Assembly Graph Construction](#phase-3-multi-assembly-graph-construction)
5. [Phase 4: Structural Variant Detection](#phase-4-structural-variant-detection)
6. [Phase 5: Functional Annotation and Association Analysis](#phase-5-functional-annotation-and-association-analysis)
7. [SV Catalog Pipeline: Technical Details](#sv-catalog-pipeline-technical-details)
8. [Key Design Decisions](#key-design-decisions)
9. [Software and Tool Versions](#software-and-tool-versions)
10. [References](#references)

---

## Overview

COWADAPT employs a multi-stage genomic analysis workflow to detect, annotate, and characterize structural variants (SVs) in zebu cattle (*Bos indicus*) and identify variants associated with tropical adaptation traits. The core methodological innovation is the use of long-read sequencing and a multi-assembly graph approach to overcome the reference bias inherent in linear reference genome-based analyses.

---

## Phase 1: Data Collection and Quality Control

### Long-read Sequencing Data

- **Technology:** PacBio HiFi (CCS reads) and Oxford Nanopore Technology (ONT)
- **Expected coverage:** 30x minimum per individual assembly; 10-15x for population-level analyses
- **Breeds targeted:** Nellore (primary), Gir, Brahman, and selected taurine outgroups

### Quality Control Pipeline

Quality control is performed before any downstream analysis:

1. **NanoComp** — Comparative summary statistics and plots across multiple samples
2. **Porechop** — Adapter trimming for ONT reads
3. **Seqkit** — Read filtering (Q >= 10 for SUP basecalls)

Reads that fail quality thresholds are excluded from assembly and alignment steps.

---

## Phase 2: Genome Assembly

### De Novo Assembly with HiFiasm

Individual genomes are assembled from PacBio HiFi reads using **HiFiasm** (v0.19+):

- k-mer size: 31
- Threads: 32
- ONT ultra-long reads used to scaffold HiFi assemblies where available
- Output: Phased assembly graphs (GFA format) for both haplotypes

### Haplotig Removal

Redundant haplotigs are identified and removed using **Purge_Dups**:

1. Map reads to primary assembly with Minimap2
2. Compute per-base coverage
3. Identify coverage cutoffs
4. Self-alignment to find overlaps
5. Identify and extract haplotigs
6. Produce purged primary assembly + haplotigs FASTA

### Assembly Quality Assessment

Assembly statistics are computed with **seqkit stats**:
- Contig N50, N90
- Total assembly size
- GC content
- Number of contigs and gaps

---

## Phase 3: Multi-Assembly Graph Construction

### Rationale

A single linear reference genome (ARS-UCD1.2, from a Hereford *Bos taurus* individual) introduces systematic mapping bias when used for zebu (*Bos indicus*) samples. The phylogenetic divergence between taurine and indicine lineages is approximately 500,000 years, resulting in pronounced sequence differences that impair variant detection.

### Graph Construction Tools

Two complementary approaches are under evaluation:

- **Minigraph** — Fast construction of sequence variation graphs; suitable for SV-level variation
- **Minigraph-Cactus** — Full pangenome graph with SNP-level resolution; more computationally intensive

### Input Assemblies

The graph integrates:
- ARS-UCD2.0 (reference, Bos taurus Hereford)
- Nellore haplotype-resolved assemblies (this project)
- Publicly available assemblies: Brahman, Gir, and selected taurine breeds

---

## Phase 4: Structural Variant Detection

### Alignment

Long reads (ONT or HiFi) are aligned to the reference genome (or pangenome graph) using **Minimap2**:
- Preset: `map-hifi` for PacBio HiFi; `map-ont` for Nanopore
- Threads: 64 for alignment, 8 for BAM sorting
- Output: Coordinate-sorted, indexed BAM files

### SV Calling: Dual-Caller Strategy

Two SV callers are run independently to improve sensitivity and specificity:

**Sniffles2:**
- Minimum SV length: 50 bp
- Minimum MAPQ: 20
- Produces both per-sample VCF and SNF files for joint calling
- Expected yield: ~5,200 SVs/sample

**SVIM:**
- Minimum SV length: 50 bp
- Complementary to Sniffles2; captures different SV classes
- Expected yield: ~4,800 SVs/sample

### SV Merging: SURVIVOR

Calls from both callers are merged using **SURVIVOR**:
- Maximum distance between breakpoints: 1,000 bp
- Minimum number of supporting callers: 2
- SV type must match
- Strand information considered
- Expected after merge: ~2,500 concordant SVs/sample (48% retention rate)

### Validation and Filtering

High-confidence SVs are retained based on SUPP (support) field values indicating multi-caller concordance. Expected pass rate: 60-80%.

---

## Phase 5: Functional Annotation and Association Analysis

### Functional Annotation (Ensembl VEP)

Validated SVs are annotated with the Ensembl **Variant Effect Predictor (VEP)**:
- Reference: ARS-UCD2.0 (Ensembl release for bos_taurus)
- Distance parameter: 1,000 bp from gene features
- Pick mode: One consequence per variant (most severe)
- Impact classification: HIGH, MODERATE, LOW, MODIFIER

### Tag SNP Identification

For chip-based genotyping compatibility, each SV is linked to a proxy SNP on the **BovineHD chip** using linkage disequilibrium (LD):

- LD computed with plink2
- Window: 1,000 kb
- r² threshold: >= 0.3
- Best tag SNP per SV: highest r² value
- Expected coverage: 67-78% of SVs have at least one tag SNP

### Zebu-Specificity Classification

Each SV is classified based on its overlap with SNPs from the **Kasarapu et al. (2017)** zebu ancestry SNP map:
- Window: SNPs within ±1,000 bp of SV breakpoints
- Metric: Mean Pr(Indicina) across overlapping SNPs
- Classification thresholds:
  - Pr(Indicina) >= 0.95: Indicine-specific
  - Pr(Indicina) < 0.05: Taurine-specific
  - Otherwise: Mixed/Admixed

### Association Analysis (Planned)

Graph-based GWAS for tropical adaptation traits will use:
- Phenotypic data from Nellore population panels
- Graph-aligned variant genotypes
- Linear mixed models to control for population structure
- Selection sweep analysis (iHS, XP-EHH)

---

## SV Catalog Pipeline: Technical Details

The SV catalog pipeline (`pipelines/SV_Catalog/`) implements all SV detection and annotation steps in a 7-step workflow:

| Step | Description | Key Tool | Input | Expected Output |
|---|---|---|---|---|
| 01 | SV calling | Sniffles2, SVIM | BAM files | ~10,000 SVs/sample |
| 02 | SV merge | SURVIVOR | Per-caller VCFs | ~2,500 concordant SVs |
| 03 | Validation | Custom filters | Merged VCF | ~1,500-2,000 high-confidence SVs |
| 04 | Annotation | Ensembl VEP | Validated VCF | Consequence annotations |
| 05 | SNP extraction | samtools, bcftools | BAM, BovineHD BED | Chip-position VCF |
| 06 | LD analysis | plink2 | Combined VCF | Tag SNPs per SV |
| 07 | Zebu specificity | Custom Python | Catalog + SNP map | Specificity classifications |

All parameters are centralized in `config/pipeline.config`. For detailed pipeline documentation, see `pipelines/SV_Catalog/docs/PIPELINE_OVERVIEW.md`.

---

## Key Design Decisions

### Dual-caller SV detection

Using two complementary SV callers (Sniffles2 + SVIM) and requiring concordance between them reduces false positives while maintaining sensitivity. This is a widely adopted strategy in the SV calling literature.

### 1,000 bp SURVIVOR merge distance

A merge distance of 1,000 bp balances specificity (not merging truly distinct events) with tolerance for breakpoint imprecision inherent in long-read SV calling.

### r² >= 0.3 for tag SNPs

This threshold is permissive enough to achieve broad chip coverage while excluding poorly correlated proxy SNPs. It is consistent with thresholds used in human GWAS chip design.

### ±1,000 bp window for zebu-specificity

SNPs within 1,000 bp of SV breakpoints are considered informative for classifying zebu ancestry. This window balances biological relevance (local ancestry signal) with statistical power.

### ARS-UCD2.0 as reference

ARS-UCD2.0 (GCF_002263795.3) represents the most current high-quality bovine reference genome and is the standard in current bovine genomics research.

---

## Software and Tool Versions

| Tool | Version | Purpose |
|---|---|---|
| HiFiasm | 0.19+ | Genome assembly |
| Purge_Dups | 1.2.x | Haplotig removal |
| Minimap2 | 2.24+ | Sequence alignment |
| Sniffles2 | 2.x | SV calling |
| SVIM | 1.4+ | SV calling |
| SURVIVOR | 1.0.7 | SV merging |
| Ensembl VEP | 109+ | Functional annotation |
| plink2 | 2.0 | LD analysis |
| samtools | 1.17+ | BAM file handling |
| bcftools | 1.17+ | VCF file handling |
| seqkit | 2.x | Sequence statistics |
| NanoComp | 1.x | ONT QC |
| Porechop | 0.2.x | ONT adapter trimming |
| Python | 3.8+ | Analysis scripts |
| pysam | 0.21+ | Python BAM/VCF handling |

---

## References

1. Cheng H, et al. (2021). Haplotype-resolved de novo assembly using phased assembly graphs with hifiasm. *Nature Methods*, 18, 170-175.

2. Sedlazeck FJ, et al. (2018). Accurate detection of complex structural variations using single-molecule sequencing. *Nature Methods*, 15, 461-468.

3. Rausch T, et al. (2012). DELLY: structural variant discovery by integrated paired-end and split-read analysis. *Bioinformatics*, 28(18), i333-i339.

4. Jeffares DC, et al. (2017). Transient structural variations have strong effects on quantitative traits and reproductive isolation in fission yeast. *Nature Communications*, 8, 14061.

5. Kasarapu P, et al. (2017). Sequencing of diverse mandarin, pummelo and sweet orange accessions elucidates the history of citrus domestication. *Nature Communications*, 8, 15385.

6. McLaren W, et al. (2016). The Ensembl Variant Effect Predictor. *Genome Biology*, 17, 122.

7. Garrison E, et al. (2018). Variation graph toolkit improves read mapping by representing genetic variation in the reference. *Nature Biotechnology*, 36, 875-879.

8. Daetwyler HD, et al. (2014). Whole-genome sequencing of 234 bulls facilitates mapping of monogenic and complex traits in cattle. *Nature Genetics*, 46, 858-865.
