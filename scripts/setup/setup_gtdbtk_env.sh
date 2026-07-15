#!/bin/bash
# Creates the conda environment for GTDB-Tk and downloads its reference
# database using GTDB-Tk's own bundled download-db.sh script.
#
# GTDB-Tk's bioconda package has no known dependency resolution conflicts
# at the time of writing (unlike MaxBin2, DAS Tool, and CheckM2 elsewhere
# in this project). Channel order matters: conda-forge must come before
# bioconda, per GTDB-Tk's own documentation.
#
# RESOURCE WARNING: the reference database is ~98GB (v2.7.0+ pre-sketched
# release). Running classification against it (scripts/06_gtdbtk.sh)
# requires ~140GB RAM in standard mode, or ~35GB in split-tree mode —
# both well beyond typical laptop hardware. This script
# performs the environment setup and database download only; it does not
# run any classification. See scripts/06_gtdbtk.sh for full context.
#
# Usage: bash scripts/setup/setup_gtdbtk_env.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_NAME="gtdbtk"
DB_DIR="${PROJECT_ROOT}/databases/gtdbtk"

if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Environment '${ENV_NAME}' already exists, skipping creation."
else
    echo "Creating '${ENV_NAME}' environment..."
    conda create -n "$ENV_NAME" -c conda-forge -c bioconda gtdbtk -y
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

echo "Verifying installation..."
gtdbtk check_install || {
    echo "WARNING: check_install reported an issue. Review output above"
    echo "before attempting to run classify_wf."
}

if [ -f "${DB_DIR}/metadata/metadata.txt" ]; then
    echo "GTDB-Tk database already present at ${DB_DIR}, skipping download."
else
    echo ""
    echo "Downloading GTDB-Tk reference database (~98GB) to ${DB_DIR}..."
    echo "This will take a substantial amount of time and disk space."
    mkdir -p "$DB_DIR"
    GTDBTK_DATA_PATH="$DB_DIR" download-db.sh
fi

echo ""
echo "GTDB-Tk setup complete."
echo "Set GTDBTK_DATA_PATH before running scripts/06_gtdbtk.sh:"
echo "  export GTDBTK_DATA_PATH=\"${DB_DIR}\""
