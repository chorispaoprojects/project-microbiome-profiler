#!/bin/bash
# Step 5: Bin quality assessment via CheckM2
#
# Runs CheckM2 across all three binning outputs (MetaBAT2 raw, MaxBin2 raw,
# DAS Tool refined) for direct comparison — not just the final refined set —
# so completeness/contamination differences between binners are visible
# for troubleshooting and reporting purposes.
#
# Usage: bash scripts/05_checkm2.sh <sample_name>
#
# Requires the 'checkm2' conda environment and its downloaded database
# (see docs/README.md setup notes / scripts/setup/ for database setup).
# Assumes the database lives at databases/checkm2/ relative to the project
# root — adjust CHECKM2DB below if yours is located elsewhere.

set -euo pipefail

SAMPLE=$1

# Resolve the project root relative to this script's own location, so
# this works regardless of where the repo is cloned/checked out
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Needed to allow 'conda activate' inside a non-interactive script
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate checkm2

export CHECKM2DB="${PROJECT_ROOT}/databases/checkm2/CheckM2_database/uniref100.KO.1.dmnd"

BINNING_DIR="results/bins/${SAMPLE}"

echo "=== CheckM2 on MetaBAT2 bins ==="
checkm2 predict -i "${BINNING_DIR}/metabat2/bins" -x fa -o "${BINNING_DIR}/metabat2/checkm2" --threads 4

echo "=== CheckM2 on MaxBin2 bins ==="
checkm2 predict -i "${BINNING_DIR}/maxbin2/bins" -x fasta -o "${BINNING_DIR}/maxbin2/checkm2" --threads 4

echo "=== CheckM2 on DAS Tool refined bins ==="
checkm2 predict -i "${BINNING_DIR}/dastool/dastool_DASTool_bins" -x fa -o "${BINNING_DIR}/dastool/checkm2" --threads 4

echo "=== CheckM2 assessment complete for $SAMPLE ==="
echo "MetaBAT2 report:  ${BINNING_DIR}/metabat2/checkm2/quality_report.tsv"
echo "MaxBin2 report:   ${BINNING_DIR}/maxbin2/checkm2/quality_report.tsv"
echo "DAS Tool report:  ${BINNING_DIR}/dastool/checkm2/quality_report.tsv"
