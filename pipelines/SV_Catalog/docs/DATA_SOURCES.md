# Reference Data Sources & Download Guide

Complete guide to obtaining and setting up all reference data required for the COWADAPT pipeline.

---

## Overview

The COWADAPT pipeline requires 4 main reference files:

| File | Size | Source | Notes |
|------|------|--------|-------|
| **ARS-UCD2.0 Genome** | 3.1 GB | NCBI | Must download |
| **ARS-UCD2.0 Index (.fai)** | 30 KB | Generated locally | Created automatically |
| **BovineHD Chip Positions** | ~500 KB | Illumina/Papers | Must obtain |
| **Zebu SNPmap** | ~10 MB | Kasarapu et al. 2017 | Must obtain |
| **VEP Cache** | 15 GB | Ensembl | Downloaded automatically |

---

## 1. ARS-UCD2.0 Reference Genome

### ✅ CORRECT SOURCE (NCBI GenBank)

**Download URL:**  
https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_002263795.3/

**File Details:**
- **Accession:** GCF_002263795.3
- **Species:** Bos taurus (cattle)
- **Assembly:** ARS-UCD2.0
- **Size:** ~3.1 GB (uncompressed FASTA)
- **License:** Public domain (NCBI)

### Quick Download (Option A: Interactive)

1. Go to: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_002263795.3/
2. Click "Download" button
3. Select:
   - ✅ Genome sequences (FASTA)
   - ❌ Uncheck "Proteins" and other unnecessary files
4. Click "Download"
5. Extract the .zip file

### Automated Download (Option B: Script)

**NEW FILE: `src/utils/download_reference_genome.sh`**

```bash
#!/bin/bash

# Download ARS-UCD2.0 Reference Genome
# Usage: bash download_reference_genome.sh [output_dir]

set -euo pipefail

OUTPUT_DIR="${1:-data/reference}"
mkdir -p "$OUTPUT_DIR"

echo "Downloading ARS-UCD2.0 reference genome from NCBI..."
echo "Archive: GCF_002263795.3"
echo "Output: $OUTPUT_DIR"

cd "$OUTPUT_DIR"

# Download from NCBI Datasets
# Note: NCBI Datasets API endpoint
wget -c "https://www.ncbi.nlm.nih.gov/datasets/api/v1/genome/accession/GCF_002263795.3/download?include_annotation_type=FASTA" \
  -O "GCF_002263795.3.zip" \
  --header="Accept: application/zip" \
  2>&1 | tee download.log

# Alternative: Direct FTP (if available)
# wget -c "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.3_ARS-UCD2.0/..." \
#   -O "ARS-UCD2.0.fasta.gz"

echo "Extracting..."
unzip -j "GCF_002263795.3.zip" "*.fna" -d .
mv *.fna "ARS-UCD2.0_genomic.fa" 2>/dev/null || true

# Verify
if [ -f "ARS-UCD2.0_genomic.fa" ]; then
  echo "✓ Download successful!"
  ls -lh "ARS-UCD2.0_genomic.fa"
else
  echo "✗ Download failed!"
  exit 1
fi

echo ""
echo "Next step: Create index file (automatically done by pipeline)"
echo "Or manually: samtools faidx ARS-UCD2.0_genomic.fa"
```

### Create Index File (.fai) - LOCALLY GENERATED

**The .fai index file is NOT downloaded. It's generated locally from the FASTA file.**

**Automatic (pipeline handles this):**
```bash
# The pipeline creates this automatically if missing
samtools faidx data/reference/ARS-UCD2.0_genomic.fa
# → Creates: data/reference/ARS-UCD2.0_genomic.fa.fai
```

**Manual (if you want to do it yourself):**
```bash
cd data/reference
samtools faidx ARS-UCD2.0_genomic.fa
```

**Why generate locally?**
- Index is specific to your FASTA file
- Very small (~30 KB)
- Takes <1 minute to generate
- Avoids version mismatches

---

## 2. BovineHD Chip Positions

### Source Information

**Illumina SNP Chip:** BovineHD BeadChip  
**Number of SNPs:** ~75,000  
**Coordinates:** Must be in ARS-UCD2.0 assembly

### Where to Get It

#### Option A: Published Papers
Papers about BovineHD chip often include coordinate files:
- Search: "BovineHD" + "ARS-UCD2.0" in Google Scholar
- Download supplementary materials
- Extract BED file with positions

#### Option B: Directly from Illumina (requires registration)
- Illumina SNP Database: https://support.illumina.com/
- Login required
- Search for "BovineHD" 
- Download manifest or BED file

#### Option C: From your institution
- If your lab has previously mapped SNPs
- Check shared databases
- Ask your bioinformatician

