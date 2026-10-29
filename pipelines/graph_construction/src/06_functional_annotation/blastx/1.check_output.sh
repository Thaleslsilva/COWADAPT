#!/bin/bash

set -euo pipefail

echo "How many sequences had at least 1 hit"
cut -f1 nruis_blastx_results.tsv | sort -u | wc -l
echo ""

echo "Total lines (hits)"
wc -l nruis_blastx_results.tsv
echo ""

echo "E-value distribution"
awk '{print $11}' nruis_blastx_results.tsv | \
    awk '{
        if ($1+0 <= 1e-50) c50++
        else if ($1+0 <= 1e-20) c20++
        else if ($1+0 <= 1e-10) c10++
        else c5++
    } END {
        print "<= 1e-50:", c50
        print "<= 1e-20:", c20
        print "<= 1e-10:", c10
        print "<= 1e-5: ", c5
    }'
echo ""

echo "Top 20 most frequently hit proteins"
awk '{print $15}' nruis_blastx_results.tsv | \
    sort | uniq -c | sort -rn | head -20
echo ""
