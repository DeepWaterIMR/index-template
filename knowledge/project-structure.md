# The generated project structure

`index-new-project` copies `project-template/` and stamps it with `config.yaml` to produce a
**new project folder** for one species (or a small group of related species). This is the
"output" structure — the user's own repo. index-template itself is never this structure.

```
<species>-index/
├── AGENTS.md            # Project agent contract (points back at the index-template method)
├── CLAUDE.md            # Thin Claude Code pointer
├── config.yaml          # The one place species/area/model settings live
├── _run_analysis.R      # Render all model documents and update data end-to-end
├── .gitignore           # Ignores data/, logs/, review/, renders, .quarto/
├── R/                   # Scripts shared by the docs
│   └── 00_setup.R        # Packages, ggplot theme, paths, config loader
├── memory/              # AI-agent PROJECT memory (use THIS, not local agent memory)
│   ├── MEMORY.md         # Index of memory files (read first)
│   ├── README.md         # Memory format & rules
│   ├── scaffold-interview.md   # The questionnaire answers for this project
│   ├── workflow.md       # Which steps are done / pending
│   └── constraints.md    # Project-specific hard rules
├── docs/
│   ├── data/            # STEP 1 — data compilation + data report
│   │   ├── compile-data.qmd            # reads BES (+ optional SPD), filters, dedupes, saves
│   │   └── <species>-data-report.qmd   # the data report (SI-Text-1 style)
│   ├── exploration/     # STEPS 2–3 — fit & validate
│   │   ├── fit.qmd                     # first feasible model (no length groups)
│   │   └── validate.qmd                # model selection / CV / retro
│   └── <species>/       # STEP 4 — final report + extensions (ONE folder per species)
│       ├── report.qmd
│       ├── mesh-section.qmd
│       ├── barrier-section.qmd
│       ├── retro-section.qmd
│       ├── cross-validation-section.qmd
│       └── survey-comparison-section.qmd
├── data/
│   ├── source/          # local source data (GIS polygons, SPD extracts) — gitignored
│   └── output/          # model outputs (.rds/.rda: fits, grids, predictions, indices) — gitignored
├── logs/                # screen-session render logs — gitignored
└── review/              # AI reviews, duplicate reports, temp — gitignored
```

## Rules

- **`data/`, `logs/`, `review/` are git-ignored.** Only code, docs, `memory/`, and
  `config.yaml` are committed. No raw data or private paths in tracked files.
- **`config.yaml` is the single source of truth** for species, `filter_sp`, surveys, response
  variables, length groups, study area / CRS / grid size / mesh cutoff, gear-width policy, and
  output paths. Documents read from it (via `R/00_setup.R`); they do not hard-code settings.
- **Multiple species** → one `docs/<species>/` folder each, all sharing `docs/data/` and
  `docs/exploration/` where the compiled dataset supports it. Otherwise scaffold one project
  per species.
- **Outputs cache to `data/output/`.** Expensive fits, prediction grids, predictions, and
  indices are saved there so re-renders load instead of recomputing (toggle-controlled — see
  `rendering.md`).
- **Project memory lives in `memory/`.** Agents read `memory/MEMORY.md` first and write new
  memory files there — not in the agent's local per-machine memory.

## `config.yaml` fields (stamped by `scaffold.R`)

`SPECIES_NAME` (display), `SPECIES_SLUG` (folder/file slug), `SPECIES_LATIN`, `FILTER_SP`
(Norwegian commonname value(s)), `SURVEYS` (cruise series to include), `USE_SPD` (true/false),
`RESPONSE` (`biomass`/`abundance`), `LENGTH_GROUPS`, `OVER_CM` threshold, `ASSESSMENT_MODEL`,
`FIRST_YEAR`, `CRS` (EPSG), `GRID_KM`, `MESH_CUTOFF_KM`, `BARRIER` (true/false), `GEAR_WIDTH`
(`per_gear`/set value), `INCLUDE_RUSSIAN` (default true), `SELECTED_INDEX`.
