# Metagenomics Pipeline

A plug-and-play shotgun metagenomics pipeline for taxonomic profiling, assembly,
metagenome-assembled genome (MAG) reconstruction, and functional annotation of
microbial community sequencing data.

For the detailed day-by-day development history, troubleshooting log, and
results as they were obtained, see [PROGRESS_LOG.md](PROGRESS_LOG.md).

---

## Data Naming Convention

Raw and processed FASTQ files follow the pattern `<sample_name>_1.fastq.gz` /
`<sample_name>_2.fastq.gz`.

Subsampled datasets (used during development/testing) are suffixed with `_sub`,
e.g. `SRR24442552_sub_1.fastq.gz`. When running pipeline scripts, pass the full
sample name including the suffix:

    bash scripts/01_qc.sh SRR24442552_sub

## Datasets

- **Dataset A (development):** SRR24442552 — biofloc aquaculture metagenome
  (subsampled to 500,000 read pairs via seqtk, seed 100)
- **Dataset B (validation):** TBD — planned marine/sea-ice associated microbiome or clinical dataset where community members might be better represented in databases

## Pipeline Stages

1. QC & Trimming (FastQC, Trimmomatic, MultiQC)
2. Taxonomic Profiling (Kraken2, Bracken)
3. Assembly (MEGAHIT)
4. Binning (MetaBAT2, MaxBin2, refined via DAS Tool — CONCOCT evaluated and excluded, see Progress Log)
5. MAG Quality Assessment (CheckM2)
6. MAG Taxonomy (GTDB-Tk) — script written and integrated, not executed (see Limitations)
7. Functional Annotation (Prodigal + eggNOG-mapper) — planned
8. Optional: read-based functional profiling (HUMAnN) — planned opt-in module, see below

---

## Setup and Environments — READ CAREFULLY

Four separate conda environments are used in this pipeline, due to dependency
conflicts between tools that could not be resolved within a single shared
environment (see [PROGRESS_LOG.md](PROGRESS_LOG.md) for full details of each
conflict and its resolution).

| Environment | File | Used for | Fully reproducible from YAML alone? |
|---|---|---|---|
| `metaflow` | `envs/metaflow_environment.yml` | Core pipeline (QC, taxonomy, assembly, mapping, MetaBAT2) | Yes |
| `maxbin2_env` | `envs/maxbin2_environment.yml` | MaxBin2 binning | Yes |
| `dastool` | `envs/dastool_environment.yml` | DAS Tool bin refinement | **No** — see below |
| `checkm2` | `envs/checkm2_environment.yml` | Bin quality assessment | **No** — see below |
| `gtdbtk` | (created via setup script) | MAG taxonomy (not executed — see Limitations) | Yes |

**`dastool` additional setup required after creating from YAML:**
DAS Tool's R package dependencies (data.table, magrittr, docopt) are installed
directly via CRAN, not via conda, and are therefore not captured in the
exported YAML. Run `scripts/setup/setup_dastool_env.sh` to reproduce this
fully (scripted non-interactively), or manually:
```bash
conda activate dastool
Rscript -e "install.packages('data.table', repos='http://cran.us.r-project.org')"
Rscript -e "install.packages('magrittr', repos='http://cran.us.r-project.org')"
Rscript -e "install.packages('docopt', repos='http://cran.us.r-project.org')"
```
DAS Tool itself is not a conda package — clone it separately via
`scripts/setup/setup_dastool.sh`.

**`checkm2` additional setup required after creating from YAML:**
CheckM2's Python package itself is not installed by its own `checkm2.yml`
environment file (dependencies only), and needs an explicit `pip install .`
from its cloned source. Run `scripts/setup/setup_checkm2_env.sh` to reproduce
this fully, or manually:
```bash
conda activate checkm2
cd tools/CheckM2
pip install .
```
CheckM2's own source is not a conda package — clone it separately via
`scripts/setup/setup_checkm2.sh`. The reference database is downloaded
automatically by `setup_checkm2_env.sh`.

