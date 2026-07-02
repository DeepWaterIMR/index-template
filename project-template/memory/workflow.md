---
name: workflow
description: Progress through the four-step index workflow for {{SPECIES_NAME}}.
metadata:
  type: project
  author: <agent>
  created: <YYYY-MM-DD>
---

# Workflow status — {{SPECIES_NAME}}

Update as steps complete. See the index-template `workflow.md` knowledge file for detail.

- [ ] **Step 1 — Compile & report data** (`docs/data/`). Survey list, filters applied,
  duplicates found, SPD used?  _<notes>_
- [ ] **Step 2 — First model** (`docs/exploration/fit.qmd`). No length groups. Mesh cutoff,
  sanity result.  _<notes>_
- [ ] **Step 3 — Validate / select** (`docs/exploration/validate.qmd`). Family,
  spatiotemporal structure, mesh, retro decisions.  _<notes>_
- [ ] **Step 4 — Final report + export** (`docs/{{SPECIES_SLUG}}/report.qmd`). Products,
  selected index, export path.  _<notes>_

**Cached outputs in `data/output/`:** _<list files so re-renders can load them>_.
