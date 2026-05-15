# Contributing to COWADAPT

Thank you for your interest in contributing to COWADAPT! This document provides guidelines and information to help you get started.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Community](#community)

---

## Code of Conduct

This project adheres to a Contributor Code of Conduct. By participating, you are expected to:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community and the science
- Show empathy towards other community members

---

## How Can I Contribute?

### Types of Contributions

We welcome several types of contributions:

- **Bug reports** — Help us identify issues in the code or documentation
- **Feature requests** — Suggest new analyses, tools, or improvements
- **Code contributions** — Submit fixes or new features via pull requests
- **Documentation** — Improve or expand our documentation
- **Data contributions** — Share relevant publicly available datasets or resources
- **Scientific review** — Provide feedback on methodology and results

---

## Reporting Bugs

Before creating a bug report, please check if the issue has already been reported.

When submitting a bug report, please include:

1. **A clear and descriptive title**
2. **Steps to reproduce** the problem
3. **Expected behavior** — what you expected to happen
4. **Actual behavior** — what actually happened
5. **Environment details** — OS, software versions, relevant configurations
6. **Relevant logs or error messages**

Use the [Issues](../../issues) tab and apply the `bug` label.

---

## Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

1. **A clear and descriptive title**
2. **Motivation** — why this enhancement would be useful
3. **Proposed solution** — describe the desired behavior
4. **Alternatives considered** — other approaches you've considered
5. **Additional context** — any relevant references or examples

Use the [Issues](../../issues) tab and apply the `enhancement` label.

---

## Pull Request Process

1. **Fork** the repository and create a branch from `main`
2. **Name your branch** descriptively (e.g., `feature/graph-qc-metrics` or `fix/mapping-script-bug`)
3. **Make your changes** following the style guidelines below
4. **Write or update tests** if applicable
5. **Update the documentation** to reflect your changes
6. **Commit your changes** with a clear commit message
7. **Open a pull request** against the `main` branch
8. **Respond to review comments** promptly

### Commit Message Guidelines

Write commit messages in the imperative mood and keep them concise:

- Good: `Add heat tolerance GWAS pipeline`
- Good: `Fix alignment script memory overflow`
- Avoid: `Fixed some stuff` or `WIP`

---

## Style Guidelines

### Code

- Use clear, descriptive variable and function names
- Add comments to explain non-obvious logic
- Follow language-specific conventions:
  - **Python**: PEP 8 style guide
  - **R**: tidyverse style guide
  - **Shell scripts**: Use `#!/usr/bin/env bash` and set `-euo pipefail`
- Include a brief docstring or comment block at the top of each script

### Documentation

- Write in clear, concise English
- Use Markdown formatting consistently
- Include code examples where relevant
- Cite relevant literature for methodological choices

### Data and File Organization

- Follow the repository structure outlined in the README
- Use descriptive filenames in `snake_case`
- Do not commit large raw data files — use metadata and manifests instead
- Document all input/output file formats

---

## Community

For questions, discussions, or collaborative ideas that don't fit as issues, feel free to:

- Open a [Discussion](../../discussions) on GitHub
- Reach out to the project maintainers

We are excited to collaborate with researchers from all backgrounds to advance our understanding of zebu cattle genomics and adaptation.

---

*Thank you for helping make COWADAPT better!*

*— The COWADAPT Team (USP × ETH Zurich)*
