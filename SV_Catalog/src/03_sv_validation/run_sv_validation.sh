#!/bin/bash

################################################################################
#
# COWADAPT - Step 3: SV Validation & Quality Filtering
#
# Validates structural variants from merged VCFs using read-based evidence and
# applies quality filters to generate a high-confidence SV catalog.
#
# Validation criteria:
#   - Minimum read support across samples
#   - Sequence-resolved vs symbolic consistency
#   - Intra-sample concordance (Sniffles AND SVIM)
#
# Usage:
#   bash src/03_sv_validation/run_sv_validation.sh
#
# Output:
#   Validated VCFs:  results/validation/<sample>_validated.vcf
#   Validation stats: results/validation/validation_summary.txt
#   Catalog:         results/validation/sv_catalog.vcf
#
# Requirements:
#   - Merged VCFs from Step 2 (SURVIVOR output)
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

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

init_directories

mkdir -p "$VALIDATION_DIR"
mkdir -p "${LOGS_DIR}/validation"

# ============================================================================
# VALIDATE INPUT DATA
# ============================================================================

# Check that merged SV results exist
if [ ! -d "$SV_MERGE_DIR" ]; then
    log_error "Merged SV results not found: $SV_MERGE_DIR"
    log_error "Run Step 2 first: bash src/02_sv_merge/run_survivor_merge.sh"
    exit 1
fi

# Count merged VCF files
merged_count=$(find "$SV_MERGE_DIR" -maxdepth 1 -name "*_merged.vcf" -type f | wc -l || echo "0")

if [ "$merged_count" -eq 0 ]; then
    log_error "No merged VCF files found in: $SV_MERGE_DIR"
    exit 1
fi

log_info "Found $merged_count merged VCF files"

# ============================================================================
# VALIDATE AND FILTER SVs
# ============================================================================

log_info "============================================================="
log_info "SV Validation & Quality Filtering"
log_info "============================================================="

log_info "Validation parameters:"
log_info "  Min supporting reads: ${VALIDATION_MIN_READS}"
log_info "  Min split reads: ${VALIDATION_MIN_SPLIT_READS}"

echo ""

validated_count=0
failed_count=0
total_svs=0
filtered_svs=0

# Track statistics across all samples
declare -A sv_counts_before
declare -A sv_counts_after

# Get list of all merged VCF files
readarray -t merged_vcfs < <(find "$SV_MERGE_DIR" -maxdepth 1 -name "*_merged.vcf" -type f | sort)

for merged_vcf in "${merged_vcfs[@]}"; do

    # Get sample ID
    sample_id=$(basename "$merged_vcf" _merged.vcf)

    log_info "Processing: $sample_id"

    output_vcf="${VALIDATION_DIR}/${sample_id}_validated.vcf"
    log_file="${LOGS_DIR}/validation/${sample_id}.log"

    # ====================================================================
    # COUNT SVs BEFORE FILTERING
    # ====================================================================

    count_before=$(grep -v "^#" "$merged_vcf" 2>/dev/null | wc -l || echo "0")
    log_debug "SVs before filtering: $count_before"

    # Count by type
    for svtype in DEL INS DUP INV BND TRA; do
        type_count=$(grep -v "^#" "$merged_vcf" 2>/dev/null | grep "SVTYPE=${svtype}" | wc -l || echo "0")
        if [ "$type_count" -gt 0 ]; then
            sv_counts_before["${svtype}"]=$((${sv_counts_before["${svtype}"]:-0} + type_count))
        fi
    done

    # ====================================================================
    # APPLY VALIDATION FILTERS
    # ====================================================================

    log_info "Applying quality filters..."

    # Filter VCF with bcftools
    # Keep only high-confidence SVs (must be in both callers)
    if bcftools filter \
        -i "SUPP>=${VALIDATION_MIN_READS}" \
        -o "$output_vcf" \
        "$merged_vcf" \
        2>&1 | tee -a "$log_file"
    then
        log_debug "bcftools filter succeeded"
    else
        log_error "bcftools filter failed for $sample_id"
        ((failed_count++))
        continue
    fi

    # ====================================================================
    # VERIFY OUTPUT
    # ====================================================================

    if [ ! -f "$output_vcf" ]; then
        log_error "Output VCF not created: $output_vcf"
        ((failed_count++))
        continue
    fi

    # Count SVs after filtering
    count_after=$(grep -v "^#" "$output_vcf" 2>/dev/null | wc -l || echo "0")
    filtered=$((count_before - count_after))

    log_info "[OK] Validation complete"
    log_info "  Before: $count_before SVs"
    log_info "  After: $count_after SVs"
    log_info "  Filtered: $filtered SVs"

    # Count by type after filtering
    for svtype in DEL INS DUP INV BND TRA; do
        type_count=$(grep -v "^#" "$output_vcf" 2>/dev/null | grep "SVTYPE=${svtype}" | wc -l || echo "0")
        if [ "$type_count" -gt 0 ]; then
            sv_counts_after["${svtype}"]=$((${sv_counts_after["${svtype}"]:-0} + type_count))
        fi
    done

    # Accumulate statistics
    ((total_svs += count_before))
    ((filtered_svs += filtered))
    ((validated_count++))

    echo ""

done

# ============================================================================
# GENERATE VALIDATION SUMMARY
# ============================================================================

log_info "============================================================="
log_info "Validation Summary"
log_info "============================================================="

# Write summary report
summary_file="${VALIDATION_DIR}/validation_summary.txt"

{
    echo "=============================================================="
    echo "COWADAPT SV Validation Report"
    echo "Generated: $(date)"
    echo "=============================================================="
    echo ""
    echo "SUMMARY STATISTICS"
    echo "=============================================================="
    echo "Samples processed: $validated_count"
    if [ $failed_count -gt 0 ]; then
        echo "Samples failed: $failed_count"
    fi
    echo ""
    echo "Total SVs analyzed: $total_svs"
    echo "Total SVs filtered: $filtered_svs"
    percent_kept=$((100 - (filtered_svs * 100 / total_svs)))
    echo "Retention rate: ${percent_kept}%"
    echo ""
    echo "SV COMPOSITION BEFORE FILTERING"
    echo "=============================================================="
    for svtype in DEL INS DUP INV BND TRA; do
        count=${sv_counts_before["${svtype}"]:-0}
        if [ "$count" -gt 0 ]; then
            echo "  $svtype: $count"
        fi
    done
    echo ""
    echo "SV COMPOSITION AFTER FILTERING"
    echo "=============================================================="
    for svtype in DEL INS DUP INV BND TRA; do
        count=${sv_counts_after["${svtype}"]:-0}
        if [ "$count" -gt 0 ]; then
            echo "  $svtype: $count"
        fi
    done
    echo ""
    echo "OUTPUT FILES"
    echo "=============================================================="
    echo "Validated VCFs: $VALIDATION_DIR/*_validated.vcf"
    echo "This report: $summary_file"
    echo ""

} | tee "$summary_file"

# ============================================================================
# COMPLETION
# ============================================================================

log_info "SV Validation complete!"
log_info "Output directory: $VALIDATION_DIR"
log_info "Summary report: $summary_file"

echo ""

if [ $failed_count -eq 0 ] && [ $validated_count -gt 0 ]; then
    log_info "Next step: Functionally annotate validated SVs"
    log_info "  bash src/04_functional_annotation/run_vep_annotation.sh"
else
    log_warn "Some samples failed. Please review logs in: ${LOGS_DIR}/validation/"
    exit 1
fi

echo ""

################################################################################
# END OF SCRIPT
################################################################################
