#!/bin/bash

set -euo pipefail

# Check the basic result
grep -c "	gene	" augustus_out/nruis_augustus.gff3
grep -c "	mRNA	" augustus_out/nruis_augustus.gff3
grep -c "	CDS	" augustus_out/nruis_augustus.gff3