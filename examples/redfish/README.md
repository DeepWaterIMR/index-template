# Worked example — beaked redfish

This is the reference example, matching the published paper and the beaked benchmark so a
generated index can be compared against a known result.

- **Config**: [`config.yaml`](config.yaml) — beaked redfish (*Sebastes mentella*), ICES 1-2,
  five surveys, SPD included, delta-lognormal AR1, 10 km grid, 60 km mesh, selected index
  "Over 30 cm biomass" feeding SPiCT.

## Scaffold it

```r
source("<index_template_path>/scaffold.R")
scaffold_index("examples/redfish/config.yaml", target = "../snabeluer-index", dry = TRUE)  # preview
scaffold_index("examples/redfish/config.yaml", target = "../snabeluer-index")              # create
```

Then follow the four steps (`index-compile-data` → `index-fit-model` →
`index-validate-model` → `index-final-report`). Compiling the data needs a local BES database
and an IMR intranet connection.

## Reference materials (not distributed here — no data)

The method and expected results are documented in:

- **ref-index-paper** (public showcase) — the SI files `SI-Text-1-data`, `SI-Text-2-sdmTMB`,
  `SI-Text-3-model-selection` are the blueprint for Steps 1–3.
- **ref-assessment-index** `docs/benchmark/beaked/` — the blueprint for the Step-4 final
  report and its optional sections.
- Vihtakari et al. (2026), *ICES J. Mar. Sci.*,
  [doi:10.1093/icesjms/fsag009](https://doi.org/10.1093/icesjms/fsag009).

Nothing here contains data or private paths.
