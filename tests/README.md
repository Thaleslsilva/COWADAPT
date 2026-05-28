# Tests

This directory is reserved for automated tests of COWADAPT pipeline scripts and analysis utilities.

---

## Current Status

Automated testing is planned for a future release. See `pipelines/SV_Catalog/UNDER_CONSTRUCTION.md` for the full development roadmap.

---

## Planned Test Coverage

| Module | Test Type | Status |
|---|---|---|
| `utils_vcf_to_bed.py` | Unit tests (VCF parsing, coordinate validation) | Planned |
| `extract_vep_annotations.py` | Unit tests (CSQ field parsing) | Planned |
| `convert_sv_to_biallelic.py` | Unit tests (genotype conversion) | Planned |
| `identify_tag_snps.py` | Unit tests (r-squared filtering, deduplication) | Planned |
| `generate_catalog.py` | Integration tests (merge correctness, row count sanity check) | Planned |
| `annotate_zebu_specificity.py` | Unit tests (classification thresholds, window logic) | Planned |
| Full SV Catalog pipeline | End-to-end test with public test dataset | Planned |

---

## Running Tests (Future)

```bash
# Activate the conda environment
conda activate cowadapt

# Run all tests
pytest tests/

# Run a specific module
pytest tests/test_generate_catalog.py -v
```

---

## Contributing Tests

If you would like to contribute tests, please follow the conventions in [CONTRIBUTING.md](../CONTRIBUTING.md):
- Use `pytest` as the test framework
- Place unit tests in `tests/unit/` and integration tests in `tests/integration/`
- Name test files `test_<module_name>.py`
- Each test function name should describe the behavior being tested
