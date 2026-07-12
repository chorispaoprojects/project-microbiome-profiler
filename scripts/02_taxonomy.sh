#!/bin/bash
# Step 2: Taxonomic profiling via Kraken2 + Bracken abundance re-estimation
#
# Usage: bash scripts/02_taxonomy.sh <sample_name> <path_to_kraken_db>
#
# Expects trimmed, paired reads already present in data/processed/
# (i.e. run scripts/01_qc.sh first)

set -euo pipefail

SAMPLE=$1
KRAKEN_DB=$2

PROCESSED_DIR="data/processed"
TAXONOMY_DIR="results/taxonomy"

mkdir -p "$TAXONOMY_DIR"

echo "Running Kraken2 classification for $SAMPLE..."
kraken2 --db "$KRAKEN_DB" \
    --paired \
    --threads 4 \
    --report "${TAXONOMY_DIR}/${SAMPLE}_kraken2_report.txt" \
    --output "${TAXONOMY_DIR}/${SAMPLE}_kraken2_output.txt" \
    "${PROCESSED_DIR}/${SAMPLE}_1_paired.fastq.gz" \
    "${PROCESSED_DIR}/${SAMPLE}_2_paired.fastq.gz"

echo "Running Bracken abundance re-estimation (species level)..."
bracken -d "$KRAKEN_DB" \
    -i "${TAXONOMY_DIR}/${SAMPLE}_kraken2_report.txt" \
    -o "${TAXONOMY_DIR}/${SAMPLE}_bracken_species.txt" \
    -w "${TAXONOMY_DIR}/${SAMPLE}_bracken_species_report.txt" \
    -r 150 \
    -l S \
    -t 10

echo "Taxonomic profiling complete for $SAMPLE"
