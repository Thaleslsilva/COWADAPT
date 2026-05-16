#!/bin/bash

################################################################################
#
# COWADAPT - Step 2: SV Merge & Concordance Filtering with SURVIVOR
#
# Merges structural variant VCFs from both callers (Sniffles2 + SVIM) and
# applies concordance filtering to identify high-confidence SVs with support
# from both callers.
#
# Usage:
#   bash src/02_sv_merge/run_survivor_merge.sh
#   SURVIVOR_DISTANCE=500 bash src/02_sv_merge/run_survivor_merge.sh
#
# Output:
#   Merged VCFs:    results/sv_merge/<sample>_merged.vcf
#   File list:      results/sv_merge/<sample>_vcf_list.txt (temporary)
#
# Parameters:
#   SURVIVOR_DISTANCE (default 1000 bp) - Merge window for concordance
#   SURVIVOR_MIN_CALLERS (default 2) - Minimum caller support
#
# Note:
#   - Requires both Sniffles2 and SVIM results from Step 1
#   - SURVIVOR merges overlapping calls within distance window
#   - Higher distance = more permissive
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

if ! command_exists SURVIVOR; then
    log_error "SURVIVOR not found in PATH"
    log_error "Install with: conda install -c bioconda survivor"
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

init_directories

mkdir -p "$SV_MERGE_DIR"
mkdir -p "${LOGS_DIR}/survivor"

# ============================================================================
# VALIDATE INPUT DATA
# ============================================================================

# Check that both SV calling results exist
if [ ! -d "$SV_SNIFFLES_DIR" ]; then
    log_error "Sniffles2 results not found: $SV_SNIFFLES_DIR"
    log_error "Run Step 1A first: bash src/01_sv_calling/run_sniffles2_calling.sh"
    exit 1
fi

if [ ! -d "$SV_SVIM_DIR" ]; then
    log_error "SVIM results not found: $SV_SVIM_DIR"
    log_error "Run Step 1B first: bash src/01_sv_calling/run_svim_calling.sh"
    exit 1
fi

# Count VCF files
sniffles_count=$(find "$SV_SNIFFLES_DIR" -maxdepth 1 -name "*.vcf" -type f | wc -l || echo "0")
svim_count=$(find "$SV_SVIM_DIR" -maxdepth 1 -name "*.vcf" -type f | wc -l || echo "0")

if [ "$sniffles_count" -eq 0 ] || [ "$svim_count" -eq 0 ]; then
    log_error "Missing VCF files from Step 1"
    log_error "  Sniffles2 VCFs: $sniffles_count"
    log_error "  SVIM VCFs: $svim_count"
    exit 1
fi

log_info "Found $sniffles_count Sniffles2 VCFs and $svim_count SVIM VCFs"

# ============================================================================
# MERGE VCFs WITH SURVIVOR
# ============================================================================

log_info "============================================================="
log_info "SV Merging with SURVIVOR"
log_info "============================================================="

log_info "Merge parameters:"
log_info "  Distance: ${SURVIVOR_DISTANCE} bp"
log_info "  Min callers: ${SURVIVOR_MIN_CALLERS}"
log_info "  Min size: ${SURVIVOR_MIN_SIZE} bp"

echo ""

merged_count=0
failed_count=0

# Get list of all Sniffles VCF files
readarray -t sniffles_vcfs < <(find "$SV_SNIFFLES_DIR" -maxdepth 1 -name "*.vcf" -type f | sort)

for sniffles_vcf in "${sniffles_vcfs[@]}"; do

    # Get sample ID
    sample_id=$(basename "$sniffles_vcf" .vcf)

    # Corresponding SVIM VCF
    svim_vcf="${SV_SVIM_DIR}/${sample_id}.vcf"

    # Verify both VCFs exist
    if [ ! -f "$sniffles_vcf" ]; then
        log_warn "Sniffles VCF not found: $sniffles_vcf"
        ((failed_count++))
        continue
    fi

    if [ ! -f "$svim_vcf" ]; then
        log_warn "SVIM VCF not found: $svim_vcf"
        ((failed_count++))
        continue
    fi

    log_info "Processing: $sample_id"

    # Create temporary VCF list file
    vcf_list="${SV_MERGE_DIR}/${sample_id}_vcf_list.txt"
    output_vcf="${SV_MERGE_DIR}/${sample_id}_merged.vcf"
    log_file="${LOGS_DIR}/survivor/${sample_id}.log"

    # Write VCF list (required format for SURVIVOR)
    {
        echo "$sniffles_vcf"
        echo "$svim_vcf"
    } > "$vcf_list"

    log_debug "VCF list: $vcf_list"
    log_debug "Command: SURVIVOR merge $vcf_list $SURVIVOR_DISTANCE $SURVIVOR_MIN_CALLERS $SURVIVOR_SEQUENCE_TYPE 1 0 $SURVIVOR_MIN_SIZE $output_vcf"

    # Run SURVIVOR merge
    if SURVIVOR merge \
        "$vcf_list" \
        "$SURVIVOR_DISTANCE" \
        "$SURVIVOR_MIN_CALLERS" \
        "$SURVIVOR_SEQUENCE_TYPE" \
        1 \
        0 \
        "$SURVIVOR_MIN_SIZE" \
        "$output_vcf" \
        2>&1 | tee -a "$log_file"
    then
        log_info "[OK] Merge completed for $sample_id"
        ((merged_count++))
    else
        log_error "SURVIVOR merge failed for $sample_id"
        ((failed_count++))
        continue
    fi

    # ====================================================================
    # VERIFY OUTPUT AND GATHER STATISTICS
    # ====================================================================

    if [ ! -f "$output_vcf" ]; then
        log_error "Output VCF not created: $output_vcf"
        ((failed_count++))
        continue
    fi

    # Count SVs by type
    log_info "SV composition in merged VCF:"
    for svtype in DEL INS DUP INV BND TRA; do
        count=$(grep -v "^#" "$output_vcf" 2>/dev/null | grep "SVTYPE=${svtype}" | wc -l || echo "0")
        if [ "$count" -gt 0 ]; then
            log_info "  $svtype: $count"
        fi
    done

    # Total SV count
    total_count=$(grep -v "^#" "$output_vcf" 2>/dev/null | wc -l || echo "0")
    vcf_size=$(get_file_size "$output_vcf")
    log_info "  Total: $total_count SVs ($vcf_size)"

    # Clean up temporary VCF list file
    rm -f "$vcf_list"
    log_debug "Removed temporary file: $vcf_list"

    echo ""

done

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

log_info "============================================================="
log_info "SV Merge complete!"
log_info "============================================================="

log_info "Results:"
log_info "  Merged: $merged_count samples"
if [ $failed_count -gt 0 ]; then
    log_warn "  Failed: $failed_count samples"
fi

log_info "Output directory: $SV_MERGE_DIR"

echo ""

if [ $failed_count -eq 0 ] && [ $merged_count -gt 0 ]; then
    log_info "Next step: Validate merged SVs"
    log_info "  bash src/03_sv_validation/run_sv_validation.sh"
else
    log_error "Some samples failed. Please review logs in: ${LOGS_DIR}/survivor/"
    exit 1
fi

echo ""

################################################################################
# END OF SCRIPT
################################################################################
