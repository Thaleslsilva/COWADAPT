# Sequence Alignment Pipeline

This pipeline aligns long-read sequencing data against reference or assembled genomes using [Minimap2](https://github.com/lh3/minimap2), producing sorted and indexed BAM files that feed into downstream variant calling.

## Pipeline Steps

The scripts must be run in the following order:

1. **[`Minimap2.sh`](./Minimap2.sh)** — Assembly-based read alignment

---

### 1. Minimap2.sh

Aligns filtered long-read sequencing data to the corresponding genome assembly of each sample using [minimap2](https://github.com/lh3/minimap2) and generates a sorted, indexed BAM file with [samtools](https://github.com/samtools/samtools).

**Dependencies:**
- `minimap2` (v2.17 or later)
- `samtools` (v1.10 or later)

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `BASE_DIR` | Base project directory | `.` |
| `READS_DIR` | Directory containing filtered fastq files (expects `{SAMPLE}_filt.fq.gz`) | `${BASE_DIR}/KG000421_fq/2_filtered_fqs` |
| `ASSEMBLIES_DIR` | Directory containing assembly fasta files (expects `{SAMPLE}/{SAMPLE}.fasta`) | `${BASE_DIR}/KG000421_fq/4_assembly` |
| `OUTPUT_DIR` | Output directory for BAM files | `${BASE_DIR}/KG000421_bam/assmBased` |
| `SAMPLE_PATTERN` | Sample name pattern to process | `COWADAPT_*` |

**Usage:**

```bash
export BASE_DIR="/home/bt-h1/KG000421"
./Minimap2.sh

# Or with custom directories:
BASE_DIR=/path/to/project READS_DIR=/path/to/reads ASSEMBLIES_DIR=/path/to/assemblies \
OUTPUT_DIR=/path/to/output ./Minimap2.sh
```

**Output:** one `{SAMPLE}_alnRead.bam` (and its `.bai` index) per sample in `OUTPUT_DIR`.

---

## Choosing the Right Alignment Strategy

The output of a de novo assembly (e.g. from HiFiasm, see [`genome_assembly/`](../genome_assembly)) can be used in two different ways, depending on the downstream analysis goal: structural variant (SV) detection or SNP/INDEL calling.

### 1. Structural Variant (SV) Detection — align the assembly to the reference

Use the primary contig assembly (`*.p_ctg.fa`) as the query and align it against a reference genome (e.g. ARS-UCD1.2 or ARS-UCD2.0):

```
hifiasm contigs (p_ctg.fa) -> minimap2 (align to ref) -> samtools sort/index -> sniffles / cuteSV / SVIM
```

```bash
minimap2 -ax asm5 reference.fa assembly.p_ctg.fa > aligned.sam
samtools view -Sb aligned.sam | samtools sort -o aligned.sorted.bam
samtools index aligned.sorted.bam
```

Call structural variants from the resulting BAM with one of:

```bash
sniffles --input aligned.sorted.bam --vcf sv_calls.vcf --threads 16
```

```bash
cuteSV aligned.sorted.bam reference.fa sv_cutesv.vcf tmp/ --threads 16
```

For a more global comparison between assembly and reference (e.g. inversions, translocations), consider [MUMmer](https://github.com/mummer4/mummer) (`nucmer` + `delta-filter` + `dnadiff`) or [SyRI](https://github.com/schneebergerlab/syri).

### 2. SNP/INDEL Calling — align the raw reads to the reference

For SNP calling, it is recommended to align the raw HiFi/long reads directly to the reference genome rather than using the assembly:

```
reads HiFi (*.fq.gz) -> minimap2 (align to ref) -> samtools sort/index -> DeepVariant / Clair3 / GATK
```

```bash
minimap2 -ax map-hifi reference.fa reads.fq.gz | samtools sort -o aligned.sorted.bam
samtools index aligned.sorted.bam
```

The resulting BAM can then be passed to a variant caller such as [DeepVariant](https://github.com/google/deepvariant), [Clair3](https://github.com/HKU-BAL/Clair3), or [GATK](https://github.com/broadinstitute/gatk).

### Summary

| Goal | Alignment input | minimap2 preset | Downstream tools |
|---|---|---|---|
| Structural variants (SVs) | Assembly (`p_ctg.fa`) vs. reference | `-ax asm5` | `sniffles`, `cuteSV`, `SVIM`, `SyRI` |
| SNPs / INDELs | Raw reads vs. reference | `-ax map-hifi` / `-ax map-ont` | `DeepVariant`, `Clair3`, `GATK` |

**Tips:**
- Use the assembly for SV detection and the raw reads for SNP/INDEL calling — combine both for a complete variant picture.
- `Minimap2.sh` in this pipeline performs assembly-based read alignment (reads aligned to each sample's own assembly), which is used for coverage-based QC and duplicate purging (see [`genome_assembly/Purge_Dups.sh`](../genome_assembly/Purge_Dups.sh)).
