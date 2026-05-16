#!/bin/bash

################################################################################
#
# COWADAPT - Helper: Map BovineHD Positions to ARS-UCD2.0
#
# Converts BovineHD SNP manifest coordinates to BED format for use with
# ARS-UCD2.0 reference assembly. Handles Illumina manifest conversion.
#
# Usage:
#   bash src/05_snp_extraction/map_bovhd_to_arsucd.sh <manifest_csv>
#   Example: bash src/05_snp_extraction/map_bovhd_to_arsucd.sh data/reference/BovineHD_B1.csv
#
# Output:
#   BED file: data/reference/bovine_hd_chip/bovineHD_ARS-UCD2.0.bed
#   Log file: <output_directory>/manifest_conversion.log
#
# Requirements:
#   - Python 3 with csv module (standard library)
#   - Illumina BovineHD manifest CSV file
#   - Columns: Chr, MapInfo (position), Name (SNP ID)
#
# Notes:
#   - Adds BTA prefix to chromosome names
#   - Converts MapInfo to 0-based coordinates for BED
#   - Skips invalid or missing coordinate entries
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
    log_error "Usage: bash src/05_snp_extraction/map_bovhd_to_arsucd.sh <manifest_csv>"
    log_error "Example: bash src/05_snp_extraction/map_bovhd_to_arsucd.sh data/reference/BovineHD_B1.csv"
    exit 1
fi

manifest_file="$1"

if [ ! -f "$manifest_file" ]; then
    log_error "Manifest file not found: $manifest_file"
    exit 1
fi

if ! command_exists python3; then
    log_error "Python3 not found in PATH"
    exit 1
fi

# ============================================================================
# INITIALIZE DIRECTORIES
# ============================================================================

mkdir -p "$(dirname "$BOVINE_HD_BED")"
mkdir -p "${LOGS_DIR}/snp_mapping"

# ============================================================================
# CONVERT MANIFEST TO BED
# ============================================================================

log_info "============================================================="
log_info "Converting BovineHD Manifest to BED Format"
log_info "============================================================="

log_info "Input manifest: $manifest_file"
log_info "Output BED: $BOVINE_HD_BED"

# Python script to convert Illumina manifest CSV to BED
python3 - "$manifest_file" "$BOVINE_HD_BED" <<'PYTHON_SCRIPT'
import csv
import sys

manifest = sys.argv[1]
output_bed = sys.argv[2]

snps_converted = 0
snps_invalid = 0
snps_skipped = 0

try:
    with open(manifest) as f, open(output_bed, "w") as out:
        # Try to read as DictReader (assumes header row)
        f.seek(0)

        # Detect delimiter (CSV or tab)
        first_line = f.readline()
        f.seek(0)

        if "\t" in first_line:
            delimiter = "\t"
        else:
            delimiter = ","

        reader = csv.DictReader(f, delimiter=delimiter)

        # Get fieldnames (case-insensitive matching)
        fieldnames = {k.lower(): k for k in reader.fieldnames} if reader.fieldnames else {}

        # Find the correct column names
        chr_col = None
        pos_col = None
        name_col = None

        for key in fieldnames:
            if "chr" in key.lower():
                chr_col = fieldnames[key]
            elif "pos" in key.lower() or "mapinfo" in key.lower():
                pos_col = fieldnames[key]
            elif "name" in key.lower() or "snpid" in key.lower():
                name_col = fieldnames[key]

        if not chr_col or not pos_col or not name_col:
            print(f"ERROR: Could not find required columns in manifest", file=sys.stderr)
            print(f"Available columns: {list(fieldnames.values())}", file=sys.stderr)
            sys.exit(1)

        print(f"Using columns: Chr={chr_col}, Pos={pos_col}, Name={name_col}")

        for row in reader:
            try:
                chrom = row.get(chr_col, "").strip()
                pos_str = row.get(pos_col, "").strip()
                name = row.get(name_col, "").strip()

                # Skip empty rows
                if not chrom or not pos_str or not name:
                    snps_skipped += 1
                    continue

                # Validate position is numeric
                if not pos_str.isdigit():
                    snps_invalid += 1
                    continue

                pos = int(pos_str)

                # Add BTA prefix if not present
                if not chrom.startswith("BTA"):
                    chrom = f"BTA{chrom}"

                # Write BED format (0-based coordinates)
                out.write(f"{chrom}\t{pos-1}\t{pos}\t{name}\n")
                snps_converted += 1

            except Exception as e:
                snps_invalid += 1
                continue

        print(f"Successfully converted: {snps_converted} SNPs")
        print(f"Invalid entries: {snps_invalid}")
        print(f"Skipped entries: {snps_skipped}")

except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)

PYTHON_SCRIPT

# ============================================================================
# VERIFY OUTPUT
# ============================================================================

echo ""

if [ ! -f "$BOVINE_HD_BED" ]; then
    log_error "BED file not created"
    exit 1
fi

bed_lines=$(wc -l < "$BOVINE_HD_BED")
log_info "[OK] BED file created: $BOVINE_HD_BED"
log_info "  SNPs in BED: $bed_lines"

# Show sample lines
log_info "Sample entries (first 5):"
head -5 "$BOVINE_HD_BED" | while read line; do
    log_info "  $line"
done

# Chromosome distribution
log_info "Chromosome distribution:"
cut -f1 "$BOVINE_HD_BED" | sort | uniq -c | awk '{print $2, $1}' | while read chrom count; do
    log_info "  $chrom: $count SNPs"
done

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

log_info "============================================================="
log_info "BovineHD Mapping Complete"
log_info "============================================================="

log_info "BED file ready for SNP extraction:"
log_info "  bash src/05_snp_extraction/extract_bovhd_snps.sh <vcf_file>"

echo ""

################################################################################
# END OF SCRIPT
################################################################################
