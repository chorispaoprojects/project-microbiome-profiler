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
