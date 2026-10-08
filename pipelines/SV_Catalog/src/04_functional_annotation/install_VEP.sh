#!/bin/bash

################################################################################
#
# COWADAPT - Helper: Install and Setup VEP
#
# Downloads and configures Ensembl Variant Effect Predictor (VEP) cache
# for Bos taurus ARS-UCD2.0 assembly. Must run before functional annotation.
#
# Usage:
#   bash src/04_functional_annotation/install_and_run_vep.sh
#   THREADS=8 bash src/04_functional_annotation/install_and_run_vep.sh
#
# Output:
#   VEP cache directory with species data
#   Verification report
#
# Requirements:
#   - VEP installed (conda install -c bioconda ensembl-vep)
#   - 20+ GB disk space for cache
#   - Internet connection for initial download
#
# Notes:
#   - First run downloads ~15-20 GB of data
#   - Subsequent runs verify existing cache
#   - Caches ARS-UCD2.0 specific data
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

if ! command_exists vep; then
    log_error "VEP not found in PATH"
    log_error "Install with: conda install -c bioconda ensembl-vep"
    exit 1
fi

if ! command_exists vep_install; then
    log_error "vep_install utility not found"
    log_error "Usually comes with ensembl-vep installation"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

log_info "============================================================="
log_info "VEP Cache Setup for Bos taurus ARS-UCD2.0"
log_info "============================================================="

log_info "Cache directory: $VEP_CACHE_DIR"

# Check if cache already exists
if [ -d "$VEP_CACHE_DIR/bos_taurus" ]; then
    log_info "[OK] VEP cache already exists"

    cache_size=$(du -sh "$VEP_CACHE_DIR" 2>/dev/null | awk '{print $1}' || echo "unknown")
    log_info "  Cache size: $cache_size"

    # Verify cache integrity
    species_dir="$VEP_CACHE_DIR/bos_taurus"
    cache_files=$(find "$species_dir" -type f 2>/dev/null | wc -l || echo "0")
    log_info "  Cache files: $cache_files"

    if [ "$cache_files" -gt 100 ]; then
        log_info "[OK] Cache appears valid"
        echo ""
        log_info "Next step: Run VEP annotation"
        log_info "  bash src/04_functional_annotation/run_vep_annotation.sh"
        echo ""
        exit 0
    else
        log_warn "Cache appears incomplete, re-downloading..."
    fi
else
    log_info "Cache not found, downloading..."
fi

echo ""

# ============================================================================
# CREATE CACHE DIRECTORY
# ============================================================================

mkdir -p "$VEP_CACHE_DIR"
log_info "Created cache directory: $VEP_CACHE_DIR"

echo ""

# ============================================================================
# DOWNLOAD VEP CACHE
# ============================================================================

log_info "============================================================="
log_info "Downloading VEP Cache (this may take 15-30 minutes)"
log_info "============================================================="

log_info "Parameters:"
log_info "  Species: $VEP_SPECIES"
log_info "  Assembly: $VEP_ASSEMBLY"
log_info "  Cache dir: $VEP_CACHE_DIR"

echo ""
log_info "Starting download... (this will run in background)"

# Run vep_install to download cache
# Using AUTO cf for automated, force download
if vep_install \
    --AUTO cf \
    --SPECIES "$VEP_SPECIES" \
    --ASSEMBLY "$VEP_ASSEMBLY" \
    --CACHEDIR "$VEP_CACHE_DIR/" \
    --NO_HTSLIB 0 \
    2>&1 | tee "${LOGS_DIR}/vep_install.log"
then
    log_info "[OK] VEP cache download completed"
else
    log_error "VEP cache download failed"
    log_error "See log: ${LOGS_DIR}/vep_install.log"
    exit 1
fi

echo ""

# ============================================================================
# VERIFY CACHE
# ============================================================================

log_info "============================================================="
log_info "Verifying Cache Installation"
log_info "============================================================="

species_cache="$VEP_CACHE_DIR/bos_taurus"

if [ ! -d "$species_cache" ]; then
    log_error "Species cache directory not found: $species_cache"
    exit 1
fi

log_info "Cache directory contents:"
ls -lh "$species_cache" 2>/dev/null | head -20 | while read line; do
    log_info "  $line"
done

cache_size=$(du -sh "$species_cache" 2>/dev/null | awk '{print $1}' || echo "unknown")
cache_files=$(find "$species_cache" -type f 2>/dev/null | wc -l || echo "0")

log_info "[OK] Cache verified"
log_info "  Size: $cache_size"
log_info "  Files: $cache_files"

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

log_info "============================================================="
log_info "VEP Setup Complete"
log_info "============================================================="

log_info "VEP is ready for functional annotation"
log_info "Next step: Run VEP annotation"
log_info "  bash src/04_functional_annotation/run_vep_annotation.sh"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
