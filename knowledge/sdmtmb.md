# sdmTMB essentials for survey indices

[sdmTMB](https://github.com/sdmTMB/sdmTMB) fits spatial and spatiotemporal GLMMs with Gaussian
random fields (via TMB + a SPDE mesh). Docs: <https://pbs-assess.github.io/sdmTMB/>. **Read
the docs before writing model code — do not guess the API.** This file is the minimum you
need for a survey index; the helpers in `sdmtmbexperiments.md` wrap most of the tedious parts.

## The model

A survey index model predicts density at every point in space and time, then integrates over
a prediction grid to get a total. The building blocks:

- **Response** — swept-area density (`rho_biomass` in kg·nmi⁻², or `rho_abundance` in
  n·nmi⁻²). See `data-filtering.md`. (The benchmark alternatively models raw catch with a
  swept-area **offset**; density-as-response is the default here, matching the paper.)
- **Fixed effects** — `~ 0 + geartype + s(month) + s(depth)`. The `0 +` drops the global
  intercept so each `geartype` level is estimated directly; `s()` are penalised smooths
  (mgcv-style) for seasonal and depth effects. **No temperature term by default.**
- **Spatial random field** `omega_s` — `spatial = "on"`. Time-invariant spatial structure.
- **Spatiotemporal field** `epsilon_st` — `spatiotemporal = "ar1"` (also `"iid"`, `"rw"`,
  `"off"`), with `time = "year"`. AR1 shares information across years; IID does not.
- **Family** — `delta_lognormal()` (a hurdle: binomial presence × lognormal positive
  density). Alternatives: `delta_gamma()`, `tweedie()`.

## Coordinates — kilometres

sdmTMB expects projected `X`/`Y` in **kilometres**. Add them from lon/lat with:

```r
dt <- sdmTMB::add_utm_columns(dt, ll_names = c("lon", "lat"), utm_crs = 32633)  # X, Y in km
```

Keep the CRS (here EPSG:32633, UTM 33N) — you need it for the grid and maps. `sdmTMBexperiments`
helpers multiply `X`/`Y` by `coord_multiplier = 1000` to get CRS metres.

## Mesh

```r
mesh <- sdmTMB::make_mesh(dt, xy_cols = c("X", "Y"), cutoff = mesh_cutoff)  # cutoff in km
```

Smaller `cutoff` → more knots → finer resolution but slower. Typical values 50–100 km for
shelf-scale surveys. Optionally add a land barrier:

```r
mesh <- sdmTMBextra::add_barrier_mesh(mesh, land_polygon, proj_scaling = 1000)
```

Visualise with `sdmTMBexperiments::plot_mesh(mesh, crs = dt_crs, data = dt)`.

## Fit

```r
fit <- sdmTMB::sdmTMB(
  value ~ 0 + geartype + s(month) + s(depth),
  data           = dt,
  mesh           = mesh,
  family         = sdmTMB::delta_lognormal(),
  spatial        = "on",
  spatiotemporal = "ar1",
  time           = "year",
  control        = sdmTMB::sdmTMBcontrol(newton_loops = 2)
)

sdmTMB::sanity(fit)   # ALWAYS check convergence, SE gradients, PD Hessian, range vs domain
```

If `sanity()` flags problems (large gradients, non-positive-definite Hessian, range larger
than the domain), the index is not trustworthy — simplify (drop a smooth, coarsen the mesh,
change the spatiotemporal structure) rather than pressing on.

## Prediction grid and index

Predict to a regular grid covering the survey domain, replicated over years, with reference
values for the fixed effects; then integrate. Use the helpers for the grid:

```r
region <- sdmTMBexperiments::make_survey_prediction_region(dt, crs = dt_crs)
grid   <- sdmTMBexperiments::make_prediction_grid(region, resolution = grid_side_size,  # km
                                                  max_depth = 1400)
grid   <- tidyr::crossing(grid, year = sort(unique(dt$year)))
grid$geartype <- "Shrimp"; grid$month <- 8L   # reference levels

pred  <- predict(fit, newdata = grid, return_tmb_object = TRUE)
index <- sdmTMB::get_index(pred, bias_correct = TRUE, area = grid_cell_area_nmi2)
# index: year, est, lwr, upr, se, log_est, se (on the response scale after bias correction)
```

- **`area`** scales cell density to cell total; use the grid cell area in the response's area
  unit (e.g. `(grid_side_size / 1.852)^2` nmi² for 10 km cells).
- **`bias_correct = TRUE`** for final indices (epsilon bias correction; slower). Leave `FALSE`
  while exploring.
- For **length-group** indices, fit/predict per group and combine; `get_index_split()`
  computes indices for many response columns efficiently — see `sdmtmbexperiments.md`.

## Diagnostics

- Randomised-quantile residuals + Q-Q (`sdmTMBexperiments::plot_residual_qq()`).
- `simulate(fit, nsim = ...)` for posterior-predictive checks.
- Predicted density maps and random-field maps
  (`plot_prediction_map()`, `plot_random_field()`).
- Cross-validation with `sdmTMB::sdmTMB_cv()` (wrapped by `sdmTMB_mesh_cv()`).

## Gotchas

- **X/Y must be km.** Passing metres puts data in the wrong place and breaks the mesh.
- **Keep true zeros** — the binomial part needs absences.
- **AR1 vs IID + year effect** — for assessment inputs that must not be temporally smoothed,
  use `spatiotemporal = "iid"` with `year` as a fixed effect. See `workflow.md` step 4.
- Bias correction and `simulate()` are slow; cache model outputs to `data/output` and toggle
  refits off on re-render (`rendering.md`).
