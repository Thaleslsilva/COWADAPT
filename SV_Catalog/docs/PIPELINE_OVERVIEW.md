# COWADAPT Pipeline - Technical Overview

Comprehensive technical documentation of the COWADAPT structural variant detection and characterization pipeline.

**Project:** COWADAPT — Structural Variants in Zebu Cattle  
**Reference Genome:** ARS-UCD2.0 (Bos taurus)  
**Data Type:** Long-read sequencing (PacBio CLR)  
**Sample Size:** 20 Nelore cattle  

---

## Pipeline Architecture

### Data Flow

```
Long-read BAM files (20 samples × ~50-100 GB each)
    ↓
    ├─[01] SV Calling (Sniffles2 + SVIM in parallel)
    │       Output: 2 × 20 VCF files
    │
    ├─[02] SV Merge & Concordance (SURVIVOR)
    │       Input: Paired VCFs (Sniffles2 + SVIM)
    │       Filter: r² = 1000 bp, min_callers = 2
    │       Output: 20 VCF files (concordant SVs only)
    │
    ├─[03] SV Validation (SVvalidation.py)
    │       Input: Concordant SVs
    │       Verify: Read spanning, split-reads in original BAM
    │       Output: Confidence-scored SV catalog
    │
    ├─[04] Functional Annotation (VEP)
    │       Input: Validated SVs
    │       Tools: Ensembl VEP (offline cache)
    │       Output: Gene mapping, impact prediction (HIGH/MODERATE/LOW)
    │
    ├─[05] SNP Extraction (BovineHD chip)
    │       Input: WGS SNP VCF + BovineHD positions (ARS-UCD2.0)
    │       Filter: Biallelic, AC>0, DP/GQ thresholds
    │       Output: SNP VCF at chip positions
    │
    ├─[06] LD Analysis & Tag SNP Identification
    │       Input: Validated SVs (biallelic format) + SNPs
    │       Merge: Single VCF with SV + SNP genotypes
    │       LD: plink2 --r2 (500 kb window)
    │       Identify: Best tag SNP per SV (r² ≥ 0.3)
    │       Output: Tag SNP catalog
    │
    └─[07] Zebu-Specificity Annotation
            Input: SVs + SNPmap (Indicine/Taurine probabilities)
            Filter: Flanking window 1 kb, Pr_Indicine > 0.95
            Output: Final SV catalog with ancestry classification
                    ├─ SV ID, position, type, size
                    ├─ Gene(s), functional impact
                    ├─ Tag SNP, r²
                    └─ Zebu-specificity classification
```

---

## Detailed Step Descriptions

### [01] SV Calling

**Purpose:** Detect structural variants from long-read BAM alignments

**Input Files:**
- BAM files (PacBio CLR, long reads)
- Reference genome FASTA (ARS-UCD2.0)

**Tools & Parameters:**
```bash
# Sniffles2
sniffles2 --input sample.bam \
  --vcf output.vcf \
  --min-sv-length 50 \
  --max-sv-length 1000000 \
  --min-support 2 \
  --threads 8

# SVIM (similar)
svim alignment output.dir sample.bam reference.fa \
  --min-sv-length 50 \
  --min-support 2
```

**Output:**
- `results/sv_calls/sniffles_output/*.vcf` — Per-sample Sniffles2 VCF
- `results/sv_calls/svim_output/*.vcf` — Per-sample SVIM VCF

**Performance:**
- Runtime: ~6-24 hours per sample (depends on coverage, compute)
- Output size: ~50-200 MB per sample per caller
- Expected SVs: 3,000-8,000 per sample

**SV Types Detected:**
- DEL (deletions)
- INS (insertions)
- DUP (duplications)
- INV (inversions)
- BND (breakends)
- TRA (translocations)

---

### [02] SV Merge & Concordance

**Purpose:** Merge calls from 2 independent callers; retain only high-confidence SVs detected by both

**Input Files:**
- `results/sv_calls/sniffles_output/sample.vcf`
- `results/sv_calls/svim_output/sample.vcf`

