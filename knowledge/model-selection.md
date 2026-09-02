# Model selection for a survey index

Step 3 has to leave behind a **defended specification**: formula, family, spatiotemporal
structure, mesh cutoff, barrier. This file is the method. The mechanics are in
`sdmTMBexperiments::sdmTMB_selection()` and friends — see `sdmtmbexperiments.md` for the
catalogue and `?sdmTMB_selection` for the argument reference. **Use the helpers; do not
hand-roll a CV loop.**

A selection table is easy to produce and easy to get wrong. Almost every way it goes wrong is
a comparability failure — two rows that look like they answer the same question but do not.
The rules below exist to stop that, and each is enforced or reported by the helper.

## The comparability contract

1. **Identical records.** AIC and hold-out log-likelihoods only compare models fitted to the
   same response data. If one candidate carries `s(depth)` and another does not, and `depth`
   has gaps, `sdmTMB()` silently drops different rows for each and the AIC column compares two
   different quantities. Build the complete-case frame **once**, up front:

   ```r
   dt_sel <- selection_frame(dt, candidates, extra = c("X", "Y", "year"))
   ```

   `sdmTMB_selection(complete_cases = TRUE)` (the default) does this for you and reports how
   many rows it dropped. Then fit the **selected** specification to the full `dt` — there is no
   reason to keep discarding records because a covariate that did not enter the model is
   missing for them.

2. **AIC is not comparable across different response data.** Same formula, different response
   (biomass vs abundance), or a positive-only Gamma beside a zero-inclusive Tweedie: these have
   no common likelihood scale. Do not put them in one weighted table. `add_aic_weights(group =)`
   exists for the case where you must show them side by side — weights are then computed within
   each group and left blank for singletons. Delta families and Tweedie *on the same response
   column and the same rows* **are** comparable; that is the family-selection stage.

3. **Hold-out log-likelihood per observation, never summed.** A summed hold-out likelihood
   rewards whichever candidate scored the fewest points. `sdmTMB_cv_summary()` divides by
   `n_heldout` and reports `n_heldout` and `folds_pdhess` beside it, so a fragile row is
   visible as such. This is why the plain `sum_loglik` from `sdmTMB::sdmTMB_cv()` (and the
   default metric of `sdmTMB_mesh_cv()`) needs care when candidates differ in size.

4. **Only compare rows marked `comparable`.** It is `TRUE` for a candidate that fitted, whose
   Hessian was positive definite, that saw the modal number of records, and — under CV — every
   fold of which resolved. **Never quote an AIC or NLL difference unless both candidates are
   comparable.** A likelihood from a fit that did not resolve is not evidence.

5. **`sanity()` is reported, not a gate.** `sdmTMB::sanity()` fails routinely on perfectly
   usable fits (`se_magnitude_ok`, `sigmas_ok`), so it does not gate `comparable` — gating on it
   would drop the best-fitting candidate from every comparison. Read it as a reason to consider
   simplifying, and say so in the text when the selected model fails it.

6. **Look the winner up in the column, never at row 1.** The table's sort key changes with
   whether CV ran. Use `best_candidate(sel)`; in prose, quote the gap with a value read from
   the table, not typed in by hand.

7. **State the full specification, not a label.** Every row of the table carries a `spec`
   column (formula | family | spatial | spatiotemporal). Print it, or at least the `formula`
   column: a reader cannot tell what "Model 3" was.

## The stages

Each stage is the same operation with a different thing varied, so all of them use
`sdmTMB_selection()` with a different `candidates` list. Do them in this order; each stage
fixes its winner before the next varies something else.

| Stage | Vary | Typical candidates |
|---|---|---|
| 1. Component ranking | `formula` (one term at a time), `spatial`, `spatiotemporal` | `~ s(depth)`, `~ fyear`, `~ s(month)`, `~ geartype`, `~ 1` with fields on, `~ 1` with `spatial = "off"` |
| 2. Fixed effects | `formula` (drop one term from the full model) | Full model, no depth, no month, no gear, no year, null |
| 3. Family | `family` | `delta_lognormal()`, `delta_gamma()`, `tweedie()` |
| 4. Spatiotemporal structure | `spatiotemporal` | `iid`, `ar1`, `rw`, `off` |
| 5. Mesh resolution | `cutoff` | 40, 60, 80, 100 km — or `compare_meshes()` / `sdmTMB_mesh_cv()` |

Stage 1 tells you which single components carry information at all; stage 2 tells you which
survive together. Stage 4 has an assessment constraint, not just a statistical one — see the
section below.

**Every stage gets three outputs**: the table, `plot(sel)` (the status-coded ranking), and
`plot(sel, type = "index", newdata = grid)`. The third is the one that matters most and is the
one most often skipped: *does this choice actually move the index?* A stage where the winner
and the runner-up produce the same index is a stage you can stop arguing about.

## Cost control: AIC first, CV on a shortlist

