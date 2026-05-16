# SV_Catalog - Development Status

## Current Status: UNDER CONSTRUCTION

This component of the COWADAPT repository is actively under development. While the pipeline is functional, documentation and testing are ongoing.

### What's Ready
- [x] All 17 bash scripts (refactored and verified)
- [x] Centralized configuration system (pipeline.config)
- [x] Project root detection and portable deployment
- [x] ASCII/ANSI encoding compliance
- [x] English-language documentation
- [x] Reference genome download utility
- [x] SV calling workflows (Sniffles2, SVIM)
- [x] SV merging (SURVIVOR)
- [x] Validation and filtering
- [x] Functional annotation (VEP)
- [x] SNP extraction and quality control
- [x] LD analysis framework
- [x] Zebu-specificity analysis

### In Progress
- [ ] Comprehensive testing with real datasets
- [ ] Extended user documentation
- [ ] Performance benchmarking
- [ ] Example workflows with public datasets

### Not Yet Implemented
- [ ] Automated dependency installation scripts
- [ ] Docker/Conda environment files
- [ ] Nextflow/Snakemake workflow integration
- [ ] Web-based visualization dashboard
- [ ] Publication of companion paper

## Getting Started

Despite the "under construction" status, the pipeline is fully functional:

1. **Review** `README.md` for pipeline overview
2. **Check** `docs/USAGE.md` for step-by-step instructions
3. **Prepare** your long-read BAM files
4. **Run** `bash src/utils/init_pipeline.sh` to validate environment
5. **Execute** pipeline steps in sequence

## Known Limitations

- Reference data downloads are large (~15-20 GB for VEP cache)
- Pipeline requires significant disk space for intermediate files
- Some optional data files must be downloaded manually (BovineHD chip, Zebu SNPmap)
- HPC configuration is SLURM-specific (other schedulers require modification)

## Reporting Issues

If you encounter problems:
1. Check `docs/TROUBLESHOOTING.md` (if available)
2. Verify all prerequisites with: `bash src/utils/init_pipeline.sh`
3. Review pipeline logs in: `results/logs/`
4. Report issues to: https://github.com/Thaleslsilva/COWADAPT/issues

## Contributing

Contributions, bug reports, and suggestions are welcome. Please submit pull requests or open issues on the main COWADAPT repository.

## Timeline

Expected completion: Q3 2026 (estimated)

---

Last updated: May 2026
Developed by: COWADAPT Team
