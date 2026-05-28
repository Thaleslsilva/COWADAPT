# Installation Guide

Step-by-step instructions to set up the COWADAPT environment and pipelines.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Clone the Repository](#clone-the-repository)
3. [Install Dependencies](#install-dependencies)
4. [Download Reference Data](#download-reference-data)
5. [Configure the Pipeline](#configure-the-pipeline)
6. [Verify Installation](#verify-installation)
7. [HPC / SLURM Setup](#hpc--slurm-setup)
8. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Hardware

| Resource | Minimum | Recommended |
|---|---|---|
| CPU cores | 8 | 16-32 |
| RAM | 64 GB | 128 GB |
| Disk space | 500 GB | 3.5 TB |
| Network | Standard | High-speed for reference downloads |

Disk space breakdown:
- Input BAM files: 1-2 TB
- Reference data (genome + VEP cache): ~200 GB
- Intermediate pipeline files: ~1 TB
- Final results and figures: ~10-50 GB

### Software

| Tool | Version | Notes |
|---|---|---|
| OS | Ubuntu 20.04+ / CentOS 7+ | Other Linux distributions should work |
| Bash | 4.0+ | Required by all pipeline scripts |
| Python | 3.8+ | Required for analysis scripts |
| Git | 2.0+ | For cloning the repository |
| Conda | Latest | Recommended for dependency management |

---

## Clone the Repository

```bash
git clone https://github.com/Thaleslsilva/COWADAPT.git
cd COWADAPT
```

---

## Install Dependencies

### Using Conda (Recommended)

```bash
# Create and activate a dedicated environment
conda create -n cowadapt python=3.8
conda activate cowadapt

# Install bioinformatics tools from the bioconda channel
conda install -c bioconda -c conda-forge \
    sniffles \
    svim \
    survivor \
    samtools \
    bcftools \
    minimap2 \
    seqkit \
    nanocomp \
    porechop \
    hifiasm \
    purge_dups \
    gfatools

# Install Python packages
pip install pysam numpy pandas matplotlib seaborn biopython
```

### Ensembl VEP (Variant Effect Predictor)

VEP is required for the functional annotation step (Step 4 of the SV Catalog pipeline).

```bash
# Install VEP (requires Perl)
git clone https://github.com/Ensembl/ensembl-vep.git
cd ensembl-vep
perl INSTALL.pl

# Download the bovine cache (~15 GB, takes 30-60 minutes)
./vep_install.sh -s bos_taurus -y ARS-UCD1.2
cd ..
```

Alternatively, run the automated installer:

```bash
bash pipelines/SV_Catalog/src/04_functional_annotation/install_and_run_vep.sh
```

### plink2 (for LD Analysis)

```bash
# Download plink2 from https://www.cog-genomics.org/plink/2.0/
wget https://s3.amazonaws.com/plink2-assets/alpha3/plink2_linux_amd64_20221024.zip
unzip plink2_linux_amd64_20221024.zip
sudo mv plink2 /usr/local/bin/
```

---

## Download Reference Data

### ARS-UCD2.0 Reference Genome (Automated)

```bash
bash pipelines/SV_Catalog/src/utils/download_reference_genome.sh
```

This script downloads the ARS-UCD2.0 bovine reference genome from NCBI (GCF_002263795.3), verifies the download, and creates a samtools index. Download size is approximately 3.1 GB.

### BovineHD SNP Chip Positions (Manual)

The BovineHD chip position file (BED format) must be obtained from Illumina or your institution. Once obtained:

```bash
# Place the BED file in the reference directory
cp /path/to/bovine_hd_chip.bed data/reference/bovhd_arsucd2.bed
```

### Zebu SNP Map (Manual)

The Kasarapu et al. (2017) zebu SNP map is available from the supplementary data of:

> Kasarapu P, et al. (2017). "Sequencing of diverse mandarin, pummelo and sweet orange accessions." *Nature Communications*, 8, 15385.

```bash
cp /path/to/zebu_snpmap.txt data/reference/zebu_snpmap_kasarapu2017.txt
```

### Run All Reference Setup at Once

```bash
bash pipelines/SV_Catalog/src/utils/setup_reference_data.sh
```

This orchestrates automated downloads and reports which files require manual acquisition.

---

## Configure the Pipeline

Edit the central configuration file to match your system:

```bash
nano pipelines/SV_Catalog/config/pipeline.config
```

Key parameters to update:

```bash
# Data paths
RAW_BAM_DIR="/path/to/your/bam/files"
REFERENCE_DIR="/path/to/reference/data"
OUTPUT_DIR="/path/to/results"

# Reference files
REFERENCE_GENOME="${REFERENCE_DIR}/ARS-UCD2.0.fa"
BOVINE_HD_BED="${REFERENCE_DIR}/bovhd_arsucd2.bed"
ZEBU_SNPMAP="${REFERENCE_DIR}/zebu_snpmap_kasarapu2017.txt"
VEP_CACHE_DIR="${HOME}/.vep"

# Compute resources
THREADS=8
MAX_PARALLEL_JOBS=4
MEMORY_PER_CPU="4G"
```

---

## Verify Installation

Run the built-in initialization and validation script:

```bash
bash pipelines/SV_Catalog/src/utils/init_pipeline.sh
```

This checks:
- Required tools are installed and accessible
- Reference files exist and are indexed
- Input BAM files exist and have index files
- Output directories are writable
- Configuration parameters are set

---

## HPC / SLURM Setup

The SV Catalog pipeline supports SLURM job submission. Configure the HPC section in `pipeline.config`:

```bash
# HPC / SLURM configuration
SLURM_PARTITION="compute"
SLURM_TIME="24:00:00"
SLURM_MEM_PER_CPU="4G"
SLURM_CPUS=8
SLURM_ACCOUNT="your_project"
```

Submit jobs using the `--slurm` flag where supported, or use the HPC-specific scripts:

```bash
sbatch pipelines/SV_Catalog/src/01_sv_calling/run_sniffles2_calling.sh
```

---

## Troubleshooting

### Tool not found

```
Error: sniffles2 command not found
```

Activate your conda environment: `conda activate cowadapt`

### BAM file missing index

```
Error: BAM index not found for sample_001.bam
```

Index your BAM files: `samtools index sample_001.bam`

### VEP cache not found

```
Error: VEP cache directory /path/.vep does not exist
```

Run VEP setup: `bash pipelines/SV_Catalog/src/04_functional_annotation/install_and_run_vep.sh`

### Insufficient disk space

The pipeline generates large intermediate files. Ensure you have at least 500 GB free per sample. Use `df -h` to check available space before starting.

---

For pipeline-specific installation details, see [pipelines/SV_Catalog/docs/install_guides/INSTALLATION.md](../pipelines/SV_Catalog/docs/install_guides/INSTALLATION.md).
