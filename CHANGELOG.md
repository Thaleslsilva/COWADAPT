# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- Centralized pipeline configuration system (`pipelines/SV_Catalog/config/pipeline.config`)
- 7-step SV catalog pipeline for Nellore cattle structural variant analysis
- Automated reference genome download utility
- Zebu-specificity annotation module
- Chromosomal ideogram visualization for publication-quality figures
- Comprehensive pipeline documentation (USAGE.md, PIPELINE_OVERVIEW.md, DATA_SOURCES.md)
- INSTALLATION.md guide covering system requirements and setup
- MIT License
- .gitignore for bioinformatics workflows
- examples/ directory with usage demonstrations

### Changed
- Refactored all pipeline scripts to use centralized configuration
- Standardized all code comments and documentation to English

### Fixed
- Merge key logic in `generate_catalog.py` to prevent Cartesian product on SV-SNP joins
- Deduplication of tag SNP and support tables before catalog merge

---

## [0.1.0] — 2024-01-01

### Added
- Initial repository structure for COWADAPT project
- Genome assembly pipeline (HiFiasm, Purge Dups, Assembly QC)
- Quality control pipeline (NanoComp, Porechop, Seqkit)
- Sequence alignment pipeline (Minimap2)
- Scientific background documentation
- CONTRIBUTING.md with contribution guidelines
- Collaboration setup between USP (Brazil) and ETH Zurich (Switzerland)

---

[Unreleased]: https://github.com/Thaleslsilva/COWADAPT/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Thaleslsilva/COWADAPT/releases/tag/v0.1.0
