# Background

## 1. Summary of the Research Plan

Approximately 1.3 billion people directly depend on farm animals for their livelihood. Characterizing and maintaining the genetic diversity of livestock is paramount to increase resource efficiency and make farm animal-based food production systems more environmentally friendly and resilient to future, potentially warmer, conditions.

Cattle production in tropical and alpine grasslands plays an important role in converting forages and agricultural by-products into high-quality protein. Under such conditions, cattle are exposed to harsh environments, low-quality pasture as well as ecto- and endo-parasites. Despite being well adapted to harsh environments, indicine (*Bos taurus indicus*) cattle remain largely underrepresented in genetic studies, which limits our understanding of genetic mechanisms underpinning adaptability.

The alignment of indicine genomes to the current *Bos taurus* reference genome (assembled from a Hereford cow) is susceptible to mapping bias. This compromises reference-guided variant discovery, particularly for samples with great genetic distance from the reference. Further research is needed to develop reference structures that mitigate reference allele bias and facilitate unbiased assessment and utilization of genomic variation in cattle from underrepresented breeds.

**COWADAPT** poses the hypothesis that this could be accomplished through multi-assembly graphs.

### Research Questions

- To what extent do individual indicine and taurine cattle genomes contain large sequence variants that are missing in the reference genome, and what is their functional relevance?
- What is the optimal structure of a pangenome graph to enable unbiased sequence variant analysis in diverging breeds of indicine and taurine cattle?
- Are structural variants that are inaccessible from the current linear reference genome associated with the adaptability of indicine cattle to tropical conditions?

### Specific Aims

- Compile reference-quality genome assemblies for different breeds of indicine and taurine cattle using long-read sequencing.
- Develop and implement a framework to integrate multiple assemblies and their sites of variation into multi-assembly graphs.
- Functional characterization of large structural variants from the multi-assembly graph that remained unused so far.
- Investigate the association between structural variants and traits relevant for the adaptability of *Bos indicus* cattle to harsh environments.

---

## 2. Research Plan

### 2.1 Current State of Research in the Field

Reference genomes of important farm animal species were assembled more than a decade ago using bacterial artificial chromosome and whole-genome shotgun sequencing. Allelic differences resulting either from sequencing errors or natural variation were collapsed into a haploid consensus sequence during the assembly process, resulting in fragmented assemblies for highly heterozygous genomes.

The reference sequence of the domestic cattle genome (*Bos taurus taurus*) was generated from the inbred Hereford cow "L1 Dominette 01449". The draft assembly had 2.87 Gb and its annotation revealed ~22,000 genes.

#### Creating Reference-Quality Assemblies from Long Sequencing Reads

Decreasing error rates and increasing outputs of PacBio single molecule real-time (SMRT) and Oxford Nanopore sequencing have enabled spectacular improvements in genome assembly. The gap-free assembly of entire chromosomes is now reality. The contig N50 size of genome assemblies increased from kilo- to megabases over the past 5 years. A new version of the bovine reference genome produced with a phase-aware assembly algorithm has 2,597 contigs and a contig N50 size of 25.9 Mb, representing an almost 100-fold improvement over preceding assemblies (UMD3.1, Btau5.0).

The "trio-binning" strategy enables simultaneous haplotype-resolved assembly at chromosome scale for diploid individuals by exploiting unique k-mers detected in parental short-read data to partition long reads from a diploid individual into paternal and maternal origin. These resources enable investigating genetic biodiversity beyond SNPs and INDELs.

#### A Reference Genome Enables the Systematic Detection of Genetic Diversity

The genome assembly from "L1 Dominette 01449" is the widely accepted *Bos taurus* reference genome for both taurine and indicine breeds. Typical genome-wide alignments of DNA sequences from taurine individuals differ at ~8 million positions from the reference in the form of SNPs and small (<50 bp) INDELs. The number of differences is higher for samples with greater divergence from Hereford, such as the indicine Brahman and Nellore breeds.

