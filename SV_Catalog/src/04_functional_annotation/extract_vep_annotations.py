#!/usr/bin/env python3
# extract_vep_annotations.py
# Converts the VEP CSQ field into a readable TSV table
# Usage: python3 2.1.extract_vep_annotations.py vep_output/svs_anotadas5kb.vcf sv_annotations.tsv

import sys
import re

def parse_info(info_str):
    info_dict = {}
    for item in info_str.split(";"):
        if "=" in item:
            key, value = item.split("=", 1)
            info_dict[key] = value
    return info_dict

def main():
    vcf_input  = sys.argv[1]
    tsv_output = sys.argv[2]

    # CSQ fields to extract (defined in the VEP header order)
    csq_fields = None
    desired_fields = [
        "Consequence", "SYMBOL", "Gene", "Feature_type",
        "BIOTYPE", "EXON", "INTRON", "HGVSc", "IMPACT",
        "DISTANCE", "STRAND", "Existing_variation"
    ]

    with open(vcf_input) as vcf, open(tsv_output, "w") as tsv:

        # Output header
        tsv.write(
            "CHROM\tPOS\tID\tSVTYPE\tSVLEN\t" +
            "\t".join(desired_fields) + "\n"
        )

        for line in vcf:

            # Extract CSQ field structure from the VEP header
            if line.startswith("##INFO=<ID=CSQ"):
                match = re.search(r'Format: ([^"]+)"', line)
                if match:
                    csq_fields = match.group(1).split("|")
                continue

            if line.startswith("#"):
                continue

            cols = line.strip().split("\t")

            if len(cols) < 8:
                continue

            chrom = cols[0]
            pos   = cols[1]
            var_id = cols[2]

            info = parse_info(cols[7])

            svtype = info.get("SVTYPE", ".")
            svlen  = info.get("SVLEN", ".")

            csq_raw = info.get("CSQ", "")

            if not csq_raw or not csq_fields:
                # SV without annotation (distant intergenic region)
                tsv.write(
                    f"{chrom}\t{pos}\t{var_id}\t{svtype}\t{svlen}\t" +
                    "\t".join(["."] * len(desired_fields)) + "\n"
                )
                continue

            # Get the first annotation (--pick ensures it is the most severe)
            first_csq = csq_raw.split(",")[0].split("|")

            csq_dict = dict(zip(csq_fields, first_csq))

            values = [csq_dict.get(field, ".") for field in desired_fields]

            tsv.write(
                f"{chrom}\t{pos}\t{var_id}\t{svtype}\t{svlen}\t" +
                "\t".join(values) + "\n"
            )

    print(f"Annotations extracted: {tsv_output}")

if __name__ == "__main__":
    main()