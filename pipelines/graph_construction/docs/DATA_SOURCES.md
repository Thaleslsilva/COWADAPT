# Data sources

## Zenodo record

[10.5281/zenodo.21535203](https://doi.org/10.5281/zenodo.21535203): *Data for Indicine Cattle Multi-Assembly Pangenome Graph* (CC-BY-4.0).

| File | Content |
|------|---------|
| `IND_pangenome_final.gfa.gz` (3.4 GB) | Final pangenome graph |
| `COWADAPT_Nelore_005/010/011/017/019/020.fasta.gz` | Six Nelore assemblies (ONT), generated in this study |
| `SxGCHEF120170207244_Gyr.fasta.gz` | Gyr assembly (PacBio HiFi) |
| `BRAGUZ_M_07_Guzerat.hap1/hap2.fasta.gz` | Guzerat haplotype assemblies |
| `BRASIN_F_08_Sindi.hap1/hap2.fasta.gz` | Sindi haplotype assemblies |
| `BRATAB_F_8423_Tabapua.hap1/hap2.fasta.gz` | Tabapua haplotype assemblies |

The mapping between assembly names in the manuscript and these files is in `config/samples.tsv`. The Gyr, Guzerat, Sindi and Tabapua assemblies were produced by the Animal Genomics group at ETH Zurich and are deposited with the permission of H. Pausch.

## Reference genome

ARS-UCD2.0 (*Bos taurus*, Hereford): NCBI [GCF_002263795.3](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_002263795.3/). The analyses use the 29 autosomes only. Inside the graph the reference path prefix is `ARS_UCD2` (see `config/pipeline.config`).

## Protein databases (step 06)

`src/06_functional_annotation/5.1.prep_prot_db.sh` builds the DIAMOND database from:

- UniProtKB/Swiss-Prot (`uniprot_sprot.fasta.gz`, current release at download time);
- RefSeq proteins of the ARS-UCD1.2 assembly (`GCF_002263795.1`).

`TODO(author)`: record here the exact taxa, release/download dates and number of sequences of the database used for the manuscript.

## Annotation resources

| Resource | Used for |
|----------|----------|
| eggNOG 5.0 database (`download_eggnog_data.py`) | eggNOG-mapper annotation (`6.1.GO_KEGG.sh`) |
| `org.Bt.eg.db` (R/Bioconductor) | Gene ID conversion for enrichment (R, Pending) |
| UniProt REST API | GO terms of the BLASTx hits (`blastx/4.uniprot_go_fetch.py`) |
| Augustus `human` species model | Ab initio prediction (`augustus/1.1.pred_indvSeq.sh`) |

## Not in this repository

Raw sequencing reads, intermediate graph files and result tables are not stored here because of their size.