The latest variant detection run of the 1000 Bull Genomes Project included more than 4,000 cattle from 140 taurine and indicine breeds. Principal components analysis clearly separates indicine from taurine cattle -- the first PC explains 18.3% of the variation and reflects indicine ancestry, indicating pronounced genetic differences between both lineages.

#### Adaptation to Harsh Environments is a Complex Trait

Tracking within- and across-population diversity is key to reveal demographic processes, domestication signatures, and adaptation to environmental conditions. Indicine cattle have short and slick hair that makes them more tolerant to hot conditions. However, differentiating thermotolerant from thermosensitive individuals is typically not possible from visual characteristics alone.

There is growing evidence that resilience to tropical conditions is a heritable trait and may be improved using selective breeding. However, the molecular-genetic basis of resilience and phenotype plasticity is poorly understood. So far, studies investigating thermotolerance and adaptation to tropical conditions in both taurine and indicine cattle relied on SNP genotypes from microarrays designed for mainstream taurine breeds.

Our recent research showed that indicine cattle genomes contain many variants that are novel when compared to a database of variants detected in taurine cattle. Ascertainment bias resulting from the underrepresentation of indicine-specific SNPs in microarray-derived genotypes prevents a comprehensive analysis of complex traits such as adaptation in indicine cattle.

#### Towards a Bovine Pangenome from Reference-Quality Assemblies

Recent technology developments facilitate the de novo assembly of haplotype-resolved reference-quality genomes from long sequencing reads. A new paradigm of investigating sequence diversity from multiple haplotype-resolved assemblies has emerged:

- It has recently become affordable to assemble haplotype-resolved genomes de novo that exceed in continuity, correctness, and completeness current reference genomes.
- The lack of genetic diversity in the *Bos taurus* reference genome poses challenges for analysis of DNA samples whose ancestry differs greatly from the reference, as is the case for indicine cattle.
- Genomic analyses that rely on reference-guided alignment of short-read data are biased and largely blind to structural variants -- this can be avoided using augmented reference structures.

A multi-assembly reference graph is an intriguing solution to address current limitations. Multi-assembly graphs may unify a well-annotated reference coordinate system and allelic diversity from other assemblies. Nodes of a genome graph represent distinct alleles at a given position connected through edges. Haplotypes can be represented as a path in the graph.

---

### 2.2 Current State of Own Research

#### 2.2.1 Hubert Pausch -- ETH Zurich

The ETH Animal Genomics group was established in 2017. Research is supported by the Swiss National Science Foundation, the Swiss Federal Office for Agriculture, EU H2020, ETH internal funding programs, and industry partners.

As a member of the 1000 Bull Genomes Consortium, the group has access to whole-genome sequence variant genotypes from thousands of cattle from various taurine and indicine breeds. Previous work developed the first bovine genome graphs and showed that graph-based methods improve sequence variant analysis in cattle.

A breed-specific whole-genome reference graph was constructed by augmenting the Hereford-based reference sequence with DNA variants prioritized based on allele frequency in different cattle breeds. Using both real and simulated sequencing data, they showed that read mapping is more accurate using graph-based than linear reference genomes.

The group created the first bovine de novo assembly using HiFi reads from an Original Braunvieh animal (contig N50: 86 Mb) and integrated this resource and five other reference-quality assemblies from the Bovinae subfamily into a bovine multi-assembly graph. The multi-assembly graph revealed 70 million bases novel when compared to the *Bos taurus* reference genome, with more than 11 million novel bases found in Brahman (*Bos taurus indicus*). The Brahman assembly contained many putatively novel genes not included in the reference genome, suggesting that indicine cattle harbour a large amount of hitherto unused genetic diversity. This research question triggered the development of COWADAPT.

#### 2.2.2 Roberto Carvalheiro -- Sao Paulo State University (UNESP)

With the support of Brazilian cattle breeding programs, research funding agencies, and partner institutions, this research group has led several genomic studies of indicine cattle.

Key findings include:

