# Experimental Snakemake pipelines

Snakemake versions of two parts of step 02:

| Folder | Replaces | Jobs in a dry run |
|--------|----------|-------------------|
| `graph_level/Snakefile` | `graph_level/2.odgi_pipeline.sh` and `3.CoreFlex_analysis.sh` | 13 |
| `coreflex/Snakefile` | `coreflex/1.core_acessory_anl.sh` (density step parallelized per chromosome) | 124 |

**Status: experimental.** They were validated with `snakemake -n` only (dummy inputs) and were not used to generate the manuscript results. The shell scripts are the reference implementation.

Differences from the shell scripts:

- ODGI commands that are commented out in `2.odgi_pipeline.sh` exist as rules but are outside the default target (`stats`, `paths_list`, `node_matrix`, `degree`, `edge_matrix`, `edge_matrix_P`). `pav` also needs a BED file (`pav_bed_file` in `config/workflow.yaml`).
- `odgi normalize` uses the configured graph prefix instead of the fixed `graph.sorted.og`.
- The per-chromosome density step reads `{core,accessory,private}_nodes.txt` (the shell loop reads `../nodes_${TYPE}.txt`, which does not exist).
- The chromosome list comes from `config/workflow.yaml` (the 29 ARS-UCD2.0 autosomes) instead of being parsed from the GFA.

## Running

Input paths in the Snakefiles are relative to the working directory, which follows the layout in [docs/USAGE.md](../../../docs/USAGE.md). Use `--directory` to point to it:

```bash
# graph_level: working directory is post_pangenome/scripts
snakemake -s src/02_graph_statistics/snakemake/graph_level/Snakefile \
          --directory <workdir>/post_pangenome/scripts --cores 8 -n

# coreflex: working directory is post_pangenome/IND_analysis/coreFlex_analysis
snakemake -s src/02_graph_statistics/snakemake/coreflex/Snakefile \
          --directory <workdir>/post_pangenome/IND_analysis/coreFlex_analysis --cores 8 -n
```

Remove `-n` to execute.
