#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as errors
# Catch pipeline errors
set -euo pipefail

# Loop over all FASTA files in the current directory
for fasta in *.fasta; do

    echo "Processing: $fasta"

    # Remove .fasta extension to build output name
    base=$(basename "$fasta" .fasta)

    # Define temporary and final output names
    output_fasta="${base}_autoss.fasta"
    output_gz="${output_fasta}.gz"

    # Filter and rename contigs:
    # - Keep only contigs with numeric IDs between 1 and 29
    # - Preserve everything before the last "#" field
    # - Rename final field to chr01-chr29 (zero padded)
    awk '
    /^>/{
        header=$0
        sub(/^>/,"",header)

        # Split header by "#"
        n=split(header,a,"#")

        # Expect pattern like: prefix#hap#contig
        if(n>=3){
            contig_num=a[n]

            # Keep only numeric contigs between 1 and 29
            if(contig_num ~ /^[0-9]+$/ && contig_num >=1 && contig_num <=29){

                # Reconstruct prefix (everything except last field)
                prefix=a[1]
                for(i=2;i<n;i++){
                    prefix=prefix"#"a[i]
                }

                # Print renamed header with zero-padded chromosome number
                printf(">%s#chr%02d\n", prefix, contig_num)
                keep=1
            } else {
                keep=0
            }
        } else {
            keep=0
        }
        next
    }

    # Print sequence lines only if header was kept
    keep{print}
    ' "$fasta" > "$output_fasta"

    echo "Compressing with bgzip: $output_gz"

    # Compress using bgzip (block gzip format)
    bgzip -f "$output_fasta"

    echo "Indexing compressed FASTA with samtools faidx"

    # Index the compressed FASTA
    samtools faidx "$output_gz"

    echo "Finished: $output_gz"
    echo "--------------------------------------------"

done

echo "All FASTA files processed successfully."