#!/bin/bash
# Downloads and extracts a Kraken2-compatible reference database.
#
# Usage: bash scripts/setup/setup_kraken_db.sh <database_url> <db_name>
#
# Find current database URLs at: https://benlangmead.github.io/aws-indexes/k2
# (database options and their sizes/contents change periodically; always
# check the index page for the current, correctly-dated filename rather
# than reusing an old URL, since these are not permanently stable links)
#
# Example:
#   bash scripts/setup/setup_kraken_db.sh \
#       https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16_GB_20260226.tar.gz \
#       pluspf_16gb

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: bash setup_kraken_db.sh <database_url> <db_name>"
    echo "  <db_name> is used only to name the local folder under databases/"
    exit 1
fi

DB_URL=$1
DB_NAME=$2

DB_DIR="databases/${DB_NAME}"
mkdir -p "$DB_DIR"

echo "Downloading Kraken2 database from: $DB_URL"
wget -O "${DB_DIR}/database.tar.gz" "$DB_URL"

echo "Extracting..."
tar -xzvf "${DB_DIR}/database.tar.gz" -C "$DB_DIR"
rm "${DB_DIR}/database.tar.gz"

echo ""
echo "Database ready at: $DB_DIR"
echo "Pass this path to scripts/02_taxonomy.sh as the --db argument"
