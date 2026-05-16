#!/bin/bash

################################################################################
#
# COWADAPT - Step 1A: SV Calling with Sniffles2
#
# Detects structural variants (SVs) from long-read BAM files using Sniffles2.
# Can run on local machine or HPC cluster (SLURM/SGE).
#
# Usage:
#   Single sample:  bash src/01_sv_calling/run_sniffles2_calling.sh <bam_file>
#   All samples:    bash src/01_sv_calling/run_sniffles2_calling.sh
#   With threads:   THREADS=32 bash src/01_sv_calling/run_sniffles2_calling.sh
#
# Output:
#   VCF files:      results/sv_calls/sniffles2/*.vcf
#   Sniffles data:  results/sv_calls/sniffles2/*.snf (for merging)
#
################################################################################

set -euo pipefail

# ============================================================================
# SOURCE CONFIGURATION
# ============================================================================
# Find project root and load central configuration

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

if ! command_exists sniffles; then
    log_error "sniffles not found in PATH"
    log_error "Install with: conda install -c bioconda sniffles2"
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

mkdir -p "$SV_SNIFFLES_DIR"
mkdir -p "${LOGS_DIR}/sniffles2"

# ============================================================================
# DETERMINE INPUT BAMS
# ============================================================================

# Get input BAM file(s)
if [ -n "${1:-}" ]; then
    # Specific BAM file provided as argument
    if [ ! -f "$1" ]; then
        log_error "BAM file not found: $1"
        exit 1
    fi
    readarray -t BAM_LIST < <(echo "$1")

elif [ -n "${SLURM_ARRAY_TASK_ID:-}" ]; then
    # Running as SLURM job array
    readarray -t BAM_LIST < <(find "$RAW_BAM_DIR" -maxdepth 1 -name "*.bam" -type f | sort)

    if [ ${#BAM_LIST[@]} -eq 0 ]; then
        log_error "No BAM files found in $RAW_BAM_DIR"
        exit 1
    fi

    if [ $SLURM_ARRAY_TASK_ID -ge ${#BAM_LIST[@]} ]; then
        log_error "Array index $SLURM_ARRAY_TASK_ID out of range (${#BAM_LIST[@]} files)"
        exit 1
    fi

    BAM_FILE="${BAM_LIST[$SLURM_ARRAY_TASK_ID]}"
    readarray -t BAM_LIST < <(echo "$BAM_FILE")

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

for bam_file in "${BAM_LIST[@]}"; do

    log_info "============================================================="
    log_info "Processing: $bam_file"
    log_info "============================================================="

    # Validate BAM file
    if [ ! -f "$bam_file" ]; then
        log_error "BAM file not found: $bam_file"
        continue
    fi

    # Verify BAM is indexed
    if ! verify_bam_index "$bam_file"; then
        log_error "Failed to index BAM: $bam_file"
        continue
    fi

    # Get sample name
    sample_id=$(get_sample_id "$bam_file")

    # Define output files
    output_vcf="${SV_SNIFFLES_DIR}/${sample_id}.vcf"
    output_snf="${SV_SNIFFLES_DIR}/${sample_id}.snf"
    log_file="${LOGS_DIR}/sniffles2/${sample_id}.log"

    log_info "Sample ID: $sample_id"
    log_info "Input BAM: $bam_file ($(get_file_size $bam_file))"
    log_info "Output VCF: $output_vcf"
    log_info "Threads: $THREADS"

    # ========================================================================
    # RUN SNIFFLES2
    # ========================================================================

    log_info "Running Sniffles2..."
    log_debug "Command: sniffles --input $bam_file --vcf $output_vcf --snf $output_snf"

    if sniffles \
        --input "$bam_file" \
        --vcf "$output_vcf" \
        --snf "$output_snf" \
        --allow-overwrite \
        --threads "$THREADS" \
        --minsvlen "$SNIFFLES_MIN_SV_LENGTH" \
        --mapq "$SNIFFLES_MAPQ" \
        --reference "$REFERENCE_GENOME" \
        2>&1 | tee -a "$log_file"
    then
        log_info "[OK] Sniffles2 completed successfully"
    else
        log_error "Sniffles2 failed for $sample_id"
        log_error "See log: $log_file"
        continue
    fi

    # ========================================================================
    # VERIFY OUTPUT
    # ========================================================================

    if [ ! -f "$output_vcf" ]; then
        log_error "Output VCF not created: $output_vcf"
        continue
    fi

    if [ ! -f "$output_snf" ]; then
        log_error "Output SNF not created: $output_snf"
        continue
    fi

    # Count detected SVs
    sv_count=$(grep -v "^#" "$output_vcf" 2>/dev/null | wc -l || echo "0")
    vcf_size=$(get_file_size "$output_vcf")
    snf_size=$(get_file_size "$output_snf")

    log_info "[OK] Output files created"
    log_info "  VCF: $vcf_size ($sv_count SVs)"
    log_info "  SNF: $snf_size"

    # ========================================================================
    # PROCESS MULTIPLE CALLERS IN ARRAY MODE
    # ========================================================================

    # In SLURM array mode, process only one sample
    if [ -n "${SLURM_ARRAY_TASK_ID:-}" ]; then
        log_info "SLURM array job mode - stopping after first file"
        break
    fi

    log_info "============================================================="
    echo ""

done

# ============================================================================
# COMPLETION
# ============================================================================

log_info "Sniffles2 calling complete!"
log_info "Output directory: $SV_SNIFFLES_DIR"
echo ""
log_info "Next step: Run SVIM calling"
log_info "  bash src/01_sv_calling/run_svim_calling.sh"
echo ""

################################################################################
# END OF SCRIPT
################################################################################
