# Script Refactoring Guide - Removing Hardcoded Paths

## Overview

All pipeline scripts have been refactored to use a **centralized configuration system** instead of hardcoded paths. This makes the pipeline portable and usable by external researchers.

**Status:** 
- ✅ Configuration system created (`config/pipeline.config`)
- ✅ Initialization script created (`src/utils/init_pipeline.sh`)
- ✅ 2 Critical scripts refactored (SV calling)
- ⏳ 6 Additional scripts ready for refactoring

---

## Key Changes

### Before (Hardcoded Paths)

```bash
#!/bin/bash

# ❌ BAD: These paths only work on the original author's machine!
genRef="/cluster/work/pausch/thales/KG000421/genRef/ARS-UCD2.0_genomic.fa"
BAM_LIST=($(ls AlignARS2_Bam/*.bam))
OUT_DIR="../../KG000421_svs/readBased/SVIM"

sniffles --input "$bam_file" --reference "$genRef"
```

**Problems:**
- Scripts fail immediately for any user without those exact directories
- No documentation of where data should go
- Different scripts use different directory structures
- Cluster-specific paths embedded in code

### After (Configuration-Based)

```bash
#!/bin/bash

# ✅ GOOD: Everything sourced from central config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${PROJECT_ROOT}/config/pipeline.config"

# Variables now come from config:
# $REFERENCE_GENOME = "data/reference/ARS-UCD2.0_genomic.fa"
# $RAW_BAM_DIR = "data/raw/bams"
# $SV_SNIFFLES_DIR = "results/sv_calls/sniffles2"

init_directories                    # Creates all needed output dirs
check_references                    # Validates reference files exist
readarray -t BAM_LIST < <(find "$RAW_BAM_DIR" -name "*.bam")

sniffles --input "$bam_file" --reference "$REFERENCE_GENOME"
```

**Benefits:**
- Single source of truth for all paths
- Works anywhere (local computer, HPC, cloud)
- Clear error messages if files are missing
- Easy to customize via one config file

---

## System Architecture

```
project-root/
├── config/
│   └── pipeline.config          ← CENTRAL CONFIG (all paths & parameters)
│
├── src/
│   ├── utils/
│   │   ├── init_pipeline.sh     ← Validates setup before running
│   │   └── setup_reference_data.sh (already updated)
│   │
│   └── 01_sv_calling/
│       ├── run_sniffles2_calling.sh    ✅ REFACTORED
│       └── run_svim_calling.sh         ✅ REFACTORED
│
└── data/
    ├── raw/
    │   └── bams/                ← User puts BAM files here
    └── reference/               ← User puts/downloads reference files here
        ├── ARS-UCD2.0_genomic.fa
        ├── bovine_hd_chip/
        ├── zebu_snpmap/
        └── vep_cache/
```

---

## Central Configuration: `config/pipeline.config`

### Structure

```bash
# SOURCE this in every script:
source "${PROJECT_ROOT}/config/pipeline.config"

# Access variables like:
echo $REFERENCE_GENOME       # Path to reference genome FASTA
echo $RAW_BAM_DIR            # Where to find input BAM files
echo $SV_SNIFFLES_DIR        # Where to save Sniffles2 output
echo $THREADS                # Number of CPUs to use
echo $SURVIVOR_DISTANCE      # Parameters for each step
```

### Variable Categories

| Category | Examples | Purpose |
|----------|----------|---------|
| **Directories** | `PROJECT_ROOT`, `DATA_DIR`, `RAW_BAM_DIR` | Path locations |
| **Reference Files** | `REFERENCE_GENOME`, `BOVINE_HD_BED`, `VEP_CACHE_DIR` | Data files |
| **Output Directories** | `SV_SNIFFLES_DIR`, `SV_SVIM_DIR`, `ANNOTATION_DIR` | Results |
| **Parameters** | `SNIFFLES_MIN_SV_LENGTH`, `SURVIVOR_DISTANCE`, `LD_R2_THRESHOLD` | Algorithm settings |
| **Compute** | `THREADS`, `MAX_PARALLEL_JOBS`, `MEMORY_PER_CPU` | Hardware settings |
| **Functions** | `init_directories()`, `check_references()`, `log_info()` | Utilities |

### Example Config Section

