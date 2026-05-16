#!/usr/bin/env python3
# sv_genotype_to_biallelic_vcf.py
# Converts SV genotypes into a biallelic VCF (A/T) compatible with plink2
# Usage: python3 sv_genotype_to_biallelic_vcf.py validated_final_svs.vcf biallelic_svs.vcf

import sys
import re

def main():

    vcf_input  = sys.argv[1]
    vcf_output = sys.argv[2]

    with open(vcf_input) as f_in, open(vcf_output, "w") as f_out:

        samples = []

        for line in f_in:

            # Rewrite minimal header compatible with plink2
            if line.startswith("##"):
                f_out.write(line)
                continue

            if line.startswith("#CHROM"):
                cols = line.strip().split("\t")
                samples = cols[9:]
                f_out.write(line)
                continue

            cols = line.strip().split("\t")

            if len(cols) < 9:
                continue

            chrom = cols[0]
            pos   = cols[1]
            var_id = cols[2]
            info  = cols[7]
            fmt   = cols[8]
            genotypes = cols[9:]

            # Extract SVTYPE from INFO
            svtype = "SV"

            match = re.search(r'SVTYPE=(\w+)', info)

            if match:
                svtype = match.group(1)

            # Replace symbolic alleles with A (REF) and T (ALT)
            # for plink2 compatibility
            ref_allele = "A"
            alt_allele = "T"

            # Ensure FORMAT contains GT as the first field
            fmt_fields = fmt.split(":")
            gt_index = fmt_fields.index("GT") if "GT" in fmt_fields else 0

            new_genotypes = []

            for genotype_field in genotypes:

                gt_values = genotype_field.split(":")
                gt_raw = gt_values[gt_index] if gt_index < len(gt_values) else "./."

                # Normalize genotype separator
                gt_normalized = gt_raw.replace("|", "/")

                # Preserve missing, heterozygous, and homozygous genotypes
                if gt_normalized in ("./.", ".", "0/0", "0/1", "1/0", "1/1"):

                    new_genotypes.append(
                        gt_normalized + (
                            ":" + ":".join(gt_values[1:])
                            if len(gt_values) > 1 else ""
                        )
                    )

                else:
                    new_genotypes.append("./.")

            # Build new ID - includes SVTYPE for traceability
            new_id = (
                f"{var_id}_{svtype}"
                if var_id != "."
                else f"SV_{chrom}_{pos}_{svtype}"
            )

            f_out.write(
                f"{chrom}\t{pos}\t{new_id}\t"
                f"{ref_allele}\t{alt_allele}\t.\t.\t"
                f"SVTYPE={svtype}\t"
                f"{fmt}\t"
                f"{chr(9).join(new_genotypes)}\n"
            )

    print(f"Conversion completed: {vcf_output}")

if __name__ == "__main__":
    main()