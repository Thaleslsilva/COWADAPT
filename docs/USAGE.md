# Usage Guide

Practical examples and instructions for running COWADAPT pipelines.

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-pipeline: Quality Control](#pre-pipeline-quality-control)
3. [Pre-pipeline: Genome Assembly](#pre-pipeline-genome-assembly)
4. [Pre-pipeline: Sequence Alignment](#pre-pipeline-sequence-alignment)
5. [Main Pipeline: SV Catalog](#main-pipeline-sv-catalog)
6. [Output Interpretation](#output-interpretation)
7. [Example Use Cases](#example-use-cases)

---

## Overview

COWADAPT is organized into independent modular pipelines that can be run separately or as part of the full workflow:

```
Raw long reads (FASTQ)
       |
  [QC Pipeline] — NanoComp, Porechop, Seqkit
       |
  [Assembly Pipeline] — HiFiasm, Purge Dups
       |
  [Alignment Pipeline] — Minimap2
       |
  [SV Catalog Pipeline] — 7-step SV detection and annotation
       |
  Final SV Catalog (TSV) + Publication figures
```

All scripts source their parameters from a central configuration file. Before running any pipeline, configure `pipelines/SV_Catalog/config/pipeline.config` with your data paths and compute resources.

---

## Pre-pipeline: Quality Control

Located in `pipelines/quality_control/`.

### Compare long-read quality across samples

```bash
bash pipelines/quality_control/NanoComp.sh
```

Generates comparative QC plots for multiple FASTQ files using NanoComp. Output is written to the directory specified in the script.

### Trim sequencing adapters (Nanopore)

```bash
bash pipelines/quality_control/Porechop.sh
```

Removes ONT adapters using Porechop with 100 threads. Output: adapter-trimmed, compressed FASTQ files.

### Filter reads by quality

```bash
bash pipelines/quality_control/Seqkit.sh
```

Filters reads to Q >= 10 (SUP basecalls). Output: quality-filtered FASTQ files.

---

## Pre-pipeline: Genome Assembly

Located in `pipelines/genome_assembly/`.

### Step 1: Assemble with HiFiasm

```bash
bash pipelines/genome_assembly/Hifiasm.sh
```

De novo assembly from PacBio HiFi long reads. Output: GFA graph files for both haplotypes.

### Step 2: Convert GFA to FASTA

```bash
bash pipelines/genome_assembly/GFA2FASTA_conversion.sh
```

Converts HiFiasm GFA output to indexed FASTA format using gfatools, bgzip, and samtools faidx.

### Step 3: Remove haplotigs

```bash
bash pipelines/genome_assembly/Purge_Dups.sh
```

Identifies and removes duplicate haplotypic sequences using Purge_Dups. Output: purged primary assembly + haplotigs.

### Step 4: Assess assembly quality

```bash
bash pipelines/genome_assembly/Assembly_QC.sh
```

Computes length distribution, GC content, and N-count statistics using seqkit.

---

## Pre-pipeline: Sequence Alignment

Located in `pipelines/sequence_alignment/`.

### Align reads to assembly

```bash
bash pipelines/sequence_alignment/Minimap2.sh
```

Aligns long reads to the corresponding assembly. Output: sorted, indexed BAM files.

---

## Main Pipeline: SV Catalog

Located in `pipelines/SV_Catalog/`. This is the primary research pipeline for building the Nellore structural variant catalog.

### Initialize and validate environment

```bash
bash pipelines/SV_Catalog/src/utils/init_pipeline.sh
```

### Step 1: Call structural variants

```bash
# Sniffles2 (primary caller)
bash pipelines/SV_Catalog/src/01_sv_calling/run_sniffles2_calling.sh

# SVIM (complementary caller)
bash pipelines/SV_Catalog/src/01_sv_calling/run_svim_calling.sh
```

Produces one VCF file per sample per caller. Expected: ~5,200 SVs/sample (Sniffles2), ~4,800 (SVIM).

### Step 2: Merge SV calls

```bash
bash pipelines/SV_Catalog/src/02_sv_merge/run_survivor_merge.sh
```

Merges calls from both callers using SURVIVOR (1000 bp distance, minimum 2 callers). Expected: ~2,500 concordant SVs/sample.

Inspect the merge output:

```bash
bash pipelines/SV_Catalog/src/02_sv_merge/inspect_survivor_output.sh
```

### Step 3: Validate SVs

```bash
bash pipelines/SV_Catalog/src/03_sv_validation/run_sv_validation.sh
```

Filters for high-confidence SVs supported by multiple callers. Expected: ~1,500-2,000 validated SVs/sample.

### Step 4: Annotate functional impact

```bash
bash pipelines/SV_Catalog/src/04_functional_annotation/run_vep_annotation.sh
```

Runs Ensembl VEP to assign functional consequences (HIGH, MODERATE, LOW, MODIFIER) to each SV.

Extract annotations to a readable table:

```bash
python pipelines/SV_Catalog/src/04_functional_annotation/extract_vep_annotations.py \
    --input results/sv_validation/validated_svs.vcf \
    --output results/functional/vep_annotations.tsv
```

### Step 5: Extract SNP chip data

```bash
bash pipelines/SV_Catalog/src/05_snp_extraction/extract_bovhd_snps.sh
bash pipelines/SV_Catalog/src/05_snp_extraction/filter_snp_quality.sh
```

Extracts SNPs at BovineHD chip positions and filters by quality thresholds.

### Step 6: LD analysis and tag SNP identification

```bash
# Combine SV and SNP VCFs
bash pipelines/SV_Catalog/src/06_ld_analysis/combine_sv_snp_vcf.sh

# Convert SVs to biallelic format for plink2
python pipelines/SV_Catalog/src/06_ld_analysis/convert_sv_to_biallelic.py \
    --input results/sv_validation/validated_svs.vcf \
    --output results/ld_analysis/svs_biallelic.vcf

# Identify tag SNPs (r² >= 0.3)
python pipelines/SV_Catalog/src/06_ld_analysis/identify_tag_snps.py \
    --ld-file results/ld_analysis/sv_snp.ld \
    --output results/ld_analysis/tag_snps_per_sv.tsv

# Generate the final SV catalog
python pipelines/SV_Catalog/src/06_ld_analysis/generate_catalog.py \
    --annotations results/functional/vep_annotations.tsv \
    --tag-snps results/ld_analysis/tag_snps_per_sv.tsv \
    --output results/catalog/final_nelore_sv_catalog.tsv
```

Expected: ~1,200-1,400 SVs with at least one tag SNP (67-78% coverage).

### Step 7: Zebu-specificity annotation

```bash
python pipelines/SV_Catalog/src/07_zebu_specificity/annotate_zebu_specificity.py \
    --catalog results/catalog/final_nelore_sv_catalog.tsv \
    --snpmap data/reference/zebu_snpmap_kasarapu2017.txt \
    --output results/zebu/sv_zebu_specificity.txt
```

Classifies each SV as indicine-specific, taurine-specific, or mixed/admixed based on Kasarapu et al. (2017) SNP probabilities.

Generate summary and ideogram figure:

```bash
python pipelines/SV_Catalog/src/07_zebu_specificity/summarize_zebu_specificity.py
python pipelines/SV_Catalog/src/07_zebu_specificity/generate_ideogram.py
```

---

## Output Interpretation

### Final catalog columns (`final_nelore_sv_catalog.tsv`)

| Column | Description |
|---|---|
| CHROM | Chromosome |
| POS | Start position (ARS-UCD2.0 coordinates) |
| SVTYPE | SV type (DEL, INS, DUP, INV, BND) |
| SVLEN | SV length in base pairs |
| SUPP | Number of callers supporting the SV |
| Consequence | VEP consequence (e.g., intron_variant, missense_variant) |
| SYMBOL | Gene symbol |
| IMPACT | VEP impact level (HIGH, MODERATE, LOW, MODIFIER) |
| TAG_SNP | Best tag SNP position on BovineHD chip |
| TAG_R2 | Linkage disequilibrium r² with tag SNP |
| ZEBU_CLASS | Zebu specificity classification |
| INDICINE_PROB | Mean Pr(Indicina) for overlapping SNPs |

### Zebu specificity classifications

| Classification | Criterion |
|---|---|
| Indicine-specific | Mean Pr(Indicina) >= 0.95 |
| Taurine-specific | Mean Pr(Indicina) < 0.05 |
| Mixed/Admixed | 0.05 <= Mean Pr(Indicina) < 0.95 |
| No SNP data | No Kasarapu et al. SNPs within 1000 bp |

---

## Example Use Cases

For self-contained runnable examples demonstrating each pipeline step, see the [examples/](../examples/) directory.

For the complete SV Catalog pipeline walkthrough with advanced options (HPC, parallel execution, custom parameters), see [pipelines/SV_Catalog/docs/USAGE.md](../pipelines/SV_Catalog/docs/USAGE.md).