```bash
# From config/pipeline.config

# ============================================================================
# AUTOMATIC DIRECTORY DETECTION
# ============================================================================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================================================
# DATA DIRECTORIES
# ============================================================================
DATA_DIR="${PROJECT_ROOT}/data"
RAW_BAM_DIR="${DATA_DIR}/raw/bams"
REFERENCE_DIR="${DATA_DIR}/reference"

# ============================================================================
# REFERENCE FILES
# ============================================================================
REFERENCE_GENOME="${REFERENCE_DIR}/ARS-UCD2.0_genomic.fa"
REFERENCE_INDEX="${REFERENCE_GENOME}.fai"
BOVINE_HD_BED="${REFERENCE_DIR}/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
init_directories() {
    mkdir -p "$RAW_BAM_DIR"
    mkdir -p "$SV_SNIFFLES_DIR"
    mkdir -p "$SV_SVIM_DIR"
    # ... etc
}

check_references() {
    if [ ! -f "$REFERENCE_GENOME" ]; then
        log_error "Reference genome not found"
        return 1
    fi
    # ... validation logic
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
}
```

---

## Refactored Script Template

Use this template when refactoring remaining scripts:

```bash
#!/bin/bash

################################################################################
# COWADAPT - Step [N]: [Description]
#
# Purpose: What this script does
#
# Usage:
#   bash src/[N]_[name]/run_[step].sh                # Process all samples
#   bash src/[N]_[name]/run_[step].sh <sample.bam>   # Specific sample
#   THREADS=16 bash src/[N]_[name]/run_[step].sh     # Custom threading
#
# Output:
#   [output directory description]
#
# Requirements:
#   - Reference files (checked automatically)
#   - BAM files in: data/raw/bams/
#
################################################################################

set -euo pipefail

# ============================================================================
# SOURCE CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -f "$PROJECT_ROOT/config/pipeline.config" ]; then
    echo "[ERROR] Configuration file not found: $PROJECT_ROOT/config/pipeline.config"
    exit 1
fi

source "$PROJECT_ROOT/config/pipeline.config"

# ============================================================================
# VALIDATE PREREQUISITES
# ============================================================================

if ! command_exists [required_tool]; then
    log_error "[tool] not found in PATH"
    log_error "Install with: conda install -c bioconda [tool]"
    exit 1
fi

if ! check_references; then
    log_error "Required reference files are missing!"
    exit 1
fi

# ============================================================================
# INITIALIZE
# ============================================================================

init_directories
mkdir -p "$OUTPUT_DIRECTORY"
mkdir -p "${LOGS_DIR}/[step_name]"

# ============================================================================
# MAIN LOGIC
# ============================================================================

log_info "Starting [step name]..."

# Get input samples
readarray -t SAMPLE_LIST < <(find "$RAW_BAM_DIR" -maxdepth 1 -name "*.bam" -type f | sort)

if [ ${#SAMPLE_LIST[@]} -eq 0 ]; then
    log_error "No BAM files found in $RAW_BAM_DIR"
    exit 1
fi

# Process each sample
for bam_file in "${SAMPLE_LIST[@]}"; do
    sample_id=$(get_sample_id "$bam_file")
    log_info "Processing: $sample_id"
    
    # Your processing logic here
    # Use variables from config instead of hardcoded paths
    
    [command] \
        --input "$bam_file" \
        --output "$OUTPUT_DIRECTORY/${sample_id}.out" \
        --reference "$REFERENCE_GENOME" \
        --threads "$THREADS"
done

# ============================================================================
# COMPLETION
# ============================================================================

log_info "Step complete!"
log_info "Output: $OUTPUT_DIRECTORY"

```

---

## Refactoring Checklist

When refactoring each script:

- [ ] Add header with purpose, usage, output description
- [ ] Source `config/pipeline.config` at top
- [ ] Check for required tools with `command_exists`
- [ ] Call `check_references` to validate data files
- [ ] Call `init_directories` to create output dirs
- [ ] Replace all hardcoded paths with config variables
- [ ] Use `log_info`, `log_warn`, `log_error` for messages
- [ ] Handle both local execution and SLURM array jobs (if applicable)
- [ ] Verify all output files are created
- [ ] Test with real or sample data
- [ ] Document any new variables needed in `pipeline.config`

---

## Scripts to Refactor (Priority Order)

### CRITICAL (2-3 hours) - Already Done
- [x] `src/01_sv_calling/run_sniffles2_calling.sh` 
- [x] `src/01_sv_calling/run_svim_calling.sh`

### HIGH (4-5 hours)
- [ ] `src/02_sv_merge/run_survivor_merge.sh`
  - Uses SURVIVOR to merge VCFs from both callers
  - Creates output: `results/sv_merge/`
  
- [ ] `src/03_sv_validation/run_sv_validation.sh`
  - Validates SV predictions with read-based support
  - Creates output: `results/validation/`
  
