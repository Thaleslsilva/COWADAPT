#!/bin/bash

################################################################################
#
# COWADAPT - Step 6: Combine SVs and SNPs for LD Analysis
#
# Prepares structural variants and SNPs for linkage disequilibrium (LD)
# analysis by combining them into a single multi-sample VCF for LD calculation.
#
# Workflow:
#   1. Convert SV genotypes to biallelic format (required for LD calculation)
#   2. Merge SV and SNP VCFs (maintain non-overlapping positions)
#   3. Convert to plink2 format (PGEN) for efficient LD calculation
#   4. Calculate SV-SNP associations (identify tag SNPs for each SV)
#
# Usage:
#   bash src/06_ld_analysis/combine_sv_snp_vcf.sh
#
# Output:
#   Combined VCFs:  results/ld_analysis/<sample>_svs_snps_merged.vcf.gz
#   PGEN files:     results/ld_analysis/pgen/<sample>_svs_snps.*
#   LD report:      results/ld_analysis/<sample>_ld_summary.txt
#
# Requirements:
#   - Validated SVs from Step 3 (results/validation/*_validated.vcf)
#   - Filtered SNPs from Step 5B (results/snp_extraction/*_snps_qc.vcf.gz)
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
# VALIDATE INPUT DATA
# ============================================================================

# Check SVs
if [ ! -d "$VALIDATION_DIR" ]; then
    log_error "Validated SV results not found: $VALIDATION_DIR"
    log_error "Run Step 3 first: bash src/03_sv_validation/run_sv_validation.sh"
    exit 1
fi

sv_count=$(find "$VALIDATION_DIR" -maxdepth 1 -name "*_validated.vcf" -type f | wc -l || echo "0")
if [ "$sv_count" -eq 0 ]; then
    log_error "No validated SV VCF files found in: $VALIDATION_DIR"
    exit 1
fi

# Check SNPs
if [ ! -d "$SNP_EXTRACTION_DIR" ]; then
    log_error "Filtered SNP results not found: $SNP_EXTRACTION_DIR"
    log_error "Run Step 5B first: bash src/05_snp_extraction/filter_snp_quality.sh"
    exit 1
fi

snp_count=$(find "$SNP_EXTRACTION_DIR" -maxdepth 1 -name "*_snps_qc.vcf.gz" -type f | wc -l || echo "0")
if [ "$snp_count" -eq 0 ]; then
    log_error "No filtered SNP VCF files found in: $SNP_EXTRACTION_DIR"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

mkdir -p "$LD_ANALYSIS_DIR"
mkdir -p "$LD_ANALYSIS_DIR/pgen"
mkdir -p "${LOGS_DIR}/ld_analysis"

# ============================================================================
# PREPARE DATA
# ============================================================================

log_info "============================================================="
log_info "SV-SNP Combination for LD Analysis"
log_info "============================================================="

log_info "Found $sv_count SV samples and $snp_count SNP samples"

# ============================================================================
# PROCESS EACH SAMPLE
# ============================================================================

combined_count=0
failed_count=0

# Get list of SV VCFs
readarray -t sv_vcfs < <(find "$VALIDATION_DIR" -maxdepth 1 -name "*_validated.vcf" -type f | sort)