### Coordinate Conversion (if needed)

If you have BovineHD positions in **UCD1.2** coordinates:

**Use liftOver to convert to ARS-UCD2.0:**

```bash
# Download liftOver tool (UCSC)
wget https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
chmod +x liftOver

# Download chain file for coordinate conversion
wget https://hgdownload.cse.ucsc.edu/goldenPath/bosTau6/liftOver/bosTau6ToARS-UCD2.0.over.chain.gz
gunzip bosTau6ToARS-UCD2.0.over.chain.gz

# Convert coordinates
./liftOver bovineHD_UCD1.2.bed bosTau6ToARS-UCD2.0.over.chain \
  bovineHD_ARS-UCD2.0.bed \
  unmapped_snps.bed

# Result: bovineHD_ARS-UCD2.0.bed
```

### File Format (BED)

The file should be tab-separated with format:
```
chromosome	start	end	snp_id	score	strand
1	1000	1001	rs123456	0	+
1	2000	2001	rs234567	0	+
2	3000	3001	rs345678	0	+
```

**Save as:** `data/reference/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed`

---

## 3. Zebu-Specificity SNPmap (Kasarapu et al. 2017)

### Source

**Citation:** Kasarapu et al. (2017)  
**Title:** "Selection for different body types in the same breed reveals the genomic basis of bovine body composition"  
**DOI:** https://doi.org/10.1038/ncomms14482  
**Journal:** Nature Communications  

### How to Obtain

1. **From Journal Website:**
   - Go to: https://www.nature.com/articles/ncomms14482
   - Scroll to: "Supplementary Information"
   - Download: "Supplementary Data 1"
   - File: Contains Indicine/Taurine SNP map

2. **From Authors:**
   - Contact corresponding author
   - Request: "SNPmap_IND_TAU_ARS.txt" or similar
   - May already be in ARS-UCD2.0 coordinates

3. **From Research Archive:**
   - Check ResearchGate, figshare, or Zenodo
   - Search: "Kasarapu 2017 SNPmap"
   - Download supplementary files

### File Format

Expected format (TSV):
```
Chromosome	Position	SNP_ID	Gene	Pr_Indicina	Pr_Taurine
1	1000000	snp_001	GENE_A	0.95	0.05
1	2000000	snp_002	INTERGENIC	0.15	0.85
2	3000000	snp_003	GENE_B	0.75	0.25
```

**Coordinates:** 
- If in UCD1.2: Use liftOver to convert to ARS-UCD2.0
- If already ARS-UCD2.0: Use as-is

**Save as:** `data/reference/zebu_snpmap/SNPmap_IND_TAU_ARS.txt`

---

## 4. VEP Annotation Cache (Automatic Download)

**NO manual download needed!** The pipeline downloads automatically.

### What Happens Automatically

When you run `src/04_functional_annotation/install_and_run_vep.sh`:

```bash
# This command automatically:
# 1. Downloads Ensembl VEP release 115 cache
# 2. Uncompresses to: data/reference/vep_cache/
# 3. Extracts: bos_taurus/115_ARS-UCD2.0/

vep_install \
  --AUTO cf \
  --SPECIES bos_taurus \
  --ASSEMBLY ARS-UCD2.0 \
  --CACHEDIR data/reference/vep_cache/ \
  --NO_HTSLIB 0
```

**Size:** ~15 GB (will take 30-60 minutes to download)

**Internet:** Requires good connection (will resume if interrupted)

---

## Complete Download Setup Script

**NEW FILE: `src/utils/setup_reference_data.sh`**

