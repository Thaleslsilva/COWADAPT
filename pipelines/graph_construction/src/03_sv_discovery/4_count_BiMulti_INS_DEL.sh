#!/bin/bash

############################
# Biallelic SV
############################

bcftools view -m2 -M2 SV.vcf.gz | grep -cv "^#" 

############################
# Biallelic INS and DEL
############################

bcftools view -m2 -M2 -H SV.vcf.gz | \
awk '{
    if (length($5) > length($4)) ins++
    else if (length($4) > length($5)) del++
}
END {
    print "Insertions:", ins
    print "Deletions:", del
}'

############################
# Multiallelic SV
############################

bcftools view -m3 SV.vcf.gz | grep -cv "^#" 

############################
# Multiallelic INS and DEL
############################

bcftools view -m3 SV.vcf.gz | \
awk '{
    if (length($5) > length($4)) ins++
    else if (length($4) > length($5)) del++
}
END {
    print "Insertions:", ins
    print "Deletions:", del
}'

############################
# Count SV insertions
############################

bcftools query -f '%REF\t%ALT\n' SV.vcf.gz | \
awk 'length($2) > length($1) {
    n++
    sum += length($2)-length($1)
}
END {
    print "SV Insertions:", n
    print "Total inserted bp:", sum
}'

############################
# Count SV deletions
############################

bcftools query -f '%REF\t%ALT\n' SV.vcf.gz | \
awk 'length($1) > length($2) {
    n++
    sum += length($1) - length($2)
}
END {
    print "SV Deletions:", n
    print "Total deleted bp:", sum
}'

############################
# Count small insertions
############################

bcftools query -f '%REF\t%ALT\n' small.vcf.gz | \
awk 'length($2) > length($1) {
    n++
    sum += length($2)-length($1)
}
END {
    print "Small Insertions:", n
    print "Total inserted bp:", sum
}'


############################
# Count small deletions
############################

bcftools query -f '%REF\t%ALT\n' small.vcf.gz | \
awk 'length($1) > length($2) {
    n++
    sum += length($1) - length($2)
}
END {
    print "Small Deletions:", n
    print "Total deleted bp:", sum
}'

