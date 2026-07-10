# Metagenomics Pipeline

A plug-and-play shotgun metagenomics pipeline for taxonomic profiling, assembly, 
metagenome-assembled genome (MAG) reconstruction, and functional annotation.

## Data Naming Convention
Raw and processed FASTQ files follow the pattern `<sample_name>_1.fastq.gz` / `<sample_name>_2.fastq.gz`.

Subsampled datasets (used during development/testing) are suffixed with `_sub`,
e.g. `SRR24442552_sub_1.fastq.gz`. When running pipeline scripts, pass the full
sample name including the suffix:

    bash scripts/01_qc.sh SRR24442552_sub

## Datasets
- **Dataset A (development):** SRR24442552 — biofloc aquaculture metagenome 
  (subsampled to 500,000 read pairs via seqtk, seed 100)
- **Dataset B (validation):** TBD — planned marine/sea-ice associated microbiome

## Pipeline Stages
1. QC & Trimming (FastQC, Trimmomatic, MultiQC)
2. Taxonomic Profiling (Kraken2, Bracken) — planned
3. Assembly (MEGAHIT) — planned
4. Binning (MetaBAT2) — planned
5. MAG Quality Assessment (CheckM2) — planned
6. MAG Taxonomy (GTDB-Tk) — planned
7. Functional Annotation (Prodigal + eggNOG-mapper) — planned
