---
name: index-validate-model
description: Step 3 of the index workflow — validate and select the sdmTMB model via cross-validation and sensitivity analysis (fixed-effect ranking, family, spatiotemporal structure, mesh resolution, retrospective). Use after a first feasible model works (step 2).
---

# Step 3 — Validate / select the model

Goal: justify the model. Rank components by predictive skill, select the family and
spatiotemporal structure, and check robustness to mesh resolution and to dropping recent
years. (For background material, see the lookup table in `knowledge/workflow.md`.)

Read `knowledge/sdmtmbexperiments.md` first. Use the helpers — don't hand-roll CV loops.

## Work in `docs/exploration/validate.qmd`

1. **Component ranking** — compare candidate fixed effects (`geartype`, `s(month)`,
   `s(depth)`, optionally `s(temperature)`) and random-field structures by cross-validated
   predictive skill / NLL.
2. **Model selection** — forward-select the fixed effects that improve predictive skill;
   `compare_models(..., newdata = grid)` gives indices, per-cell prediction differences, and
   sanity across candidates (`plot(type = "index")`, `plot(type = "spatial")`).
3. **Family** — compare `delta_lognormal()`, `delta_gamma()`, `tweedie()`.
4. **Spatiotemporal structure** — compare `iid`, `ar1`, `rw`, `off`. Remember the assessment
   use-case: total/length indices → `ar1` (no year effect); the assessment-selected index →
   often `iid` + `year` as a fixed effect (avoids temporal smoothing).
5. **Mesh sensitivity** — `compare_meshes(fit, mesh_cutoffs = c(...), newdata = grid)` and
   `sdmTMB_mesh_cv(fit, mesh_cutoffs = c(...), k = ...)` (needs `blockCV`); plot
   `sum_loglik` / `deltaAIC`.
6. **Retrospective** — `sdmTMB_retro(fit, newdata = grid, nyears = 5)` and `mohns_rho()`.

## Toggles & rendering

CV, mesh comparison, and retros are the slowest steps — put each behind its own compute toggle
and cache results to `data/output/`. **Code-review before rendering**; render via
`index-render` in a screen session with a log; **suggest running on a server**. Flip toggles to
`FALSE` after the first successful render.

## Output

A defended model specification (formula, family, spatiotemporal structure, mesh cutoff, barrier
choice). Record the decision and its evidence in project memory.

## Next

Step 4 — final report and extensions (`index-final-report`).
