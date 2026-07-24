# Releasing COWADAPT

This document describes how versions of COWADAPT are packaged and delivered to users, following [GitHub's guide for managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

## Versioning

COWADAPT follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`):

- **MAJOR** — incompatible changes to pipeline configuration, inputs, or outputs
- **MINOR** — new pipelines, modules, or documentation added in a backward-compatible way
- **PATCH** — backward-compatible bug fixes

Every release is recorded in [`CHANGELOG.md`](CHANGELOG.md), which follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format. Keep the `[Unreleased]` section up to date as pull requests are merged, so cutting a release is just a matter of renaming that section.

## Cutting a release

1. **Update the changelog**
   - Rename the `[Unreleased]` heading in `CHANGELOG.md` to the new version and date, e.g. `## [0.2.0] — 2026-07-24`.
   - Add a fresh, empty `[Unreleased]` section above it for future changes.
   - Update the comparison links at the bottom of the file.

2. **Commit the changelog update**
   ```bash
   git add CHANGELOG.md
   git commit -m "chore: prepare release vX.Y.Z"
   git push origin main
   ```

3. **Tag the release**
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin vX.Y.Z
   ```

4. **Publish the GitHub Release**
   - Go to the repository's [Releases](../../releases) page and click **Draft a new release**, or run:
     ```bash
     gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <(sed -n '/## \[X.Y.Z\]/,/^---/p' CHANGELOG.md)
     ```
   - Select the tag created in step 3.
   - Use "Generate release notes" and/or paste the relevant `CHANGELOG.md` section as the release description.
   - Mark as a **pre-release** for `0.x` versions or release candidates.
   - Publish the release.

## Notes

- Only maintainers with push access to the repository should cut releases.
- Tags and releases are public and visible to all users — double-check the changelog and version number before publishing.
- This repository does not currently ship a packaged artifact (e.g., PyPI/Conda package); releases mark tested, citable snapshots of the pipelines and documentation for reproducibility.
