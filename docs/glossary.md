# Glossary

Key terms and definitions used throughout the COWADAPT project.

---

## Genomics and Sequencing

**Assembly graph (GFA)**
A graph-based representation of a genome assembly where nodes represent sequences and edges represent connections. Output format of HiFiasm and other assemblers. GFA = Graphical Fragment Assembly.

**Contig N50**
A summary statistic of assembly contiguity: the length of the shortest contig such that 50% of the total assembly length is contained in contigs of that length or longer. Higher N50 values indicate better contiguity.

**Coverage (sequencing depth)**
The average number of reads covering each position in the genome. Typically expressed as Nx (e.g., 30x coverage).

**HiFi reads (PacBio CCS)**
High-fidelity long reads produced by PacBio SMRT sequencing using circular consensus sequencing (CCS). Typical read lengths: 10-25 kb. Error rate: less than 1%.

**Long-read sequencing**
Sequencing technologies (PacBio, Oxford Nanopore) that produce reads of 10 kb or longer, enabling resolution of repetitive regions and large structural variants.

**ONT (Oxford Nanopore Technology)**
A sequencing platform that measures changes in electrical current as DNA passes through protein nanopores. Produces ultra-long reads (up to megabases) but with higher error rates than PacBio HiFi.

**Pangenome graph**
A reference structure that encodes genomic variation from multiple individuals or populations as a directed sequence graph. Unlike a linear reference, it can represent insertions, deletions, and rearrangements relative to all input genomes simultaneously.

**Scaffold**
A sequence assembled from multiple contigs that are ordered and oriented with respect to each other, often with gaps (represented as Ns) where connections are uncertain.

---

## Cattle Genetics

**ARS-UCD2.0**
The current bovine reference genome (NCBI accession GCF_002263795.3), assembled from a Hereford Bos taurus cow. Supersedes ARS-UCD1.2. Used as the coordinate system for all SV positions in COWADAPT.

**Bos indicus (zebu)**
The indicine subspecies of domestic cattle, originating in South Asia. Characterized by a distinct hump, long ears, and adaptation to tropical environments. Key breeds: Nellore, Gir, Brahman, Sahiwal.

**Bos taurus (taurine)**
The taurine subspecies of domestic cattle, originating in the Near East and Europe. The current bovine reference genome was assembled from a Hereford Bos taurus individual.

**BovineHD chip**
The Illumina BovineHD BeadChip, a microarray genotyping platform with approximately 777,000 SNPs distributed across the bovine genome. Used for cost-effective population genotyping.

**Indicine ancestry / Pr(Indicina)**
A per-SNP probability derived from the Kasarapu et al. (2017) SNP map, indicating the likelihood that a given allele traces its ancestry to Bos indicus rather than Bos taurus.

**Nellore**
The most numerous Bos indicus breed worldwide, dominant in Brazilian cattle production. Valued for heat tolerance, tick resistance, and reproductive efficiency in tropical systems. The primary breed studied in COWADAPT.

**Reference bias**
Systematic errors in variant detection caused by using a reference genome from a distantly related individual or breed. Manifests as reduced mapping rates, inflated false-negative variant calls, and incorrect allele frequencies.

---

## Structural Variants

**BND (breakend)**
A generic SV notation for a single breakpoint in a rearrangement, often used for translocations or complex variants with unclear structure.

**CNV (Copy Number Variant)**
A class of structural variant involving the gain or loss of copies of a genomic segment. Includes duplications and deletions affecting larger regions.

**DEL (Deletion)**
A structural variant in which a segment of DNA is absent from the sample genome relative to the reference. COWADAPT detects deletions of 50 bp or larger.

**DUP (Duplication)**
A structural variant in which a segment of DNA is present in more copies in the sample than in the reference genome.

**INDEL**
A small insertion or deletion, typically under 50 bp. Distinct from structural variants, which are conventionally 50 bp or larger.

**INS (Insertion)**
A structural variant in which a DNA sequence is present in the sample but absent from the reference genome. Includes novel sequence insertions and mobile element insertions.

**INV (Inversion)**
A structural variant in which a segment of DNA is reversed in orientation relative to the reference genome.

**SUPP (support field)**
A field in SURVIVOR-merged VCF files indicating the number of callers (Sniffles2, SVIM) that independently called the same SV. Higher SUPP values indicate higher confidence.

**SVLEN**
The length of a structural variant in base pairs.

**SVTYPE**
The type of a structural variant: DEL, INS, DUP, INV, BND, or TRA (translocation).

---

## Statistical and Bioinformatic Terms

**CSQ field (VEP consequence)**
A VCF INFO field added by Ensembl VEP containing variant effect predictions. Encodes consequence type, affected gene, and impact level.

**GWAS (Genome-Wide Association Study)**
A statistical method that tests for associations between genetic variants (SNPs, SVs) and phenotypic traits across many individuals.

**Haplotig**
A duplicate contig in a genome assembly representing the same genomic region from the second haplotype. Haplotigs should be removed (purged) before using an assembly as a reference.

**Impact level (VEP)**
A qualitative assessment of functional consequence severity: HIGH (e.g., frameshift, stop codon), MODERATE (e.g., missense), LOW (e.g., synonymous), MODIFIER (e.g., intronic, intergenic).

**LD (Linkage Disequilibrium)**
Non-random association between alleles at different loci in a population. Measured as r-squared (0 = no association, 1 = perfect correlation). Used in COWADAPT to identify chip SNPs that can serve as proxies for SVs.

**MAPQ (Mapping Quality)**
A Phred-scaled score indicating the probability that a read is mapped to the wrong location. Higher values indicate more confident placement. COWADAPT filters reads with MAPQ below 20 during SV calling.

**r-squared threshold**
The minimum r-squared value required to consider a SNP a valid tag SNP for a given SV. COWADAPT uses an r-squared threshold of 0.3.

**SNP (Single Nucleotide Polymorphism)**
A genetic variant in which a single base pair differs between individuals or populations.

**SUP basecall**
High-accuracy basecalling model (SUP = super-accuracy) available for Oxford Nanopore reads. Produces Q >= 10 reads used after filtering in COWADAPT.

**Tag SNP**
A SNP in high LD with a structural variant, enabling the SV to be indirectly genotyped using SNP chip data. The best tag SNP for each SV is reported in the final catalog.

**VCF (Variant Call Format)**
A text file format for storing genome sequence variation. Contains a header and data lines for each variant, with fields for chromosome, position, reference allele, alternate allele, quality, and sample genotypes.

**VEP (Variant Effect Predictor)**
An Ensembl tool that predicts the functional consequences of genomic variants (SNPs, indels, SVs) with respect to annotated gene models.

---

## Pipeline-Specific Terms

**Concordant SV**
An SV call supported by at least two independent callers (Sniffles2 and SVIM) within 1,000 bp of each other, as determined by SURVIVOR.

**Indicine-specific SV**
An SV for which the mean Pr(Indicina) of overlapping Kasarapu SNPs is 0.95 or above, indicating strong zebu ancestry at that locus.

**Pipeline configuration file**
The central configuration file at `pipelines/SV_Catalog/config/pipeline.config` that defines all file paths, parameters, and compute settings for the SV Catalog pipeline.

**SNF file (Sniffles2)**
A binary file format used by Sniffles2 to store per-sample SV evidence for efficient joint calling across multiple samples.

**SURVIVOR**
A tool for benchmarking, comparing, and merging structural variant calls from multiple callers or samples.
