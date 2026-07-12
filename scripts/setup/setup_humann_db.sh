#!/bin/bash
# Downloads and extracts the reference databases required by HUMAnN
# (ChocoPhlAn pangenome database + UniRef protein database).
#
# This is the OPTIONAL read-based functional profiling module setup.
# The core pipeline does not require this — only run this script if you
# intend to use scripts/02b_humann.sh.
#
# Usage: bash scripts/setup/setup_humann_db.sh <chocophlan_url> <uniref_url>
#
# Find current database URLs via HUMAnN's own download utility listings:
#   https://github.com/biobakery/humann#5-download-the-databases
# (ChocoPhlAn and UniRef are versioned and updated periodically — check
# the current recommended version rather than reusing an old URL)
#
# Note on UniRef choice: UniRef90 (~20GB) offers better functional
# sensitivity than UniRef50 (~5GB) and is the standard choice in most
# published HUMAnN analyses. UniRef50 trades sensitivity for a
# substantially faster download/setup, useful primarily for rapid
# iteration on constrained hardware. This project uses UniRef90 by
# default for correctness; swap the URL argument for UniRef50 if faster
# setup is prioritized over sensitivity.
#
# Example:
#   bash scripts/setup/setup_humann_db.sh \
#       http://huttenhower.sph.harvard.edu/humann_data/chocophlan/full_chocophlan.v296_201901.tar.gz \
#       http://huttenhower.sph.harvard.edu/humann_data/uniprot/uniref90_annotated/uniref90_annotated_v201901b_full.tar.gz

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: bash setup_humann_db.sh <chocophlan_url> <uniref_url>"
    exit 1
fi

CHOCOPHLAN_URL=$1
UNIREF_URL=$2

CHOCOPHLAN_DIR="databases/humann/chocophlan"
UNIREF_DIR="databases/humann/uniref"

mkdir -p "$CHOCOPHLAN_DIR" "$UNIREF_DIR"

echo "Downloading ChocoPhlAn database from: $CHOCOPHLAN_URL"
wget -O "${CHOCOPHLAN_DIR}/chocophlan.tar.gz" "$CHOCOPHLAN_URL"

echo "Extracting ChocoPhlAn..."
tar -xzvf "${CHOCOPHLAN_DIR}/chocophlan.tar.gz" -C "$CHOCOPHLAN_DIR"
rm "${CHOCOPHLAN_DIR}/chocophlan.tar.gz"

echo ""
echo "Downloading UniRef database from: $UNIREF_URL"
wget -O "${UNIREF_DIR}/uniref.tar.gz" "$UNIREF_URL"

echo "Extracting UniRef..."
tar -xzvf "${UNIREF_DIR}/uniref.tar.gz" -C "$UNIREF_DIR"
rm "${UNIREF_DIR}/uniref.tar.gz"

echo ""
echo "HUMAnN databases ready:"
echo "  ChocoPhlAn: $CHOCOPHLAN_DIR"
echo "  UniRef:     $UNIREF_DIR"
echo "Pass these paths to scripts/02b_humann.sh as the --chocophlan and --uniref arguments"
