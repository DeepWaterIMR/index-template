---
name: index-validate-model
description: Step 3 of the index workflow — validate and select the sdmTMB model via cross-validation and sensitivity analysis (component ranking, fixed effects, family, spatiotemporal structure, mesh resolution, retrospective). Use after a first feasible model works (step 2).
---

# Step 3 — Validate / select the model

Goal: leave behind a **defended specification** — formula, family, spatiotemporal structure,
mesh cutoff, barrier — with the evidence for each and an honest note wherever the carried
model is not the winner.

**Read `knowledge/model-selection.md` first**, then `knowledge/sdmtmbexperiments.md`. The
method is the comparability contract in the first file; the functions are only the mechanics.
Use `sdmTMBexperiments::sdmTMB_selection()` — do not hand-roll a CV loop.

Before producing project files, read `knowledge/academic-writing.md` and the installed
`academic-style`, `academic-conventions`, and `academic-data-report` skills. Apply their
conventions to every generated artifact; retain index-template's scientific workflow.

## Work in `docs/data-report/validation/validate.qmd`

The document already has the five stages wired up, each with its own compute toggle and its own
cache prefix. Adapt the candidate lists to the species and config; do not restructure it
without reason.

1. **Component ranking** — what each single term is worth on its own (`s(depth)`, `s(month)`,
   `fyear`, `geartype`, optionally `s(temperature)`), plus fields-only, no-spatial and
   no-spatiotemporal rows.
2. **Fixed effects** — the full model, each term dropped in turn, and the null.
3. **Cross-validation of a shortlist** — the top `cv_top_n` by AIC only. CV costs `k` fits per
   candidate; cross-validating the whole ladder costs days and changes nothing.
4. **Family** — `delta_lognormal()`, `delta_gamma()`, `tweedie()`.
5. **Spatiotemporal structure** — `iid`, `ar1`, `rw`, `off`, and `iid` + `fyear`. Remember the
   assessment use-case: total/length indices → `ar1` with no year effect; the
   assessment-selected index → often `iid` + `year` as a fixed effect, to avoid temporal
   smoothing. Confirm with the user which the assessment consumes.
6. **Mesh resolution** — a cutoff ladder through `sdmTMB_selection()`, plus
   `sdmTMB_mesh_cv(fit, mesh_cutoffs = c(...), k = ...)` (needs `blockCV`) and
   `compare_meshes()`.
7. **Retrospective** — `sdmTMB_retro(fit, newdata = grid, nyears = 5)` and `mohns_rho()`.

**Every stage produces three outputs**: the table, `plot(sel)` (status-coded ranking), and
`plot(sel, type = "index", newdata = grid)`. The third is the one that decides whether the
stage mattered — a choice that does not move the index is not worth arguing about.

## Non-negotiables

- **Identical records.** Build the selection frame once with `selection_frame()`; fit the
  chosen specification to the full data afterwards.
- **Compare only `comparable` rows**, and never quote a delta unless both candidates are
  comparable. `sanity()` is reported but does not gate comparability.
- **Look the winner up in the column** (`best_candidate()`), never at row 1.
- **State the full specification**, not a row label.
- **Record the gap** when the carried-forward model is not the table's winner.

## Toggles & rendering

CV, mesh comparison and retros are the slowest steps — each is behind its own toggle, and
`sdmTMB_selection(cache_dir =)` caches one file per candidate so an interrupted stage resumes.
`only = "<candidate>"` spreads a long stage across R sessions when memory is the constraint.
**Code-review before rendering**; render via `index-render` in a screen session with a log;
**suggest running on a server**. Flip toggles to `FALSE` after the first successful render.

## Output

A defended model specification and a short "Decision" section stating it, the evidence, and any
deliberate divergence from the table. Record it in project memory.

## Next

Step 4 — final report and extensions (`index-final-report`).
