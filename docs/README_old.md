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

##Setup and environments **READ CAREFULLY**

### Environment files

Four separate conda environments are used in this pipeline, due to
dependency conflicts between tools that could not be resolved within a
single shared environment (see Progress Log for full details of each
conflict and its resolution).

| Environment | File | Used for | Fully reproducible from YAML alone? |
|---|---|---|---|
| `metaflow` | `envs/metaflow_environment.yml` | Core pipeline (QC, taxonomy, assembly, mapping, MetaBAT2) | Yes |
| `maxbin2_env` | `envs/maxbin2_environment.yml` | MaxBin2 binning | Yes |
| `dastool` | `envs/dastool_environment.yml` | DAS Tool bin refinement | **No** — see below |
| `checkm2` | `envs/checkm2_environment.yml` | Bin quality assessment | **No** — see below |

**`dastool` additional setup required after creating from YAML:**
DAS Tool's R package dependencies (data.table, magrittr, docopt) were
installed directly via CRAN inside an R session, not via conda, and are
therefore not captured in the exported YAML. After creating the
environment, run:
```bash
conda activate dastool
R
```
```r
repo <- 'http://cran.us.r-project.org'
install.packages('data.table', repos=repo, dependencies=TRUE)
install.packages('magrittr', repos=repo, dependencies=TRUE)
install.packages('docopt', repos=repo, dependencies=TRUE)
q()
```
DAS Tool itself is not a conda package — clone it separately via
`scripts/setup/setup_dastool.sh`.

**`checkm2` additional setup required after creating from YAML:**
CheckM2's Python package itself is not installed by its own `checkm2.yml`
environment file (which installs dependencies only), and needs an
explicit `pip install .` from its cloned source after the environment is
created:
```bash
conda activate checkm2
cd tools/CheckM2
pip install .
```
CheckM2's own source is not a conda package — clone it separately via
`scripts/setup/setup_checkm2.sh`. The reference database must also be
downloaded separately (see Setup & Reproducibility section).

## Running the Pipeline

**All pipeline scripts must be run from the project root directory**
(`metaflow-pipeline/`). Scripts use paths relative to the working
directory for sample data and results. The only exception is references
to externally-cloned tools (e.g., DAS Tool), which resolve relative to
each script's own file location regardless of working directory.


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


**Binning tool selection:** originally planned to use a three-binner ensemble
(MetaBAT2, MaxBin2, CONCOCT) refined via DAS Tool. This was revised during
setup due to genuine package-level dependency issues, detailed below.
 
**MetaBAT2 + MaxBin2 (+ bowtie2, samtools for read-mapping):** installed
cleanly into the `metaflow` environment via conda, no issues.
 
**CONCOCT — dropped from the pipeline.** CONCOCT's bioconda package has not
been updated since 2019 and is pinned to dependency versions (specifically
`openblas >=0.3.5,<0.3.6.0a0`) that no longer exist on current conda
channels. This was confirmed to be a genuine channel/packaging issue rather
than an environment conflict: the same error occurred both inside the main
`metaflow` environment and inside a freshly created, isolated environment
targeting an older Python version. Attempts with `mamba` as an alternative
solver and explicit version pinning (`concoct=1.1.0`) also failed. CONCOCT
was excluded from the binning ensemble as a result.
 
This is also consistent with a separate, independent limitation identified
earlier in pipeline design: CONCOCT's clustering approach is optimized for
multi-sample coverage profiles, and its practical value on this project's
single-sample dataset was already expected to be reduced. The packaging
failure reinforces, rather than contradicts, the decision to proceed without
it at this stage.
 
**DAS Tool — installed via a non-conda workaround.** DAS Tool's bioconda
package also failed to resolve, due to a pinned R dependency
(`r-magrittr >=2.0.1`) conflicting with other available package versions.
Pinning to the specific R version DAS Tool's recipe targets (R 4.1) was
attempted and failed for an unrelated reason: r-base 4.1's own dependency
chain (`libtiff`/`libdeflate`) has also bit-rotted on current conda channels.
 
Resolution: installed a current (unpinned) version of r-base via conda into
a dedicated `dastool` environment, then installed DAS Tool's three required
R packages (`data.table`, `magrittr`, `docopt`) directly from CRAN inside an
R session, bypassing the broken conda recipe entirely. DAS Tool itself was
then obtained directly from its GitHub source
(github.com/cmks/DAS_Tool) rather than as a conda package, and runs as a
script from that cloned directory.
 