**Tool: SURVIVOR**
```bash
# Create list
echo "sniffles.vcf" > list.txt
echo "svim.vcf" >> list.txt

# Merge
SURVIVOR merge list.txt \
  1000 \          # Distance threshold (bp)
  2 \             # Min. num callers (require both)
  1 \             # Minimum SV length (type-specific)
  1 \             # Allow strand differences
  0 \             # Allow translocations within same chromosome
  50 \            # Minimum SV length for output
  sample_merged.vcf
```

**Output:**
- `results/sv_calls/merged_vcfs/*.vcf` — Merged, concordant SVs only

**Filtering Rationale:**
- **Distance: 1000 bp** — Allows ~10% tolerance for flanking sequence variation
- **Min. callers: 2** — Eliminates false positives from single-caller artifacts
- **SV length: 50 bp** — Minimum reliable detection size

**Statistics Example:**
```
Sniffles2 per sample:   5,200 SVs
SVIM per sample:        4,800 SVs
Concordant (merged):    ~2,500 SVs (48%)
```

---

### [03] SV Validation

**Purpose:** Confirm SV calls exist in original BAM reads (reduce false positives further)

**Tool: SVvalidation.py**

```bash
# Setup (first time)
git clone https://github.com/nwpuzhengyan/SVvalidation.git
cd SVvalidation
pip install pysam numpy

# Run validation
python3 SVvalidation.py \
  --input sample_merged.vcf \
  --bam sample.bam \
  --output sample_validated.vcf
```

**What It Does:**
1. Extracts reads mapping ± 500 bp from SV breakpoints
2. Checks for:
   - Spanning reads (read covers both breakpoints)
   - Split-reads (read spans breakpoint with soft clipping)
   - Discordant pairs (read pair shows characteristic distance/orientation)
3. Assigns confidence score to each SV

**Output:**
- `results/validation/validated_svs/svs_final_validadas.vcf`

**Expected Reduction:**
- Input: ~2,500 concordant SVs
- Output: ~1,500-2,000 validated SVs (60-80% pass)

---

### [04] Functional Annotation (VEP)

**Purpose:** Predict functional impact; map SVs to genes

**Tool: Ensembl VEP (Variant Effect Predictor)**

```bash
# Download cache (first time, ~15 GB)
vep_install --CACHEDIR vep_cache/ \
  --SPECIES bos_taurus \
  --ASSEMBLY ARS-UCD2.0 \
  --AUTO cf

# Run annotation
vep --input_file svs_validated.vcf \
  --output_file vep_output.vcf \
  --cache \
  --dir_cache vep_cache/ \
  --species bos_taurus \
  --assembly ARS-UCD2.0 \
  --everything \
  --pick \
  --distance 1000 \
  --fork 8
```

**VEP Output Annotations:**
- **Consequence:** Frameshift, stop_lost, missense, synonymous, intergenic, etc.
- **Impact:** HIGH / MODERATE / LOW / MODIFIER
- **Gene:** Ensembl gene ID, symbol
- **Transcript:** Affected transcript
- **sift:** Deleterious/Tolerated
- **PolyPhen:** Probably damaging/Benign

**Output:**
- `results/annotation/vep_output/svs_anotadas.vcf` (VCF with CSQ field)
- Custom TSV extracted: `sv_annotations.tsv`

**Example Annotation:**
```
SV_ID: sv_00123_DEL
Gene: BRCA1
Impact: HIGH (frameshift)
Consequence: frameshift_variant
Tissue: Mammary (if available)
```

---

### [05] SNP Extraction (BovineHD)

**Purpose:** Extract SNPs from WGS data at BovineHD chip loci for subsequent LD analysis

**Input Files:**
- WGS SNP VCF (all autosomal SNPs)
- BovineHD chip BED file (positions in ARS-UCD2.0 coordinates)

**Process:**

```bash
# Step 1: Map BovineHD positions to ARS-UCD2.0
# (assumes chip designed for older assembly)
# Using liftOver or direct extraction

# Step 2: Extract SNPs at chip positions
bcftools view \
  --regions-file bovhd_positions.txt \
  --types snps \
  --include 'AC>0' \
  -m2 -M2 \
  -Oz -o snps_bovineHD_wgs.vcf.gz \
  wgs_snps.vcf.gz

# Step 3: Quality filters
bcftools view \
  --include 'DP>=5 & DP<=100 & GQ>=20' \
  snps_bovineHD_wgs.vcf.gz | \
  bgzip -c > snps_bovineHD_qc.vcf.gz
```

