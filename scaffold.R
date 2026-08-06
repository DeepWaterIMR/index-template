# scaffold.R — instantiate a new index project from project-template/
#
# Copies the project-template/ skeleton into a target directory, renames the SPECIES
# folder/files to the species slug, and stamps {{PLACEHOLDER}} identity tokens from a
# config.yaml. Analytical settings (CRS, grid size, mesh cutoff, length groups, …) are NOT
# hard-stamped — the documents read them from config.yaml at run time via R/00_setup.R. Only
# identity and path-shaping tokens are stamped here.
#
# Usage:
#   source("<index_template_path>/scaffold.R")
#   scaffold_index(config = "config.yaml", target = "../snabeluer-index")             # do it
#   scaffold_index(config = "config.yaml", target = "../snabeluer-index", dry = TRUE)  # preview
#   # If the template can't be auto-located, pass it explicitly:
#   scaffold_index("config.yaml", "../snabeluer-index", template = "<path>/project-template")
#
# Requires: yaml. (install.packages("yaml"))

# --- Read a YAML file as UTF-8, independent of the R locale ----------------------------
.read_yaml_utf8 <- function(path) {
  txt <- readChar(path, file.info(path)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  yaml::yaml.load(txt)
}

# --- Locate the project-template/ directory -------------------------------------------
# Order: explicit arg -> ~/.index-template/config.json (written by index-install) ->
# ./project-template -> error.
.find_template <- function(template = NULL) {
  if (!is.null(template) && dir.exists(template)) return(normalizePath(template))

  cfg_json <- path.expand("~/.index-template/config.json")
  if (file.exists(cfg_json) && requireNamespace("jsonlite", quietly = TRUE)) {
    p <- tryCatch(jsonlite::read_json(cfg_json)$index_template_path, error = function(e) NULL)
    if (!is.null(p)) {
      cand <- file.path(p, "project-template")
      if (dir.exists(cand)) return(normalizePath(cand))
    }
  }

  cand <- file.path(getwd(), "project-template")
  if (dir.exists(cand)) return(normalizePath(cand))

  stop("Cannot locate project-template/. Pass it explicitly via `template=`.")
}

scaffold_index <- function(config, target, template = NULL, dry = FALSE) {

  if (!requireNamespace("yaml", quietly = TRUE))
    stop("The 'yaml' package is required: install.packages('yaml')")

  template <- .find_template(template)
  msg <- function(...) cat(if (dry) "[dry] " else "", ..., "\n", sep = "")

  # --- Read and validate the config ---------------------------------------------------
  # Read as UTF-8 bytes so Norwegian species names (å/æ/ø) parse regardless of R locale.
  cfg <- .read_yaml_utf8(config)
  required <- c("SPECIES_NAME", "SPECIES_SLUG", "SPECIES_LATIN", "FILTER_SP")
  miss <- setdiff(required, names(cfg))
  if (length(miss)) stop("config.yaml is missing required keys: ", paste(miss, collapse = ", "))

  slug <- cfg$SPECIES_SLUG
  if (!grepl("^[a-z0-9-]+$", slug))
    stop("SPECIES_SLUG must be lower-case kebab-case (a-z, 0-9, -): got '", slug, "'")

  # Regions are optional for single-domain projects, but when a project is split by region
  # the region slug belongs in data-document filenames to keep N62/S62 outputs unambiguous.
  region_slug <- if (!is.null(cfg$REGION_SLUG)) as.character(cfg$REGION_SLUG) else "all"
  if (!grepl("^[A-Za-z0-9-]+$", region_slug))
    stop("REGION_SLUG must contain only letters, numbers, and hyphens: got '", region_slug, "'")

  # --- Copy the skeleton --------------------------------------------------------------
  if (dir.exists(target) && length(list.files(target, all.files = TRUE, no.. = TRUE)))
    stop("Target '", target, "' exists and is not empty. Choose an empty/new directory.")

  if (!dry) {
    dir.create(target, recursive = TRUE, showWarnings = FALSE)
    file.copy(list.files(template, full.names = TRUE, all.files = TRUE, no.. = TRUE),
              target, recursive = TRUE, copy.mode = TRUE)
    file.copy(config, file.path(target, "config.yaml"), overwrite = TRUE)
  }
  msg("Copied project-template/ -> ", target)

  # --- Rename SPECIES folder and SPECIES-* files to the slug --------------------------
  if (!dry) {
    sp_dir <- file.path(target, "docs", "SPECIES")
    if (dir.exists(sp_dir)) file.rename(sp_dir, file.path(target, "docs", slug))
    for (f in list.files(target, recursive = TRUE, full.names = TRUE)) {
      if (grepl("SPECIES", basename(f)))
        file.rename(f, file.path(dirname(f), gsub("SPECIES", slug, basename(f))))
    }
    for (f in list.files(target, recursive = TRUE, full.names = TRUE)) {
      if (grepl("\\{\\{REGION_SLUG\\}\\}", basename(f)))
        file.rename(f, file.path(dirname(f), gsub("\\{\\{REGION_SLUG\\}\\}", region_slug, basename(f))))
    }
  }
  msg("Renamed SPECIES -> ", slug, " and region -> ", region_slug, " in paths")

  # --- Stamp identity tokens in text files --------------------------------------------
  tokens <- c(
    "{{SPECIES_NAME}}"  = as.character(cfg$SPECIES_NAME),
    "{{SPECIES_SLUG}}"  = as.character(cfg$SPECIES_SLUG),
    "{{SPECIES_LATIN}}" = as.character(cfg$SPECIES_LATIN),
    "{{REGION_SLUG}}"   = region_slug
  )
  text_ext <- c("qmd", "rmd", "r", "md", "yaml", "yml", "css", "bib")
  scan_root <- if (dry) template else target
  files <- list.files(scan_root, recursive = TRUE, full.names = TRUE)
  files <- files[tolower(tools::file_ext(files)) %in% text_ext]

  for (f in files) {
    txt <- tryCatch({
      s <- readChar(f, file.info(f)$size, useBytes = TRUE); Encoding(s) <- "UTF-8"; s
    }, error = function(e) NULL)
    if (is.null(txt)) next
    new <- txt
    for (tok in names(tokens)) new <- gsub(tok, tokens[[tok]], new, fixed = TRUE)
    if (!dry && !identical(new, txt))
      writeBin(charToRaw(enc2utf8(new)), f)
  }
  msg("Stamped identity tokens (SPECIES_NAME/SLUG/LATIN)")

  # --- Sanity check: no leftover identity placeholders --------------------------------
  if (!dry) {
    left <- character()
    for (f in files) {
      txt <- tryCatch({
        s <- readChar(f, file.info(f)$size, useBytes = TRUE); Encoding(s) <- "UTF-8"; s
      }, error = function(e) "")
      if (grepl("\\{\\{(SPECIES_(NAME|SLUG|LATIN)|REGION_SLUG)\\}\\}", txt)) left <- c(left, f)
    }
    if (length(left))
      warning("Leftover identity placeholders in:\n  ", paste(left, collapse = "\n  "))
    else
      msg("No leftover identity placeholders.")
    message("Scaffolded '", cfg$SPECIES_NAME, "' at: ", normalizePath(target))
    message("Next: review config.yaml, then run Step 1 (index-compile-data).")
  }

  invisible(target)
}
