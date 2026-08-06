# AGENTS.md — {{SPECIES_NAME}} survey index

This project builds a **spatiotemporal sdmTMB survey index** for **{{SPECIES_NAME}}**
(*{{SPECIES_LATIN}}*) for stock assessment, using the method of Vihtakari et al. (2026,
ICES JMS). It was scaffolded from
[index-template](https://github.com/DeepWaterIMR/index-template).

> Codex, Cursor, Gemini CLI, Mistral, and other agents read this file. Claude Code reads
> [`CLAUDE.md`](CLAUDE.md).

## The method lives in index-template

The *how* — data filtering, sdmTMB usage, the helper functions, the four-step workflow,
rendering discipline — is documented in the installed **index-template** knowledge pack and
its `index-*` skills. **Read those; don't re-derive the method here.** Data access comes from
**BAIT** (`biotic-*` skills). If either is missing, install it (`install
https://github.com/DeepWaterIMR/index-template`).

## This project's rules

1. **`config.yaml` is the single source of truth.** Species, surveys, response, length
   groups, CRS, map display settings, grid size, mesh cutoff, gear-width policy, and the selected
   index all live there and are read at run time by `R/00_setup.R`. Don't hard-code them in the qmds.
2. **No data or private paths in tracked files.** `data/`, `logs/`, and `review/` are
   git-ignored. Real GIS polygons and data extracts go in `data/source/` only.
3. **Filter correctly.** Reproduce index-template's `data-filtering.md` exactly
   (`gearcondition`, the conditional `samplequality`, `stationtype`, duplicates, true zeros,
   swept-area density). This is where indices most often go wrong.
4. **Start simple.** First model has no length groups and no temperature term.
5. **Step 1 roles are distinct.** `compile-data.qmd` is survey selection and coverage;
   `<species>-<region>-data-report.qmd` is the compiled station/response report and owns length
   products and diagnostics. Do not duplicate length-allocation material in survey selection.
6. **Document provenance is explicit.** Keep the `VERSION` date label and the
   index-template/researcher-supervised-AI provenance statement near the beginning of both Step 1
   documents; add project-specific authors and affiliations in their YAML headers.
7. **Review before you render.** Renders are slow — code-review changed chunks and fix issues
   first, then render in a screen session with a log in `logs/` (index-template `index-render`
   skill). Flip compute toggles to `FALSE` once `data/output/` files exist.

## Workflow

| Step | Document(s) | index-template skill |
|---|---|---|
| 1. Compile & report data | `docs/data/compile-data.qmd`, `docs/data/{{SPECIES_SLUG}}-{{REGION_SLUG}}-data-report.qmd` | `index-compile-data` |
| 2. Fit first model | `docs/exploration/fit.qmd` | `index-fit-model` |
| 3. Validate / select | `docs/exploration/validate.qmd` | `index-validate-model` |
| 4. Final report + export | `docs/{{SPECIES_SLUG}}/report.qmd` (+ `*-section.qmd`) | `index-final-report` |

Full rebuild: `Rscript _run_analysis.R` (slow — see the rendering rules).

## Project memory

Read [`memory/MEMORY.md`](memory/MEMORY.md) first. Record non-obvious decisions as new memory
files here (this shared `memory/` folder — **not** your local per-machine memory) and add a
pointer to `MEMORY.md`. The questionnaire answers are in `memory/scaffold-interview.md`.

## House style

tidyverse; coordinates in km for sdmTMB; attach `library(sdmTMBexperiments)`; **do not
hard-wrap prose** in qmd files; raster figures `fig-format: jpeg`; keep HTML small.
