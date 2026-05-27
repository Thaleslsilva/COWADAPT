#!/bin/bash

#############################################################################
###
###                           COWADAPT PROJECT
### Trim nanopore reads with Porechop v.0.2.4 and compress with gzip
###
### v.24.10.24                                          Thales de Lima Silva
###
#############################################################################

# List of prefixes
PREFIXES=(
  COWADAPT_012 COWADAPT_001 COWADAPT_015 COWADAPT_018
  COWADAPT_004 COWADAPT_002 COWADAPT_008 COWADAPT_010
  COWADAPT_009 COWADAPT_005 COWADAPT_003 COWADAPT_006
  COWADAPT_020 COWADAPT_023 COWADAPT_017 COWADAPT_019
  COWADAPT_014 COWADAPT_013 COWADAPT_011 COWADAPT_016
)

# Check if number of files matches number of prefixes
FILES=(*.fq.gz)
if [ "${#FILES[@]}" -ne "${#PREFIXES[@]}" ]; then
  echo "Number of files (.fq.gz) does not match number of provided prefixes."
  exit 1
fi

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
