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


## Progress Log

### Day 1 — QC & Trimming (Dataset A)
- Downloaded SRR24442552 (biofloc aquaculture metagenome) via SRA-tools
- Subsampled to 500,000 read pairs (seqtk, seed 100) for fast iteration
- Ran QC pipeline: FastQC -> Trimmomatic -> FastQC -> MultiQC
- Results: 96.3% of read pairs survived trimming (481,741 / 500,000)
- Zero FastQC module failures pre- or post-trim
- Next step: taxonomic profiling with Kraken2/Bracken


### Day 2 — Taxonomic Profiling & Assembly (Dataset A)
 
**Taxonomic profiling (Kraken2 + Bracken):**
- Database: PlusPF-8 (capped at 8GB via k-mer downselection; PlusPF-16 was
  initially attempted but exceeded available WSL2 memory on 16GB development
  hardware — see Limitations section)
- 96.4% of reads unclassified (464,396 / 481,741)
- Of classified reads, dominant taxa were Rhodobacterales/Roseobacteraceae
  (Marivita, Ruegeria, Seohaeicola, Sulfitobacter genera)

**Assembly (MEGAHIT):**
- Input: 481,741 trimmed, paired reads (500K read pair subsample)
- Output: 8,313 contigs, 10.8 Mbp total assembled length
- N50: 2,153 bp (1,159 contigs at N50)
- Longest contig: 15,295 bp
- GC content: 56.2% (consistent with 57% GC observed in raw reads —
  no unexpected compositional bias introduced during assembly)
- Modest N50 and contig fragmentation are expected outcomes of the
  500K read-pair subsampling depth (chosen for fast iteration); binning
  is expected to recover a small number of bins, primarily from the
  more abundant, better-covered taxa
- Next step: read-mapping/coverage generation, then multi-binner
  approach (MetaBAT2, MaxBin2, CONCOCT) refined via DAS Tool