- Linkage disequilibrium at short inter-marker distances is lower in indicine than taurine breeds, suggesting a larger historical effective population size of indicine breeds.
- Population structure analyses enabled detection of low levels (<1%) of taurine introgression in the two most important indicine cattle breeds for production of beef (Nellore) and milk (Gyr) in Brazil.
- Assessment of autozygosity in Nellore cattle through runs of homozygosity revealed candidate signatures of selection involved in resistance to infectious diseases and fertility.
- Genome-wide association analyses allowed mapping of candidate genomic regions related to phenotypic plasticity and environmental sensitivity of Nellore cattle.

The group has also been participating in collaborative research to study the association between structural (copy number) variation and complex traits in *Bos indicus* cattle. More recently, whole-genome sequence data from Nellore key-ancestor animals were used to accurately infer sequence variant genotypes for a large mapping cohort. The group believes that the indicine genome could be better characterized with long-read sequencing data and indicine-specific haplotype-resolved assemblies.

#### 2.2.3 Strengths of the ETH-UNESP Collaboration

The ETH Animal Genomics group (led by Hubert Pausch) has strong expertise in building multi-assembly graphs in cattle. The UNESP group (led by Roberto Carvalheiro) has strong expertise in the genetic and genomic characterization of indicine cattle, including access to a large mapping cohort of Nellore cattle with phenotypes for adaptation-relevant traits.

Both groups are well-connected nationally and internationally, and maintain excellent collaborations with the 1000 Bull Genomes Consortium, the Bovine Pangenome Consortium (BPG), BovReg, and breeding associations.

---

### 2.3 Detailed Research Plan

#### 2.3.1 Objectives

The prevalence of large structural variations in the cattle genome as well as their sequence content and biological relevance remain largely unknown. COWADAPT will construct a multi-assembly graph integrating reference-quality assemblies from underrepresented breeds of indicine and taurine cattle, investigate the sequence content of structural variants, and test if previously unused sequences harbour variants associated with the adaptability of indicine cattle to tropical environments.

The project is organized into four Work Packages (WPs) over 48 months.

---

#### Objective 1: De Novo Assembly of Reference-Quality Genomes from Taurine and Indicine Cattle Breeds

**Lead:** Hubert Pausch, ETH | **Person months:** 24 (12 Postdoc ETH + 12 Postdoc UNESP)

**Rationale:** The extent to which large (>50 kb) genomic differences exist within or between indicine and taurine cattle remains largely unknown. Haplotype-resolved genome assemblies are required to investigate the full spectrum of sequence diversity. In a preliminary study, individual taurine assemblies contained ~3 million bases missing in the bovine reference genome; the Brahman genome contained almost twice that amount.

**Planned breeds:**
- Taurine (alpine/tropical): Simmental, Ehringer, Ratisches Grauvieh, Caracu
- Indicine (important for beef/dairy in Brazil and adaptability): Gyr, Guzerat, Red Sindhi

**Approach:** Apply trio-binning with PacBio HiFi reads (CCS, 20 kb length, ~50x coverage) to assemble haplotype-resolved genomes. Reference-guided scaffolding will use RagTag. Quality assessment will use BUSCO, Merqury, and mapping-rate metrics. A Simmental x Gyr F1 hybrid calf will be sequenced at the start of COWADAPT.

Long-read sequencing (n=20 Nellore samples, ~20x HiFi coverage) will be collected to investigate the frequency of structural variants at the population level.

**Milestones:**
- Long-read sequencing data collected for taurine and indicine cattle breeds (PM9)
- Haplotype-resolved genome assemblies constructed (PM12)
- Long-read sequencing data collected for 20 Nellore cattle (PM12)

---

#### Objective 2: Establish the Pangenome of Taurine and Indicine Cattle

**Lead:** Hubert Pausch, ETH | **Person months:** 60 (48 Doctoral Student ETH + 12 Postdoc UNESP)

**Rationale:** Taurine and indicine breeds used for beef and dairy production in alpine and tropical environments may show great genetic divergence from Hereford cattle and carry large structural variants encompassing millions of bases with biologically relevant features not included in the *Bos taurus* reference genome.

