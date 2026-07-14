#!/bin/bash
# Creates an isolated conda environment for MaxBin2.
#
# MaxBin2 requires isolation from the main 'metaflow' environment due to
# an R dependency conflict (r-gplots/r-catools pinned to unavailable
# R 3.2/3.3 builds when installed alongside metaflow's other packages —
# see docs/README.md progress log for full details). Version 2.2.7 is
# pinned explicitly since it includes the run_MaxBin.pl wrapper script,
# which was missing from the default-resolved 2.2.1 build.
#
# Usage: bash scripts/setup/setup_maxbin2_env.sh

set -euo pipefail

ENV_NAME="maxbin2_env"

if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Environment '${ENV_NAME}' already exists, skipping creation."
else
    conda create -n "$ENV_NAME" -c bioconda -c conda-forge maxbin2=2.2.7 -y
fi

echo "MaxBin2 environment ready. Activate with: conda activate ${ENV_NAME}"
