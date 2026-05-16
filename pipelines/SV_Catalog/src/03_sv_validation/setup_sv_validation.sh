#!/bin/bash

################################################################################
#
# COWADAPT - Helper: Setup SV Validation Dependencies
#
# Installs and configures dependencies for structural variant validation.
# Sets up Python packages and reference tools required for SV validation steps.
#
# Usage:
#   bash src/03_sv_validation/setup_sv_validation.sh
#   THREADS=8 bash src/03_sv_validation/setup_sv_validation.sh
#
# Requirements:
#   - Python 3.6+
#   - samtools (for BAM indexing)
#   - bcftools (for VCF operations)
#
# Notes:
#   - Installs pysam and numpy for Python-based validation tools
#   - Verifies and indexes all BAM files in RAW_BAM_DIR
#   - Creates indexed BAM list for downstream validation
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

if ! command_exists python3; then
    log_error "Python3 not found in PATH"
    exit 1
fi

python3_version=$(python3 --version 2>&1 | awk '{print $2}')
log_info "Python version: $python3_version"

if ! command_exists samtools; then
    log_error "samtools not found in PATH"
    log_error "Install with: conda install -c bioconda samtools"
    exit 1
fi

if ! command_exists bcftools; then
    log_error "bcftools not found in PATH"
    log_error "Install with: conda install -c bioconda bcftools"
    exit 1
fi

# ============================================================================
# INSTALL PYTHON DEPENDENCIES
# ============================================================================

log_info "============================================================="
log_info "Setup SV Validation Dependencies"
log_info "============================================================="

log_info "Checking Python packages..."

# Check pysam
python3 -c "import pysam; print('pysam: OK')" 2>/dev/null || {
    log_warn "pysam not found, installing..."
    pip install pysam --break-system-packages 2>&1 | grep -v "already satisfied" || true
}

# Check numpy
python3 -c "import numpy; print('numpy: OK')" 2>/dev/null || {
    log_warn "numpy not found, installing..."
    pip install numpy --break-system-packages 2>&1 | grep -v "already satisfied" || true
}

log_info "[OK] Python dependencies verified"

echo ""

# ============================================================================
# VERIFY AND INDEX BAM FILES
# ============================================================================

log_info "Verifying BAM files in: $RAW_BAM_DIR"

if [ ! -d "$RAW_BAM_DIR" ]; then
    log_error "BAM directory not found: $RAW_BAM_DIR"
    exit 1
fi

# Find all BAM files
bam_list=$(find "$RAW_BAM_DIR" -maxdepth 1 -name "*.bam" -type f | sort)
bam_count=$(echo "$bam_list" | wc -l)

if [ "$bam_count" -eq 0 ]; then
    log_warn "No BAM files found in: $RAW_BAM_DIR"
    exit 0
fi

log_info "Found $bam_count BAM files"

# Check and create missing indices
missing_indices=0
while IFS= read -r bam; do
    if [ -z "$bam" ]; then
        continue
    fi

    bam_name=$(basename "$bam")

    if [ ! -f "${bam}.bai" ]; then
        log_info "Indexing: $bam_name"
        samtools index -@ "$THREADS" "$bam" 2>&1 | head -1
        ((missing_indices++))
    else
        log_debug "Index exists: $bam_name"
    fi
done <<< "$bam_list"

if [ "$missing_indices" -gt 0 ]; then
    log_info "[OK] Created $missing_indices new BAM indices"
else
    log_info "[OK] All BAM files are indexed"
fi

echo ""

# ============================================================================
# GENERATE BAM LIST FOR VALIDATION
# ============================================================================

mkdir -p "$VALIDATION_DIR"

bam_list_file="${VALIDATION_DIR}/bam_list.txt"
echo "$bam_list" > "$bam_list_file"

log_info "Generated BAM list: $bam_list_file"
log_info "  Total BAMs: $bam_count"

# Verify all indices
indices_ok=0
while IFS= read -r bam; do
    if [ -z "$bam" ]; then
        continue
    fi
    if [ -f "${bam}.bai" ]; then
        ((indices_ok++))
    fi
done <<< "$bam_list"

log_info "  Indexed BAMs: $indices_ok"

if [ "$indices_ok" -eq "$bam_count" ]; then
    log_info "[OK] All BAM files ready for validation"
else
    log_error "Some BAM files are missing indices!"
    exit 1
fi

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

log_info "============================================================="
log_info "SV Validation Setup Complete"
log_info "============================================================="

log_info "Ready to run SV validation:"
log_info "  bash src/03_sv_validation/run_sv_validation.sh"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
