#!/bin/bash

# Temporary file with the chromosome order
chrom_order="chrom_order.txt"
cat > "$chrom_order" <<EOF
NC_037328.1
NC_037329.1
NC_037330.1
NC_037331.1
NC_037332.1
NC_037333.1
NC_037334.1
NC_037335.1
NC_037336.1
NC_037337.1
NC_037338.1
NC_037339.1
NC_037340.1
NC_037341.1
NC_037342.1
NC_037343.1
NC_037344.1
NC_037345.1
NC_037346.1
NC_037347.1
NC_037348.1
NC_037349.1
NC_037350.1
NC_037351.1
NC_037352.1
NC_037353.1
NC_037354.1
NC_037355.1
NC_037356.1
EOF


echo "=== Preparing files ==="
for i in $(seq -w 28 56); do
    chr="NC_0373${i}.1"
    raw="${chr}/IND_pangenome.raw.vcf"
    bub="${chr}/IND_pangenome/Pangenome-out/final/IND_pangenome.bub.vcf"
    nrm="${chr}/IND_pangenome/Pangenome-out/final/IND_pangenome.norm.vcf"
    wav="${chr}/IND_pangenome/Pangenome-out/final/IND_pangenome.wavey.vcf"

    if [[ -f "${bub}" || -f "${nrm}" || -f "${wav}" ]]; then
       echo "Compressing VCF files..."
       bgzip -f "${raw}"
       bgzip -f "${bub}"
       bgzip -f "${nrm}"
       bgzip -f "${wav}"

       #tabix -f -p vcf "${bub}.gz"
    else
        echo "No file found in ${chr}"
    fi
done

# Cleanup
rm "$chrom_order"

echo ""
echo "... DONE ..."
