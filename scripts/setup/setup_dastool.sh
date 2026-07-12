#!/bin/bash
# Clones DAS Tool source directly from GitHub, bypassing its broken
# bioconda package (see docs/README.md progress log for details).
#
# Also requires a dedicated 'dastool' conda environment with r-base
# and the CRAN packages data.table, magrittr, and docopt installed —
# see README for full setup steps, since these aren't easily scriptable
# in an unattended way (R's interactive package installer).
#
# Usage: bash scripts/setup/setup_dastool.sh

set -euo pipefail

mkdir -p tools
cd tools

if [ -d "DAS_Tool" ]; then
    echo "DAS_Tool already present at tools/DAS_Tool, skipping clone."
else
    git clone https://github.com/cmks/DAS_Tool.git
fi

echo "DAS Tool source ready at tools/DAS_Tool"
echo "Remember: also requires the 'dastool' conda environment — see README setup instructions"
