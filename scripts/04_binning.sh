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
# ENVIRONMENT NOTE: this script spans three separate conda environments
# due to unresolvable dependency conflicts between tools (see
# docs/README.md progress log for full details):
#   - metaflow      : bowtie2, samtools, metabat2 (mapping + MetaBAT2)
#   - maxbin2_env    : MaxBin2 (isolated due to r-gplots/R version conflicts)
#   - dastool        : DAS Tool (isolated due to r-magrittr conflicts;
#                       installed via CRAN + GitHub source, not conda)
#
# CONCOCT was evaluated and excluded entirely due to an unresolvable
# bioconda packaging issue (pinned to an unavailable openblas build).
#
# Requires: tools/DAS_Tool/ (see scripts/setup/setup_dastool.sh)

set -euo pipefail

SAMPLE=$1

PROCESSED_DIR="data/processed"
ASSEMBLY_DIR="results/assembly/${SAMPLE}"
CONTIGS="${ASSEMBLY_DIR}/final.contigs.fa"
BINNING_DIR="results/bins/${SAMPLE}"
MAPPING_DIR="${BINNING_DIR}/mapping"

mkdir -p "$MAPPING_DIR"

# Needed to allow 'conda activate' inside a non-interactive script
source "$(conda info --base)/etc/profile.d/conda.sh"

# ============================================================
# Stage A: Read-mapping / coverage generation (metaflow env)
# ============================================================
conda activate metaflow

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
rm "${MAPPING_DIR}/${SAMPLE}.sam"

echo "=== Generating per-contig depth file ==="
jgi_summarize_bam_contig_depths --outputDepth "${MAPPING_DIR}/${SAMPLE}_depth.txt" "${MAPPING_DIR}/${SAMPLE}_sorted.bam"

# ============================================================
# Stage B: MetaBAT2 (metaflow env)
# ============================================================
echo "=== Running MetaBAT2 ==="
METABAT_DIR="${BINNING_DIR}/metabat2/bins"
mkdir -p "$METABAT_DIR"

metabat2 -i "$CONTIGS" \
    -a "${MAPPING_DIR}/${SAMPLE}_depth.txt" \
    -o "${METABAT_DIR}/bin" \
    -t 4 \
    -m 1500

echo "MetaBAT2 complete. Bins written to: $METABAT_DIR"

# ============================================================
# Stage C: MaxBin2 (maxbin2_env — isolated due to R dependency conflicts)
# ============================================================
conda activate maxbin2_env

echo "=== Running MaxBin2 ==="
MAXBIN_DIR="${BINNING_DIR}/maxbin2/bins"
mkdir -p "$MAXBIN_DIR"

cut -f1,3 "${MAPPING_DIR}/${SAMPLE}_depth.txt" | tail -n +2 > "${MAPPING_DIR}/${SAMPLE}_maxbin_depth.txt"

run_MaxBin.pl -contig "$CONTIGS" \
    -abund "${MAPPING_DIR}/${SAMPLE}_maxbin_depth.txt" \
    -out "${MAXBIN_DIR}/bin" \
    -thread 4

echo "MaxBin2 complete. Bins written to: $MAXBIN_DIR"

# ============================================================
# Stage D: DAS Tool consensus refinement (dastool env)
# ============================================================
conda activate dastool

echo "=== Running DAS Tool bin refinement ==="
DASTOOL_DIR="${BINNING_DIR}/dastool"
mkdir -p "$DASTOOL_DIR"

# DAS Tool needs a simple contig-to-bin mapping (tsv) per binner,
# not raw FASTA bin files directly — generate these using DAS Tool's
# own helper script
tools/DAS_Tool/src/Fasta_to_Contig2Bin.sh -i "$METABAT_DIR" -e fa > "${DASTOOL_DIR}/metabat2_contig2bin.tsv"
tools/DAS_Tool/src/Fasta_to_Contig2Bin.sh -i "$MAXBIN_DIR" -e fasta > "${DASTOOL_DIR}/maxbin2_contig2bin.tsv"

tools/DAS_Tool/DAS_Tool \
    -i "${DASTOOL_DIR}/metabat2_contig2bin.tsv,${DASTOOL_DIR}/maxbin2_contig2bin.tsv" \
    -l metabat2,maxbin2 \
    -c "$CONTIGS" \
    -o "${DASTOOL_DIR}/dastool" \
    --threads 4 \
    --write_bins

echo "DAS Tool complete. Refined bins written to: ${DASTOOL_DIR}/dastool_DASTool_bins"

echo "=== Binning stage complete for $SAMPLE ==="
echo "MetaBAT2 bins: $METABAT_DIR"
echo "MaxBin2 bins: $MAXBIN_DIR"
echo "DAS Tool refined bins: ${DASTOOL_DIR}/dastool_DASTool_bins"
