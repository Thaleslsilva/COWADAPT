# Pipeline overview

```
Assemblies (13 indicine + ARS-UCD2.0)
   |
   +-- 00  PanSN renaming ........ sample#haplotype#contig FASTA
   +-- 00  Mash distances ........ guide tree for the order of assemblies
   |
   v
01  Minigraph-Cactus ............. GFA / VG / GBZ / ODGI graph
   |
   +--> 02  Graph statistics
   |        - graph size, NR nodes and bases, sample intersections
   |        - core / accessory / private genome, per-breed sharing
   |
   +--> 03  vg deconstruct (per chromosome)
            vcfbub -> vcfwave -> bcftools norm -> split by |ILEN| >= 50 bp
            |
            +--> SV.vcf.gz, small.vcf.gz
                    |
                    +--> 04  PCA (PLINK), UpSet plots, breed-private insertions
                    |
                    +--> 05  NR insertions -> FASTA
                              CD-HIT-EST (95% identity)
                              RepeatModeler + RepeatMasker (soft-masking)
                              non-repetitive blocks (>= 100 bp / >= 500 bp)
                              |
                              +--> 06  DIAMOND BLASTx, Augustus, eggNOG-mapper, GO/KEGG
                                        |
                                        +--> 07  PAV matrix, candidate genes
```

## Inputs and outputs by step

| Step | Main inputs | Main outputs |
|------|-------------|--------------|
| 00 | Assembly FASTA files | PanSN FASTA, `tree/combined_distance.tsv` |
| 01 | Assemblies, Cactus `seqFile` | `IND_pangenome_final.{gfa,og,vg,gbz}` |
| 02 | Graph (`.og`, `.gfa`) | Node/edge tables, `intersections.tsv`, `core_genome_size.txt`, `breed_intersections.tsv`, plots |
| 03 | Per-chromosome graphs | `SV.vcf.gz`, `small.vcf.gz`, variant counts |
| 04 | `SV.vcf.gz` | PCA eigenvectors, `Indicine_Breed_Presence_Matrix.tsv`, UpSet figure |
| 05 | `SV.vcf.gz` | `SV_INS.FASTA`, clustered and masked NR FASTA, non-repetitive blocks, repeat tables |
| 06 | Non-repetitive blocks | BLASTx hits, Augustus models, integrated gene table, eggNOG annotations |
| 07 | Graph (`.gfa`), gene table | `nrui_pav_matrix.tsv`, candidate list |

File names follow the scripts; see each script header for details.

## Design notes

- `config/pipeline.config` is the single place for shared parameters.
- Scripts are kept close to how they were run. Commented commands are alternatives or earlier attempts and are kept for traceability.
- The Snakemake files are an optional, experimental re-expression of step 02 and are not used for the manuscript results.
