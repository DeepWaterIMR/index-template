# 00_setup.R — shared setup sourced by every document in this project.
# Loads packages, reads config.yaml into `cfg`, sets a ggplot theme, and derives a few
# convenience values. Keep project-wide settings in config.yaml, not here.

`%||%` <- function(a, b) if (is.null(a)) b else a

# --- Packages ---------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(sdmTMB)
  library(sdmTMBexperiments)   # ATTACH (not ::) so ggOceanMaps land data is available
})
# Data access (Biotic database) is provided by BAIT — see its biotic-connect skill.

# --- Config -----------------------------------------------------------------------------
# Documents may be rendered with the working directory at the project root (recommended) or
# at the qmd's own folder; find config.yaml either way.
.find_config <- function() {
  for (p in c("config.yaml", "../config.yaml", "../../config.yaml", "../../../config.yaml"))
    if (file.exists(p)) return(normalizePath(p))
  stop("config.yaml not found. Render from the project root, or set the working directory.")
}
# Read as UTF-8 bytes so Norwegian species names (å/æ/ø) parse regardless of R locale.
.read_yaml_utf8 <- function(path) {
  txt <- readChar(path, file.info(path)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  yaml::yaml.load(txt)
}
cfg <- .read_yaml_utf8(.find_config())

# Derived convenience values.
dt_crs         <- cfg$CRS
grid_side_size <- cfg$GRID_KM                       # km
grid_cell_area_nmi2 <- (cfg$GRID_KM / 1.852)^2      # nmi^2 per cell (for get_index area=)
response_col   <- if (identical(cfg$RESPONSE, "abundance")) "rho_abundance" else "rho_biomass"

model_family <- switch(cfg$FAMILY,
  delta_lognormal = sdmTMB::delta_lognormal(),
  delta_gamma     = sdmTMB::delta_gamma(),
  tweedie         = sdmTMB::tweedie(),
  stop("Unknown FAMILY in config.yaml: ", cfg$FAMILY)
)

# Default model formula — geartype stays in when there is >1 major gear type OR a single set
# gear width is used (so the model absorbs the gear-width difference). Temperature is off by
# default (config INCLUDE_TEMPERATURE).
build_formula <- function(cfg, has_multiple_gears = TRUE) {
  terms <- c("s(month)", "s(depth)")
  if (has_multiple_gears || !identical(cfg$GEAR_WIDTH, "per_gear")) terms <- c("geartype", terms)
  if (isTRUE(cfg$INCLUDE_TEMPERATURE)) terms <- c(terms, "s(temperature)")
  stats::as.formula(paste("value ~ 0 +", paste(terms, collapse = " + ")))
}

# --- Paths ------------------------------------------------------------------------------
out_dir <- cfg$OUTPUT_DIR %||% "data/output"
src_dir <- cfg$SOURCE_DIR %||% "data/source"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# --- Theme ------------------------------------------------------------------------------
theme_set(theme_bw(base_size = 11))
