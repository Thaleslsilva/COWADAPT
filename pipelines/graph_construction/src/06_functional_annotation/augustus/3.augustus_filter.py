# This step is critical for the manuscript. Complete models must be distinguished from fragments.

import re
from collections import defaultdict

def parse_augustus_gff3(filepath):
    genes = {}
    current_gene = None

    with open(filepath) as f:
        for line in f:
            if line.startswith("#"):
                continue
            parts = line.strip().split("\t")
            if len(parts) < 9:
                continue

            seqid, source, feat, start, end, score, strand, phase, attrs = parts

            if feat == "gene":
                gene_id = re.search(r'ID=([^;]+)', attrs).group(1)
                current_gene = gene_id
                genes[gene_id] = {
                    "seqid": seqid,
                    "start": int(start),
                    "end": int(end),
                    "strand": strand,
                    "length": int(end) - int(start) + 1,
                    "has_start": False,
                    "has_stop": False,
                    "has_tss": False,
                    "has_tts": False,
                    "n_exons": 0,
                    "cds_length": 0,
                    "transcripts": []
                }

            elif feat == "mRNA" and current_gene:
                mrna_id = re.search(r'ID=([^;]+)', attrs).group(1)
                genes[current_gene]["transcripts"].append(mrna_id)

            elif feat == "start_codon" and current_gene:
                genes[current_gene]["has_start"] = True

            elif feat == "stop_codon" and current_gene:
                genes[current_gene]["has_stop"] = True

            elif feat == "transcription_start_site" and current_gene:
                genes[current_gene]["has_tss"] = True

            elif feat == "transcription_end_site" and current_gene:
                genes[current_gene]["has_tts"] = True

            elif feat == "exon" and current_gene:
                genes[current_gene]["n_exons"] += 1

            elif feat == "CDS" and current_gene:
                genes[current_gene]["cds_length"] += (
                    int(end) - int(start) + 1
                )

    return genes

# Load predictions
genes = parse_augustus_gff3(
    "augustus_out/nruis_augustus.gff3"
)

# Classify models
complete = []
partial = []
fragment = []

for gid, g in genes.items():
    g["gene_id"] = gid
    protein_len = g["cds_length"] // 3

    # Complete model: has start + stop + CDS >= 150 bp (50 aa)
    if (g["has_start"] and g["has_stop"] and
        g["cds_length"] >= 150):
        g["model_type"] = "complete"
        complete.append(g)

    # Partial model: has start or stop, CDS >= 150 bp
    elif (g["has_start"] or g["has_stop"]) and g["cds_length"] >= 150:
        g["model_type"] = "partial"
        partial.append(g)

    # Fragment: CDS < 150 bp or no start/stop
    else:
        g["model_type"] = "fragment"
        fragment.append(g)

print("=== Augustus gene model summary ===")
print(f"Total predicted genes:     {len(genes)}")
print(f"  Complete models:         {len(complete)}")
print(f"  Partial models:          {len(partial)}")
print(f"  Fragments (< 150 bp):    {len(fragment)}")
print()

# Statistics for complete models
if complete:
    import statistics
    cds_lens = [g["cds_length"] for g in complete]
    prot_lens = [g["cds_length"]//3 for g in complete]
    exon_counts = [g["n_exons"] for g in complete]

    print("=== Statistics - complete models ===")
    print(f"Mean CDS:          {statistics.mean(cds_lens):.0f} bp")
    print(f"Median CDS:        {statistics.median(cds_lens):.0f} bp")
    print(f"Mean protein:      {statistics.mean(prot_lens):.0f} aa")
    print(f"Exons per gene:    {statistics.mean(exon_counts):.1f} (mean)")

# Save table of complete models
import csv
with open("augustus_complete_models.tsv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=[
        "gene_id","seqid","start","end","strand","length",
        "cds_length","n_exons","model_type"
    ], delimiter="\t")
    writer.writeheader()
    for g in complete + partial:
        writer.writerow({k: g[k] for k in writer.fieldnames})

print(f"\nTable saved: augustus_complete_models.tsv")
