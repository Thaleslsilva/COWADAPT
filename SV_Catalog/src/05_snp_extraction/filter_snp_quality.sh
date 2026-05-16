#!/bin/bash

################################################################################
#
# COWADAPT - Step 5B: SNP Quality Filtering
#
# Applies population genetics quality filters to SNP VCFs before linkage
# disequilibrium (LD) analysis. Removes rare, monomorphic, and HWE-deviant SNPs.
#
# Filter criteria (standard for population LD):
#   - Minor Allele Frequency (MAF) >= 0.05
#   - Missing rate <= 0.10 (max 10% missing genotypes)
#   - Hardy-Weinberg Equilibrium (HWE) p-value > 1e-6
#
# Uses plink2 for efficient filtering and VCF conversion.
#
# Usage:
#   bash src/05_snp_extraction/filter_snp_quality.sh <input_vcf>
#   Example: bash src/05_snp_extraction/filter_snp_quality.sh results/snp_extraction/snps_bovhd_snps_biallelic.vcf.gz
#
# Output:
#   Filtered VCF:    results/snp_extraction/<sample>_snps_qc.vcf.gz
#   PGEN files:      results/snp_extraction/pgen/<sample>_qc.*
#   Summary report:  results/snp_extraction/filtering_summary.txt
#
# Requirements:
#   - plink2 (for VCF filtering and PGEN conversion)
#   - bcftools (for VCF operations)
#   - Biallelic SNP VCF from Step 5A
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

if ! command_exists plink2; then
    log_error "plink2 not found in PATH"
    log_error "Install with: conda install -c bioconda plink2"
    exit 1
fi

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

if [ -z "${1:-}" ]; then
    log_error "Usage: bash src/05_snp_extraction/filter_snp_quality.sh <input_vcf>"
    log_error "Example: bash src/05_snp_extraction/filter_snp_quality.sh results/snp_extraction/snps_bovhd_snps_biallelic.vcf.gz"
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

mkdir -p "$SNP_EXTRACTION_DIR"
mkdir -p "$SNP_EXTRACTION_DIR/pgen"
mkdir -p "${LOGS_DIR}/snp_qc"

# ============================================================================
# DEFINE FILTERING PARAMETERS
# ============================================================================

# Quality filtering thresholds
MAF_THRESHOLD=0.05              # Minor allele frequency
MISSING_THRESHOLD=0.10          # Missing genotype rate
HWE_THRESHOLD=1e-6              # Hardy-Weinberg equilibrium p-value

log_info "============================================================="
log_info "SNP Quality Filtering"
log_info "============================================================="

log_info "Filter parameters:"
log_info "  MAF threshold: $MAF_THRESHOLD"
log_info "  Missing rate: $MISSING_THRESHOLD"
log_info "  HWE p-value: $HWE_THRESHOLD"

echo ""

# ============================================================================
# GET SAMPLE ID AND PREPARE FILES
# ============================================================================

sample_id=$(basename "$input_vcf" _bovhd_snps_biallelic.vcf.gz)
if [ "$sample_id" = "$(basename $input_vcf)" ]; then
    sample_id=$(basename "$input_vcf" .vcf.gz)
fi

log_info "Processing: $sample_id"

temp_vcf="${SNP_EXTRACTION_DIR}/${sample_id}_temp.vcf.gz"
pgen_prefix="${SNP_EXTRACTION_DIR}/pgen/${sample_id}_qc"
output_vcf="${SNP_EXTRACTION_DIR}/${sample_id}_snps_qc.vcf.gz"
log_file="${LOGS_DIR}/snp_qc/${sample_id}.log"

# ====================================================================
# COUNT SNPS BEFORE FILTERING
# ====================================================================

snps_before=$(bcftools query -f '.\n' "$input_vcf" 2>/dev/null | wc -l || echo "0")
log_info "SNPs before filtering: $snps_before"

# ====================================================================
# CONVERT TO PGEN WITH PLINK2 (APPLIES FILTERS)
# ====================================================================

log_info "Applying quality filters with plink2..."
log_debug "Filters: MAF>$MAF_THRESHOLD, geno<$MISSING_THRESHOLD, HWE>$HWE_THRESHOLD"

