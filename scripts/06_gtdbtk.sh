#!/bin/bash
# Step 6: MAG taxonomy assignment via GTDB-Tk
#
# Usage: bash scripts/06_gtdbtk.sh <sample_name>
#
# ============================================================================
# RESOURCE REQUIREMENTS — READ BEFORE RUNNING
# ============================================================================
# GTDB-Tk's classify_wf requires substantial memory to place genomes into
# the GTDB reference tree via pplacer:
#   - Standard mode (current release): ~140GB RAM minimum
#   - Split-tree mode (v2+): ~35GB RAM
#     (still well beyond typical laptop hardware)
# Reference database storage: ~98GB
#
# This is different from this pipeline's other reference
# databases (e.g. Kraken2), where a smaller pre-built database option
# could trade sensitivity for a lower memory footprint. GTDB-Tk's memory
# requirement is tied to the reference tree itself and is not meaningfully
# reducible below the tens-of-GB range.
#
# This script is written, integrated into the pipeline's stage sequence,
# and follows the project's established conventions, but was NOT executed
# against Dataset A's MAGs, since neither the development laptop nor a
# reasonably-costed cloud instance could accommodate the RAM requirement
# without expense disproportionate to the value of classifying one or two
# low-completeness MAGs from a subsampled development dataset. This is a
# deliberate scope decision — see docs/README.md for full context.
#
# On appropriate hardware/infrastructure (which this stage is designed for),
# this script is expected to run without modification.
# ============================================================================
#
# Expects:
#   - DAS Tool refined bins in results/bins/<sample>/dastool/dastool_DASTool_bins/
#     (from scripts/04_binning.sh)
#   - The 'gtdbtk' conda environment and downloaded database
#     (see scripts/setup/setup_gtdbtk_env.sh)
#   - GTDBTK_DATA_PATH environment variable set to the database location

set -euo pipefail

SAMPLE=$1

if [ -z "${GTDBTK_DATA_PATH:-}" ]; then
    echo "ERROR: GTDBTK_DATA_PATH environment variable is not set."
    echo "Set it with: export GTDBTK_DATA_PATH=/path/to/databases/gtdbtk"
    echo "See scripts/setup/setup_gtdbtk_env.sh"
    exit 1
fi

BINS_DIR="results/bins/${SAMPLE}/dastool/dastool_DASTool_bins"
GTDBTK_DIR="results/annotation/${SAMPLE}/gtdbtk"

mkdir -p "$GTDBTK_DIR"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate gtdbtk

echo "=== Running GTDB-Tk classify_wf ==="
echo "WARNING: this step requires ~140GB RAM (or ~35GB in split-tree mode)."
echo "Confirm your system has adequate memory before proceeding."

gtdbtk classify_wf \
    --genome_dir "$BINS_DIR" \
    --out_dir "$GTDBTK_DIR" \
    --extension fa \
    --cpus 4

echo "GTDB-Tk classification complete for $SAMPLE"
echo "Summary: ${GTDBTK_DIR}/gtdbtk.bac120.summary.tsv (bacterial genomes)"
echo "         ${GTDBTK_DIR}/gtdbtk.ar53.summary.tsv (archaeal genomes, if any)"
