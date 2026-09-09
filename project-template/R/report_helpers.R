# report_helpers.R — software citations for the HTML data reports.

#' Cite the installed software used by a report
#'
#' Writes report-specific BibTeX from citation() and emits narrative citations with
#' installed versions. Keep literature references in docs/assets/references.bib.
#' @param packages Character vector of packages that influenced this report.
#' @param bibliography Path to this report's generated software bibliography.
#' @return Invisibly, the generated BibTeX entries.
report_software <- function(packages, bibliography) {
  packages <- unique(c("base", packages))
  entries <- character()
  prose <- character()
  for (package in packages) {
    refs <- utils::citation(package)
    keys <- paste0("software-", gsub("[^A-Za-z0-9]", "", package), "-", seq_along(refs))
    for (i in seq_along(refs)) {
      ref <- refs[i]
      ref$key <- keys[i]
      entries <- c(entries, as.character(utils::toBibtex(ref)), "")
    }
    label <- if (package == "base") "R" else package
    version <- if (package == "base") as.character(getRversion()) else
      as.character(utils::packageVersion(package))
    prose <- c(prose, paste0(label, " ", version, " [",
                            paste0("@", keys, collapse = "; "), "]"))
  }
  dir.create(dirname(bibliography), recursive = TRUE, showWarnings = FALSE)
  writeLines(entries, bibliography, useBytes = TRUE)
  cat("The analysis and report used ", paste(prose, collapse = ", "), ".\n\n", sep = "")
  invisible(entries)
}
