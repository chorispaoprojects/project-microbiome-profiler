#!/bin/bash
# Step 1: Quality control and trimming
# Usage: bash scripts/01_qc.sh <sample_name>

set -euo pipefail

# NOTE: This script expects paired FASTQ files named <SAMPLE>_1.fastq.gz and <SAMPLE>_2.fastq.gz
# For subsampled test data, we name files as <original_accession>_sub_1.fastq.gz / _sub_2.fastq.gz
# and pass "<original_accession>_sub" as the SAMPLE argument, e.g.:
#   bash scripts/01_qc.sh SRR24442552_sub



SAMPLE=$1
RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
QC_DIR="results/qc"

mkdir -p "$QC_DIR/pre_trim" "$QC_DIR/post_trim" "$PROCESSED_DIR"

echo "Running FastQC on raw reads..."
fastqc "$RAW_DIR/${SAMPLE}_1.fastq.gz" "$RAW_DIR/${SAMPLE}_2.fastq.gz" \
    -o "$QC_DIR/pre_trim"

echo "Running Trimmomatic..."
trimmomatic PE -phred33 \
    "$RAW_DIR/${SAMPLE}_1.fastq.gz" "$RAW_DIR/${SAMPLE}_2.fastq.gz" \
    "$PROCESSED_DIR/${SAMPLE}_1_paired.fastq.gz" "$PROCESSED_DIR/${SAMPLE}_1_unpaired.fastq.gz" \
    "$PROCESSED_DIR/${SAMPLE}_2_paired.fastq.gz" "$PROCESSED_DIR/${SAMPLE}_2_unpaired.fastq.gz" \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

echo "Running FastQC on trimmed reads..."
fastqc "$PROCESSED_DIR/${SAMPLE}_1_paired.fastq.gz" "$PROCESSED_DIR/${SAMPLE}_2_paired.fastq.gz" \
    -o "$QC_DIR/post_trim"

echo "Running MultiQC..."
multiqc "$QC_DIR" -o "$QC_DIR"

echo "QC complete for $SAMPLE"
