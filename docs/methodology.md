## Methodology

### Phase 1 — Data Collection and Quality Control
- Acquisition of high-quality, long-read genome assemblies (PacBio HiFi / ONT) from target zebu breeds
- Short-read whole-genome sequencing (WGS) data for large population panels
- Phenotypic data for traits of interest (heat tolerance, disease resistance, etc.)

### Phase 2 — Multi-Assembly Graph Construction
- Assembly of individual genomes using state-of-the-art assemblers (e.g., Hifiasm)
- Graph construction using tools such as **Minigraph-Cactus** or **Minigraph**
- Quality assessment and graph annotation

### Phase 3 — Variant Calling and Genotyping
- Long-read alignment to the pangenome graph (e.g., using **vg giraffe**)
- Structural variant calling and genotyping across the population panel
- Comparison with linear-reference-based results to quantify improvements

### Phase 4 — Association Analysis
- Graph-based GWAS for adaptive traits
- Selection sweep analysis to identify signatures of positive selection
- Haplotype analysis of candidate regions

### Phase 5 — Functional Interpretation
- Gene annotation of candidate regions
- Integration with transcriptomic (RNA-seq) data
- Comparison with known adaptive loci in related species