**Planned tasks:**

- **Prototype indicine-aware reference graph:** Integrate the Nellore reference-quality assembly into a multi-assembly graph using minigraph. Label nodes by origin, annotate repetitive elements (RepeatMasker), and predict novel genes (Augustus + BLASTX). Extract non-reference sequences as additional contigs for a Nellore-augmented linear reference (available at PM12).

- **Bovine pangenome framework:** Integrate assemblies from WP1 and other publicly available assemblies (taurine, indicine, and Bovinae relatives) into a comprehensive multi-assembly graph. Estimate genetic divergence using Mash.

- **Optimal pangenome graph structure:** Compare minigraph, Cactus + VG, and pggb with respect to size, sequence content, read mapping accuracy, variant discovery sensitivity/specificity, and reference allele bias. Results available at PM30.

- **Size and content of the bovine pangenome:** Quantify core and flexible pangenome content, presence/absence variations, and mobile genetic element insertion sites. Available at PM38.

- **Framework for association testing from graphs:** Develop frequency-aware node labeling to enable GWAS and signature-of-selection detection directly from the graph.

**Milestones:**
- Nellore-augmented reference sequence established (PM12)
- Scalable workflows established to build pangenome graphs (PM24)
- Indicine-specific sequences derived from the multi-assembly graph (PM36)

---

#### Objective 3: Structural Variant Detection in the Genome of Indicine Cattle

**Lead:** Roberto Carvalheiro, UNESP | **Person months:** 54 (6 Postdoc ETH + 24 PhD Student UNESP + 24 IT technician UNESP)

**Rationale:** Multiple studies have highlighted an important contribution of DNA structural variants (SVs) to phenotypic variation in cattle and other species. The current taurine reference genome is unable to fully characterize cattle genetic diversity, and the role of SVs in cattle adaptation remains poorly characterized. COWADAPT will use long-read sequencing data mapped onto an indicine-augmented reference to assess the full spectrum of population sequence variation in Nellore.

**Planned tasks:**

- **Long-read SV calling:** Align Nellore long reads (from WP1) to the Nellore-augmented reference (WP2) using NGMLR. Call SVs with Sniffles (supports nested SVs including inverted tandem duplications and inversions flanked by indels). Polish SVs using Iris and merge with SURVIVOR. Repeat SV discovery from the multi-assembly graph (PM30) using GraphAligner.

- **Genotyping in short reads:** Use long-read-discovered SVs as a reference to infer SV genotypes in n=151 Nellore samples with short-read sequencing (avg 14.5x coverage) using Paragraph, which generates graph representations of reference and alternative alleles.

- **Imputation into SNP array genotyped animals:** Impute sequence-discovered SVs into a larger cohort (>20,000 Nellore animals) genotyped with medium- to high-density SNP arrays. Imputation will use Eagle2 and Minimac4 with 5-fold cross-validation to assess accuracy.

- **Functional characterization of SVs:** Annotate SVs using Ensembl Variant Effect Predictor, classify by Sequence Ontology, perform enrichment analysis of GO terms and KEGG pathways (KOBAS), and compare with QTLs from AnimalQTLdb.

**Milestones:**
- Long read alignment and accurate SV calling of Nellore samples (PM16)
- Genotype long-read-discovered SVs in short-read sequencing data (PM20)
- Impute sequence-discovered SVs in SNP array genotyped animals (PM24)
- Characterize detected SVs (PM30)

---

#### Objective 4: The Role of Structural Variation in Cattle Adaptation to Tropical Conditions

**Lead:** Roberto Carvalheiro, UNESP | **Person months:** 24 (24 PhD Student UNESP)

**Rationale:** Most GWAS studies relied on SNP genotypes. However, there is increasing evidence that SVs are an important source of phenotypic variation in cattle. Genome-wide SV association studies for adaptation-related traits are underrepresented in the literature. Moreover, previous SV-based GWAS used only copy number variation data from microarrays, limiting our understanding. COWADAPT will for the first time conduct association testing between SV genotypes and tropical adaptation in an indicine cattle breed.

