# COWADAPT Pipeline - Usage Guide

Complete guide to running the COWADAPT structural variant detection pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup](#setup)
3. [Quick Start](#quick-start)
4. [Detailed Step-by-Step](#detailed-step-by-step)
5. [Advanced Usage](#advanced-usage)
6. [Output Interpretation](#output-interpretation)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- Linux/Unix system (macOS works with adjustments)
- bash 4.0+
- Python 3.7+
- Git

### Required Bioinformatics Tools
```bash
# Via conda (bioconda channel):
conda install -c bioconda sniffles2 svim survivor samtools bcftools
```

See [INSTALLATION.md](install_guides/INSTALLATION.md) for detailed setup.

### Data Requirements
- BAM files aligned to ARS-UCD2.0 reference genome
- BAM index files (.bai)
- ~500 GB disk space per sample (intermediate files)
- Reference genome FASTA + index

---

## Setup

### 1. Clone Repository
```bash
git clone https://github.com/thalesbioinfo/cowadapt-svs.git
cd cowadapt-svs
```

### 2. Create Conda Environment
```bash
conda create -n cowadapt python=3.8
conda activate cowadapt
bash install.sh
```

### 3. Prepare Input Data
```bash
# Create data directory
mkdir -p data/raw/bams

# Copy BAM files
cp /path/to/your/bams/* data/raw/bams/

# Verify BAM files are indexed
cd data/raw/bams
for f in *.bam; do
  [ ! -f "$f.bai" ] && samtools index "$f"
done
cd ../../../
```

### 4. Update Configuration
```bash
# Edit parameters
nano config/parameters.yaml

# Update sample manifest
nano config/sample_manifest.txt
```

---

## Quick Start

### All-in-One Command (Bash)
```bash
# Run all 7 steps
for step in src/0[1-7]_*/*.sh; do
  echo "Running: $step"
  bash "$step" || exit 1
done
```

### Step-by-Step (Bash)
```bash
# Step 1: SV Calling
bash src/01_sv_calling/run_sniffles2_calling.sh
bash src/01_sv_calling/run_svim_calling.sh

# Step 2: Merge
bash src/02_sv_merge/run_survivor_merge.sh

# Step 3: Validation
bash src/03_sv_validation/run_sv_validation.sh

# Step 4: Annotation
bash src/04_functional_annotation/run_vep_annotation.sh

# Step 5: SNP extraction
bash src/05_snp_extraction/extract_bovhd_snps.sh

# Step 6: LD Analysis
bash src/06_ld_analysis/combine_sv_snp_vcf.sh
python3 src/06_ld_analysis/identify_tag_snps.py

# Step 7: Zebu Specificity
python3 src/07_zebu_specificity/annotate_zebu_specificity.py
```

### Via Nextflow (Recommended)
```bash
nextflow run pipeline.nf \
  -profile cluster \
  --input config/sample_manifest.txt \
  --outdir results \
  -resume -with-timeline
```

---

## Detailed Step-by-Step

### Step 1: SV Calling (6-24 hours per sample)

**Input:** BAM files (long-read sequencing)
**Output:** VCF files with SV calls

#### Sniffles2
```bash
cd src/01_sv_calling

# View parameters
grep "sniffles" run_sniffles2_calling.sh

# Run manually for 1 sample (debugging)
sniffles2 \
  --input ../../data/raw/bams/SAMPLE_001.bam \
  --vcf results/SAMPLE_001.sniffles.vcf \
  --threads 8 \
  --min-sv-length 50 \
  --max-sv-length 1000000

# Or use the batch script
bash run_sniffles2_calling.sh
```

#### SVIM
```bash
# Similar process for SVIM
bash run_svim_calling.sh

# Results should be in results/sv_calls/svim_output/
```

---

### Step 2: SV Merge & Concordance (1 hour)

**Input:** VCFs from Sniffles2 and SVIM
**Output:** Merged VCF with concordant SVs only

```bash
cd src/02_sv_merge

# This script:
# 1. Creates list of VCF pairs (one from each caller)
# 2. Merges with SURVIVOR (1000bp threshold, 2 callers required)
# 3. Filters to keep only concordant SVs

bash run_survivor_merge.sh

# Inspect results
bash inspect_survivor_output.sh

# Check number of SVs per type
bcftools query -f '%INFO/SVTYPE\n' results/merged_svs.vcf | sort | uniq -c
```

---

### Step 3: SV Validation (4-8 hours)

**Input:** Merged concordant SVs
**Output:** Validated SVs with confidence scores

```bash
cd src/03_sv_validation

# Setup validation tool (first time only)
bash setup_sv_validation.sh

# Run validation
bash run_sv_validation.sh

# Check results
wc -l results/validation/validated_svs/svs_final_validadas.vcf
```

---

### Step 4: Functional Annotation (8-16 hours)

**Input:** Validated SVs
**Output:** Annotated VCFs with gene information

```bash
cd src/04_functional_annotation

# Download VEP cache (first time, ~15GB, requires ~1 hour)
bash install_and_run_vep.sh

# This will download the cache and annotate in one go
# Or run annotation only (if cache exists):
bash run_vep_annotation.sh

# Extract key annotations
python3 extract_vep_annotations.py \
  --vcf results/annotation/vep_output/svs_anotadas.vcf \
  --output sv_annotations.tsv

# View results
head sv_annotations.tsv
```

---

### Step 5: SNP Extraction (1-2 hours)

**Input:** WGS SNP VCF + BovineHD chip positions
**Output:** SNP VCF filtered to chip positions

```bash
cd src/05_snp_extraction

# Map BovineHD positions to ARS-UCD2.0
bash map_bovhd_to_arsucd.sh

# Extract SNPs
bash extract_bovhd_snps.sh

# Apply quality filters
bash filter_snp_quality.sh

# Check output
bcftools stats results/annotation/snp_vcfs/snps_bovineHD_wgs.vcf.gz
```

---

### Step 6: LD Analysis & Tag SNPs (4-8 hours)

**Input:** Validated SVs + BovineHD SNPs
**Output:** Catalog with tag SNPs

```bash
cd src/06_ld_analysis

# Convert SV genotypes to biallelic format
python3 convert_sv_to_biallelic.py \
  --input svs_validated.vcf \
  --output svs_biallelic.vcf

# Merge SVs and SNPs
bash combine_sv_snp_vcf.sh

# Calculate LD with plink2
plink2 \
  --vcf merged_svs_snps.vcf \
  --r2 \
  --ld-window-kb 500 \
  --out ld_svs_snps

# Identify tag SNPs
python3 identify_tag_snps.py

# Check results
head reports/tag_snps_per_sv.tsv
```

---

### Step 7: Zebu-Specificity Annotation (1-2 hours)

**Input:** SVs + SNPmap (Kasarapu et al.)
**Output:** Final catalog with Indicine/Taurine classification

```bash
cd src/07_zebu_specificity

# Rename chromosomes if needed
bash rename_chromosomes.sh

# Annotate with Indicine-specific SNPs
python3 annotate_zebu_specificity.py \
  --vcf svs_renamed.vcf \
  --snpmap SNPmap_IND_TAU_ARS.txt \
  --output sv_zebu_specificity.txt

# Summarize results
python3 summarize_zebu_specificity.py

# Generate visualization
python3 generate_ideogram.py \
  --vcf svs_renamed.vcf \
  --catalog sv_zebu_specificity.txt \
  --output ideogram_zebu_svs.pdf

# View final catalog
head sv_zebu_specificity.txt | column -t
```

---

## Advanced Usage

### Running on HPC Cluster (SLURM)

```bash
# Modify config/parameters.yaml:
# cluster:
#   enabled: true
#   job_partition: "long"

# Submit as job array (20 samples)
sbatch --array=0-19 src/01_sv_calling/run_sniffles2_calling.sh

# Monitor
squeue -u $USER
```

### Parallel Execution

```bash
# Run multiple steps in parallel (requires sufficient resources)
bash src/01_sv_calling/run_sniffles2_calling.sh &
bash src/01_sv_calling/run_svim_calling.sh &
wait

# Then proceed sequentially for dependent steps
bash src/02_sv_merge/run_survivor_merge.sh
```

### Resume from Checkpoint

```bash
# With Nextflow
nextflow run pipeline.nf -resume

# Bash scripts (check logs for failure point)
# Re-run from last failed step
```

### Custom Parameters

```bash
# Override defaults in command line
export SV_MIN_LENGTH=100
export SV_MAX_LENGTH=500000
bash src/01_sv_calling/run_sniffles2_calling.sh
```

---

## Output Interpretation

### Key Output Files

| File | Location | Description |
|------|----------|-------------|
| SV VCF (merged) | `results/sv_calls/merged_svs.vcf` | Concordant SVs from both callers |
| SV VCF (validated) | `results/validation/validated_svs/svs_final_validadas.vcf` | Read-validated SVs |
| VEP annotation | `results/annotation/vep_output/svs_anotadas.vcf` | Annotated SVs with genes |
| SNP extraction | `results/annotation/snp_vcfs/snps_bovineHD_wgs.vcf.gz` | Filtered SNPs |
| LD results | `results/analysis/ld_analysis/ld_svs_snps.vcor` | Plink2 LD output |
| Tag SNPs | `results/analysis/tag_snps/tag_snps_per_sv.tsv` | **Final: SV ↔ SNP mapping** |
| Zebu catalog | `results/analysis/zebu_specificity.txt` | **Final: Complete catalog** |

### Final Catalog Format

```
SV_ID           TAG_SNP       R2      GENE        IMPACT    Pr_Indicine   Classification
sv_001_DEL      rs1234567     0.95    GENE_A      HIGH      0.98          Indicine-specific
sv_002_INS      rs9876543     0.42    INTERGENIC  LOW       0.12          Taurine-specific
...
```

---

## Troubleshooting

### Issue: "Command not found"
**Solution:** Ensure environment is activated
```bash
conda activate cowadapt
which sniffles2  # Should show path
```

### Issue: BAM file not indexed
**Solution:** Create indices
```bash
samtools index data/raw/bams/*.bam
```

### Issue: Out of memory
**Solution:** Reduce threads or increase available RAM
```bash
export OMP_NUM_THREADS=4  # Reduce threads
# Or add more RAM/swap
```

### Issue: VEP cache not found
**Solution:** Download cache
```bash
bash src/04_functional_annotation/install_and_run_vep.sh
```

### Issue: Slow performance
**Solution:** Check resource usage
```bash
top  # Monitor CPU/memory
df -h  # Check disk space
htop  # More detailed
```

---

## Getting Help

1. Check [README.md](../README.md) for overview
2. See [troubleshooting section](#troubleshooting) above
3. Review script comments: `head -50 src/0X_*/run_*.sh`
4. Check error logs: `cat logs/*.err`
5. Open GitHub issue with:
   - Error message & log snippet
   - Your environment (OS, tool versions)
   - Steps to reproduce

---

## Next Steps

After pipeline completion:
1. Review final catalog
2. Filter SVs by impact (HIGH/MODERATE)
3. Validate findings with independent method (PCR, etc.)
4. Perform association studies if phenotypes available
5. Publish findings!

Good luck! 🧬
