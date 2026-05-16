# COWADAPT Installation Guide

Complete step-by-step guide to install and configure the COWADAPT pipeline.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Clone Repository](#clone-repository)
3. [Install Dependencies](#install-dependencies)
4. [Download Reference Data](#download-reference-data)
5. [Verify Installation](#verify-installation)
6. [Prepare Input Data](#prepare-input-data)

---

## System Requirements

### Hardware
- **CPU:** 8+ cores (16+ recommended)
- **RAM:** 64 GB minimum (128 GB recommended for parallel jobs)
- **Disk Space:** ~3.5 TB total
  - Input BAM files: 1-2 TB
  - Reference data: ~200 GB
  - Intermediate/results: ~1.3 TB
- **Network:** Good connection for reference data downloads (especially VEP cache ~15 GB)

### Software
- **OS:** Linux/Unix (Ubuntu 20.04+ tested)
- **Shell:** bash 4.0+
- **Git:** v2.0+

### Package Manager
- **conda** (Miniconda or Anaconda)
  - Download: https://docs.conda.io/projects/miniconda/en/latest/

---

## Clone Repository

```bash
# Clone the repository
git clone https://github.com/thalesbioinfo/cowadapt-svs.git
cd cowadapt-svs

# Verify structure
ls -la
# Output should show: README.md, LICENSE, src/, config/, data/, docs/, etc.
```

---

## Install Dependencies

### Step 1: Run Automated Installation Script

```bash
# This installs all conda and pip dependencies
bash install.sh

# Enter conda environment when prompted (or manually)
conda activate cowadapt
```

**What the script does:**
- Creates conda environment (Python 3.8)
- Installs bioinformatics tools (sniffles2, svim, survivor, samtools, bcftools, VEP, plink2)
- Installs Python packages (pandas, numpy, pysam, matplotlib, etc.)
- Verifies all tools are accessible

### Step 2: Verify Installation

```bash
# Check conda environment
conda info --envs
# Should list 'cowadapt' environment

# Activate it
conda activate cowadapt

# Test key tools
sniffles2 --version    # Should print version
svim --version
samtools --version
bcftools --version
plink2 --version
vep --version
```

### Troubleshooting Installation

**Problem:** `conda: command not found`
```bash
# Solution: Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
# Follow prompts, add to PATH
```

**Problem:** Tool installation fails
```bash
# Solution: Install tools manually from bioconda
conda activate cowadapt
conda install -c bioconda sniffles2 svim survivor samtools bcftools
conda install -c bioconda ensembl-vep plink2
```

**Problem:** Python package installation fails
```bash
# Solution: Install packages individually
pip install --break-system-packages pandas numpy pysam matplotlib
```

---

## Download Reference Data

### Overview

You need 5 reference files. The pipeline can **automate 2 of them**:

| File | Size | Auto? | How |
|------|------|-------|-----|
| ARS-UCD2.0 genome | 3.1 GB | ✅ | Download from NCBI |
| Index (.fai) | 30 KB | ✅ | Create locally |
| BovineHD chip | ~500 KB | ❌ | Manual (see below) |
| SNPmap | ~10 MB | ❌ | Manual (see below) |
| VEP cache | 15 GB | ✅ | Download from Ensembl |

### Automated Download

```bash
# This script automates ARS-UCD2.0 genome + VEP cache
bash src/utils/setup_reference_data.sh

# Or do them one by one:

# 1. Download ARS-UCD2.0 genome (NCBI)
bash src/utils/download_reference_genome.sh data/reference

# 2. Index is created automatically by the above script
# Manual: samtools faidx data/reference/ARS-UCD2.0_genomic.fa

# 3. Download VEP cache (Ensembl) - takes 30-60 minutes
vep_install \
  --AUTO cf \
  --SPECIES bos_taurus \
  --ASSEMBLY ARS-UCD2.0 \
  --CACHEDIR data/reference/vep_cache/ \
  --NO_HTSLIB 0
```

### Manual Downloads (BovineHD + SNPmap)

#### BovineHD Chip Positions

**Option A: From Illumina**
1. Go to: https://support.illumina.com/
2. Login or register
3. Search for: "BovineHD"
4. Download: SNP manifest or BED file
5. Convert coordinates if needed (UCD1.2 → ARS-UCD2.0)
6. Save to: `data/reference/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed`

**Option B: From Published Papers**
1. Search Google Scholar for "BovineHD ARS-UCD"
2. Find papers with supplementary materials
3. Download BED/manifest file
4. Save to: `data/reference/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed`

**Option C: Coordinate Conversion (if you have UCD1.2)**

If you have BovineHD positions in UCD1.2 coordinates, convert using liftOver:

```bash
# Get liftOver tool
wget https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
chmod +x liftOver

# Get chain file
wget https://hgdownload.cse.ucsc.edu/goldenPath/bosTau6/liftOver/bosTau6ToARS-UCD2.0.over.chain.gz
gunzip bosTau6ToARS-UCD2.0.over.chain.gz

# Convert
./liftOver bovineHD_UCD1.2.bed bosTau6ToARS-UCD2.0.over.chain \
  bovineHD_ARS-UCD2.0.bed unmapped.bed

# Move to correct location
mv bovineHD_ARS-UCD2.0.bed data/reference/bovine_hd_chip/
```

#### Zebu SNPmap (Kasarapu et al. 2017)

**Source:** https://doi.org/10.1038/ncomms14482

**Steps:**
1. Go to: https://www.nature.com/articles/ncomms14482
2. Scroll to: "Supplementary Information"
3. Download: "Supplementary Data 1" (SNPmap with Pr_Indicina/Pr_Taurine)
4. Extract text file
5. Ensure coordinates are ARS-UCD2.0 (may need liftOver from UCD1.2)
6. Save to: `data/reference/zebu_snpmap/SNPmap_IND_TAU_ARS.txt`

**Or contact authors:**
- Email corresponding author
- Request: SNPmap remapped to ARS-UCD2.0
- Usually provided in supplementary materials

### Verify Downloaded Files

```bash
# Check directory structure
ls -R data/reference/

# Expected output:
# data/reference/
# ├── ARS-UCD2.0_genomic.fa (3.1 GB)
# ├── ARS-UCD2.0_genomic.fa.fai (30 KB)
# ├── bovine_hd_chip/
# │   └── bovineHD_ARS-UCD2.0.bed (~500 KB)
# ├── zebu_snpmap/
# │   └── SNPmap_IND_TAU_ARS.txt (~10 MB)
# └── vep_cache/
#     └── bos_taurus/115_ARS-UCD2.0/ (~15 GB)

# Verify file sizes
du -sh data/reference/*

# Verify indices
ls -lh data/reference/*.fai
```

---

## Prepare Input Data

### Add Sample BAM Files

The pipeline expects long-read BAM files (PacBio CLR or ONT).

```bash
# Create BAM directory
mkdir -p data/raw/bams

# Copy your BAM files
cp /path/to/your/bams/*.bam data/raw/bams/
cp /path/to/your/bams/*.bam.bai data/raw/bams/

# Verify BAM files are indexed
for bam in data/raw/bams/*.bam; do
  if [ ! -f "${bam}.bai" ]; then
    echo "Indexing: $bam"
    samtools index -@ 4 "$bam"
  fi
done
```

### Update Sample Manifest

Edit `config/sample_manifest.txt` with your sample information:

```bash
nano config/sample_manifest.txt
```

Format:
```
sample_id    bam_file              breed    phenotype    notes
SAMPLE_001   bams/SAMPLE_001.bam   Nelore   Control      High coverage
SAMPLE_002   bams/SAMPLE_002.bam   Nelore   Resistant    Disease resistant
...
```

### Update Configuration (Optional)

Edit `config/parameters.yaml` if you need custom settings:

```bash
nano config/parameters.yaml

# Common changes:
# - threads: number of CPU cores to use
# - min_sv_length: minimum SV size to report
# - cluster.job_partition: SLURM partition (if using cluster)
```

---

## Verify Installation

Run verification script:

```bash
bash src/utils/check_dependencies.sh

# Expected output:
# ✓ python3
# ✓ sniffles2
# ✓ svim
# ✓ samtools
# ✓ bcftools
# ✓ vep
# ✓ plink2
# ✓ pandas, numpy, pysam (Python packages)
```

---

## Test Installation (Optional)

Run pipeline on small test dataset:

```bash
# Download small test BAM (10 MB)
bash src/utils/download_test_data.sh

# Run first step on test data
bash src/01_sv_calling/run_sniffles2_calling.sh --config config/parameters.yaml --sample TEST_001

# Should complete in <5 minutes
```

---

## Setup for HPC Cluster (SLURM)

If running on a compute cluster:

```bash
# 1. Load conda module (if required by cluster)
module load miniconda3
# or
module load conda

# 2. Create environment on shared filesystem
conda create -n cowadapt python=3.8 -p /path/to/shared/conda/cowadapt

# 3. Install tools
conda activate /path/to/shared/conda/cowadapt
bash install.sh

# 4. Update config/parameters.yaml for cluster
nano config/parameters.yaml
# Set: cluster.enabled = true
# Set: cluster.job_partition = your_partition_name

# 5. Submit as job array
sbatch --array=0-19 src/01_sv_calling/run_sniffles2_calling.sh
```

See: `docs/install_guides/SLURM_GUIDE.md` for detailed HPC setup.

---

## Setup Complete!

Once all steps are done, your directory should look like:

```
cowadapt-svs/
├── src/                    # Pipeline scripts
├── config/                 # Configuration files
├── data/
│   ├── raw/bams/         # Your BAM files
│   └── reference/         # Reference data (just downloaded)
├── results/               # Will be filled during pipeline run
├── docs/                  # Documentation
└── [other files]
```

You're now ready to run the pipeline!

---

## Next Steps

1. **Quick Test (Optional):**
   ```bash
   bash src/01_sv_calling/run_sniffles2_calling.sh --config config/parameters.yaml --sample TEST_001
   ```

2. **Run Full Pipeline:**
   ```bash
   bash src/01_sv_calling/run_sniffles2_calling.sh
   bash src/01_sv_calling/run_svim_calling.sh
   bash src/02_sv_merge/run_survivor_merge.sh
   # ... continue through step 07
   ```

3. **Or use Snakemake (if implemented):**
   ```bash
   snakemake -j 8 --use-conda
   ```

4. **Read Documentation:**
   - `docs/USAGE.md` — Detailed usage guide
   - `docs/PIPELINE_OVERVIEW.md` — Technical details
   - `README.md` — Project overview

---

## Troubleshooting

See `docs/TROUBLESHOOTING.md` for common issues and solutions.

---

## Getting Help

- Check: `docs/TROUBLESHOOTING.md`
- Read: `docs/USAGE.md`
- Review: `docs/PIPELINE_OVERVIEW.md`
- Contact: medvet21@gmail.com

