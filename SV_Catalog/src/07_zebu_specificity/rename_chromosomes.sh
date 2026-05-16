#!/bin/bash

################################################################################
#
# COWADAPT - Helper: Rename Chromosomes in VCF
#
# Renames chromosome IDs in VCF files to alternative formats (e.g., BTA14
# to NC_037328.1) for compatibility with different reference assemblies
# or downstream tools.
#
# Usage:
#   bash src/07_zebu_specificity/rename_chromosomes.sh <input_vcf> <mapping_file>
#   Example: bash src/07_zebu_specificity/rename_chromosomes.sh results/validation/sample1_validated.vcf data/reference/chr_rename.txt
#
# Mapping file format (tab-separated, one per line):
#   old_name	new_name
#   BTA1		NC_037324.1
#   BTA2		NC_037325.1
#   (etc)
#
# Output:
#   Renamed VCF:     <input_name>_renamed.vcf.gz
#   Index:           <input_name>_renamed.vcf.gz.tbi
#   Log:             From LOGS_DIR/chr_rename/
#
# Requirements:
#   - bcftools (for chromosome renaming)
#   - tabix (for VCF indexing)
#   - Chromosome mapping file
#
# Notes:
#   - Creates indexed VCF output
#   - Preserves all variant data
#   - Can process multiple VCFs with same mapping
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

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    log_error "Usage: bash src/07_zebu_specificity/rename_chromosomes.sh <input_vcf> <mapping_file>"
    log_error "Example: bash src/07_zebu_specificity/rename_chromosomes.sh results/validation/sample1_validated.vcf data/reference/chr_rename.txt"
    exit 1
fi

input_vcf="$1"
mapping_file="$2"

if [ ! -f "$input_vcf" ]; then
    log_error "Input VCF not found: $input_vcf"
    exit 1
fi

if [ ! -f "$mapping_file" ]; then
    log_error "Mapping file not found: $mapping_file"
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
# INITIALIZE DIRECTORIES
# ============================================================================

mkdir -p "${LOGS_DIR}/chr_rename"

# ============================================================================
# PREPARE OUTPUT PATHS
# ============================================================================

log_info "============================================================="
log_info "Rename Chromosomes in VCF"
log_info "============================================================="

# Get directory and base name
input_dir=$(dirname "$input_vcf")
input_name=$(basename "$input_vcf" .vcf)
if [ "$input_name" = "$(basename $input_vcf)" ]; then
    input_name=$(basename "$input_vcf" .vcf.gz)
fi

output_vcf="${input_dir}/${input_name}_renamed.vcf"
output_vcf_gz="${output_vcf}.gz"
log_file="${LOGS_DIR}/chr_rename/${input_name}.log"

log_info "Input VCF: $input_vcf"
log_info "Mapping file: $mapping_file"
log_info "Output VCF: $output_vcf_gz"

echo ""

# ============================================================================
# VERIFY MAPPING FILE FORMAT
# ============================================================================

log_info "Validating mapping file..."

line_count=$(wc -l < "$mapping_file")
log_info "Mapping entries: $line_count"

# Show first few entries
log_info "Sample mappings:"
head -3 "$mapping_file" | while read line; do
    log_info "  $line"
done

echo ""

# ============================================================================
# RENAME CHROMOSOMES
# ============================================================================

log_info "Renaming chromosomes..."
log_debug "Command: bcftools annotate --rename-chrs $mapping_file $input_vcf"

if bcftools annotate \
    --rename-chrs "$mapping_file" \
    "$input_vcf" \
    -Ov \
    -o "$output_vcf" \
    2>&1 | tee -a "$log_file"
then
    log_info "[OK] Chromosome renaming completed"
else
    log_error "bcftools annotate failed"
    log_error "See log: $log_file"
    exit 1
fi

# ============================================================================
# COMPRESS AND INDEX
# ============================================================================

log_info "Compressing VCF..."

if bgzip -f "$output_vcf" 2>&1 | tee -a "$log_file"; then
    log_info "[OK] VCF compressed"
else
    log_error "bgzip compression failed"
    exit 1
fi

log_info "Indexing VCF..."

if tabix -p vcf "$output_vcf_gz" 2>&1 | tee -a "$log_file"; then
    log_info "[OK] VCF indexed"
else
    log_error "tabix indexing failed"
    exit 1
fi

# ============================================================================
# VERIFY OUTPUT
# ============================================================================

if [ ! -f "$output_vcf_gz" ]; then
    log_error "Output VCF not created: $output_vcf_gz"
    exit 1
fi

log_info "[OK] Output VCF verified"

# Show chromosome names
log_info "Renamed chromosomes:"
bcftools view "$output_vcf_gz" -h | grep "^#CHROM" | cut -f1 | sort -u | while read chr; do
    log_info "  $chr"
done

# Count variants
vcf_size=$(get_file_size "$output_vcf_gz")
variant_count=$(bcftools query -f '.\n' "$output_vcf_gz" 2>/dev/null | wc -l || echo "0")

log_info "Output statistics:"
log_info "  Size: $vcf_size"
log_info "  Variants: $variant_count"

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

log_info "============================================================="
log_info "Chromosome Renaming Complete"
log_info "============================================================="

log_info "Renamed VCF: $output_vcf_gz"
log_info "Index: ${output_vcf_gz}.tbi"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