**`gtdbtk` setup:** run `scripts/setup/setup_gtdbtk_env.sh`, which creates the
environment and downloads the ~98GB reference database using GTDB-Tk's own
bundled `download-db.sh`. See Limitations below before running this — the
database and classification step both carry substantial resource requirements.

---

## Running the Pipeline

**All pipeline scripts must be run from the project root directory**
(`metaflow-pipeline/`). Scripts use paths relative to the working directory
for sample data and results. The only exception is references to
externally-cloned tools (e.g., DAS Tool), which resolve relative to each
script's own file location regardless of working directory.

```bash
cd metaflow-pipeline
bash scripts/01_qc.sh <sample_name>
bash scripts/02_taxonomy.sh <sample_name> <path_to_kraken_db>
bash scripts/03_assembly.sh <sample_name>
bash scripts/04_binning.sh <sample_name>
bash scripts/05_checkm2.sh <sample_name>
bash scripts/06_gtdbtk.sh <sample_name>   # see Limitations — resource-intensive, not run in this project
```

---

## Repository Structure

```
metaflow-pipeline/
├── data/
│   ├── raw/              # Original/downloaded sequencing reads (gitignored)
│   └── processed/        # QC'd, trimmed reads (gitignored)
├── databases/             # Reference databases (gitignored)
├── tools/                 # Externally-cloned tools not available as conda packages (gitignored)
│   ├── DAS_Tool/
│   └── CheckM2/
├── results/
│   ├── qc/
│   ├── taxonomy/
│   ├── assembly/
│   ├── bins/
│   └── annotation/
├── scripts/
│   ├── 01_qc.sh
│   ├── 02_taxonomy.sh
│   ├── 03_assembly.sh
│   ├── 04_binning.sh
│   ├── 05_checkm2.sh
│   ├── 06_gtdbtk.sh
│   └── setup/
│       ├── setup_kraken_db.sh
│       ├── setup_humann_db.sh
│       ├── setup_dastool.sh
│       ├── setup_dastool_env.sh
│       ├── setup_checkm2.sh
│       ├── setup_checkm2_env.sh
│       ├── setup_maxbin2_env.sh
│       └── setup_gtdbtk_env.sh
├── envs/
│   ├── metaflow_environment.yml
│   ├── maxbin2_environment.yml
│   ├── dastool_environment.yml
│   └── checkm2_environment.yml
├── docs/
│   ├── README.md (this file)
│   └── PROGRESS_LOG.md
└── notebooks/
    └── results_summary.ipynb
```

---

## Design Rationale

### Why this stage order and tool selection

**QC before anything else.** Sequencing artifacts (adapter contamination,
low-quality base calls) propagate into every downstream step if not removed
first. Assembly in particular is highly sensitive to input read quality.

**Taxonomic profiling (Kraken2/Bracken) before assembly.** Read-based
classification is computationally cheap and gives an immediate community
overview, used as a sanity check before committing to the much more
expensive assembly step, and as an independent cross-validation against MAG
taxonomy assigned later.

**MEGAHIT for assembly.** This project is built around short-read Illumina data, for which de Bruijn
graph assemblers like MEGAHIT or metaSPAdes are the preferred tool class.
MEGAHIT was chosen over metaSPAdes specifically for its lower memory
footprint, appropriate for laptop-scale development; metaSPAdes would be the
natural upgrade on HPC resources for better assembly contiguity. No
polishing step (e.g. Medaka) is required, since polishing addresses
long-read basecalling errors that don't apply to Illumina short-read data. 
A long-read assembler like Flye can easily be swapped into the pipeline.

**Multi-binner ensemble (MetaBAT2 + MaxBin2) refined via DAS Tool.**
Different binners weight tetranucleotide composition and coverage depth
differently and can recover different genomes from the same assembly. DAS
Tool combines multiple binners' outputs and selects the highest-scoring,
non-redundant bin set. CONCOCT was evaluated and excluded — see
[PROGRESS_LOG.md](PROGRESS_LOG.md) for the packaging issue and the
independent, pre-existing limitation (CONCOCT's clustering approach favors
multi-sample coverage profiles, which this single-sample project does not
have).

