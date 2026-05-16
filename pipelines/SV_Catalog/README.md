# SV_Catalog: Structural Variant Detection and Analysis Pipeline

## Overview

SV_Catalog is a comprehensive bioinformatics pipeline for detecting, validating, annotating, and analyzing structural variants (SVs) in long-read sequencing data, developed for the COWADAPT project (Cattle Genomic Adaptation to Environmental Stress).

This pipeline processes long-read BAM files (PacBio or Oxford Nanopore) to identify structural variants in cattle genomes and perform downstream analysis including functional annotation, SNP extraction, linkage disequilibrium analysis, and breed-specificity assessment.

## Quick Start

### Requirements
- samtools >= 1.15
- bcftools >= 1.15
- Sniffles2
- SVIM
- SURVIVOR
- Ensembl VEP
- plink2
- Python 3.8+ (pysam, numpy)

### Basic Usage

1. Initialize pipeline environment:
   bash src/utils/init_pipeline.sh

2. Download reference data:
   bash src/utils/setup_reference_data.sh

3. Add your BAM files to: data/raw_bam/

4. Create sample manifest: config/sample_manifest.txt

5. Run SV calling:
   bash src/01_sv_calling/run_sniffles2_calling.sh
   bash src/01_sv_calling/run_svim_calling.sh

6. Follow subsequent steps (2-7) as documented in docs/USAGE.md

## Pipeline Workflow

| Step | Module | Input | Output |
|------|--------|-------|--------|
| 1 | SV Calling | BAM files | VCF (Sniffles2 + SVIM) |
| 2 | SV Merging | VCF files | Merged VCF (SURVIVOR) |
| 3 | Validation | Merged VCF | Validated VCF + QC metrics |
| 4 | Annotation | Validated VCF | Annotated VCF (VEP) |
| 5 | SNP Extraction | Annotated VCF | SNP subset (BovineHD) |
| 6 | LD Analysis | SVs + SNPs | LD statistics, tag SNPs |
| 7 | Zebu Specificity | LD results | Breed-specific variants |

## Configuration

All pipeline parameters are centralized in: config/pipeline.config

Key settings:
- THREADS: CPU threads for parallel processing
- SNIFFLES_MIN_SV_LENGTH: Minimum SV length (default: 50 bp)
- SURVIVOR_DISTANCE: SV merging distance (default: 1000 bp)
- LD_R2_THRESHOLD: Linkage disequilibrium threshold (default: 0.8)
- Reference genome: Bos taurus ARS-UCD2.0

## Output Structure

results/
|-- sv_calls/              # Step 1: Raw SV calls
|-- sv_merge/              # Step 2: Merged SVs
|-- validation/            # Step 3: Validated SVs
|-- annotation/            # Step 4: Annotated SVs
|-- snp_extraction/        # Step 5: SNP subsets
|-- ld_analysis/           # Step 6: LD analysis
|-- zebu_specificity/      # Step 7: Breed analysis
L-- logs/                  # Pipeline logs

## Documentation

- docs/USAGE.md - Complete usage guide
- docs/PIPELINE_OVERVIEW.md - Technical pipeline details
- docs/DATA_SOURCES.md - Reference data sources
- docs/COWADAPT_PROJECT.md - Project context

## Reference Data

Required:
- Bos taurus ARS-UCD2.0 reference genome (auto-download available)
- Reference index (.fai)

Optional:
- BovineHD SNP chip positions (for Step 5)
- Zebu SNPmap (for Step 7)
- VEP annotation cache (for functional annotation)

Download with: bash src/utils/setup_reference_data.sh

## Example Dataset

The pipeline is designed to work with:
- Long-read BAM files (PacBio SMRT or Oxford Nanopore)
- Minimum coverage: 15x recommended
- Paired reads from 2 or more SV callers for robust variant calls

## License

This pipeline is part of the COWADAPT project.

## Citation

If you use this pipeline, please cite the COWADAPT project accordingly.

## Support

For issues, questions, or contributions, please refer to the main COWADAPT repository: https://github.com/Thaleslsilva/COWADAPT

---

NOTE: This component of the COWADAPT repository is currently under active development. See UNDER_CONSTRUCTION.md for current status.