**Planned analyses:**

- **Linkage disequilibrium (LD) between SVs and SNPs:** Compute r2 between each SV and adjacent SNPs (within a 1 Mb window) using PLINK in the mapping cohort. Low LD would indicate an opportunity to discover novel associations not captured by SNP arrays.

- **Depigmentation (skin pigmentation):** Approximately 5% of Nellore animals have depigmented skin areas, impairing health and performance. Candidate genes KIT and MITF were previously identified. A threshold mixed animal model will be applied using phenotypic data from ~500,000 Nellore animals and a mapping cohort of ~15,000 animals with imputed SV genotypes.

- **Calf mortality:** A complex trait with large environmental and genetic components (direct and maternal additive effects). Previous GWAS identified candidate genes for preweaning mortality. A genome-wide SV association study will use ~200,000 Nellore calves (3.5% preweaning mortality rate) and ~10,000 animals with imputed SV genotypes.

- **Phenotypic plasticity:** The capacity of an organism to change a phenotype in response to environmental variation. Reaction norm mixed models will be applied to mapping cohorts of ~200,000 (reproduction) and ~500,000 (growth) Nellore animals with imputed SV genotypes for >20,000 animals.

**Milestones:**
- Quantifying linkage disequilibrium between SVs and SNPs (PM28)
- Association testing of structural variants with depigmentation (PM34)
- Association testing of structural variants with calf mortality (PM40)
- Association testing of structural variants with phenotypic plasticity (PM48)

---

### 2.4 Schedule and Milestones

| Milestone | Description | Due Month |
|-----------|-------------|-----------|
| 1.1 | Long-read sequencing data collected for taurine and indicine cattle breeds | PM9 |
| 1.2 | Haplotype-resolved genome assemblies constructed | PM12 |
| 1.3 | Long-read sequencing data collected for 20 Nellore cattle | PM12 |
| 2.1 | Nellore-augmented reference sequence established | PM12 |
| 2.2 | Scalable workflows established to build pangenome graphs | PM24 |
| 2.3 | Indicine-specific sequences derived from the multi-assembly graph | PM36 |
| 3.1 | Long read alignment and accurate SV calling of Nellore samples | PM16 |
| 3.2 | Genotype long-read-discovered SVs in short-read sequencing data | PM20 |
| 3.3 | Impute sequence-discovered SVs in SNP array genotyped animals | PM24 |
| 3.4 | Characterize detected SVs | PM30 |
| 4.1 | Quantifying linkage disequilibrium between SVs and SNPs | PM28 |
| 4.2 | Association testing of structural variants with depigmentation | PM34 |
| 4.3 | Association testing of structural variants with calf mortality | PM40 |
| 4.4 | Association testing of structural variants with phenotypic plasticity | PM48 |

---

### 2.5 Relevance and Impact

COWADAPT exploits new long-read sequencing technologies to obtain reference-quality assemblies for underrepresented breeds of cattle, revealing a large amount of yet unused sequence variation relevant to cattle adaptability to harsh environments. All novel resources and computational workflows will be made publicly available.

The project proposes a novel approach that considerably extends the current state-of-the-art for investigating sequence variation and genetic diversity in species with diverging subpopulations. For the first time, the genetic diversity between and within breeds of indicine and taurine cattle will be investigated from a bovine multi-assembly graph. The methodological approach developed in COWADAPT is expected to be broadly applicable to many other species with diverging subpopulations.

**Expected publications:**
- Sequence variation of underrepresented breeds of cattle characterized from de novo genome assemblies
- Optimal design of multi-assembly graphs
- Prevalence of sequence variation in cattle genomes beyond SNPs and INDELs
- Population-frequency of structural variations in the Nellore genome
- Association of large structural sequence variation with adaptability of cattle to harsh environments

Results will be published in open-access journals, preprints deposited at bioRxiv, and code shared at the ETH Animal Genomics GitHub repository.
