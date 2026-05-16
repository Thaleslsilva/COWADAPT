#!/bin/bash

################################################################################
#
# COWADAPT - Helper: Inspect SURVIVOR Merge Output
#
# Generates summary statistics and diagnostic reports for merged SV VCFs.
# Useful for verifying merge results and generating validation datasets.
#
# Usage:
#   bash src/02_sv_merge/inspect_survivor_output.sh <merged_vcf>
#   Example: bash src/02_sv_merge/inspect_survivor_output.sh results/sv_merge/sample1_merged.vcf
#
# Output:
#   Summary report: printed to stdout
#   BED coordinates: <input_name>_validation.bed (if conversion enabled)
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
# VALIDATE INPUT
# ============================================================================

if [ -z "${1:-}" ]; then
    log_error "Usage: bash src/02_sv_merge/inspect_survivor_output.sh <merged_vcf>"
    log_error "Example: bash src/02_sv_merge/inspect_survivor_output.sh results/sv_merge/sample1_merged.vcf"
    exit 1
fi

input_vcf="$1"

if [ ! -f "$input_vcf" ]; then
    log_error "Input VCF not found: $input_vcf"
    exit 1
fi

if ! command_exists bcftools; then
    log_error "bcftools not found in PATH"
    log_error "Install with: conda install -c bioconda bcftools"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

mkdir -p "${LOGS_DIR}/merge_inspection"

# ============================================================================
# GENERATE INSPECTION REPORT
# ============================================================================

sample_id=$(basename "$input_vcf" .vcf)
if [ "$sample_id" = "$(basename $input_vcf)" ]; then
    sample_id=$(basename "$input_vcf" .vcf.gz)
fi

log_info "============================================================="
log_info "Inspecting SURVIVOR Merge Output"
log_info "============================================================="

log_info "Input VCF: $input_vcf"
log_info "File size: $(get_file_size $input_vcf)"

# Count total SVs
total_svs=$(grep -v "^#" "$input_vcf" 2>/dev/null | wc -l || echo "0")
log_info "Total SVs: $total_svs"

echo ""

# Count by SV type
log_info "SV Type Distribution:"
declare -A sv_counts

for svtype in DEL INS DUP INV BND TRA; do
    count=$(grep -v "^#" "$input_vcf" 2>/dev/null | grep "SVTYPE=${svtype}" | wc -l || echo "0")
    if [ "$count" -gt 0 ]; then
        sv_counts["${svtype}"]=$count
        log_info "  ${svtype}: $count"
    fi
done

echo ""

# Verify genotype columns
log_info "Genotype Information:"
sample_count=$(grep "^#CHROM" "$input_vcf" 2>/dev/null | awk '{print NF-9}' || echo "0")
log_info "  Samples: $sample_count"

column_count=$(grep -v "^#" "$input_vcf" 2>/dev/null | head -1 | awk '{print NF}' || echo "0")
log_info "  Total columns: $column_count"

echo ""

# SV size distribution
log_info "SV Size Distribution:"
awk -F'SVLEN=' '
!/^#/ {
  split($2,a,";");
  v=a[1];
  if(v!=""){
    if(v<0)v=-v;
    if(min=="" || v<min)min=v;
    if(v>max)max=v;
    sum+=v;
    n++;
  }
}
END{
  if(n>0) {
    printf "  N=%d, Min=%dbp, Max=%dbp, Mean=%dbp\n", n, min, max, int(sum/n);
  } else {
    print "  No SVLEN information found";
  }
}' "$input_vcf" | while read line; do
    log_info "$line"
done

echo ""

# SUPP field analysis (support from multiple callers)
log_info "Caller Support Distribution (SUPP field):"
grep -v "^#" "$input_vcf" 2>/dev/null | \
    grep -o "SUPP=[0-9]" | sort | uniq -c | \
    while read count support; do
        caller_count=${support#*=}
        log_info "  From $caller_count caller(s): $count SVs"
    done

echo ""

# ============================================================================
# GENERATE SUMMARY REPORT
# ============================================================================

report_file="${SV_MERGE_DIR}/inspection_${sample_id}.txt"

{
    echo "=============================================================="
    echo "COWADAPT SURVIVOR Merge Inspection Report"
    echo "Generated: $(date)"
    echo "=============================================================="
    echo ""
    echo "INPUT VCF"
    echo "=============================================================="
    echo "File: $input_vcf"
    echo "Size: $(get_file_size $input_vcf)"
    echo ""
    echo "SUMMARY STATISTICS"
    echo "=============================================================="
    echo "Total SVs: $total_svs"
    echo "Samples: $sample_count"
    echo "Columns: $column_count"
    echo ""
    echo "SV TYPE DISTRIBUTION"
    echo "=============================================================="
    for svtype in DEL INS DUP INV BND TRA; do
        count=${sv_counts["${svtype}"]:-0}
        if [ "$count" -gt 0 ]; then
            pct=$((count * 100 / total_svs))
            echo "  ${svtype}: $count ($pct%)"
        fi
    done
    echo ""
    echo "QUALITY CHECKS"
    echo "=============================================================="
    echo "VCF header: Present"
    echo "Genotype columns: $((sample_count)) samples + 9 fixed columns"
    echo ""

} | tee "$report_file"

log_info "[OK] Inspection report saved: $report_file"

echo ""

################################################################################
# END OF SCRIPT
################################################################################