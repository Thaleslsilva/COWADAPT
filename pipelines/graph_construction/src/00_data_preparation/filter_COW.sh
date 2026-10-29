#!/bin/bash

set -euo pipefail

echo "Starting filtering and renaming process..."

for fasta in COWADAPT_01*.fasta; do

    echo "Processing: $fasta"

    # Extract sample name from filename
    sample=$(basename "$fasta" .fasta)

    output_fasta="${sample}.0.fasta"
    output_gz="${output_fasta}.gz"

    awk -v SAMPLE="$sample" '
    /^>/{
        header=$0
        sub(/^>/,"",header)

        split(header,a,"#")

        # Expect pattern:
        # D01A220B#1#<chr>#<fragment>_RagTag

        if(length(a) >= 4){

            chr=a[3]

            if(chr ~ /^[0-9]+$/ && chr >=1 && chr <=29){

                # Extract fragment part (everything after third #)
                fragment=a[4]

                # Reconstruct new header
                printf(">%s#0#chr%s#%s\n", SAMPLE, chr, fragment)

                keep=1
            } else {
                keep=0
            }

        } else {
            keep=0
        }

        next
    }

    keep{print}
    ' "$fasta" > "$output_fasta"

    echo "Compressing with pbgzip..."
    pbgzip -n 32 -f "$output_fasta"

    echo "Indexing with samtools faidx..."
    samtools faidx "$output_gz"

    echo "Finished: $output_gz"
    echo "--------------------------------------------"

done

echo "All files processed successfully."