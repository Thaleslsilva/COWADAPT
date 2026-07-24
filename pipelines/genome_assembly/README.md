# Genome Assembly Pipeline

This pipeline performs de novo genome assembly from PacBio HiFi / ONT long-read sequencing data. It takes filtered long reads through assembly, quality control, format conversion, and (optionally) duplicate purging.

## Pipeline Steps

The scripts must be run in the following order:

1. **[`Hifiasm.sh`](./Hifiasm.sh)** — Genome assembly
2. **[`Assembly_QC.sh`](./Assembly_QC.sh)** — Assembly quality control statistics
3. **[`GFA2FASTA_conversion.sh`](./GFA2FASTA_conversion.sh)** — GFA to FASTA conversion and indexing
4. **[`Purge_Dups.sh`](./Purge_Dups.sh)** — Duplicate/haplotig purging *(optional)*

---

### 1. Hifiasm.sh

Performs de novo genome assembly from filtered long-read FASTQ files using [HiFiasm](https://github.com/chhylp123/hifiasm). Loops over every filtered fastq file in `READS_DIR` and produces one assembly per sample.

**Dependencies:**
- `hifiasm` (v0.19 or later)
- `gzip`

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `READS_DIR` | Directory containing input `.fq.gz` files (expects `*_filt.fq.gz`) | `/home/2.qc_fastq/Filtered_fq` |
| `OUTPUT_DIR` | Base output directory | `./hifiasm_output` |

**Usage:**

```bash
OUTPUT_DIR="./hifiasm_output" ./Hifiasm.sh

# Or overriding defaults:
READS_DIR="/path/to/reads" OUTPUT_DIR="/path/to/output" ./Hifiasm.sh
```

**Output:** one subdirectory per sample under `OUTPUT_DIR`, each containing the HiFiasm assembly graphs (`.gfa`) and logs.

---

### 2. Assembly_QC.sh

Generates comprehensive quality control statistics for genome assemblies using [seqkit](https://github.com/shenwei356/seqkit), including sequence length distribution, GC content, N-count, and other assembly metrics.

**Dependencies:**
- `seqkit` (v2.8.2 or later)

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `ASSEMBLY_DIR` | Directory containing assembly fasta files (required) | — |
| `OUTPUT_DIR` | Output directory for statistics files | current directory |
| `SAMPLE_LIST` | File containing sample IDs, one per line. If not provided, a single sample is processed from the command-line argument | — |
| `THREADS` | Number of parallel threads | `4` |

**Usage:**

```bash
# Single sample
ASSEMBLY_DIR="/path/to/assemblies" ./Assembly_QC.sh SAMPLE_NAME

# Multiple samples from a list file
ASSEMBLY_DIR="/path/to/assemblies" SAMPLE_LIST="samples.txt" ./Assembly_QC.sh

# Examples
./Assembly_QC.sh COWADAPT_001
ASSEMBLY_DIR="./hifiasm_output" SAMPLE_LIST="allSamples.txt" ./Assembly_QC.sh
```

**Output:** one `{SAMPLE_ID}_assm_stats.tsv` file per sample in `OUTPUT_DIR`.

---

### 3. GFA2FASTA_conversion.sh

Converts HiFiasm graph assembly (GFA) output to FASTA sequences using [gfatools](https://github.com/lh3/gfatools), compresses them with `bgzip`, and generates FASTA indices for both haplotype assemblies (hap1/hap2).

**Dependencies:**
- `gfatools` (v0.4.1 or later)
- `bgzip` (from htslib)
- `samtools` (v1.10 or later) — for FASTA indexing

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `BASE_DIR` | Directory containing sample subdirectories (required) | `.` |
| `GFA_PATTERN_HAP1` | File pattern for haplotype 1 | `*.asm.bp.hap1.p_ctg.gfa` |
| `GFA_PATTERN_HAP2` | File pattern for haplotype 2 | `*.asm.bp.hap2.p_ctg.gfa` |
| `FORCE_OVERWRITE` | Overwrite existing compressed files | `false` |

**Usage:**

```bash
export BASE_DIR="/path/to/samples"
./GFA2FASTA_conversion.sh

# Or with custom patterns:
BASE_DIR="/path/to/samples" \
GFA_PATTERN_HAP1="*.hap1.gfa" \
GFA_PATTERN_HAP2="*.hap2.gfa" \
./GFA2FASTA_conversion.sh
```

**Output:** for each sample and haplotype:
- `{sample}.hap1.fasta.gz` / `{sample}.hap2.fasta.gz` — compressed FASTA
- `{sample}.hap1.fasta.gz.fai` / `{sample}.hap2.fasta.gz.fai` — FASTA index
- `{sample}.hap1.fasta.gz.gzi` / `{sample}.hap2.fasta.gz.gzi` — compressed index

---

### 4. Purge_Dups.sh *(optional)*

Identifies and removes duplicate sequences and haplotigs from haplotype-collapsed genome assemblies using coverage analysis and self-alignment via [purge_dups](https://github.com/dfguan/purge_dups). This step is optional and recommended when the assembly is expected to retain duplicated haplotype content.

**Dependencies:**
- `minimap2` (v2.17 or later)
- `samtools` (v1.10 or later)
- `purge_dups` (v1.2.5 or later) and its helper scripts: `pbcstat`, `calcuts`, `split_fa`, `get_seqs`

**Environment variables:**

| Variable | Description | Default |
|---|---|---|
| `READS_DIR` | Directory containing filtered fastq files (required) | `.` |
| `ASSEMBLY_DIR` | Directory containing assembly fasta files (required) | `.` |
| `OUTPUT_DIR` | Output directory for purged sequences (required) | `.` |
| `SAMPLE_ID` | Sample identifier to process (required) | — |
| `THREADS` | Number of threads for minimap2 | `32` |
| `SAMTOOLS_THREADS` | Number of threads for samtools | `8` |

**Usage:**

```bash
export READS_DIR="/path/to/reads"
export ASSEMBLY_DIR="/path/to/assemblies"
export OUTPUT_DIR="/path/to/output"
./Purge_Dups.sh COWADAPT_008

# Or with environment variables:
READS_DIR=/path ASSEMBLY_DIR=/path OUTPUT_DIR=/path SAMPLE_ID=COWADAPT_008 ./Purge_Dups.sh
```

**Output:**
- `{SAMPLE_ID}_purged.fa` — primary purged sequence
- `{SAMPLE_ID}_haplotigs.fa` — haplotype sequences
- `PB.stat` — coverage statistics
- `dups.bed` — duplication coordinates
- `asm.split.self.paf.gz` — self-alignment PAF
