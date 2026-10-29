# nrui_blastx_integration.py
import pandas as pd
import re

# Load filtered hits
hits = pd.read_csv("nruis_blastx_best_hits.tsv", sep="\t")

# Block IDs have the format: nrui_nodeID_nonrep_N
# or: nodeID:start-end (if bedtools getfasta was used)
# Extract the original NRUI ID

def extract_nrui_id(qseqid):
    # Adjust the pattern to match your IDs' format
    # Example: "s12345:100-450" -> "s12345"
    return qseqid.split(":")[0]

hits["nrui_id"] = hits["qseqid"].apply(extract_nrui_id)

# Group hits by original NRUI
nrui_summary = hits.groupby("nrui_id").agg(
    n_hits=("qseqid", "count"),
    best_evalue=("evalue", "min"),
    best_pident=("pident", "max"),
    best_protein=("stitle", lambda x: x.iloc[0])
).reset_index()

print(f"NRUIs with at least 1 BLASTx hit: {len(nrui_summary)}")
nrui_summary.to_csv("nruis_annotated_blastx.tsv", sep="\t", index=False)