A cross-validated candidate costs `k` fits. Cross-validating a ten-candidate ladder at `k = 10`
is a hundred spatiotemporal fits, which is days, not hours. Rank on AIC first, then
cross-validate the top few:

```r
sel <- sdmTMB_selection(cands, data = dt_sel, ..., cache_dir = sel_dir,
                        cache_prefix = "fixed")                # cheap: 1 fit each
short <- best_candidate(sel, n = 3, by = "aic")
cv <- sdmTMB_selection(cands[short], data = dt_sel, ..., cv = 10, cache_dir = sel_dir,
                       cache_prefix = "fixed")                 # reuses those fits
```

Keep the same `cache_prefix` for the two calls. The cache holds the whole-frame fit and the
cross-validation in separate files per candidate, so the second call reuses the fits the ladder
already paid for and pays only for the folds.

The shortlist is defined by AIC rank and nothing else — no candidate is designated in advance
and none is exempt — so if the ladder is re-run with different covariates the shortlist follows
the evidence. Candidates far down the AIC table are not rescued by predictive performance, and
spending a day establishing that changes nothing.

## Which cross-validation asks which question

- **Random folds** (the default, `cv = k`) hold out scattered stations: this measures
  *interpolation* — predicting a station with others nearby in space and time.
- **Spatially clustered folds** (`fold_ids` from `blockCV::cv_spatial()`) hold out whole areas:
  this measures *extrapolation* into ground the survey did not cover that year. That is the
  harder test, and the relevant one for a model whose entire purpose is to integrate over a
  grid, including cells nobody sampled.
- **Leave-future-out** (`lfo = TRUE`) fits to years up to *t* and scores year *t + 1*. This is
  the question an assessment update actually asks, and it is the hardest one for a model with
  an AR1 field, whose terminal year sits at the end of the chain.

`sdmTMB_cv()` down-weights held-out rows to zero rather than deleting them, which is what keeps
every time step present for an `ar1`/`rw` field. Do not replace it with a loop that subsets the
data — deleting rows can empty a year and quietly change the model being validated.

Log-likelihood, RMSE and MAE do not have to agree, and where they do not the disagreement is
informative. Log-likelihood is sensitive to the whole predictive distribution, including the
zeros; RMSE is dominated by the largest catches, since it squares the errors; MAE weights every
station equally and is the most robust to the long right tail. A candidate that wins on
log-likelihood but not RMSE predicts the *shape* of the catch distribution well while missing
some large hauls — for an index built by integrating a predicted field, that is usually the
trade worth making.

## The assessment constraint on the spatiotemporal structure

Statistical fit is not the only criterion here. Total and length-group indices use
`spatiotemporal = "ar1"` and **no** year fixed effect. The assessment-selected index (feeding
e.g. SPiCT) often uses `iid` with **year as a fixed effect**, so that the series is not
temporally smoothed before the assessment model sees it. If cross-validation prefers `ar1` for
the assessment index, say so in the text and carry `iid` anyway, with the reason — see the next
section.

## When the carried-forward model is not the winner

This is common and legitimate: comparability across documents, an assessment requirement, or a
model simple enough to converge every year. **Record the gap, do not hide it.** Read the
difference from the table and state it, so the document says "AIC prefers X by N units; Y is
carried forward because …" rather than implying the choice followed from the selection.

```r
carried <- "Full model"
gap <- sel$table$deltaAIC[match(carried, sel$table$model)]
```

Note the idiom: matched **by label**, not by row position. The table is sorted by the metric,
so `sel$table$AIC[1] - sel$table$AIC[2]` is best-minus-runner-up regardless of which model you
meant, and it is negative by construction whichever way the comparison actually falls. The same
applies to correlation matrices and any other lookup in a rendered document: index by name, and
guard the lookup so a candidate that failed to fit produces a dash in a sentence rather than an
error at the end of a long render.

## Caching and resumability

Selection is the slowest thing in the project, so it is the most likely to be interrupted.

- `cache_dir` writes **one `.rds` per candidate**. A failure on the last candidate then costs
  one candidate, not the whole ladder. Use a different `cache_prefix` per stage.
- `only = "<candidate name>"` computes just that candidate and reads the rest from cache. This
  is what lets a long ladder be spread across several R sessions: a large spatiotemporal fit
  can peak at several GB, and a dozen of them accumulating in one process exhausts memory, at
  which point candidates start failing for reasons that have nothing to do with the model.
- Free each fit between candidates in any hand-written loop (`rm(m); gc()`); `sdmTMB_selection()`
  keeps only the summary and the fit you asked it to keep.

See `rendering.md` for the render-side toggles and the screen-session discipline.

## What the document must end with

A short "Decision" section stating the chosen formula, family, spatiotemporal structure, mesh
cutoff and barrier choice; the evidence (which table, which metric, by how much); and — where
the choice was not the table's winner — why. Record it in `memory/` as a decision. That
paragraph is what a reviewer reads.
