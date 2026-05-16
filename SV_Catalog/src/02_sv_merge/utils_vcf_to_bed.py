#!/usr/bin/env python3
# survivor_vcf_to_bed.py
# Converte o VCF mergeado do SURVIVOR para o formato BED do SVvalidation
# Uso: python3 survivor_vcf_to_bed.py svs_concordantes.vcf svs_para_validar.bed

import sys
import re

def parse_info(info_str):
    """Extrai campos do campo INFO do VCF em um dicionario."""
    d = {}
    for item in info_str.split(";"):
        if "=" in item:
            k, v = item.split("=", 1)
            d[k] = v
        else:
            d[item] = True
    return d

def main():
    if len(sys.argv) != 3:
        print(f"Uso: python3 {sys.argv[0]} input.vcf output.bed")
        sys.exit(1)

    vcf_file = sys.argv[1]
    bed_file = sys.argv[2]

    tipos_aceitos = {"DEL", "INS", "DUP", "INV"}  # SVvalidation suporta esses tipos
    skipped = 0
    written = 0

    with open(vcf_file) as vcf, open(bed_file, "w") as bed:
        for line in vcf:
            # Pular cabecalho
            if line.startswith("#"):
                continue

            cols = line.strip().split("\t")
            if len(cols) < 8:
                continue

            chrom = cols[0]
            pos   = int(cols[1])   # posicao 1-based no VCF
            info  = parse_info(cols[7])

            svtype = info.get("SVTYPE", "").upper()
            if svtype not in tipos_aceitos:
                skipped += 1
                continue

            # Calcular posicao END
            if "END" in info:
                end = int(info["END"])
            elif "SVLEN" in info:
                svlen = int(info["SVLEN"])
                end = pos + abs(svlen)
            else:
                skipped += 1
                continue

            # Garantir que start < end e SV > 50 bp
            start = pos - 1  # converter para 0-based (padrao BED)
            if end <= start:
                end = start + 1  # seguranca para INS que tem SVLEN=0 as vezes
            if (end - start) < 50 and svtype != "INS":
                skipped += 1
                continue

            # Escrever linha BED: chrom, start (0-based), end, svtype
            svlen = int(info["SVLEN"])          
            bed.write(f"{chrom}\t{start}\t{end}\t{svlen}\t{svtype}\n")
            #bed.write(f"{chrom}\t{start}\t{end}\t{svtype}\n")
            written += 1

    print(f"[OK] SVs escritas no BED: {written}")
    print(f"[SKIP] SVs ignoradas (tipo nao suportado ou sem END/SVLEN): {skipped}")

if __name__ == "__main__":
    main()