**CheckM2 run independently on every raw binner output, not just the final
DAS Tool-refined set.** see the Results Summary below for how this surfaced a
disagreement between DAS Tool's internal bin selection and CheckM2's
independent quality assessment.

**Multi-sample-aware script design.** `03_assembly.sh` and `04_binning.sh`
are structured to accept a sample list and support (in principle) both
individual and co-assembly modes, even though this project runs a single
sample. This is intended to make future multi-sample analysis (e.g.,
multiple biofloc tank replicates or timepoints) a configuration change
rather than a script rewrite. See PROGRESS_LOG.md for the full discussion of
why multi-sample coverage improves binning resolution.

**Read-based and assembly-based analysis as parallel branches, not one
linear chain.** Kraken2/Bracken (read-based) and the assembly→binning→
annotation chain answer different questions and have different resource
profiles; assembly-based analysis can discover novel organisms not in any
reference database, while read-based analysis retains some signal even for
organisms too low-abundance to assemble. HUMAnN (optional, see below) adds
read-based functional profiling to complement Kraken2/Bracken's read-based
taxonomic profiling.

### Optional module: HUMAnN (read-based functional profiling)

Kraken2/Bracken provide read-based taxonomy; HUMAnN adds read-based
functional profiling (gene families, pathway abundance), catching
functional signal from organisms too rare to assemble. This is opt-in due
to its substantial additional reference database size (ChocoPhlAn +
UniRef90, ~35-40GB):
- **Setup is opt-in:** `scripts/setup/setup_humann_db.sh` is never run
  automatically; a user must deliberately choose to download HUMAnN's
  databases.
- **Execution is opt-in:** `scripts/02b_humann.sh` is independent of the
  core pipeline chain; no other script depends on its output, and it is
  never called automatically.
- UniRef90 is used by default for better sensitivity,
  since the setup script accepts a direct database URL and a user running
  this deliberately would want the more sensitive, standard option.

---

## Results Summary

See [PROGRESS_LOG.md](PROGRESS_LOG.md) for full day-by-day results,
troubleshooting narrative, and all supporting numbers. 
---

## Limitations & Notes on Scale

This project was developed at laptop scale, using subsampled
data and reduced/capped reference databases, to prioritize fast iteration.
Consequences are documented explicitly:

- **Kraken2 database (PlusPF-8, capped at 8GB):** trades classification
  sensitivity for a memory footprint that fits 16GB development hardware.
  PlusPF-16 was initially attempted and exceeded available memory.
- **500,000 read-pair subsample (of ~45 million available):** sufficient to
  demonstrate pipeline function and characterize the most abundant
  community members, but produces a more fragmented assembly and fewer,
  less-complete MAGs than the full dataset would.
- **MEGAHIT over metaSPAdes:** lower memory footprint at some cost to
  assembly contiguity.
- **CONCOCT excluded:** unresolvable conda packaging issue (see Progress
  Log), compounded by its reduced effectiveness on single-sample coverage
  data even had it installed successfully.
- **GTDB-Tk (Stage 6): script written and integrated, but not executed.**
  GTDB-Tk's classify_wf requires ~140GB RAM (or ~35GB in split-tree mode)
  and a ~98GB reference database . This was not reducible via a smaller 
  pre-built database the way Kraken2 was. This is a scope decision: 
  deferred to dedicated hardware/infrastructure rather than run on constrained
  personal or cloud hardware for a demonstration pipeline. 
  The setup and execution scripts are written, reviewed, and follow the project's
  established conventions, but are untested by actual execution.
- **Functional annotation (Stage 7): planned, not yet implemented.**

---

## Author

Atharva Karde 
[LinkedIn](https://www.linkedin.com/in/atharva-karde-4842252a2/)