# Bovine genome has 29 chromosomes
if plink2 \
    --vcf "$input_vcf" \
    --set-missing-var-ids '@:#:$r:$a' \
    --maf "$MAF_THRESHOLD" \
    --geno "$MISSING_THRESHOLD" \
    --hwe "$HWE_THRESHOLD" \
    --make-pgen \
    --out "$pgen_prefix" \
    --chr-set 29 \
    --allow-extra-chr \
    2>&1 | tee -a "$log_file"
then
    log_info "[OK] plink2 QC filtering completed"
else
    log_error "plink2 filtering failed"
    log_error "See log: $log_file"
    exit 1
fi

# ====================================================================
# CONVERT PGEN BACK TO VCF
# ====================================================================

log_info "Converting PGEN back to VCF format..."

if plink2 \
    --pfile "$pgen_prefix" \
    --export vcf bgz \
    --out "${SNP_EXTRACTION_DIR}/${sample_id}_temp" \
    --chr-set 29 \
    --allow-extra-chr \
    2>&1 | tee -a "$log_file"
then
    log_info "[OK] VCF export completed"
else
    log_error "VCF export failed"
    exit 1
fi

# Move to final location
mv "${SNP_EXTRACTION_DIR}/${sample_id}_temp.vcf.gz" "$output_vcf"

# Index the final VCF
log_info "Indexing filtered SNP VCF..."
if tabix -p vcf "$output_vcf" 2>&1 | tee -a "$log_file"; then
    log_info "[OK] VCF indexed"
else
    log_error "VCF indexing failed"
    exit 1
fi

# ====================================================================
# VERIFY OUTPUT AND GATHER STATISTICS
# ====================================================================

snps_after=$(bcftools query -f '.\n' "$output_vcf" 2>/dev/null | wc -l || echo "0")
snps_removed=$((snps_before - snps_after))
retention=$((snps_after * 100 / snps_before))

log_info "[OK] SNP filtering complete"
log_info "  SNPs before: $snps_before"
log_info "  SNPs after: $snps_after"
log_info "  SNPs removed: $snps_removed"
log_info "  Retention: $retention%"

vcf_size=$(get_file_size "$output_vcf")
sample_count=$(bcftools query -l "$output_vcf" 2>/dev/null | wc -l || echo "0")
log_info "Output: $vcf_size ($sample_count samples)"

# ====================================================================
# CLEANUP TEMPORARY FILES
# ====================================================================

log_info "Cleaning up temporary files..."
rm -f "${SNP_EXTRACTION_DIR}/${sample_id}_temp"* 2>/dev/null || true
log_debug "Removed temporary files"

# ============================================================================
# GENERATE FILTERING SUMMARY
# ============================================================================

log_info "============================================================="
log_info "Filtering Summary"
log_info "============================================================="

summary_file="${SNP_EXTRACTION_DIR}/filtering_summary.txt"

{
    echo "=============================================================="
    echo "COWADAPT SNP Quality Filtering Report"
    echo "Generated: $(date)"
    echo "=============================================================="
    echo ""
    echo "INPUT DATA"
    echo "=============================================================="
    echo "Input VCF: $input_vcf"
    echo "Input size: $(get_file_size $input_vcf)"
    echo ""
    echo "FILTERING PARAMETERS"
    echo "=============================================================="
    echo "MAF threshold: $MAF_THRESHOLD"
    echo "Missing rate threshold: $MISSING_THRESHOLD"
    echo "HWE p-value threshold: $HWE_THRESHOLD"
    echo ""
    echo "RESULTS"
    echo "=============================================================="
    echo "SNPs before filtering: $snps_before"
    echo "SNPs after filtering: $snps_after"
    echo "SNPs removed: $snps_removed"
    echo "Retention rate: ${retention}%"
    echo ""
    echo "OUTPUT FILES"
    echo "=============================================================="
    echo "Filtered SNP VCF: $output_vcf"
    echo "  Size: $(get_file_size $output_vcf)"
    echo "  Samples: $sample_count"
    echo "  Index: ${output_vcf}.tbi"
    echo ""
    echo "PGEN files (for LD calculation): $pgen_prefix.*"
    echo ""
    echo "This report: $summary_file"
    echo ""

} | tee "$summary_file"

# ============================================================================
# COMPLETION
# ============================================================================

log_info "SNP quality filtering complete!"
log_info "Output directory: $SNP_EXTRACTION_DIR"

echo ""
log_info "Next step: Combine SNPs with SVs for LD analysis"
log_info "  bash src/06_ld_analysis/combine_sv_snp_vcf.sh"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
