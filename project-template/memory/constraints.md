---
name: constraints
description: Project-specific hard rules for the {{SPECIES_NAME}} index.
metadata:
  type: decision
  author: <agent>
  created: <YYYY-MM-DD>
---

# Constraints — {{SPECIES_NAME}}

- **No data / no private paths in tracked files.** `data/`, `logs/`, `review/` are
  git-ignored; GIS polygons and extracts live in `data/source/` only.
- **Filtering is fixed by method.** Reproduce index-template `data-filtering.md` exactly
  (`gearcondition %in% 1:2`, conditional `samplequality`, `stationtype` exclusions, duplicate
  removal, true zeros, swept-area density). Don't improvise.
- **Config-driven.** Settings change in `config.yaml`, not in the qmds.
- **Review before render; render in screen with a log; toggle compute off after outputs
  exist.**
- **Selected assessment index:** `{{SPECIES_NAME}}` → see `config.yaml` `SELECTED_INDEX`.
  Confirm the spatiotemporal/year-effect choice with the assessment lead.

_Add project-specific rules below as they are decided._
