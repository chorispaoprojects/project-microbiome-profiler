#!/bin/bash
# Step 3: Metagenome assembly via MEGAHIT
#
# Usage: bash scripts/03_assembly.sh <sample_name> [--mode individual|coassembly]
#
# individual mode (default): assembles the single named sample
# coassembly mode: (not yet implemented) intended to pool reads from
#   multiple samples before assembly; requires a sample list rather
#   than a single sample name — see project README for design notes
#
# Expects trimmed, paired reads already present in data/processed/
# (i.e. run scripts/01_qc.sh first)
#
# Note: this script produces contigs only. Read-mapping/coverage
# generation (needed by all three binners in the next stage) is
# handled at the start of scripts/04_binning.sh, not here, so that
# re-binning or re-mapping doesn't require re-assembly.

set -euo pipefail

SAMPLE=$1
MODE="individual"

if [ "${2:-}" == "--mode" ]; then
    MODE=$3
fi

PROCESSED_DIR="data/processed"
ASSEMBLY_DIR="results/assembly/${SAMPLE}"

if [ "$MODE" == "coassembly" ]; then
    echo "ERROR: coassembly mode is not yet implemented."
    echo "This pipeline currently supports individual-sample assembly only."
    echo "See docs/README.md for planned multi-sample design."
    exit 1
fi

echo "Running MEGAHIT assembly for $SAMPLE (mode: $MODE)..."

# -m 0.8 caps MEGAHIT's memory usage at 80% of available system memory,
# leaving headroom for the OS rather than letting it claim everything
# (see docs/README.md progress log for the memory-constraint lesson
# learned during the Kraken2 database stage)
megahit \
    -1 "${PROCESSED_DIR}/${SAMPLE}_1_paired.fastq.gz" \
    -2 "${PROCESSED_DIR}/${SAMPLE}_2_paired.fastq.gz" \
    -o "$ASSEMBLY_DIR" \
    -m 0.8 \
    -t 4

echo "Computing assembly statistics..."
seqkit stats -a "${ASSEMBLY_DIR}/final.contigs.fa" > "results/assembly/${SAMPLE}_assembly_stats.txt"
cat "results/assembly/${SAMPLE}_assembly_stats.txt"

echo "Assembly complete for $SAMPLE"
echo "Contigs: ${ASSEMBLY_DIR}/final.contigs.fa"
