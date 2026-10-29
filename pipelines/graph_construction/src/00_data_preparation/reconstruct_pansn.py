#!/usr/bin/env python3

### How to use ###
# Without inserting Ns
# python reconstruct_pansn.py <file>.fa.gz <file>_panSN.fa.gz

# Inserting 100 Ns between fragments
# python reconstruct_pansn_fast.py COWADAPT_010.fasta COWADAPT_010.0.fasta 100 16

import sys
import os
import gzip
import subprocess


VALID_CHR = {f"chr{str(i).zfill(2)}" for i in range(1, 30)}


def open_fasta(path):
    """
    Open FASTA file (gz or plain text).
    """
    if path.endswith(".gz"):
        return gzip.open(path, "rt", buffering=1024*1024)
    return open(path, "r", buffering=1024*1024)


def get_prefix(path):
    """
    Extract prefix from filename.
    Example:
        COWADAPT_010.fasta.gz -> COWADAPT_010
    """
    base = os.path.basename(path)

    if base.endswith(".gz"):
        base = base[:-3]

    for ext in [".fasta", ".fa", ".fna"]:
        if base.endswith(ext):
            base = base[:-len(ext)]
            break

    return base


def normalize_chr(header):
    """
    Very fast chromosome detection.
    Assumes header contains something like:
        chr03
        chr3
        3
    """

    h = header.split()[0]

    if "chr" in h:
        idx = h.find("chr")
        chr_part = h[idx:idx+5]
        num = ''.join(filter(str.isdigit, chr_part))
        if num:
            return f"chr{num.zfill(2)}"

    # fallback numeric only
    num = ''.join(filter(str.isdigit, h))
    if num:
        return f"chr{num.zfill(2)}"

    return None


def write_output_multithreaded(output_path, data_dict, prefix, threads=8):
    """
    Use pigz for multithreaded compression.
    """

    pigz = subprocess.Popen(
        ["pigz", "-p", str(threads)],
        stdin=subprocess.PIPE,
        stdout=open(output_path, "wb")
    )

    for chr_name in sorted(data_dict.keys()):
        header = f">{prefix}#0#{chr_name}\n"
        pigz.stdin.write(header.encode())

        seq = "".join(data_dict[chr_name])

        for i in range(0, len(seq), 60):
            pigz.stdin.write(seq[i:i+60].encode() + b"\n")

    pigz.stdin.close()
    pigz.wait()


def reconstruct(input_fasta, output_fasta, gap_size=0, threads=8):

    prefix = get_prefix(input_fasta)

    chromosomes = {chr_name: [] for chr_name in VALID_CHR}

    current_chr = None

    with open_fasta(input_fasta) as f:
        for line in f:

            if line[0] == ">":
                chr_name = normalize_chr(line[1:].strip())

                if chr_name in VALID_CHR:
                    if current_chr == chr_name and gap_size > 0:
                        chromosomes[chr_name].append("N" * gap_size)
                    current_chr = chr_name
                else:
                    current_chr = None

            else:
                if current_chr:
                    chromosomes[current_chr].append(line.strip())

    write_output_multithreaded(output_fasta, chromosomes, prefix, threads)


if __name__ == "__main__":

    if len(sys.argv) < 3:
        print("Usage:")
        print("python reconstruct_pansn_fast.py input.fasta[.gz] output.fasta.gz [gap_size] [threads]")
        sys.exit(1)

    input_fasta = sys.argv[1]
    output_fasta = sys.argv[2]

    gap_size = int(sys.argv[3]) if len(sys.argv) >= 4 else 0
    threads = int(sys.argv[4]) if len(sys.argv) >= 5 else 8

    reconstruct(input_fasta, output_fasta, gap_size, threads)