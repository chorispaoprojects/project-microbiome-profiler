#!/bin/bash
# Step 4: Binning — read-mapping/coverage generation, followed by
# MetaBAT2, MaxBin2, and DAS Tool consensus refinement.
#
# Usage: bash scripts/04_binning.sh <sample_name>
#
# Expects:
#   - Trimmed reads in data/processed/ (from scripts/01_qc.sh)
#   - Assembly contigs in results/assembly/<sample>/final.contigs.fa
#     (from scripts/03_assembly.sh)
#
# Note: CONCOCT was evaluated and excluded from this pipeline due to
# an unresolvable bioconda packaging issue — see docs/README.md
# progress log for details.

set -euo pipefail

SAMPLE=$1

PROCESSED_DIR="data/processed"
ASSEMBLY_DIR="results/assembly/${SAMPLE}"
CONTIGS="${ASSEMBLY_DIR}/final.contigs.fa"
BINNING_DIR="results/bins/${SAMPLE}"
MAPPING_DIR="${BINNING_DIR}/mapping"

mkdir -p "$MAPPING_DIR"

echo "=== Building bowtie2 index from assembly ==="
bowtie2-build "$CONTIGS" "${MAPPING_DIR}/contigs_index"

echo "=== Aligning reads back to assembly ==="
bowtie2 -x "${MAPPING_DIR}/contigs_index" \
    -1 "${PROCESSED_DIR}/${SAMPLE}_1_paired.fastq.gz" \
    -2 "${PROCESSED_DIR}/${SAMPLE}_2_paired.fastq.gz" \
    -p 4 \
    -S "${MAPPING_DIR}/${SAMPLE}.sam"

echo "=== Converting SAM to sorted, indexed BAM ==="
samtools view -bS "${MAPPING_DIR}/${SAMPLE}.sam" | samtools sort -o "${MAPPING_DIR}/${SAMPLE}_sorted.bam"
samtools index "${MAPPING_DIR}/${SAMPLE}_sorted.bam"

# Remove the intermediate SAM file — large and no longer needed once
# the sorted BAM exists
rm "${MAPPING_DIR}/${SAMPLE}.sam"

echo "=== Generating per-contig depth file ==="
jgi_summarize_bam_contig_depths --outputDepth "${MAPPING_DIR}/${SAMPLE}_depth.txt" "${MAPPING_DIR}/${SAMPLE}_sorted.bam"

echo "Read-mapping and coverage generation complete for $SAMPLE"
echo "Depth file: ${MAPPING_DIR}/${SAMPLE}_depth.txt"
