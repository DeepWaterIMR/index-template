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
- **Step 3 (validate):** `compare_models`, `compare_meshes`, `sdmTMB_mesh_cv`, `sdmTMB_retro`,
  `mohns_rho`.
- **Step 4 (report):** all of the above, plus `compare_surveys` for the survey-comparison
  section and `plot_fixed_effects` / `plot_variance_partitioning` for the results.

See the package's vignette (`vignette("sdmTMBexperiments")`) for an end-to-end example on the
bundled `sebastes` data, and its `AGENTS.md`/`CLAUDE.md` for the full argument reference.
