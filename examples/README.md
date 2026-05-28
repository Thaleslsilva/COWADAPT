# Examples

Self-contained, runnable demonstrations of COWADAPT pipeline steps.

These examples use minimal synthetic or publicly available data and are designed to verify that your installation is working correctly before running the full pipeline on your data.

---

## Available Examples

| Example | Description | Runtime |
|---|---|---|
| [01_sv_calling_demo.sh](01_sv_calling_demo.sh) | Run Sniffles2 on a small test BAM file | ~2 min |
| [02_survivor_merge_demo.sh](02_survivor_merge_demo.sh) | Merge two VCF files with SURVIVOR | ~1 min |
| [03_vep_annotation_demo.sh](03_vep_annotation_demo.sh) | Annotate a small VCF with VEP | ~5 min |
| [04_tag_snp_demo.py](04_tag_snp_demo.py) | Identify tag SNPs from a precomputed LD table | ~1 min |
| [05_zebu_specificity_demo.py](05_zebu_specificity_demo.py) | Classify SVs by zebu ancestry probability | ~1 min |

---

## Running the Examples

```bash
# Activate your conda environment first
conda activate cowadapt

# Run any example script
bash examples/01_sv_calling_demo.sh
python examples/04_tag_snp_demo.py
```

Each script creates its output in a local `examples/output/` directory that is excluded from version control.
