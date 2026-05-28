# Results Directory

This directory stores pipeline outputs: summary statistics, final catalogs, and publication-quality figures.

**Large intermediate files are not stored here.** Only final results, summary tables, and figures suitable for version control are kept.

---

## Directory Structure

```
results/
├── README.md                        # This file
├── sv_calling/                      # Per-sample SV VCF files (Step 01)
├── sv_merge/                        # SURVIVOR-merged concordant SVs (Step 02)
├── sv_validation/                   # Validated high-confidence SVs (Step 03)
├── functional/                      # VEP annotations and consequence tables (Step 04)
├── snp_extraction/                  # BovineHD chip SNP VCFs (Step 05)
├── ld_analysis/                     # LD tables and tag SNP assignments (Step 06)
├── zebu/                            # Zebu-specificity classifications (Step 07)
├── catalog/                         # Final integrated SV catalog
│   └── final_nelore_sv_catalog.tsv  # Main output: annotated SV catalog
└── figures/                         # Publication-quality figures
    └── ideogram/                    # Chromosomal ideogram plots (PDF + PNG)
```

---

## Final Catalog Format

The main output (`catalog/final_nelore_sv_catalog.tsv`) has the following columns:

| Column | Type | Description |
|---|---|---|
| CHROM | string | Chromosome (ARS-UCD2.0 coordinates) |
| POS | integer | SV start position |
| SVTYPE | string | SV type: DEL, INS, DUP, INV, BND |
| SVLEN | integer | SV length in base pairs |
| SUPP | integer | Number of supporting callers (1 or 2) |
| Consequence | string | VEP consequence (e.g., intron_variant) |
| SYMBOL | string | Gene symbol |
| IMPACT | string | VEP impact: HIGH, MODERATE, LOW, MODIFIER |
| TAG_SNP | string | Best tag SNP ID on BovineHD chip |
| TAG_R2 | float | LD r-squared between SV and tag SNP |
| ZEBU_CLASS | string | Zebu-specificity classification |
| INDICINE_PROB | float | Mean Pr(Indicina) for overlapping SNPs |
| N_ZEBU_SNPS | integer | Number of Kasarapu SNPs within 1000 bp |

---

## Expected Pipeline Outputs

| Step | Output | Expected Count |
|---|---|---|
| 01 SV calling | VCFs per sample | ~5,000-5,200 SVs/sample (Sniffles2) |
| 02 SV merge | Concordant VCF | ~2,500 SVs/sample (48% retention) |
| 03 Validation | Validated VCF | ~1,500-2,000 SVs/sample (60-80% pass) |
| 04 Annotation | TSV annotations | All validated SVs annotated |
| 05 SNP extraction | Chip SNP VCF | All BovineHD positions |
| 06 LD analysis | Tag SNP TSV | 67-78% of SVs with tag SNP |
| 07 Zebu specificity | Classification TSV | All catalog SVs classified |
| Final catalog | TSV | All annotated SVs with tags and zebu class |
