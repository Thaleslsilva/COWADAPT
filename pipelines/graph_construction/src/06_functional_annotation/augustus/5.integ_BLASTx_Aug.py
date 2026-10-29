# BLASTx + Augustus integration: master table for the manuscript
import pandas as pd

# Load Augustus results (complete models)
aug = pd.read_csv("augustus_complete_models.tsv", sep="\t")
aug = aug[aug["model_type"] == "complete"].copy()

# Load best BLASTx hits
blast = pd.read_csv("../blastx_res/nruis_blastx_best_hits.tsv", sep="\t")

# Normalize IDs for merging
# Augustus uses the original sequence's seqid
# BLASTx uses the non-repetitive block's ID (with coordinates)
# You need to map seqid_block -> seqid_original
blast["nrui_id"] = blast["qseqid"].str.split(":").str[0]
aug["nrui_id"] = aug["seqid"]

# Merge: NRUIs supported by BOTH Augustus AND BLASTx
# (dual support - more reliable for the manuscript)
dual_support = aug.merge(
    blast[["nrui_id","sseqid","pident","evalue","bitscore",
           "stitle"]],
    on="nrui_id",
    how="left"
)

n_dual = dual_support["sseqid"].notna().sum()
n_aug_only = dual_support["sseqid"].isna().sum()

print("=== Evidence support for gene models ===")
print(f"Augustus complete models:              {len(aug)}")
print(f"  + BLASTx support (dual support):     {n_dual}")
print(f"  Augustus only (no BLASTx hit):       {n_aug_only}")

# This distinction is essential for the manuscript:
# Genes with dual support = higher confidence
# Augustus-only genes = putative, need transcriptomic validation

dual_support.to_csv("nruis_gene_models_integrated.tsv",
                    sep="\t", index=False)
print("\nIntegrated table saved: nruis_gene_models_integrated.tsv")