**Resulting environment structure for the binning stage:**
- `metaflow` — bowtie2, samtools, metabat2, maxbin2 (read-mapping + binning)
- `dastool` — r-base + CRAN packages, used only for DAS Tool bin refinement
- DAS Tool source: `tools/DAS_Tool/` (cloned from GitHub, not conda-installed)
This required scripts/04_binning.sh to activate different conda environments
for different steps within the same pipeline stage, rather than running
entirely within `metaflow` as earlier stages did.
 
**Why this is documented in detail:** both CONCOCT and DAS Tool's conda
packages failing for genuinely different underlying reasons, in the same
pipeline stage, is a useful illustration of a common real-world bioinformatics
problem — older or less-actively-maintained tools can have conda packaging
that decays over time as their pinned dependencies age out of availability on
current channels. Diagnosing whether a failure is a solver/environment
conflict (fixable by isolation or pinning) versus genuine package rot
(requiring an alternative installation route entirely) is itself a practical
skill, not just a setup inconvenience.

**Read-mapping / coverage generation (bowtie2 + samtools):**
- Mapped trimmed reads back against the MEGAHIT assembly to generate
  per-contig coverage depth (required input for MetaBAT2 and MaxBin2)
- Overall alignment rate: 33.16%
- This is likely explained by the assembly statistics
  already logged: only ~10.8 Mbp of the ~150 Mbp of input read sequence
  was represented in assembled contigs at this subsampling depth, so the
  majority of reads (originating from lower-abundance community members
  that did not assemble into contigs) do not map back to the assembly.
  This is the same underlying limitation — insufficient sequencing depth
  per organism at the 500K read-pair subsampling level — surfacing at a
  different pipeline stage, following the same pattern as the low Kraken2
  classification rate observed during taxonomic profiling.
