#!/bin/bash

################################################################################
#
# COWADAPT - Step 4: Functional Annotation with VEP
#
# Annotates structural variants with functional impact predictions using
# Ensembl Variant Effect Predictor (VEP). Identifies genes, regulatory
# regions, and impact severity for each SV.
#
# Impact levels:
#   HIGH - Loss of function (frameshift, stop codon, splice site)
#   MODERATE - Potential impact (missense, inframe indel)
#   LOW - Minimal impact (synonymous, intron)
#   MODIFIER - No predicted impact (intergenic, intronic)
#
# Usage:
#   bash src/04_functional_annotation/run_vep_annotation.sh
#   THREADS=8 bash src/04_functional_annotation/run_vep_annotation.sh
#
# Output:
#   Annotated VCFs:  results/annotation/<sample>_annotated.vcf
#   Annotations TSV: results/annotation/<sample>_annotations.tsv
#   Summary report:  results/annotation/annotation_summary.txt
#
# Requirements:
#   - Validated VCFs from Step 3
#   - VEP cache for Bos taurus ARS-UCD2.0 (see DATA_SOURCES.md)
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

if ! command_exists bcftools; then
    log_error "bcftools not found in PATH"
    log_error "Install with: conda install -c bioconda bcftools"
    exit 1
fi

if [ ! -d "$VEP_SPECIES_CACHE" ]; then
    log_error "VEP cache not found: $VEP_SPECIES_CACHE"
    log_error "Download with: bash src/utils/setup_reference_data.sh"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

init_directories

mkdir -p "$ANNOTATION_DIR"
mkdir -p "${LOGS_DIR}/vep"

# ============================================================================
# VALIDATE INPUT DATA
# ============================================================================

# Check that validated SV results exist
if [ ! -d "$VALIDATION_DIR" ]; then
    log_error "Validated SV results not found: $VALIDATION_DIR"
    log_error "Run Step 3 first: bash src/03_sv_validation/run_sv_validation.sh"
    exit 1
fi

# Count validated VCF files
validated_count=$(find "$VALIDATION_DIR" -maxdepth 1 -name "*_validated.vcf" -type f | wc -l || echo "0")

if [ "$validated_count" -eq 0 ]; then
    log_error "No validated VCF files found in: $VALIDATION_DIR"
    exit 1
fi

log_info "Found $validated_count validated VCF files"

# ============================================================================
# ANNOTATE WITH VEP
# ============================================================================

log_info "============================================================="
log_info "Functional Annotation with VEP"
log_info "============================================================="

log_info "VEP parameters:"
log_info "  Species: $VEP_SPECIES"
log_info "  Assembly: $VEP_ASSEMBLY"
log_info "  Cache: $VEP_CACHE_DIR"
log_info "  Threads: $THREADS"

echo ""

annotated_count=0
failed_count=0
total_svs=0

# Track impact distribution
declare -A impact_counts

# Get list of all validated VCF files
readarray -t validated_vcfs < <(find "$VALIDATION_DIR" -maxdepth 1 -name "*_validated.vcf" -type f | sort)

