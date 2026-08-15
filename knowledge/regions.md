# Analysis-region polygons

Use this reference with `index-make-regions`. It defines a reproducible approach for spatial partitions used in data extraction, sdmTMB prediction, and assessment.

## Required specification

Obtain these decisions before writing any geometry:

- Master domain to be covered exactly by the final regions.
- Project CRS for spatial operations, areas, and the GeoPackage.
- Inputs and their precedence: source regions, survey coverage, depth mask/prediction footprint, ICES/EEZ areas, and analytical latitude/longitude boundaries.
- Overlap priority or explicit splitting rule.
- Numerical tolerance for overlap, gaps, and area outside the master domain.
- Output filename and layer. The default `data/gis/regions.gpkg` is available only when it does not already exist. Never overwrite an existing GeoPackage; require a new filename from the user.

## Geometry contract

Work in the project CRS. Keep a read-only source object and derive a separate final object. Define a target/master domain before testing gaps: gaps cannot be assessed from disconnected input regions alone.

Use this validation pattern after the final partition has been constructed:

```r
regions <- regions |>
  sf::st_make_valid()

stopifnot(all(sf::st_is_valid(regions)))

region_union <- sf::st_union(sf::st_geometry(regions))
domain_union <- sf::st_union(sf::st_geometry(master_domain))
gaps <- sf::st_difference(domain_union, region_union)
outside <- sf::st_difference(region_union, domain_union)

pairwise_overlap_m2 <- function(x) {
  if (nrow(x) < 2) return(0)
  combinations <- utils::combn(seq_len(nrow(x)), 2)
  max(vapply(seq_len(ncol(combinations)), function(i) {
    overlap <- sf::st_intersection(
      sf::st_geometry(x[combinations[1, i], ]),
      sf::st_geometry(x[combinations[2, i], ])
    )
    sum(as.numeric(sf::st_area(overlap)), na.rm = TRUE)
  }, numeric(1)))
}

gap_m2 <- sum(as.numeric(sf::st_area(gaps)), na.rm = TRUE)
outside_m2 <- sum(as.numeric(sf::st_area(outside)), na.rm = TRUE)
overlap_m2 <- pairwise_overlap_m2(regions)

stopifnot(
  gap_m2 <= geometry_tolerance_m2,
  outside_m2 <= geometry_tolerance_m2,
  overlap_m2 <= geometry_tolerance_m2
)
```

Run the checks in the project CRS. Record the tolerance and the measured values. Use a small, explicit tolerance only for geometry-engine precision; do not hide material gaps or overlaps.

## Ordering

Apply the default southwest-to-northeast order to the final regions, based on an interior point in the project CRS transformed to WGS84 for geographic sorting:

```r
centres <- regions |>
  sf::st_point_on_surface() |>
  sf::st_transform(4326)
xy <- sf::st_coordinates(centres)

region_order <- regions |>
  sf::st_drop_geometry() |>
  dplyr::mutate(.lon = xy[, 1], .lat = xy[, 2]) |>
  dplyr::arrange(.lat, .lon) |>
  dplyr::pull(region)

regions <- regions |>
  dplyr::mutate(
    region_order_index = match(as.character(region), region_order),
    region = factor(as.character(region), levels = region_order)
  ) |>
  dplyr::arrange(region_order_index)
```

Preserve `region_order_index` in the GeoPackage. Reapply the factor after reading the file.

## Save and map

Save a new GeoPackage only after the user has confirmed its name. Keep the project CRS and use a single named `regions` layer unless the user specifies another layer.

```r
stopifnot(!file.exists(output_gpkg))
sf::st_write(regions, output_gpkg, layer = "regions", quiet = TRUE)
```

Use this ggOceanMaps starting point for the final map. It is deliberately uncluttered; add only the agreed region labels or boundaries.

```r
ggOceanMaps::basemap(
  regions,
  legends = FALSE,
  bathymetry = TRUE,
  bathy.style = "rbg",
  bathy.alpha = 0.5
) +
  ggnewscale::new_scale_fill() +
  ggplot2::geom_sf(
    data = regions,
    ggplot2::aes(fill = region),
    colour = "grey15",
    linewidth = 0.4,
    alpha = 0.75
  ) +
  ggplot2::theme(legend.position = "none")
```

If the map needs a spatial object in WGS84, transform a display copy rather than altering the saved analysis object.