```bash
#!/bin/bash

# Setup all reference data for COWADAPT
# Usage: bash setup_reference_data.sh

set -euo pipefail

REF_DIR="data/reference"
mkdir -p "$REF_DIR"

echo "========================================="
echo "COWADAPT Reference Data Setup"
echo "========================================="
echo ""

# 1. ARS-UCD2.0 Genome
echo "Step 1: ARS-UCD2.0 Reference Genome"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ! -f "$REF_DIR/ARS-UCD2.0_genomic.fa" ]; then
  echo "Downloading ARS-UCD2.0 from NCBI (GCF_002263795.3)..."
  bash src/utils/download_reference_genome.sh "$REF_DIR"
else
  echo "✓ ARS-UCD2.0 already present"
fi

# Create index if missing
if [ ! -f "$REF_DIR/ARS-UCD2.0_genomic.fa.fai" ]; then
  echo "Creating index (.fai)..."
  samtools faidx "$REF_DIR/ARS-UCD2.0_genomic.fa"
  echo "✓ Index created"
fi
echo ""

# 2. BovineHD Chip
echo "Step 2: BovineHD Chip Positions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p "$REF_DIR/bovine_hd_chip"
if [ ! -f "$REF_DIR/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed" ]; then
  echo "⚠️  BovineHD chip file not found!"
  echo "Please obtain: bovineHD_ARS-UCD2.0.bed"
  echo "See: docs/DATA_SOURCES.md for download instructions"
  echo "Save to: $REF_DIR/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed"
else
  echo "✓ BovineHD chip present"
fi
echo ""

# 3. Zebu SNPmap
echo "Step 3: Zebu-Specificity SNPmap"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p "$REF_DIR/zebu_snpmap"
if [ ! -f "$REF_DIR/zebu_snpmap/SNPmap_IND_TAU_ARS.txt" ]; then
  echo "⚠️  SNPmap file not found!"
  echo "Please obtain: SNPmap_IND_TAU_ARS.txt"
  echo "See: docs/DATA_SOURCES.md for download instructions"
  echo "Save to: $REF_DIR/zebu_snpmap/SNPmap_IND_TAU_ARS.txt"
else
  echo "✓ SNPmap present"
fi
echo ""

# 4. VEP Cache
echo "Step 4: VEP Annotation Cache"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p "$REF_DIR/vep_cache"
if [ ! -d "$REF_DIR/vep_cache/bos_taurus" ]; then
  echo "Downloading VEP cache (Ensembl 115)..."
  echo "This may take 30-60 minutes..."
  vep_install \
    --AUTO cf \
    --SPECIES bos_taurus \
    --ASSEMBLY ARS-UCD2.0 \
    --CACHEDIR "$REF_DIR/vep_cache/" \
    --NO_HTSLIB 0
  echo "✓ VEP cache downloaded"
else
  echo "✓ VEP cache already present"
fi
echo ""

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  ✓ ARS-UCD2.0 genome: $REF_DIR/ARS-UCD2.0_genomic.fa"
echo "  ✓ ARS-UCD2.0 index:  $REF_DIR/ARS-UCD2.0_genomic.fa.fai"
echo "  $([ -f $REF_DIR/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed ] && echo '✓' || echo '✗') BovineHD chip:  $REF_DIR/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed"
echo "  $([ -f $REF_DIR/zebu_snpmap/SNPmap_IND_TAU_ARS.txt ] && echo '✓' || echo '✗') SNPmap:         $REF_DIR/zebu_snpmap/SNPmap_IND_TAU_ARS.txt"
echo "  ✓ VEP cache:        $REF_DIR/vep_cache/"
echo ""
```

---

## Quick Setup Checklist

```bash
# 1. Download genome + create index (automatic in pipeline)
bash src/utils/download_reference_genome.sh

# 2. Manually obtain BovineHD + SNPmap:
# - See instructions above
# - Save to correct directories

# 3. Run full setup script:
bash src/utils/setup_reference_data.sh

# 4. Verify everything is present:
ls -lh data/reference/
ls -lh data/reference/ARS-UCD2.0_genomic.fa*
ls -lh data/reference/bovine_hd_chip/
ls -lh data/reference/zebu_snpmap/
ls -lh data/reference/vep_cache/bos_taurus/
```

---

## Installation in INSTALLATION.md

Add to `docs/install_guides/INSTALLATION.md`:

### Step 3: Download Reference Data

```bash
# Download ARS-UCD2.0 genome (automatic)
bash src/utils/download_reference_genome.sh

# Download/obtain other reference files manually:
# See docs/DATA_SOURCES.md for detailed instructions

# Run complete setup:
bash src/utils/setup_reference_data.sh

# Verify all files are present:
ls -R data/reference/
```

---

## Summary

| File | Size | How to Get | Status |
|------|------|-----------|--------|
| **ARS-UCD2.0.fa** | 3.1 GB | Download NCBI (GCF_002263795.3) | Automated script |
| **ARS-UCD2.0.fa.fai** | 30 KB | Create locally with samtools | Automated |
| **BovineHD chip** | ~500 KB | Obtain from Illumina/papers | Manual |
| **SNPmap** | ~10 MB | Download Kasarapu et al. 2017 | Manual |
| **VEP cache** | 15 GB | Auto-download via vep_install | Automated |

---

## Contact & Attribution

- **NCBI Genome GCF_002263795.3:** https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_002263795.3/
- **Kasarapu et al. 2017:** https://doi.org/10.1038/ncomms14482
- **Ensembl VEP:** https://www.ensembl.org/vep
- **liftOver:** https://genome.ucsc.edu/cgi-bin/hgLiftOver