- [ ] `src/04_functional_annotation/run_vep_annotation.sh`
  - Annotates SVs with VEP
  - Creates output: `results/annotation/`

### MEDIUM (2-3 hours)
- [ ] `src/05_snp_extraction/extract_bovhd_snps.sh`
  - Extracts BovineHD SNP positions
  
- [ ] `src/05_snp_extraction/filter_snp_quality.sh`
  - Filters SNPs by quality metrics
  
- [ ] `src/06_ld_analysis/combine_sv_snp_vcf.sh`
  - Combines SVs and SNPs for LD analysis

### OPTIONAL (1 hour)
- [ ] `src/02_sv_merge/inspect_survivor_output.sh` (post-processing)
- [ ] `src/07_zebu_specificity/rename_chromosomes.sh` (helper)

---

## Setup and Usage for End Users

### First Time Setup

```bash
# 1. Clone repository
git clone https://github.com/thalesbioinfo/cowadapt-svs.git
cd cowadapt-svs

# 2. Install dependencies
bash install.sh
conda activate cowadapt

# 3. Download reference data
bash src/utils/setup_reference_data.sh

# 4. Initialize pipeline
bash src/utils/init_pipeline.sh

# 5. Copy your BAM files
cp /path/to/your/*.bam data/raw/bams/
cp /path/to/your/*.bam.bai data/raw/bams/
```

### Running Pipeline

```bash
# Run SV calling on all BAMs
bash src/01_sv_calling/run_sniffles2_calling.sh
bash src/01_sv_calling/run_svim_calling.sh

# Continue with other steps
bash src/02_sv_merge/run_survivor_merge.sh
bash src/03_sv_validation/run_sv_validation.sh
# ... etc

# Or use Nextflow (when available)
nextflow run pipeline.nf -profile local
```

### Customizing Parameters

Edit `config/pipeline.config`:

```bash
# Change number of threads
THREADS=16

# Change SV size threshold
SNIFFLES_MIN_SV_LENGTH=100

# Change LD analysis threshold
LD_R2_THRESHOLD=0.5
```

---

## Benefits of This Approach

✅ **Portability** — Works on laptops, clusters, cloud  
✅ **Maintainability** — All paths defined once  
✅ **Error Detection** — Validates files exist before running  
✅ **Reproducibility** — Config file documents setup  
✅ **HPC Support** — SLURM, SGE, or local with same scripts  
✅ **Self-Documenting** — Clear variable names explain structure  
✅ **User-Friendly** — Users only modify one config file  

---

## Testing the Refactoring

### Verify Configuration Works

```bash
# Source the config file
source config/pipeline.config

# Check variables are set
echo "Project Root: $PROJECT_ROOT"
echo "Reference: $REFERENCE_GENOME"
echo "Threads: $THREADS"

# Run initialization
bash src/utils/init_pipeline.sh
```

### Test a Refactored Script

```bash
# With test data
bash src/01_sv_calling/run_sniffles2_calling.sh data/test/sample.bam

# Or all samples
bash src/01_sv_calling/run_sniffles2_calling.sh
```

---

## Migration Path for Existing Users

If you have scripts running with the old hardcoded version:

1. **Backup your original setup:**
   ```bash
   mkdir OLD_SETUP
   cp -r src OLD_SETUP/
   ```

2. **Update to new version:**
   ```bash
   git pull origin main
   ```

3. **Update your local paths:**
   Edit `config/pipeline.config`:
   ```bash
   # Change these to your actual directories
   RAW_BAM_DIR="/path/to/your/bams"
   REFERENCE_GENOME="/path/to/your/reference.fa"
   # etc
   ```

4. **Test with one sample:**
   ```bash
   bash src/01_sv_calling/run_sniffles2_calling.sh /path/to/test.bam
   ```

---

## Troubleshooting Refactored Scripts

### "Configuration file not found"
```bash
# Make sure you're in the project root directory
cd /path/to/cowadapt-svs
bash src/01_sv_calling/run_sniffles2_calling.sh
```

### "Reference genome not found"
```bash
# Run initialization to check status
bash src/utils/init_pipeline.sh

# Download missing reference files
bash src/utils/download_reference_genome.sh
```

### "No BAM files found"
```bash
# Copy your BAM files to the correct location
cp *.bam data/raw/bams/
cp *.bam.bai data/raw/bams/

# Verify they're there
ls -lh data/raw/bams/
```

---

## Questions & Feedback

- 📖 See `docs/USAGE.md` for detailed examples
- 🔧 See `docs/TROUBLESHOOTING.md` for common issues
- 💬 Contact: medvet21@gmail.com
- 🐛 Report issues on GitHub