**Output:**
- `results/annotation/snp_vcfs/snps_bovineHD_wgs.vcf.gz` (genotyped SNPs at chip positions)

**Expected Numbers:**
- BovineHD chip loci: ~75,000 SNPs
- Recovered in WGS: ~60,000-70,000 (80-95%)
- After QC: ~55,000-65,000

---

### [06] LD Analysis & Tag SNP Identification

**Purpose:** Identify best SNP on BovineHD chip as proxy for each SV (enables routine screening)

**Step 6a: Convert SV Genotypes to Biallelic Format**

```bash
# SVs are multi-allelic (DEL, INS, DUP, INV)
# plink2 requires biallelic format
# Conversion: Ref allele = no SV, Alt allele = SV present

python3 convert_sv_to_biallelic.py \
  --input svs_validated.vcf \
  --output svs_biallelic.vcf
```

**Step 6b: Merge SV + SNP VCFs**

```bash
# Create single VCF with both SVs and SNPs
bcftools concat \
  -a \
  svs_biallelic.vcf \
  snps_bovineHD_wgs.vcf.gz | \
  bgzip -c > merged_svs_snps.vcf.gz
```

**Step 6c: LD Calculation (plink2)**

```bash
# Calculate r² between all pairs
plink2 \
  --vcf merged_svs_snps.vcf.gz \
  --r2 \
  --ld-window-kb 500 \
  --ld-r2 0.1 \
  --out ld_svs_snps

# Output: ld_svs_snps.vcor
# Columns: CHROM_A POS_A ID_A CHROM_B POS_B ID_B UNPHASED_R2
```

**Step 6d: Identify Best Tag SNP**

```python
# For each SV, find SNP with highest r² (≥ 0.3)
# Rationale: r² ≥ 0.3 allows 70% statistical power to detect SV

import pandas as pd

ld = pd.read_csv('ld_svs_snps.vcor', sep='\t')

# Separate SV-SNP pairs
sv_snp_pairs = ld[
    (ld['ID_A'].str.contains('_DEL|_INS|_DUP|_INV')) & 
    (~ld['ID_B'].str.contains('_DEL|_INS|_DUP|_INV'))
]

# For each SV, retain highest r² SNP
tag_snps = sv_snp_pairs.loc[
    sv_snp_pairs.groupby('ID_A')['R2'].idxmax()
]
```

**Output:**
- `results/analysis/tag_snps/tag_snps_per_sv.tsv`
- Columns: SV_ID | TAG_SNP | R2 | GENE | IMPACT

**Expected Coverage:**
- Input SVs: ~1,800
- With tag SNP (r² ≥ 0.3): ~1,200-1,400 (67-78%)
- Enables routine BovineHD genotyping → SV detection

---

### [07] Zebu-Specificity Annotation

**Purpose:** Classify SVs as Indicine- or Taurine-specific; understand evolutionary origin

**Reference Data: SNPmap (Kasarapu et al. 2017)**
- 50,000+ SNPs with Indicine/Taurine posterior probabilities
- Remapped to ARS-UCD2.0 coordinates

**Process:**

```python
# 1. For each SV, find overlapping SNPs (±1 kb flanking)
# 2. Calculate mean Pr_Indicina for SNPs in region
# 3. Classify:
#    - Pr_Indicina > 0.95  → Indicine-specific
#    - Pr_Indicina < 0.05  → Taurine-specific
#    - 0.05 ≤ Pr ≤ 0.95   → Admixed/Shared

python3 annotate_zebu_specificity.py \
  --vcf svs_biallelic.vcf \
  --snpmap SNPmap_IND_TAU_ARS.txt \
  --flank 1000 \
  --threshold 0.95 \
  --output sv_zebu_specificity.txt
```

