---
name: index-compile-data
description: Step 1 of the index workflow — compile bottom-trawl survey data for a species from the IMR Biotic database (and optional SPD files), apply the quantitative-catch filtering, remove duplicates, compute swept-area density, and write a data report. Use after a project is scaffolded and the user is ready to prepare the data. Needs a local BES database and IMR intranet.
---

# Step 1 — Compile & report the data

Goal: produce one clean, filtered dataset of bottom-trawl stations with true absences and
swept-area density for the target species, plus a data report. **Read
`knowledge/data-filtering.md` in full and reproduce its logic exactly** — this is where indices
most often go wrong.

**Prerequisites:** a locally installed BES Biotic database and an **IMR intranet connection**.
Use BAIT for data access: `biotic-server-setup` (if the DB is missing/stale), `biotic-connect`,
`biotic-query`, `taxaindex` (species) and the cruise-series lookup (surveys).

## Work

1. **Adapt the compilation document** `docs/data/compile-data.qmd` for this species: set
   `filter_sp` and the survey list from `config.yaml`. Read `stnall` (stations) and `indall`
   (individual/length) from the Biotic database via BAIT.
2. **Apply the station filter** from `knowledge/data-filtering.md`: `gearcondition %in% 1:2`,
   the conditional `samplequality` rule (coastal series `cruiseseriescode == "23"` → `1:2`,
   else `1`), `stationtype` exclusions, `distance` 0.3–5 nmi, research/charter missions,
   `startyear` window. Russian data **included by default** (opt-out only).
3. **Keep true zeros** — join species catch onto the full retained-station set so absences are
   preserved.
4. **Remove duplicates** — flag ids where length sample exceeds catch; drop them; write the
   duplicate report to `review/`.
5. **Optional SPD files** — only if `USE_SPD: true` (northern/offshore species). Drop SPD
   years/series already in Biotic; tag `source`. For southern/coastal species, skip SPD.
6. **Swept-area density** — apply the gear-width policy from `config.yaml` (`per_gear` or set
   width) to compute `rho_biomass` / `rho_abundance`. If a set width is used with multiple gear
   types, ensure `geartype` is retained for the model.
7. **Depth** — fill missing/invalid depths from GEBCO (`ggOceanMaps::get_depth()`).
8. **Length data** — fit length–weight (`ggFishPlots::plot_lw()`) and allocate catches to
   length groups if the project needs length-based products.
9. **Save** the compiled dataset to `data/output/` (gitignored).

## Data report

Generate `docs/data/<slug>-data-report.qmd`: station maps (ggOceanMaps), station counts by
year/depth, response-variable distributions, trawl-parameter summaries (distance, duration,
door spread, wire ratio), and the length–weight / length-group allocation. Use
`fig-format: jpeg` for rasters; keep the HTML small. (For background material, see the lookup
table in `knowledge/workflow.md`.)

## Before rendering

**Code-review the compilation chunks first** (filtering is easy to get subtly wrong), then
render via `index-render` in a screen session with a log in `logs/`. Write a memory note
recording the survey list, filter choices, and any duplicates found.

## Next

Step 2 — fit the first feasible model (`index-fit-model`).
