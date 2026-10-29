# uniprot_go_fetch.py

#####      GO annotation via UniProt IDs from BLASTx hits     #####
### This path is faster and complementary to eggNOG. It uses the UniProt
### protein IDs returned by BLASTx to retrieve GO annotations directly
### from the UniProt database.


import pandas as pd
import requests
import time
import re

# Load BLASTx hits
blast = pd.read_csv("blastx_res/nruis_blastx_best_hits.tsv", sep="\t")

# Extract UniProt IDs from the hits
# Typical sseqid format: sp|P12345|GENE_BOVIN or tr|A0A1A1|...
def extract_uniprot_id(sseqid):
    match = re.search(r'[sptr]+\|([A-Z0-9]+)\|', str(sseqid))
    if match:
        return match.group(1)
    # Try the direct format
    if re.match(r'^[A-Z][0-9][A-Z0-9]{3}[0-9]', str(sseqid)):
        return sseqid.split(".")[0]
    return None

blast["uniprot_id"] = blast["sseqid"].apply(extract_uniprot_id)
uniprot_ids = blast["uniprot_id"].dropna().unique().tolist()

print(f"Unique UniProt IDs to query: {len(uniprot_ids)}")

# Query the UniProt API in batches of 100
def fetch_uniprot_go(ids_batch):
    id_string = " OR ".join([f"accession:{i}" for i in ids_batch])
    url = "https://rest.uniprot.org/uniprotkb/search"
    params = {
        "query": id_string,
        "format": "tsv",
        "fields": "accession,gene_names,go_id,go,keyword,organism_name"
    }
    r = requests.get(url, params=params, timeout=30)
    if r.status_code == 200:
        return r.text
    return ""

results = []
batch_size = 100

for i in range(0, len(uniprot_ids), batch_size):
    batch = uniprot_ids[i:i+batch_size]
    print(f"Querying batch {i//batch_size + 1}/"
          f"{len(uniprot_ids)//batch_size + 1}...", end="\r")

    text = fetch_uniprot_go(batch)
    if text:
        lines = text.strip().split("\n")
        if len(lines) > 1:  # has header + data
            results.extend(lines[1:])  # skip header

    time.sleep(0.5)  # respect the API rate limit

print(f"\nProteins with GO annotation retrieved: {len(results)}")

# Parse results
go_data = []
for line in results:
    parts = line.split("\t")
    if len(parts) >= 4:
        go_data.append({
            "uniprot_id": parts[0],
            "gene_name": parts[1],
            "go_ids": parts[2],
            "go_terms": parts[3],
            "organism": parts[5] if len(parts) > 5 else ""
        })

go_df = pd.DataFrame(go_data)

# Integrate with the BLASTx hits
blast_go = blast.merge(go_df, on="uniprot_id", how="left")
blast_go.to_csv("blastx_with_go.tsv", sep="\t", index=False)

print(f"Genes with GO via BLASTx: "
      f"{blast_go['go_ids'].notna().sum()}")