**Output Files:**
- `sv_zebu_specificity.txt` — Summary (one SV per line)
  ```
  SV_ID  TAG_SNP  R2   GENE    IMPACT  Pr_Indicina  N_zebu_SNPs  N_taurine_SNPs  Classification
  sv_001 rs12345  0.92 ABCD1   HIGH    0.98         8            1               Indicine-specific
  sv_002 rs54321  0.51 INTERG  LOW     0.22         2            6               Taurine-specific
  ```

- `sv_zebu_hits.txt` — Long format (one SV × SNP hit per line)
  ```
  SV_ID  SNP_ID   Pr_Indicina  Gene_region
  sv_001 snp_001  0.96         EXON
  sv_001 snp_002  0.99         EXON
  ```

- `ideogram_zebu_svs.pdf` — Visualization showing SV positions + classification

**Interpretation:**
- **Indicine-specific:** Likely adaptive variant in Zebu
- **Taurine-specific:** Derived from European ancestry
- **Admixed:** Shared; minimal selective pressure signal

---

## Summary Statistics

### Expected Output Numbers

| Stage | Input | Output | % Retained |
|-------|-------|--------|-----------|
| SV Calling | 20 samples | ~5,200 SVs/sample | 100% |
| Concordance | ~104,000 total | ~50,000 | 48% |
| Validation | ~50,000 | ~30,000-40,000 | 60-80% |
| Annotation | ~35,000 | ~35,000 (all) | 100% |
| Tag SNP ID | ~1,800 | ~1,200 | 67% |
| Zebu-specific | ~1,200 | ~400 Indicine / ~600 Taurine | ~80% |

### Computational Requirements

| Step | Time | RAM | Cores | Storage |
|------|------|-----|-------|---------|
| SV Calling | 6-24 h/sample | 8-16 GB | 8 | 50-100 GB/sample |
| Merge | 1-2 h | 4 GB | 4 | 100 MB |
| Validation | 4-8 h | 8 GB | 4 | 1-10 GB |
| VEP Annotation | 8-16 h | 16 GB | 8 | 5-20 GB |
| SNP Extraction | 1-2 h | 4 GB | 4 | 5-10 GB |
| LD Analysis | 4-8 h | 16 GB | 8 | 10-20 GB |
| Zebu-specificity | 1-2 h | 8 GB | 4 | 100 MB |
| **TOTAL** | ~3-4 weeks | 64 GB | 8+ cores | ~500 GB-1 TB |

---

## Key Design Decisions

1. **Dual-caller strategy** (Sniffles2 + SVIM)
   - Reduces false positive rate
   - Captures orthogonal error modes

2. **1000 bp merge threshold**
   - Tolerates short flanking sequence variations
   - Standard in large genomic studies

3. **Read-based validation**
   - Confirms SV structure in original BAM
   - Required for confidence

4. **VEP annotation distance = 1 kb**
   - Balances regulatory region detection vs. false assignments

5. **Tag SNP r² ≥ 0.3**
   - Maintains ~70% statistical power
   - Practical limit for LD block identification

6. **Zebu-specificity threshold Pr > 0.95**
   - Conservative; reduces false positive ancestry calls
   - Kasarapu et al. (2017) used this threshold

---

## Software Versions

- **Sniffles2:** v2.0.7
- **SVIM:** v1.4.2
- **SURVIVOR:** v1.0.7
- **samtools:** v1.15.1
- **bcftools:** v1.15.1
- **VEP:** v109 (Ensembl)
- **plink2:** v2.0 (alpha)
- **Python:** v3.8+
- **pysam:** v0.18.0
- **pandas:** v1.3.0+

---

## References

1. Sniffles2 documentation: https://github.com/fritzsedlazeck/Sniffles
2. SVIM documentation: https://github.com/eldariont/svim
3. SURVIVOR: https://github.com/fritzsedlazeck/SURVIVOR
4. VEP: https://www.ensembl.org/vep
5. plink2: https://www.cog-genomics.org/plink/2.0/
6. Kasarapu et al. (2017): https://doi.org/10.1038/ncomms14482
7. Grant et al. (2024): BovineHD recalibration study (CITE YOUR PAPER)

