#!/bin/bash

################################################################################
#
# COWADAPT - Step 1B: SV Calling with SVIM
#
# Detects structural variants (SVs) from long-read BAM files using SVIM.
# Complements Sniffles2 for improved SV detection accuracy through concordance.
#
# Usage:
#   Single sample:  bash src/01_sv_calling/run_svim_calling.sh <bam_file>
#   All samples:    bash src/01_sv_calling/run_svim_calling.sh
#   With threads:   THREADS=16 bash src/01_sv_calling/run_svim_calling.sh
#
# Output:
#   VCF files:      results/sv_calls/svim/*.vcf
#   SVIM workspace: results/sv_calls/svim/<sample>/ (intermediate files)
#
# Note:
#   - SVIM uses more memory than Sniffles2, especially for large BAMs
#   - Runs sequentially within each sample (doesn't use all threads)
#   - Merging both Sniffles2 + SVIM calls improves reliability
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

if ! command_exists svim; then
    log_error "svim not found in PATH"
    log_error "Install with: conda install -c bioconda svim"
    exit 1
fi

if ! check_references; then
    log_error "Required reference files are missing!"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

init_directories

mkdir -p "$SV_SVIM_DIR"
mkdir -p "${LOGS_DIR}/svim"

# ============================================================================
# DETERMINE INPUT BAMS
# ============================================================================

if [ -n "${1:-}" ]; then
    # Specific BAM file provided as argument
    if [ ! -f "$1" ]; then
        log_error "BAM file not found: $1"
        exit 1
    fi
    readarray -t BAM_LIST < <(echo "$1")

else
    # Find all BAM files
    readarray -t BAM_LIST < <(find "$RAW_BAM_DIR" -maxdepth 1 -name "*.bam" -type f | sort)

    if [ ${#BAM_LIST[@]} -eq 0 ]; then
        log_error "No BAM files found in $RAW_BAM_DIR"
        log_error "Copy your BAM files to: $RAW_BAM_DIR"
        exit 1
    fi
fi

# ============================================================================
# PROCESS EACH BAM FILE
# ============================================================================

processed=0
failed=0

for bam_file in "${BAM_LIST[@]}"; do

    log_info "============================================================="
    log_info "Processing: $bam_file"
    log_info "============================================================="

    # Validate BAM file
    if [ ! -f "$bam_file" ]; then
        log_error "BAM file not found: $bam_file"
        ((failed++))
        continue
    fi

    # Verify BAM is indexed
    if ! verify_bam_index "$bam_file"; then
        log_error "Failed to index BAM: $bam_file"
        ((failed++))
        continue
    fi

    # Get sample name
    sample_id=$(get_sample_id "$bam_file")

    # Define output directory
    sample_workspace="${SV_SVIM_DIR}/${sample_id}"
    output_vcf="${sample_workspace}/variants.vcf"
    log_file="${LOGS_DIR}/svim/${sample_id}.log"

    log_info "Sample ID: $sample_id"
    log_info "Input BAM: $bam_file ($(get_file_size $bam_file))"
    log_info "Output workspace: $sample_workspace"
    log_info "Threads: $THREADS"

    # ========================================================================
    # PREPARE WORKSPACE
    # ========================================================================

    # SVIM requires empty output directory
    if [ -d "$sample_workspace" ]; then
        log_warn "Workspace already exists, removing: $sample_workspace"
        rm -rf "$sample_workspace"
    fi

    mkdir -p "$sample_workspace"

    # ========================================================================
    # RUN SVIM
    # ========================================================================

    log_info "Running SVIM..."
    log_debug "Command: svim alignment $sample_workspace $bam_file $REFERENCE_GENOME"

    if svim alignment \
        "$sample_workspace" \
        "$bam_file" \
        "$REFERENCE_GENOME" \
        --min_sv_length "$SVIM_MIN_LENGTH" \
        2>&1 | tee -a "$log_file"
    then
        log_info "[OK] SVIM completed successfully"
        ((processed++))
    else
        log_error "SVIM failed for $sample_id"
        log_error "See log: $log_file"
        ((failed++))
        continue
    fi

    # ========================================================================
    # VERIFY OUTPUT AND RENAME
    # ========================================================================

    if [ ! -f "$output_vcf" ]; then
        log_error "Output VCF not found: $output_vcf"
        ((failed++))
        continue
    fi

    # Copy final VCF to standard location for easier access
    final_vcf="${SV_SVIM_DIR}/${sample_id}.vcf"
    if [ "$output_vcf" != "$final_vcf" ]; then
        cp "$output_vcf" "$final_vcf"
        log_debug "Copied VCF: $final_vcf"
    fi

    # Count detected SVs
    sv_count=$(grep -v "^#" "$final_vcf" 2>/dev/null | wc -l || echo "0")
    vcf_size=$(get_file_size "$final_vcf")

    log_info "[OK] Output created"
    log_info "  VCF: $vcf_size ($sv_count SVs)"

    log_info "============================================================="
    echo ""

done

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

echo ""
log_info "SVIM calling complete!"
log_info "Processed: $processed samples"
if [ $failed -gt 0 ]; then
    log_warn "Failed: $failed samples"
fi

log_info "Output directory: $SV_SVIM_DIR"
echo ""

if [ $failed -eq 0 ] && [ $processed -gt 0 ]; then
    log_info "Next step: Merge Sniffles2 and SVIM calls"
    log_info "  bash src/02_sv_merge/run_survivor_merge.sh"
else
    log_warn "Some samples failed. Please review logs in: ${LOGS_DIR}/svim/"
    exit 1
fi

echo ""

################################################################################
# END OF SCRIPT
################################################################################
