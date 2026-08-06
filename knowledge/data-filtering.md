# Data filtering — making catches quantitative

**This is the single most important file in the pack.** A spatiotemporal index is only valid
if every retained record is a *standardised, quantitative* bottom-trawl haul with a real
swept area, and if stations with no catch of the target species are kept as **true zeros**.
Getting the `gearcondition`, `samplequality`, and `stationtype` tags wrong — or leaving
duplicates in — silently corrupts the index. Reproduce this logic; do not improvise.

The logic below is distilled from the background material listed in `workflow.md` (the
IMR-internal reference project's data-compilation notebooks and data report). Access the
Biotic database through BAIT (`biotic-connect`); the tables are `stnall` (station catches),
`indall` (individual/length records), `mission`, and the `gearindex`/`taxaindex` lookups.

## Station-level filter

Apply to `stnall`. `filter_sp` holds the Norwegian `commonname` value(s) of the target
species (confirm via BAIT's `taxaindex` — don't guess).

```r
last_complete_year <- as.integer(format(Sys.Date(), "%Y"))
obsolete_gear_codes <- unique(stats::na.omit(obsolete_gear_codes))

stn <- stnall |>
  dplyr::filter(
    gearcategory == "Bottom trawls",
    missiontypename %in% c("Forskningsfartøy", "Leiefartøy"),  # research + charter vessels
    startyear > 1980,
    startyear < last_complete_year,                            # drop the incomplete current year
    !is.na(distance),
    latitudestart > 0,
    gearcondition %in% 1:2,           # gear in good/acceptable working condition
    is.na(stationtype) | !stationtype %in% c("C", "2", "A", "E"), # retain missing; drop calibration/duplicate/anchor/empty hauls
    distance >= 0.3, distance <= 5,   # trawl haul length in nautical miles
    is.na(gear) | !gear %in% obsolete_gear_codes, # retain missing; drop obsolete/non-standard trawl types
    dplyr::if_else(
      !is.na(.data$cruiseseriescode) & .data$cruiseseriescode == "23",
      .data$samplequality %in% 1:2,
      .data$samplequality %in% 1
    )
  ) |>
  dplyr::collect() |>
  # sample-quality is conditional on the cruise series:
  dplyr::filter(
    dplyr::if_else(
      !is.na(.data$cruiseseriescode) & .data$cruiseseriescode == "23",
      .data$samplequality %in% 1:2,
      .data$samplequality %in% 1
    )
  ) |>
  dplyr::mutate(id = paste(cruise, platformname, serialnumber, sep = "_"))
```

Build the station roster independently of target catch weight. Validate missing or inconsistent
target catch records after joining the target species onto the retained stations; otherwise empty
catch stations are lost before they can become true zeros.

### What the tags mean

- **`gearcondition %in% 1:2`** — the gear was in good (1) or acceptable (2) working condition.
  Higher codes mean damage/deterioration and are **not** quantitative. Always apply this.
- **`stationtype`** — `"C"`, `"2"`, `"A"`, `"E"` are calibration, duplicate, anchor-test, and
  empty/aborted hauls. They are not standard fishing stations and must be excluded. Missing values are retained explicitly: this is essential because a lazy DuckDB filter translates a bare `!stationtype %in% ...` to SQL, where `NULL` values would otherwise be dropped.
- **`samplequality`** — `1` = highest quality, `2` = acceptable. Standard surveys keep only
  `1`; the **coastal cruise series (`cruiseseriescode == "23"`)** keeps `1:2`. This
  conditional is essential — do not flatten it to one rule. If the coastal series used acoustic
  targeting for another species in early years, document why the target species is still assumed
  to be randomly sampled before retaining quality 2.
- **`distance` 0.3–5 nmi** — very short or very long hauls are unreliable for swept area.
- **`missiontypename`** — keep research and charter vessels only.
- **`last_complete_year`** — calculate this scalar in R *before* the lazy query. Calling a date-extraction function inside a DuckDB filter can be translated as invalid SQL rather than a year literal.
- **`obsolete_gear_codes`** — remove missing values from this small R vector before filtering. The explicit `is.na(gear) | ...` retains a missing gear value, matching the post-collection R semantics; SQL would otherwise drop it.

### Russian data — INCLUDED by default

Unlike `ref-index-paper` (a public showcase that *excluded* Russian data), **this template
includes Russian data by default**, because the northern surveys need it for full spatial
coverage. Offer exclusion only as an explicit opt-out. If the user opts out, filter
`!nation %in% c("140", "90")` and clip the prediction grid to exclude the Russian EEZ.

## True absences (zeros)

For each retained station, the response for the target species is the summed catch there; a
station where the species was **not** caught is a real **zero**, not a missing value. Build the
response by joining the species catch onto the *full set of retained stations* so absences are
preserved. Absences are what let the binomial part of `delta_lognormal()` estimate presence
probability. Never drop zero-catch stations.

## Duplicates — detect and remove

The Biotic database can contain duplicate or inconsistent records (e.g. the same haul entered
twice, or length-sample totals exceeding the catch). Flag ids where the length sample exceeds
the catch and drop them; write a report to `review/` for inspection.

```r
dupe_ids <- stn |>
  dplyr::filter(commonname %in% filter_sp) |>
  dplyr::group_by(cruiseseriescode, id, commonname) |>
  dplyr::reframe(
    catchweight       = sum(catchweight, na.rm = TRUE),
    catchcount        = sum(catchcount, na.rm = TRUE),
    lengthsampleweight = sum(lengthsampleweight, na.rm = TRUE),
    lengthsamplecount  = sum(lengthsamplecount, na.rm = TRUE)
  ) |>
  dplyr::filter(catchcount < lengthsamplecount | catchweight < lengthsampleweight) |>
  dplyr::pull(id)

stn <- dplyr::filter(stn, !id %in% dupe_ids)
```

## BES vs SPD files

Historical data used to live in **SPD files** (e.g. `Barentshavtokt`, `Svalbardtokt`,
`Blakveite_prosjektet`). As records are added to the Biotic database, the SPD files become
**obsolete**. When binding SPD data to BES data:

- Drop SPD years/series that are **already in Biotic** (avoid double-counting).
- Tag the source (`source = "NMD"` for Biotic, `source = "SPD"` for legacy) for traceability.
- **For southern or coastal species, SPD files add little** — suggest using BES only and skip
  the SPD documents entirely.

## Swept-area density (the response)

Convert catch to density per swept area. The default template policy uses one common effective
width for all trawls:

```r
stn <- stn |>
  dplyr::mutate(
    gear_width    = 25,                          # metres; common effective width for all trawls
    swept_area    = distance * (gear_width / 1852),   # nmi² (1852 m per nmi)
    rho_biomass   = biomass / swept_area,      # kg   · nmi⁻²
    rho_abundance = count   / swept_area       # n    · nmi⁻²
  )
```

### Gear width is a documented simplification

Use a common 25 m effective width for all trawls when the project adopts the simplified policy.
If more than one major gear type is represented, keep `geartype` in the spatial GLMM as a fixed
effect so the model can estimate systematic gear differences. Revert to gear-specific widths
only if diagnostics show that the common-width assumption is inadequate.

## Depth

Fill missing or invalid bottom depths from GEBCO bathymetry:

```r
stn$depth <- ggOceanMaps::get_depth(stn, bathy.style = "rc", bind = FALSE)
```

## Spatial domain

Keep stations inside the study-area polygon; if Russian data are excluded, clip the Russian
EEZ. These GIS files are **user-supplied** and live only in the project's `data/` — never in
the template.
