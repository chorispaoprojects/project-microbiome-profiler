#!/bin/bash
# Creates the isolated conda environment required for CheckM2, installs
# the CheckM2 package itself, and downloads its reference database.
#
# CheckM2's plain conda package has a known, actively-tracked dependency
# conflict (pinned tensorflow version with no installable providers —
# see github.com/chklovski/CheckM2/issues/141, and docs/README.md
# progress log). This script uses CheckM2's own maintainer-provided
# checkm2.yml environment file instead, which resolves cleanly, followed
# by a manual `pip install .` since the yml file installs dependencies
# only, not the CheckM2 package/CLI itself.
#
# Requires tools/CheckM2/ to already exist — run
# scripts/setup/setup_checkm2.sh first to clone the source.
#
# Usage: bash scripts/setup/setup_checkm2_env.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CHECKM2_SRC="${PROJECT_ROOT}/tools/CheckM2"
ENV_NAME="checkm2"

if [ ! -d "$CHECKM2_SRC" ]; then
    echo "ERROR: ${CHECKM2_SRC} not found."
    echo "Run scripts/setup/setup_checkm2.sh first to clone CheckM2's source."
    exit 1
fi

if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Environment '${ENV_NAME}' already exists, skipping creation."
else
    echo "Creating '${ENV_NAME}' environment from CheckM2's checkm2.yml..."
    conda env create -n "$ENV_NAME" -f "${CHECKM2_SRC}/checkm2.yml"
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

echo "Installing CheckM2 package itself (not included in checkm2.yml)..."
cd "$CHECKM2_SRC"
pip install .

DB_DIR="${PROJECT_ROOT}/databases/checkm2"
DB_FILE="${DB_DIR}/CheckM2_database/uniref100.KO.1.dmnd"

if [ -f "$DB_FILE" ]; then
    echo "CheckM2 database already present at ${DB_FILE}, skipping download."
else
    echo "Downloading CheckM2 reference database..."
    mkdir -p "$DB_DIR"
    checkm2 database --download --path "$DB_DIR"
fi

echo ""
echo "CheckM2 setup complete."
echo "Database at: ${DB_DIR}"
echo "Set CHECKM2DB before running scripts/05_checkm2.sh (handled automatically"
echo "within that script via a project-root-relative path)."