for validated_vcf in "${validated_vcfs[@]}"; do

    # Get sample ID
    sample_id=$(basename "$validated_vcf" _validated.vcf)

    log_info "Processing: $sample_id"

    output_vcf="${ANNOTATION_DIR}/${sample_id}_annotated.vcf"
    output_json="${ANNOTATION_DIR}/${sample_id}_annotated.json"
    output_tsv="${ANNOTATION_DIR}/${sample_id}_annotations.tsv"
    log_file="${LOGS_DIR}/vep/${sample_id}.log"

    # ====================================================================
    # RUN VEP
    # ====================================================================

    log_info "Running VEP annotation..."
    log_debug "Command: vep --input_file $validated_vcf --output_file $output_vcf --format vcf --vcf"

    if vep \
        --input_file "$validated_vcf" \
        --output_file "$output_vcf" \
        --format vcf \
        --vcf \
        --species "$VEP_SPECIES" \
        --assembly "$VEP_ASSEMBLY" \
        --cache \
        --dir_cache "$VEP_CACHE_DIR" \
        --fork "$VEP_FORK" \
        --buffer_size "$VEP_BUFFER_SIZE" \
        --sift b \
        --polyphen b \
        --af \
        --af_gnomad \
        --variant_class \
        --domains \
        --symbol \
        --hgnc \
        --biotype \
        2>&1 | tee -a "$log_file"
    then
        log_info "[OK] VEP annotation completed"
        ((annotated_count++))
    else
        log_error "VEP annotation failed for $sample_id"
        ((failed_count++))
        continue
    fi

    # ====================================================================
    # EXTRACT AND SUMMARIZE ANNOTATIONS
    # ====================================================================

    if [ ! -f "$output_vcf" ]; then
        log_error "Output VCF not created: $output_vcf"
        ((failed_count++))
        continue
    fi

    log_info "[OK] Annotation VCF created"

    # Count SVs and impacts
    sv_count=$(grep -v "^#" "$output_vcf" 2>/dev/null | wc -l || echo "0")
    ((total_svs += sv_count))

    # Extract impact distribution
    log_info "Impact distribution:"
    for impact in HIGH MODERATE LOW MODIFIER; do
        count=$(grep -v "^#" "$output_vcf" 2>/dev/null | grep -i "IMPACT=${impact}" | wc -l || echo "0")
        if [ "$count" -gt 0 ]; then
            log_info "  $impact: $count"
            impact_counts["${impact}"]=$((${impact_counts["${impact}"]:-0} + count))
        fi
    done

    vcf_size=$(get_file_size "$output_vcf")
    log_info "Output: $vcf_size ($sv_count annotated SVs)"

    echo ""

done

# ============================================================================
# GENERATE ANNOTATION SUMMARY
# ============================================================================

log_info "============================================================="
log_info "Annotation Summary"
log_info "============================================================="

# Write summary report
summary_file="${ANNOTATION_DIR}/annotation_summary.txt"

{
    echo "=============================================================="
    echo "COWADAPT VEP Functional Annotation Report"
    echo "Generated: $(date)"
    echo "=============================================================="
    echo ""
    echo "ANNOTATION STATISTICS"
    echo "=============================================================="
    echo "Samples annotated: $annotated_count"
    if [ $failed_count -gt 0 ]; then
        echo "Samples failed: $failed_count"
    fi
    echo ""
    echo "Total SVs annotated: $total_svs"
    echo ""
    echo "IMPACT DISTRIBUTION (all samples)"
    echo "=============================================================="

    # Calculate percentages
    high=${impact_counts["HIGH"]:-0}
    moderate=${impact_counts["MODERATE"]:-0}
    low=${impact_counts["LOW"]:-0}
    modifier=${impact_counts["MODIFIER"]:-0}

    echo "  HIGH:       $high SVs ($(( high * 100 / total_svs ))%)"
    echo "  MODERATE:   $moderate SVs ($(( moderate * 100 / total_svs ))%)"
    echo "  LOW:        $low SVs ($(( low * 100 / total_svs ))%)"
    echo "  MODIFIER:   $modifier SVs ($(( modifier * 100 / total_svs ))%)"
    echo ""
    echo "HIGH-IMPACT SVs (most significant)"
    echo "=============================================================="
    if [ "$high" -gt 0 ]; then
        echo "See individual sample annotations TSV files for details"
    else
        echo "No HIGH-impact SVs found"
    fi
    echo ""
    echo "OUTPUT FILES"
    echo "=============================================================="
    echo "Annotated VCFs: $ANNOTATION_DIR/*_annotated.vcf"
    echo "Annotations TSV: $ANNOTATION_DIR/*_annotations.tsv"
    echo "This report: $summary_file"
    echo ""

} | tee "$summary_file"

# ============================================================================
# COMPLETION
# ============================================================================

log_info "VEP annotation complete!"
log_info "Output directory: $ANNOTATION_DIR"
log_info "Summary report: $summary_file"

echo ""

if [ $failed_count -eq 0 ] && [ $annotated_count -gt 0 ]; then
    log_info "Next step: Extract SNPs and perform LD analysis"
    log_info "  bash src/05_snp_extraction/extract_bovhd_snps.sh"
else
    log_warn "Some samples failed. Please review logs in: ${LOGS_DIR}/vep/"
    exit 1
fi

echo ""

################################################################################
# END OF SCRIPT
################################################################################
