#!/bin/bash

##################################################################################################
###
###                                       COWADAPT PROJECT
### Script to run SeqKit2 v.2.8.2 on all .gz files in current folder with options
### for minimum quality -Q 10 (q-threshold>=10, SUP) and 100 threads.
###
### v.24.10.25                                                             Thales de Lima Silva
###
##################################################################################################

# Iterate over all .gz files in current folder
for arquivo in *.gz; do
    # Run seqkit seq with specified options
    seqkit seq -Q 10 -j 100 "$arquivo" -o "${arquivo%.gz}_filt.fq.gz"
done

echo "Processing completed for all .gz files"