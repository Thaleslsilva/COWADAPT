#!/bin/bash

################################################################################
#
# COWADAPT - Step 5: Extract BovineHD SNP Positions
#
# Extracts SNP genotypes for BovineHD chip positions from whole-genome
# sequencing (WGS) VCFs. Creates a SNP dataset for linkage disequilibrium
# (LD) analysis and tag SNP identification.
#
# Workflow:
#   1. Prepare BED coordinates from BovineHD chip manifest
#   2. Extract SNPs at those positions from input VCF
#   3. Apply quality filters (biallelic, AC>0)
#   4. Create indexed VCF files for downstream LD analysis
#
# Usage:
#   bash src/05_snp_extraction/extract_bovhd_snps.sh <snp_vcf>
#   Example: bash src/05_snp_extraction/extract_bovhd_snps.sh data/raw/snps.vcf.gz
#
# Output:
#   SNP VCFs:        results/snp_extraction/<sample>_bovhd_snps.vcf.gz
#   Indexed files:   results/snp_extraction/<sample>_bovhd_snps.vcf.gz.tbi
#   Stats report:    results/snp_extraction/extraction_summary.txt
#
# Requirements:
#   - BovineHD chip BED file (data/reference/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed)
#   - Input SNP VCF file (WGS or array genotyping)
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

if ! command_exists bcftools; then
    log_error "bcftools not found in PATH"
    log_error "Install with: conda install -c bioconda bcftools"
    exit 1
fi

if ! command_exists tabix; then
    log_error "tabix not found in PATH"
    log_error "Install with: conda install -c bioconda tabix"
    exit 1
fi

# ============================================================================
# VALIDATE INPUT
# ============================================================================

# Check that BovineHD chip file exists
if [ ! -f "$BOVINE_HD_BED" ]; then
    log_error "BovineHD chip BED file not found: $BOVINE_HD_BED"
    log_error "Download from: Illumina or published papers"
    log_error "See: docs/DATA_SOURCES.md for download instructions"
    exit 1
fi

# Get input SNP VCF file
if [ -z "${1:-}" ]; then
    log_error "Usage: bash src/05_snp_extraction/extract_bovhd_snps.sh <snp_vcf>"
    log_error "Example: bash src/05_snp_extraction/extract_bovhd_snps.sh data/raw/snps.vcf.gz"
    exit 1
fi

input_vcf="$1"

if [ ! -f "$input_vcf" ]; then
    log_error "Input SNP VCF not found: $input_vcf"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

init_directories

mkdir -p "$SNP_EXTRACTION_DIR"
mkdir -p "${LOGS_DIR}/snp_extraction"

# ============================================================================
# PREPARE BOVHD COORDINATES
# ============================================================================

log_info "============================================================="
log_info "BovineHD SNP Extraction"
log_info "============================================================="

log_info "Input SNP VCF: $input_vcf"
log_info "BovineHD chip BED: $BOVINE_HD_BED"

# Extract positions for bcftools (chr:pos format)
positions_file="${SNP_EXTRACTION_DIR}/bovhd_positions.txt"

log_info "Preparing BovineHD coordinates..."

# Convert BED to bcftools region format (removes BTA prefix if present)
awk '{
    chr = $1
    gsub(/^BTA/, "", chr)  # Remove BTA prefix
    print chr":"$3
}' "$BOVINE_HD_BED" > "$positions_file"

position_count=$(wc -l < "$positions_file")
log_info "Found $position_count BovineHD SNP positions"

# ============================================================================
# EXTRACT BOVHD SNPS FROM INPUT VCF
# ============================================================================

sample_id=$(basename "$input_vcf" .vcf.gz)
if [ "$sample_id" = "$(basename $input_vcf)" ]; then
    # Uncompressed VCF
    sample_id=$(basename "$input_vcf" .vcf)
fi

output_vcf="${SNP_EXTRACTION_DIR}/${sample_id}_bovhd_snps.vcf.gz"
output_biallelic="${SNP_EXTRACTION_DIR}/${sample_id}_bovhd_snps_biallelic.vcf.gz"
log_file="${LOGS_DIR}/snp_extraction/${sample_id}.log"

log_info "Extracting SNPs at BovineHD positions..."
log_debug "Command: bcftools view $input_vcf -R $positions_file -v snps -i 'AC>0' -Oz -o $output_vcf"

