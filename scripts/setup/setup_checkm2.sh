#!/bin/bash
# Clones CheckM2 source from GitHub (needed since CheckM2's conda package
# has a known, unresolved tensorflow dependency conflict — see
# docs/README.md progress log for details).
#
# After cloning, also requires:
#   conda env create -n checkm2 -f tools/CheckM2/checkm2.yml
#   conda activate checkm2
#   cd tools/CheckM2 && pip install .
#   checkm2 database --download --path databases/checkm2
#
# See README for full setup steps.
#
# Usage: bash scripts/setup/setup_checkm2.sh

set -euo pipefail

mkdir -p tools
cd tools

if [ -d "CheckM2" ]; then
    echo "CheckM2 already present at tools/CheckM2, skipping clone."
else
    git clone https://github.com/chklovski/CheckM2.git
fi

echo "CheckM2 source ready at tools/CheckM2"
echo "Remember: also requires the 'checkm2' conda environment and database — see README setup instructions"