- Depth file generated via jgi_summarize_bam_contig_depths
  (MetaBAT2's utility), used as shared input for both MetaBAT2 and
  MaxBin2 binning
- Next: run MetaBAT2 and MaxBin2 on the assembly + depth file, then
  DAS Tool consensus refinement

**MaxBin2 — additional dependency issues resolved:**
- The installed bioconda build (2.2.1) shipped only the raw `MaxBin` binary,
  missing the `run_MaxBin.pl` wrapper script that handles marker-gene-based
  seed detection automatically (via FragGeneScan + HMMER). Upgrading to
  2.2.7 hit the same class of R-dependency channel rot seen with CONCOCT
  and DAS Tool (`r-gplots`/`r-catools` pinned to unavailable R 3.2/3.3
  builds). Resolved by installing MaxBin2 2.2.7 into its own isolated
  `maxbin2_env` environment, which resolved cleanly.
- Result: 2 bins recovered (bin.001, bin.002)
**MetaBAT2 — result:**
- 1 bin recovered: 6.5 Mbp, 2,120 contigs, N50 3,319 bp, GC 57.04%
  (GC closely matches whole-sample GC, consistent with this representing
  the single dominant community member identified in earlier stages)
**DAS Tool — additional dependency issues resolved, then run successfully:**
- Beyond the R/magrittr conda packaging issue already documented, the
  DAS Tool wrapper itself (once running) required prodigal, diamond,
  pullseq, and ruby as runtime dependencies, none of which were installed
  by default in the manually-constructed `dastool` environment (since
  DAS Tool was installed via CRAN + GitHub source, not conda, its
  bioconda-declared dependency list was never applied). Installed all
  four directly via conda into the `dastool` environment.
- SCG database (db.zip) required manual extraction into a `db/`
  subfolder to match DAS Tool's default `--dbDirectory` expectation.
**DAS Tool — final result:**
- Given MetaBAT2's 1 bin and MaxBin2's 2 bins as input, DAS Tool selected
  only **one** bin for its final refined output: MaxBin2's bin.002.
- Selected bin: 3.9 Mbp, 1,670 contigs, N50 2,583 bp
- SCG completeness: 65%, SCG redundancy: 0%
- MetaBAT2's bin and MaxBin2's other candidate bin were both excluded
  from the final consensus set, implying they scored lower on DAS Tool's
  completeness/redundancy criteria than the selected bin — a plausible,
  explainable outcome given this pipeline's multi-binner design is
  specifically intended to catch and discard lower-quality or
  higher-contamination candidate bins rather than retain everything.
- Zero SCG redundancy is a positive signal that this bin represents a
  single coherent organism rather than a merged/contaminated cluster,
  despite its incomplete (65%) recovery — consistent with expectations
  given the fragmented assembly produced at this subsampling depth.
**Environment structure for the binning stage (final):**
- `metaflow` — bowtie2, samtools, metabat2
- `maxbin2_env` — MaxBin2 2.2.7 (isolated due to R dependency conflicts)
- `dastool` — r-base + CRAN packages + prodigal, diamond, pullseq, ruby
  (DAS Tool itself run from cloned GitHub source, not conda-installed)

**CheckM2 setup:** also required an isolated environment due to a known,
actively-tracked conda solver conflict (checkm2 requiring a pinned
tensorflow version with no installable providers — see
github.com/chklovski/CheckM2/issues/141). Resolved using CheckM2's own
maintainer-provided `checkm2.yml` environment file
(`conda env create -n checkm2 -f checkm2.yml`) rather than a plain
`conda install`, followed by `pip install .` from the cloned source, since
the yml file installs dependencies only, not the CheckM2 package itself.
 
**Results across all three binner outputs:**
 
| Bin | Source | Completeness | Contamination | MIMAG tier |
|---|---|---|---|---|
| bin.1 | MetaBAT2 (raw) | 65.24% | 1.65% | Medium-quality |
| bin.001 | MaxBin2 (raw) | 34.55% | 1.69% | Below medium-quality |
| bin.002 | MaxBin2 (raw) | 53.61% | 0.60% | Medium-quality |
| bin.002 | DAS Tool (refined, selected) | 53.61% | 0.60% | Medium-quality |
 
**Key finding — DAS Tool's internal selection disagreed with CheckM2's
independent assessment.** DAS Tool selected MaxBin2's bin.002 as its sole
final output (internal SCG-based score: 0.647), excluding MetaBAT2's bin.1
entirely. However, CheckM2 — a more recent, machine-learning-based
completeness/contamination estimator generally considered more accurate
than raw single-copy-gene counting — scored MetaBAT2's bin.1 as more
complete (65.24% vs. 53.61%) with comparable contamination (1.65% vs.
0.60%). By CheckM2's independent assessment, MetaBAT2's bin.1 would be the
stronger MAG to report, contradicting DAS Tool's own selection.
 
This discrepancy is attributed to the two tools using fundamentally
different scoring approaches: DAS Tool's internal score is based on raw
single-copy marker gene presence/absence counting with configurable
penalty weights, while CheckM2 uses a gradient-boosted machine learning
model trained on a large genome reference set. This is precisely why this
pipeline was deliberately designed to run CheckM2 independently on every
raw binner output, rather than trusting DAS Tool's internal selection
without independent verification — a design decision that directly paid
off here by surfacing a real, non-obvious disagreement between two
legitimate quality-assessment methods.
 
**Framing for this result:** the pipeline's purpose is to reliably produce
and surface these standardized quality metrics for any input dataset, not
to guarantee a particular biological outcome on this specific, deliberately
small development dataset. Neither bin reaches MIMAG high-quality
thresholds (≥90% completeness, ≤5% contamination) here, which is an
expected consequence of the 500K read-pair subsampling depth chosen for
fast iteration (see earlier assembly/mapping log entries) — not a defect
in the pipeline's logic. The same pipeline, pointed at the full,
non-subsampled dataset or run on HPC infrastructure, would be expected to
produce substantially more complete MAGs, since assembly contiguity and
binning resolution both scale directly with sequencing depth.
 
**Next priorities (revised, per project discussion):** with the core
analytical pipeline now functionally complete end-to-end on Dataset A,
focus shifts to reproducibility and deployability — ensuring all setup
scripts reliably install their dependencies (documenting the several
isolated-environment workarounds discovered during this build as
first-class, scripted parts of setup rather than manual tribal knowledge),
and wrapping the full pipeline in Snakemake so it can be deployed
plug-and-play on other systems, including HPC.

### Day 3 — Environment Reproducibility & Setup Script Audit

**Environment YAML exports:** all four conda environments used in this
pipeline (`metaflow`, `maxbin2_env`, `dastool`, `checkm2`) were exported to
`envs/*.yml`. Note: `dastool_environment.yml` and `checkm2_environment.yml`
capture conda-installed packages only — DAS Tool's required R packages
(installed via CRAN) and CheckM2's own package (installed via `pip install
.`) are not captured by a plain conda export and require the additional
setup steps documented in the Setup & Reproducibility section above.

**New verified setup scripts added:**
- `setup_maxbin2_env.sh` — isolated environment creation, pinned to
  MaxBin2 2.2.7 (required for the bundled `run_MaxBin.pl` wrapper)
- `setup_dastool_env.sh` — r-base + CRAN package installation
  (data.table, magrittr, docopt) scripted non-interactively via
  `Rscript -e`, plus DAS Tool's runtime dependencies (prodigal, diamond,
  pullseq, ruby)
- `setup_checkm2_env.sh` — environment creation from CheckM2's own
  `checkm2.yml`, `pip install .`, and database download, each step
  individually idempotent (checks for existing environment/database
  before acting)

All three scripts were verified against the actual working environments
built during troubleshooting (Day 2), confirming the scripted sequence
exactly reproduces what was manually debugged, rather than just looking
plausible on paper.

**Hardcoded path audit:** systematically checked all pipeline scripts
(01-05) for path assumptions that would break if run from a different
working directory or on a different machine. Finding: only one
issue existed, in `04_binning.sh`'s reference to the externally-cloned
DAS Tool source (`tools/DAS_Tool/`), which was fixed to resolve relative
to the script's own file location rather than the working directory.

All other directory variables across every script (`RAW_DIR`,
`PROCESSED_DIR`, `QC_DIR`, `TAXONOMY_DIR`, `ASSEMBLY_DIR`, `BINNING_DIR`,
etc.) are deliberately working-directory-relative, following an explicit
project convention: **all pipeline scripts must be run from the project
root directory.** This is distinct from, and not a bug alongside, the
DAS Tool fix — pipeline data paths (per-sample inputs/outputs) and tool
installation paths (fixed, one-time locations) are different categories
with different correct resolution strategies, and only the latter
appeared in this codebase outside of the working-directory convention.

**Design decision — setup orchestration deferred to Snakemake:**
considered building a `setup_all.sh` master script to check/install all
databases, environments, and cloned tools in one step (rather than
requiring the user to run each setup script individually). Decided
against building this in bash: Snakemake natively supports per-rule
conda environment creation (via `--use-conda` and a `conda:` directive
per rule) and can declare required input files/databases as prerequisites
a rule won't run without — both of which are exactly what a hand-built
`setup_all.sh` would otherwise reimplement, and would likely need to be
substantially rewritten once the Snakemake wrapper is built regardless.
This work is therefore deferred to the Snakemake implementation phase
rather than duplicated now. Individual setup scripts remain available
and independently idempotent in the meantime.

**Multi-environment orchestration (deferred to Snakemake):** `04_binning.sh`
currently hand-switches between three conda environments
(`metaflow`, `maxbin2_env`, `dastool`) via repeated `conda activate` calls.
Considered consolidating this into a shared helper script, but decided
against it for the same reason setup orchestration was deferred (see
above): Snakemake's own per-rule `conda:` directive (with `--use-conda`)
natively replaces this entire pattern, activating the correct environment
per rule automatically. Building a bash-level abstraction now would
likely be discarded once the Snakemake wrapper is in place, so this
pattern is left as-is in the interim.

**Manual-vs-scripted setup audit — conclusion:** reviewed all remaining
setup steps across the pipeline to identify what still requires manual
intervention versus what can be fully scripted. Finding: after today's
work, there is very little manual setup remaining by necessity. DAS
Tool's previously-manual CRAN package installation is now scripted
non-interactively (via `Rscript -e`). The only genuinely manual/optional
step by design, rather than limitation, is HUMAnN's two-flag (setup vs.
run) opt-in, which is intentionally not automatic (see HUMAnN design
notes above). The GTDB-Tk database setup (not yet performed) will require
setting the `GTDBTK_DATA_PATH` environment variable, which is trivially
scriptable and will be included in that stage's setup script when built.
This item is considered resolved rather than outstanding.
