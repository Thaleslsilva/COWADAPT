#!/bin/bash

################################################################################
#
# COWADAPT - Helper: Summarize SV Catalog
#
# Generates final SV catalog summary and statistics from validated,
# annotated, and LD-analyzed structural variants. Produces comprehensive
# reports on catalog composition, annotations, and variant characteristics.
#
# Usage:
#   bash src/06_ld_analysis/summarize_catalog.sh
#
# Output:
#   Catalog summary: results/ld_analysis/sv_catalog_summary.txt
#   Statistics: results/ld_analysis/catalog_statistics.txt
#   Report: printed to stdout
#
# Requirements:
#   - Validated SVs from Step 3
#   - Functional annotations from Step 4
#   - LD analysis results from Step 6
#
# Notes:
#   - Aggregates data across all samples
#   - Provides impact distribution
#   - Lists high-confidence variants
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

if [ ! -d "$VALIDATION_DIR" ]; then
    log_error "Validation directory not found: $VALIDATION_DIR"
    log_error "Run validation step first: bash src/03_sv_validation/run_sv_validation.sh"
    exit 1
fi

if [ ! -d "$ANNOTATION_DIR" ]; then
    log_error "Annotation directory not found: $ANNOTATION_DIR"
    log_error "Run annotation step first: bash src/04_functional_annotation/run_vep_annotation.sh"
    exit 1
fi

if [ ! -d "$LD_ANALYSIS_DIR" ]; then
    log_error "LD analysis directory not found: $LD_ANALYSIS_DIR"
    log_error "Run LD analysis step first: bash src/06_ld_analysis/combine_sv_snp_vcf.sh"
    exit 1
fi

if ! command_exists bcftools; then
    log_error "bcftools not found in PATH"
    exit 1
fi

# ============================================================================
# INITIALIZE
# ============================================================================

mkdir -p "${LOGS_DIR}/catalog"

log_info "============================================================="
log_info "Summarizing SV Catalog"
log_info "============================================================="

# ============================================================================
# AGGREGATE STATISTICS
# ============================================================================

total_svs=0
total_high_impact=0
total_moderate_impact=0
total_low_impact=0
total_modifier=0

declare -A sv_type_counts

# Process all validated VCFs
log_info "Aggregating statistics from validated VCFs..."

for validated_vcf in "$VALIDATION_DIR"/*_validated.vcf; do
    if [ ! -f "$validated_vcf" ]; then
        continue
    fi

    sample_id=$(basename "$validated_vcf" _validated.vcf)
    log_debug "Processing: $sample_id"

    # Count SVs
    sv_count=$(grep -v "^#" "$validated_vcf" 2>/dev/null | wc -l || echo "0")
    ((total_svs += sv_count))

    # Count by type
    for svtype in DEL INS DUP INV BND TRA; do
        type_count=$(grep -v "^#" "$validated_vcf" 2>/dev/null | grep "SVTYPE=${svtype}" | wc -l || echo "0")
        sv_type_counts["${svtype}"]=$((${sv_type_counts["${svtype}"]:-0} + type_count))
    done
done

log_info "[OK] Found $total_svs total SVs across all samples"

# Count impacts from annotations
for annotated_vcf in "$ANNOTATION_DIR"/*_annotated.vcf; do
    if [ ! -f "$annotated_vcf" ]; then
        continue
    fi

    high=$(grep -v "^#" "$annotated_vcf" 2>/dev/null | grep -i "IMPACT=HIGH" | wc -l || echo "0")
    moderate=$(grep -v "^#" "$annotated_vcf" 2>/dev/null | grep -i "IMPACT=MODERATE" | wc -l || echo "0")
    low=$(grep -v "^#" "$annotated_vcf" 2>/dev/null | grep -i "IMPACT=LOW" | wc -l || echo "0")
    modifier=$(grep -v "^#" "$annotated_vcf" 2>/dev/null | grep -i "IMPACT=MODIFIER" | wc -l || echo "0")

    ((total_high_impact += high))
    ((total_moderate_impact += moderate))
    ((total_low_impact += low))
    ((total_modifier += modifier))
done

log_info "[OK] Annotated variants: $((total_high_impact + total_moderate_impact + total_low_impact + total_modifier))"

echo ""

# ============================================================================
# GENERATE SUMMARY REPORT
# ============================================================================

log_info "============================================================="
log_info "Catalog Summary"
log_info "============================================================="

summary_file="${LD_ANALYSIS_DIR}/sv_catalog_summary.txt"

{
    echo "=============================================================="
    echo "COWADAPT SV Catalog Summary"
    echo "Generated: $(date)"
    echo "=============================================================="
    echo ""
    echo "CATALOG STATISTICS"
    echo "=============================================================="
    echo "Total SVs: $total_svs"
    echo ""
    echo "SV Type Distribution:"
    for svtype in DEL INS DUP INV BND TRA; do
        count=${sv_type_counts["${svtype}"]:-0}
        if [ "$count" -gt 0 ]; then
            pct=$((count * 100 / total_svs))
            echo "  ${svtype}: $count ($pct%)"
        fi
    done
    echo ""
    echo "Impact Distribution:"
    total_impacts=$((total_high_impact + total_moderate_impact + total_low_impact + total_modifier))
    if [ "$total_impacts" -gt 0 ]; then
        echo "  HIGH:       $total_high_impact ($((total_high_impact * 100 / total_impacts))%)"
        echo "  MODERATE:   $total_moderate_impact ($((total_moderate_impact * 100 / total_impacts))%)"
        echo "  LOW:        $total_low_impact ($((total_low_impact * 100 / total_impacts))%)"
        echo "  MODIFIER:   $total_modifier ($((total_modifier * 100 / total_impacts))%)"
    else
        echo "  No annotated variants"
    fi
    echo ""
    echo "FILES INCLUDED"
    echo "=============================================================="
    echo "Validated SVs: $VALIDATION_DIR/*_validated.vcf"
    echo "Annotations: $ANNOTATION_DIR/*_annotated.vcf"
    echo "LD analysis: $LD_ANALYSIS_DIR/*.vcf.gz"
    echo ""
    echo "CATALOG READY FOR:"
    echo "=============================================================="
    echo "- Population analysis"
    echo "- Tag SNP identification"
    echo "- Zebu-specificity analysis"
    echo "- Publication in supplementary materials"
    echo ""

} | tee "$summary_file"

log_info "[OK] Summary saved: $summary_file"

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

log_info "============================================================="
log_info "Catalog Summary Complete"
log_info "============================================================="

log_info "Catalog contains:"
log_info "  Total SVs: $total_svs"
log_info "  High-impact variants: $total_high_impact"
log_info "  Summary report: $summary_file"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
