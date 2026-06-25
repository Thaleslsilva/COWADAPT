#!/bin/bash

#############################################################################
###
###                           COWADAPT PROJECT
### Trim nanopore reads with Porechop v.0.2.4 and compress with gzip
###
### v.26.06.25                                          Thales de Lima Silva
###
#############################################################################

# Input files
FILES=(
  "250415_PAW46500_doradov0.9.6_SUP_simplex.fastq"
  "250415_PBA89745_doradov0.9.6_SUP_simplex.fastq"
  ...
)

# Output names
NAMES=(
  "ONT_001"
  "ONT_002"
  ...
)

# Check consistency
if [ "${#FILES[@]}" -ne "${#NAMES[@]}" ]; then
    echo "ERROR: Number of FASTQ files and names do not match."
    exit 1
fi

# Number of simultaneous jobs
MAX_JOBS=10

for i in "${!FILES[@]}"; do
(
    infile="${FILES[$i]}"
    sample="${NAMES[$i]}"

    echo "Processing ${infile} -> ${sample}"

    porechop \
        -i "${infile}" \
        -t 10 \
        -o "${sample}_porechop.fastq"

    pigz -p 10 "${sample}_porechop.fastq"

    echo "Finished ${sample}"
) &

    while [ "$(jobs -r | wc -l)" -ge "$MAX_JOBS" ]; do
        sleep 5
    done

done

wait

echo "All samples processed successfully!"

# Run Porechop and compression for each file
for i in "${!FILES[@]}"; do
  arquivo="${FILES[$i]}"
  prefixo="${PREFIXES[$i]}"

  # Run Porechop
  porechop -i "$arquivo" -t 100 -o "${prefixo}_porechop.fq"
done

# Wait for all Porechop processes to finish
wait

# Compress output files with gzip
for prefixo in "${PREFIXES[@]}"; do
  pigz -p 100 -c "${prefixo}_porechop.fq" > "${prefixo}_porechop.fq.gz"
done

# Wait for all gzip processes to finish
wait

echo "Processing completed!"
