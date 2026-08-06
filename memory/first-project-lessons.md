---
name: first-project-lessons
description: Reusable lessons consolidated after the first Atlantic halibut index-template project.
metadata:
  type: decision
  author: project team
  created: 2026-08-06
---

# Lessons from the first Atlantic halibut project

The generated Step 1 documents have two distinct roles. `compile-data.qmd` selects qualifying
surveys and documents coverage, catch, gear, timing, filters, and the filtering-script appendix.
`<species>-<region>-data-report.qmd` documents the compiled station/response data, effort,
length products, and diagnostics. Keep length allocation and length-completeness material out of
survey selection.

Use survey-level qualification: a survey is one cruise and qualifies when at least one positive
target catch passes the standard haul filters and the exact region test. A cruise series groups
surveys in a time series; do not backfill failed surveys merely because another survey in that
series qualifies. Uncoded surveys are assessed individually before assigning `Other`.

The standard sample-quality predicate is SQL-compatible and NA-safe:

```r
dplyr::if_else(
  !is.na(.data$cruiseseriescode) & .data$cruiseseriescode == "23",
  .data$samplequality %in% 1:2,
  .data$samplequality %in% 1
)
```

Apply it in the lazy query and retain the same check after collection. If code 23 represents a
coastal acoustic survey that targeted another species, document why the target species is assumed
to remain randomly sampled before retaining quality 2.

For prediction-region overview maps, calculate observation and polygon extents in a display CRS
(default EPSG:3995), convert bounding boxes to corner points, and pass them to `basemap(data=...)`.
Use `bathy.style = "rbg"`, `ggnewscale::new_scale_fill()` before manual polygon fills,
`expand.factor = 1.1`, and `coord_sf(expand = FALSE)`. For station-position figures where zero
hauls must remain visible, omit bathymetry and use a light grey zero layer.

The template documents use a `VERSION` date label, an index-template provenance paragraph, and
project-specific author affiliations near the top. All figures and tables have explicit captions
and stable Quarto cross-reference labels. Generated outputs belong under root-level
`data/output/`; never create document-local output folders or track raw Biotic data/private paths.
