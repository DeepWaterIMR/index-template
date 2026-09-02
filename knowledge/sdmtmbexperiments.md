# sdmTMBexperiments — the helper catalogue

[sdmTMBexperiments](https://github.com/DeepWaterIMR/sdmTMBexperiments) holds the helper
functions for this workflow: prediction grids, diagnostic maps, model/mesh/survey comparisons,
retrospectives, and cross-validation. **Use these instead of reinventing them** — they replace
the inline helpers that used to live in `ref-index-paper` and `ref-assessment-index`.

Install and attach:

```r
# install.packages("remotes")
remotes::install_github("DeepWaterIMR/sdmTMBexperiments")
library(sdmTMBexperiments)   # ATTACH (not just ::) — this attaches ggOceanMaps so basemaps
                             # find their bundled land data
```

## Conventions

- **Coordinates in kilometres.** Model `X`/`Y` are km (sdmTMB standard); helpers multiply by
  `coord_multiplier` (default `1000`) to reach CRS metres. Passing metres misplaces the data.
- **Maps** are drawn on `ggOceanMaps::basemap()` — hence attach the package.
- **Argument names mirror sdmTMB**: `newdata`, `mesh`, `time`, `bias_correct`, `level`,
  `area`; parallelism uses `n_workers` and `future_seed`.
- Comparison functions return **S3 objects with `plot()` methods** (`type = "index"`,
  `"spatial"`, `"scatter"`).
- Some functions need suggested packages: `concaveman` (survey regions), `blockCV`
  (`sdmTMB_mesh_cv`), `inlabru` (`plot_mesh`), `DHARMa`/`ggspatial` (`bubble_map`).

## Model selection

| Function | Purpose |
|---|---|
| `sdmTMB_selection(candidates, data, ...)` | Fits a named list of candidate specifications to identical records; returns a tidy table (spec, crash/convergence/sanity, `comparable`, NLL, AIC, ΔAIC, Akaike weights, and CV columns when `cv` is set) plus the fits. Covers every selection stage — components, fixed effects, family, spatiotemporal structure, mesh cutoff — because each is the same operation with a different thing varied. `cache_dir` writes one file per candidate (resumable); `only` restricts a call to named candidates so a long ladder can be spread over several R sessions. |
| `selection_frame(data, candidates, extra)` | The complete-case frame that makes those columns comparable: drops rows incomplete for **any** candidate. |
| `sdmTMB_cv_summary(cv, label)` | Summarises an `sdmTMB::sdmTMB_cv()` run **per held-out observation** (not summed), with `folds_pdhess` and `n_heldout`. |
| `best_candidate(x, n, by)` | The winner, looked up in the metric column among `comparable` rows — never by row position. `n > 1` builds a CV shortlist from an AIC ladder. |
| `add_aic_weights(x, group)` | ΔAIC + Akaike weights for any table with an `AIC` column; `group` keeps models fitted to different response data in separate weighting sets. |
| `plot(sel)` / `plot(sel, type = "index", newdata = grid)` | Status-coded ranking dot plot; and the index each candidate produces — the check that says whether the choice moves the index at all. |

**Read `model-selection.md` before using these.** The rules there (identical records, comparability, per-observation likelihood, AIC-then-CV) are the point; the functions are only the mechanics.

## Prediction grids

| Function | Purpose |
|---|---|
| `make_survey_prediction_region(data, crs, concavity = 5, buffer = 1)` | Concave-hull `sf` polygon of the survey footprint (needs `concaveman`). |
| `make_prediction_grid(region, resolution, max_depth = NULL, depth_fun = NULL)` | Regular grid of cell centres over a region; optional depth filter. Returns X, Y (km) (+ depth). Has a `plot()` method. |

## Diagnostic maps & plots (all on a ggOceanMaps basemap)

| Function | Shows |
|---|---|
| `plot_mesh(mesh, crs, data = NULL)` | The SPDE mesh, sampling points, and barrier ("land") triangles. |
| `plot_prediction_map(pred, crs, column = "est", type = "mean"|"annual")` | Predicted density (mean or per year). |
| `plot_random_field(pred, crs, field = "omega"|"epsilon")` | Spatial / spatiotemporal random fields. |
| `plot_residual_qq(fit)` | Q-Q of randomised-quantile residuals. |
| `plot_fixed_effects(fit)` | Fixed-effect estimates with CIs. |
| `plot_variance_partitioning(fit)` | Variance components. |
| `plot_prediction_histogram(fit)` | Observed vs predicted distribution. |
| `bubble_map(data, ncol, label)` | Sized/coloured bubbles of density per station. |

## Comparisons (fit variants → indices + per-cell differences → `plot()`)

| Function | Compares |
|---|---|
| `compare_models(..., newdata, reference_model = 1)` | A set of fitted models — indices, per-cell prediction diffs vs a reference, sanity checks. Plot `type = "index"` or `"spatial"`. |
| `compare_meshes(object, mesh_cutoffs, newdata)` | Index/prediction sensitivity to mesh cutoff (refits across cutoffs). |
| `compare_surveys(data, compiled_index, surveys, newdata, ...)` | Survey-specific indices vs a compiled reference; builds per-survey grids from concave hulls. Plot `type = "index"`, `"scatter"`, `"spatial"`. |

## Retrospective & cross-validation

| Function | Purpose |
|---|---|
| `sdmTMB_retro(object, newdata, nyears = 5, refit_meshes = FALSE)` | Analytical retrospective — refits per peel, index per peel via `get_index_split()`. `plot()` annotates Mohn's rho. |
| `sdmTMB_mesh_cv(object, mesh_cutoffs, k = 3)` | Spatial block CV across mesh cutoffs (`blockCV::cv_spatial()` + `sdmTMB_cv()`). `plot(metric = "sum_loglik"|"deltaAIC")`. |
| `mohns_rho(index_df, group_col, reference)` | Mohn's retrospective bias statistic. |

## Typical use in the workflow

- **Step 2 (fit):** `plot_mesh`, `make_survey_prediction_region`, `make_prediction_grid`,
  `plot_prediction_map`, `plot_random_field`, `plot_residual_qq`.
- **Step 3 (validate):** `sdmTMB_selection` + `selection_frame` / `best_candidate` /
  `selection_kable` for the selection stages; then `compare_meshes`, `sdmTMB_mesh_cv`,
  `sdmTMB_retro`, `mohns_rho`. Use `compare_models` when you want per-cell *spatial*
  prediction differences between two or three finished fits — `sdmTMB_selection` is for
  ranking many candidates.
- **Step 4 (report):** all of the above, plus `compare_surveys` for the survey-comparison
  section and `plot_fixed_effects` / `plot_variance_partitioning` for the results.

See the package's vignette (`vignette("sdmTMBexperiments")`) for an end-to-end example on the
bundled `sebastes` data, and its `AGENTS.md`/`CLAUDE.md` for the full argument reference.
