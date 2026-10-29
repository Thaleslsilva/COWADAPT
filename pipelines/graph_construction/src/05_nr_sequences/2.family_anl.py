# Parse the RepeatMasker .out file to generate a table per family

import pandas as pd
import re

rows = []
with open("nruis.fasta.out") as f:
    for _ in range(3):  # skip the 3 header lines
        next(f)
    for line in f:
        parts = line.strip().split()
        if len(parts) >= 11:
            rows.append({
                "score": int(parts[0]),
                "div": float(parts[1]),
                "query": parts[4],
                "q_start": int(parts[5]),
                "q_end": int(parts[6]),
                "repeat_name": parts[9],
                "repeat_class": parts[10].split("/")[0],
                "repeat_family": parts[10],
                "length": int(parts[6]) - int(parts[5]) + 1
            })

df = pd.DataFrame(rows)

# Group by class and family
summary = df.groupby(["repeat_class", "repeat_family"])["length"].agg(
    count="count",
    total_bp="sum"
).reset_index()
summary["pct"] = summary["total_bp"] / summary["total_bp"].sum() * 100
summary = summary.sort_values("total_bp", ascending=False)

print(summary.to_string(index=False))
summary.to_csv("te_composition_nruis.csv", index=False)