# COWADAPT Pipelines

This directory contains the bioinformatic pipelines used in the **COWADAPT** project to process long-read sequencing data, from raw reads to a pangenome graph representation of zebu cattle genomic diversity.

Each pipeline lives in its own subdirectory and includes a dedicated `README.md` with detailed instructions — dependencies, environment variables, usage examples, and expected outputs. This document only provides a high-level overview of the pipeline suite and the order in which they should be executed.

## Pipeline Execution Order

The pipelines are designed to run sequentially, with the output of each stage feeding into the next:

| Step | Pipeline | Description |
|---|---|---|
| 1 | [`quality_control/`](./quality_control) | Quality control and preprocessing of raw long-read sequencing data (comparison, adapter removal, and quality filtering). |
| 2 | [`genome_assembly/`](./genome_assembly) | De novo genome assembly from filtered long reads, including assembly QC, format conversion, and optional duplicate purging. |
| 3 | [`sequence_alignment/`](./sequence_alignment) | Alignment of long reads against reference or assembled genomes. |
| 4 | [`variant_calling/`](./variant_calling) | Detection of genomic variants, including the structural variant catalog built by [`SV_Catalog/`](./SV_Catalog). |
| 5 | [`graph_construction/`](./graph_construction) | Construction of the multi-assembly pangenome graph integrating multiple zebu genome assemblies. |

For the full scientific context and methodology behind this pipeline suite, see the [project README](../README.md).

## Pipeline Descriptions

### 1. Quality Control

Assesses and improves the quality of raw long-read sequencing data prior to assembly, including read comparison ([NanoComp](https://github.com/wdecoster/nanocomp)), adapter removal ([Porechop](https://github.com/rrwick/porechop)), and quality filtering ([Seqkit](https://github.com/shenwei356/seqkit)).

See [`quality_control/README.md`](./quality_control/README.md).

### 2. Genome Assembly

Performs de novo genome assembly from filtered long-read data using [HiFiasm](https://github.com/chhylp123/hifiasm), followed by assembly quality control, GFA-to-FASTA conversion, and optional duplicate/haplotig purging.

See [`genome_assembly/README.md`](./genome_assembly/README.md).

### 3. Sequence Alignment

Aligns long reads against reference or assembled genomes using [Minimap2](https://github.com/lh3/minimap2), producing the alignments used by downstream variant calling steps.

See [`sequence_alignment/README.md`](./sequence_alignment/README.md).

### 4. Variant Calling

Identifies genomic variants from aligned reads. This includes the [`SV_Catalog`](./SV_Catalog) pipeline, a comprehensive structural variant (SV) detection and analysis workflow covering SV calling, merging, validation, functional annotation, SNP extraction, linkage disequilibrium analysis, and breed-specificity assessment.

See [`variant_calling/README.md`](./variant_calling/README.md) and [`SV_Catalog/README.md`](./SV_Catalog/README.md).

### 5. Graph Construction

Builds the multi-assembly pangenome graph that integrates high-quality genome assemblies from multiple zebu breeds into a unified reference structure, enabling reduced reference bias and improved structural variant discovery.

See [`graph_construction/README.md`](./graph_construction/README.md).

## Utility Scripts

- [`Get_fn.sh`](./Get_fn.sh) — Retrieves and compresses decrypted FASTQ files from sample directories, generating a manifest of processed files.
