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
  "240514_PAU90126_doradov0.6.1_SUP_simplex.fastq.gz"
  "240708_PAU90117_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAW41805_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAU85751_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAW41726_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAW42170_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAW36795_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAW41613_doradov0.7.2_SUP_simplex.fastq.gz"
  "240708_PAW41607_doradov0.7.2_SUP_simplex.fastq.gz"
  "240807_PAW42124_doradov0.7.2_SUP_simplex.fastq.gz"
  "240514_PAU89876_doradov0.6.1_SUP_simplex.fastq.gz"
  "240807_PAW42033_doradov0.7.2_SUP_simplex.fastq.gz"
  "240807_PAW39366_doradov0.7.2_SUP_simplex.fastq.gz"
  "240701_PAU85745_doradov0.7.2_SUP_simplex.fastq.gz"
  "240807_PAW42201_doradov0.7.2_SUP_simplex.fastq.gz"
  "240710_PAU99997_doradov0.7.2_SUP_simplex.fastq.gz"
  "240701_PAU87849_doradov0.7.2_SUP_simplex.fastq.gz"
  "240807_PAW00680_doradov0.7.2_SUP_simplex.fastq.gz"
  "240710_PAU99920_doradov0.7.2_SUP_simplex.fastq.gz"
  "240710_PAU99949_doradov0.7.2_SUP_simplex.fastq.gz"
)

# Output names
NAMES=(
  "COWADAPT_001"
  "COWADAPT_002"
  "COWADAPT_003"
  "COWADAPT_004"
  "COWADAPT_005"
  "COWADAPT_006"
  "COWADAPT_008"
  "COWADAPT_009"
  "COWADAPT_010"
  "COWADAPT_011"
  "COWADAPT_012"
  "COWADAPT_013"
  "COWADAPT_014"
  "COWADAPT_015"
  "COWADAPT_016"
  "COWADAPT_017"
  "COWADAPT_018"
  "COWADAPT_019"
  "COWADAPT_020"
  "COWADAPT_023"
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
