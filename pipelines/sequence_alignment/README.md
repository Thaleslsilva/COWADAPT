# Sequence Alignment Pipeline

This pipeline aligns long-read sequencing data — against a reference genome or against each sample's own assembly — using [Minimap2](https://github.com/lh3/minimap2), producing sorted and indexed BAM files, and then evaluates alignment quality and coverage with [samtools](https://github.com/samtools/samtools) and [mosdepth](https://github.com/brentp/mosdepth).

## Pipeline Steps

The scripts must be run in the following order. Step 1 has two alternatives — choose the one that matches your downstream analysis goal (see [Choosing the Right Alignment Strategy](#choosing-the-right-alignment-strategy)):

1. **[`Ref-Based_Alignment.sh`](./Ref-Based_Alignment.sh)** — reference-based read alignment (for SNP/INDEL calling), or
   **[`Assm-Based_Alignment.sh`](./Assm-Based_Alignment.sh)** — assembly-based read alignment (for structural variant detection)
2. **[`BAM_QC.sh`](./BAM_QC.sh)** — BAM file quality control
3. **[`Coverage.sh`](./Coverage.sh)** — BAM file coverage

---

### 1a. Ref-Based_Alignment.sh

Aligns filtered long-read sequencing data directly to a reference genome using [minimap2](https://github.com/lh3/minimap2) and generates a sorted, indexed BAM file with [samtools](https://github.com/samtools/samtools).

**Dependencies:**
- `minimap2` (v2.17 or later)
- `samtools` (v1.10 or later)

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `BASE_DIR` | Base project directory | `.` |
| `READS_DIR` | Directory containing filtered fastq files (expects `{SAMPLE}_filt.fq.gz`) | `${BASE_DIR}/2.qc_fastq/Filtered_fq` |
| `REFER_DIR` | Directory containing genome reference fasta files | `${BASE_DIR}/genRef` |
| `REFERENCE` | Reference genome fasta file to align against | `${REFER_DIR}/ARS-UCD2.0_genomic.fa` |
| `OUTPUT_DIR` | Output directory for BAM files | `${BASE_DIR}/3.align_fastq/Align_ARS2` |
| `THREADS` | Number of threads used by minimap2/samtools | `64` |

**Usage:**

```bash
export BASE_DIR="/path/to/project"
./Ref-Based_Alignment.sh

# Or with custom directories:
BASE_DIR=/path/to/project READS_DIR=/path/to/reads REFER_DIR=/path/to/genRef \
REFERENCE=/path/to/genRef/reference.fa OUTPUT_DIR=/path/to/output ./Ref-Based_Alignment.sh
```

**Output:** one `{SAMPLE}.sorted.bam` (and its `.bai` index) per sample in `OUTPUT_DIR`.

---

### 1b. Assm-Based_Alignment.sh

Aligns each sample's filtered long reads to that same sample's own genome assembly (e.g. from HiFiasm, see [`genome_assembly/`](../genome_assembly)) using [minimap2](https://github.com/lh3/minimap2) and generates indexed BAM files.

**Dependencies:**
- `minimap2` (v2.17 or later)
- `samtools` (v1.10 or later)

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `BASE_DIR` | Base project directory | `.` |
| `READS_DIR` | Directory containing filtered fastq files (expects `{SAMPLE}_filt.fq.gz`) | **required, no default** |
| `ASSEMBLIES_DIR` | Directory containing per-sample assembly folders (expects `{SAMPLE}/{SAMPLE}.1ctg.fasta.gz`) | `${BASE_DIR}/hifiasm_output` |
| `OUTPUT_DIR` | Output directory for BAM files | `${BASE_DIR}/alignments/assmBased` |
| `SAMPLE_PATTERN` | Sample folder name pattern to process | `unespONT_*` |

**Usage:**

```bash
export BASE_DIR="/path/to/project"
export READS_DIR="/path/to/2.qc_fastq/Filtered_fq"
./Assm-Based_Alignment.sh

# Or with custom directories:
BASE_DIR=/path/to/project READS_DIR=/path/to/reads ASSEMBLIES_DIR=/path/to/assemblies \
OUTPUT_DIR=/path/to/output SAMPLE_PATTERN="COWADAPT_*" ./Assm-Based_Alignment.sh
```

**Output:** one `{SAMPLE}_alnRead.bam` (and its `.bai` index) per sample in `OUTPUT_DIR`.

> **Note:** `BAM_QC.sh` and `Coverage.sh` (below) look for files matching `*.sorted.bam`, which is the naming used by `Ref-Based_Alignment.sh`. To run QC/coverage on `Assm-Based_Alignment.sh` output, point `OUTPUT_DIR` at its output directory and rename/symlink the `_alnRead.bam` files to `*.sorted.bam` first.

---

### 2. BAM_QC.sh

Runs quality-control metrics ([`samtools flagstat`](https://www.htslib.org/doc/samtools-flagstat.html), [`samtools stats`](https://www.htslib.org/doc/samtools-stats.html) and [`samtools idxstats`](https://www.htslib.org/doc/samtools-idxstats.html)) on the sorted, indexed BAM files produced by `Ref-Based_Alignment.sh`. Samples are processed in parallel, up to `MAX_JOBS` at a time.

**Dependencies:**
- `samtools` (v1.10 or later)

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `BASE_DIR` | Base project directory | `.` |
| `OUTPUT_DIR` | Directory containing the sorted BAM files (output of `Ref-Based_Alignment.sh`) | `${BASE_DIR}/3.align_fastq/Align_ARS2` |
| `QLTCTR_DIR` | Output directory for QC reports | `${BASE_DIR}/3.align_fastq/Qlty_Ctrl` |
| `MAX_JOBS` | Maximum number of samples processed in parallel | `10` |

**Usage:**

```bash
export BASE_DIR="/path/to/project"
./BAM_QC.sh

# Or with custom directories:
BASE_DIR=/path/to/project OUTPUT_DIR=/path/to/output QLTCTR_DIR=/path/to/qc \
./BAM_QC.sh
```

**Output:** one `{SAMPLE}.flagstat`, `{SAMPLE}.stat` and `{SAMPLE}.idxstat` per sample in `QLTCTR_DIR`.

---

### 3. Coverage.sh

Computes per-base and windowed (100kb) sequencing coverage for the sorted, indexed BAM files produced by `Ref-Based_Alignment.sh`, using [mosdepth](https://github.com/brentp/mosdepth). Samples are processed in parallel, up to `MAX_JOBS` at a time.

**Dependencies:**
- `mosdepth` (v0.3 or later)

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `BASE_DIR` | Base project directory | `.` |
| `OUTPUT_DIR` | Directory containing the sorted BAM files (output of `Ref-Based_Alignment.sh`) | `${BASE_DIR}/3.align_fastq/Align_ARS2` |
| `COVRG_DIR` | Output directory for coverage reports | `${BASE_DIR}/3.align_fastq/Coverage` |
| `MAX_JOBS` | Maximum number of samples processed in parallel | `10` |

**Usage:**

```bash
export BASE_DIR="/path/to/project"
./Coverage.sh

# Or with custom directories:
BASE_DIR=/path/to/project OUTPUT_DIR=/path/to/output COVRG_DIR=/path/to/coverage \
./Coverage.sh
```

**Output:** whole-genome mosdepth output files per sample (`{SAMPLE}.mosdepth*`, `{SAMPLE}.per-base.bed.gz`, ...) and windowed 100kb coverage files (`{SAMPLE}.100kb.*`) in `COVRG_DIR`.

---

## Choosing the Right Alignment Strategy

This pipeline provides two alternative alignment strategies for step 1, matched to the downstream analysis goal: structural variant (SV) detection or SNP/INDEL calling.

### 1. Structural Variant (SV) Detection — `Assm-Based_Alignment.sh`

Aligns each sample's filtered reads to that sample's own de novo assembly (e.g. from HiFiasm, see [`genome_assembly/`](../genome_assembly)) instead of to the reference genome:

```
hifiasm assembly ({SAMPLE}.1ctg.fasta.gz) + reads ({SAMPLE}_filt.fq.gz) -> Assm-Based_Alignment.sh (minimap2 -ax map-ont) -> samtools sort/index -> sniffles / cuteSV / SVIM
```

```bash
export BASE_DIR="/path/to/project"
export READS_DIR="/path/to/2.qc_fastq/Filtered_fq"
./Assm-Based_Alignment.sh
```

Call structural variants from the resulting BAM with one of:

```bash
sniffles --input {SAMPLE}_alnRead.bam --vcf sv_calls.vcf --threads 16
```

```bash
cuteSV {SAMPLE}_alnRead.bam {SAMPLE}.1ctg.fasta.gz sv_cutesv.vcf tmp/ --threads 16
```

For a more global comparison between assembly and reference (e.g. inversions, translocations), consider [MUMmer](https://github.com/mummer4/mummer) (`nucmer` + `delta-filter` + `dnadiff`) or [SyRI](https://github.com/schneebergerlab/syri) — this whole-assembly-vs-reference comparison is not performed by any script in this pipeline.

### 2. SNP/INDEL Calling — `Ref-Based_Alignment.sh`

Aligns the raw filtered reads directly to the reference genome:

```
reads ({SAMPLE}_filt.fq.gz) -> Ref-Based_Alignment.sh (minimap2 -ax map-ont) -> samtools sort/index -> DeepVariant / Clair3 / GATK
```

```bash
export BASE_DIR="/path/to/project"
./Ref-Based_Alignment.sh
```

The resulting `{SAMPLE}.sorted.bam` can then be passed to a variant caller such as [DeepVariant](https://github.com/google/deepvariant), [Clair3](https://github.com/HKU-BAL/Clair3), or [GATK](https://github.com/broadinstitute/gatk).

### Summary

| Goal | Script | Alignment input | minimap2 preset | Downstream tools |
|---|---|---|---|---|
| Structural variants (SVs) | `Assm-Based_Alignment.sh` | Reads vs. sample's own assembly | `-ax map-ont` | `sniffles`, `cuteSV`, `SVIM`, `SyRI` |
| SNPs / INDELs | `Ref-Based_Alignment.sh` | Reads vs. reference genome | `-ax map-ont` | `DeepVariant`, `Clair3`, `GATK` |

**Tips:**
- Use `Assm-Based_Alignment.sh` for SV detection and `Ref-Based_Alignment.sh` for SNP/INDEL calling — combine both for a complete variant picture.
- `BAM_QC.sh` and `Coverage.sh` expect `*.sorted.bam` files, matching the naming used by `Ref-Based_Alignment.sh`. Adapt `OUTPUT_DIR`/file naming if you want to run them on `Assm-Based_Alignment.sh` output.
