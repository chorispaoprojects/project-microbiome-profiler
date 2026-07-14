#!/bin/bash
# Creates the isolated conda environment required for DAS Tool.
#
# DAS Tool's conda package has an unresolvable dependency conflict
# (r-magrittr pinned against unavailable versions when combined with
# other packages — see docs/README.md progress log). This script
# reproduces the working manual sequence: install a current r-base via
# conda, then install DAS Tool's required R packages directly from CRAN
# (bypassing conda entirely for those), then install DAS Tool's own
# runtime dependencies (prodigal, diamond, pullseq, ruby).
#
# DAS Tool itself is NOT installed by this script — it is not a conda
# package. Run scripts/setup/setup_dastool.sh separately to clone its
# source from GitHub.
#
# Usage: bash scripts/setup/setup_dastool_env.sh

set -euo pipefail

ENV_NAME="dastool"

if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Environment '${ENV_NAME}' already exists, skipping creation."
else
    conda create -n "$ENV_NAME" -c conda-forge r-base -y
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

echo "Installing required R packages from CRAN (data.table, magrittr, docopt)..."
Rscript -e "install.packages('data.table', repos='http://cran.us.r-project.org')"
Rscript -e "install.packages('magrittr', repos='http://cran.us.r-project.org')"
Rscript -e "install.packages('docopt', repos='http://cran.us.r-project.org')"

echo "Installing DAS Tool runtime dependencies (prodigal, diamond, pullseq, ruby)..."
conda install -n "$ENV_NAME" -c bioconda -c conda-forge prodigal diamond pullseq ruby -y

echo "DAS Tool environment ready."
echo "Remember to also run scripts/setup/setup_dastool.sh to clone DAS Tool's source."