if bcftools view \
    "$input_vcf" \
    -R "$positions_file" \
    -v snps \
    -i 'AC>0' \
    -Oz \
    -o "$output_vcf" \
    2>&1 | tee -a "$log_file"
then
    log_info "[OK] SNP extraction completed"
else
    log_error "SNP extraction failed"
    log_error "See log: $log_file"
    exit 1
fi

# Index the extracted VCF
log_info "Indexing extracted SNP VCF..."
if tabix -p vcf "$output_vcf" 2>&1 | tee -a "$log_file"; then
    log_info "[OK] VCF indexed"
else
    log_error "VCF indexing failed"
    exit 1
fi

# Count extracted SNPs
extracted_count=$(bcftools query -f '.\n' "$output_vcf" 2>/dev/null | wc -l || echo "0")
vcf_size=$(get_file_size "$output_vcf")

log_info "Extracted SNPs: $extracted_count"
log_info "Output size: $vcf_size"

# ====================================================================
# FILTER TO BIALLELIC SNPs
# ====================================================================

log_info "Filtering to biallelic SNPs..."

if bcftools view \
    -m2 -M2 \
    -v snps \
    -Oz \
    -o "$output_biallelic" \
    "$output_vcf" \
    2>&1 | tee -a "$log_file"
then
    log_info "[OK] Biallelic filtering completed"
else
    log_error "Biallelic filtering failed"
    exit 1
fi

# Index biallelic VCF
log_info "Indexing biallelic SNP VCF..."
if tabix -p vcf "$output_biallelic" 2>&1 | tee -a "$log_file"; then
    log_info "[OK] Biallelic VCF indexed"
else
    log_error "VCF indexing failed"
    exit 1
fi

# Count biallelic SNPs
biallelic_count=$(bcftools query -f '.\n' "$output_biallelic" 2>/dev/null | wc -l || echo "0")
biallelic_size=$(get_file_size "$output_biallelic")

log_info "Biallelic SNPs: $biallelic_count"
log_info "Output size: $biallelic_size"

# ====================================================================
# GATHER STATISTICS
# ====================================================================

log_info "Generating statistics..."

stats_all=$(bcftools stats "$output_vcf" 2>/dev/null | grep "^SN" || echo "")
stats_biallelic=$(bcftools stats "$output_biallelic" 2>/dev/null | grep "^SN" || echo "")

# ============================================================================
# GENERATE SUMMARY REPORT
# ============================================================================

log_info "============================================================="
log_info "Extraction Summary"
log_info "============================================================="

summary_file="${SNP_EXTRACTION_DIR}/extraction_summary.txt"

{
    echo "=============================================================="
    echo "COWADAPT BovineHD SNP Extraction Report"
    echo "Generated: $(date)"
    echo "=============================================================="
    echo ""
    echo "INPUT DATA"
    echo "=============================================================="
    echo "Input VCF: $input_vcf"
    echo "Input size: $(get_file_size $input_vcf)"
    echo ""
    echo "BOVHD CHIP REFERENCE"
    echo "=============================================================="
    echo "BED file: $BOVINE_HD_BED"
    echo "Chip SNPs in BED: $position_count"
    echo ""
    echo "EXTRACTION RESULTS"
    echo "=============================================================="
    echo "SNPs extracted at BOVHD positions: $extracted_count"
    echo "Biallelic SNPs: $biallelic_count"
    echo "Retention rate: $(( biallelic_count * 100 / extracted_count ))%"
    echo ""
    echo "OUTPUT FILES"
    echo "=============================================================="
    echo "All extracted SNPs:"
    echo "  $output_vcf ($(get_file_size $output_vcf))"
    echo "  Index: ${output_vcf}.tbi"
    echo ""
    echo "Biallelic SNPs (for LD analysis):"
    echo "  $output_biallelic ($(get_file_size $output_biallelic))"
    echo "  Index: ${output_biallelic}.tbi"
    echo ""
    echo "This report: $summary_file"
    echo ""

    if [ ! -z "$stats_biallelic" ]; then
        echo "DETAILED STATISTICS (Biallelic SNPs)"
        echo "=============================================================="
        echo "$stats_biallelic"
        echo ""
    fi

} | tee "$summary_file"

# ============================================================================
# COMPLETION
# ============================================================================

log_info "SNP extraction complete!"
log_info "Output directory: $SNP_EXTRACTION_DIR"

echo ""
log_info "Next step: Perform LD analysis with extracted SNPs"
log_info "  bash src/06_ld_analysis/combine_sv_snp_vcf.sh"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