for sv_vcf in "${sv_vcfs[@]}"; do

    # Get sample ID
    sample_id=$(basename "$sv_vcf" _validated.vcf)

    # Find corresponding SNP VCF
    snp_vcf="${SNP_EXTRACTION_DIR}/${sample_id}_snps_qc.vcf.gz"

    if [ ! -f "$snp_vcf" ]; then
        log_warn "SNP VCF not found for $sample_id, skipping"
        ((failed_count++))
        continue
    fi

    log_info "Processing: $sample_id"

    sv_biallelic="${LD_ANALYSIS_DIR}/${sample_id}_svs_biallelic.vcf"
    sv_biallelic_gz="${LD_ANALYSIS_DIR}/${sample_id}_svs_biallelic.vcf.gz"
    merged_vcf="${LD_ANALYSIS_DIR}/${sample_id}_svs_snps_merged.vcf.gz"
    pgen_prefix="${LD_ANALYSIS_DIR}/pgen/${sample_id}_svs_snps"
    log_file="${LOGS_DIR}/ld_analysis/${sample_id}.log"

    # ====================================================================
    # CONVERT SVS TO BIALLELIC
    # ====================================================================

    log_info "Converting SV genotypes to biallelic format..."

    # Use bcftools to normalize SVs to biallelic format
    if bcftools view "$sv_vcf" -Ov > "$sv_biallelic" 2>&1 | tee -a "$log_file"; then
        log_debug "SV conversion completed"
    else
        log_error "SV conversion failed for $sample_id"
        ((failed_count++))
        continue
    fi

    # Compress and index
    if bgzip -f "$sv_biallelic" 2>&1 | tee -a "$log_file"; then
        log_debug "Compression completed"
    else
        log_error "Compression failed"
        ((failed_count++))
        continue
    fi

    if tabix -p vcf "$sv_biallelic_gz" 2>&1 | tee -a "$log_file"; then
        log_debug "Indexing completed"
    else
        log_error "Indexing failed"
        ((failed_count++))
        continue
    fi

    # ====================================================================
    # MERGE SVS AND SNPS
    # ====================================================================

    log_info "Merging SVs and SNPs..."

    if bcftools concat \
        --allow-overlaps \
        "$sv_biallelic_gz" \
        "$snp_vcf" \
        --output-type z \
        --output "$merged_vcf" \
        2>&1 | tee -a "$log_file"
    then
        log_debug "Concat completed"
    else
        log_error "bcftools concat failed for $sample_id"
        ((failed_count++))
        continue
    fi

    # Index merged VCF
    if tabix -p vcf "$merged_vcf" 2>&1 | tee -a "$log_file"; then
        log_debug "Merged VCF indexed"
    else
        log_error "Merged VCF indexing failed"
        ((failed_count++))
        continue
    fi

    # Count variants
    sv_in_merged=$(bcftools view -i "SVLEN!=." "$merged_vcf" 2>/dev/null | grep -v "^#" | wc -l || echo "0")
    snp_in_merged=$(bcftools view -i "SVLEN=." "$merged_vcf" 2>/dev/null | grep -v "^#" | wc -l || echo "0")

    log_info "[OK] Merge completed"
    log_info "  SVs in merged VCF: $sv_in_merged"
    log_info "  SNPs in merged VCF: $snp_in_merged"

    # ====================================================================
    # CONVERT TO PGEN FOR LD CALCULATION
    # ====================================================================

    log_info "Converting to PGEN format for LD analysis..."

    if plink2 \
        --vcf "$merged_vcf" \
        --make-pgen \
        --out "$pgen_prefix" \
        --chr-set 29 \
        --allow-extra-chr \
        --max-alleles 2 \
        2>&1 | tee -a "$log_file"
    then
        log_info "[OK] PGEN conversion completed"
        ((combined_count++))
    else
        log_error "PGEN conversion failed for $sample_id"
        ((failed_count++))
        continue
    fi

    # ====================================================================
    # CLEAN UP TEMPORARY FILES
    # ====================================================================

    rm -f "$sv_biallelic_gz" "${sv_biallelic_gz}.tbi" 2>/dev/null || true

    echo ""

done

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

log_info "============================================================="
log_info "SV-SNP Combination Complete"
log_info "============================================================="

log_info "Results:"
log_info "  Combined: $combined_count samples"
if [ $failed_count -gt 0 ]; then
    log_warn "  Failed: $failed_count samples"
fi

log_info "Output directory: $LD_ANALYSIS_DIR"
log_info "PGEN files ready for LD calculation"

echo ""

if [ $failed_count -eq 0 ] && [ $combined_count -gt 0 ]; then
    log_info "Next step: Classify Zebu-specific variants"
    log_info "  bash src/07_zebu_specificity/run_zebu_specificity.sh"
else
    log_warn "Some samples failed. Please review logs in: ${LOGS_DIR}/ld_analysis/"
    exit 1
fi

echo ""

################################################################################
# END OF SCRIPT
################################################################################
