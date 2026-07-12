#!/bin/bash
# Downloads and extracts the GTDB-Tk reference database, required for
# assigning taxonomy to metagenome-assembled genomes (MAGs) in
# scripts/06_gtdbtk.sh.
#
# Usage: bash scripts/setup/setup_gtdbtk_db.sh <database_url>
#
# Find current database URLs at: https://ecogenomics.github.io/GTDBTk/installing/index.html
# or directly at the GTDB-Tk data repository:
#   https://data.gtdb.ecogenomic.org/releases/
# (the database is versioned alongside GTDB taxonomy releases — e.g. R220,
# R226 — check for the current release rather than reusing an old URL,
# and note that GTDB-Tk's installed software version must be compatible
# with the database release you download; check the GTDB-Tk changelog
# if unsure)
#
# Note on size: the full GTDB-Tk reference database is large (~110GB
# uncompressed as of recent releases). This is substantially larger than
# the other reference databases used in this pipeline (Kraken2, HUMAnN)
# and download/extraction may take considerably longer. Ensure adequate
# disk space is available before starting.
#
# Example:
#   bash scripts/setup/setup_gtdbtk_db.sh \
#       https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_data.tar.gz

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: bash setup_gtdbtk_db.sh <database_url>"
    exit 1
fi

DB_URL=$1
DB_DIR="databases/gtdbtk"

mkdir -p "$DB_DIR"

echo "Downloading GTDB-Tk database from: $DB_URL"
echo "(this is a large download, ~100GB+ depending on release — this will take a while)"
wget -O "${DB_DIR}/gtdbtk_data.tar.gz" "$DB_URL"

echo "Extracting..."
tar -xzvf "${DB_DIR}/gtdbtk_data.tar.gz" -C "$DB_DIR" --strip-components=1
rm "${DB_DIR}/gtdbtk_data.tar.gz"

echo ""
echo "GTDB-Tk database ready at: $DB_DIR"
echo ""
echo "Set the GTDBTK_DATA_PATH environment variable to this location before running"
echo "scripts/06_gtdbtk.sh, e.g.:"
echo "  export GTDBTK_DATA_PATH=\"\$(pwd)/${DB_DIR}\""
echo ""
echo "(GTDB-Tk reads this database location from the GTDBTK_DATA_PATH environment"
echo "variable rather than a command-line argument, unlike Kraken2/HUMAnN — this"
echo "is a GTDB-Tk convention, not a deviation from our own scripting pattern)"
