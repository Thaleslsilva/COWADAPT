#!/bin/bash

##################################################################################################
###
###                                       COWADAPT PROJECT
### Quality control of long-read sequencing data using NanoComp v.1.24.0
###
### v.24.11.01                                                             Thales de Lima Silva
###
##################################################################################################

# Output directory for NanoComp results
OUTDIR="NanoQC_fq"
THREADS=100

# Input directory for FASTQ files
INPUT_DIR="ziped_fqs/"

# Lista de arquivos FASTQ
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

# Names list
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

# Executando o NanoComp
NanoComp -t "$THREADS" --fastq "${FILES[@]/#/$INPUT_DIR}" --names "${NAMES[@]}" --outdir "$OUTDIR"
