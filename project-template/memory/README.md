# Project memory

This is the **shared, committed project memory** for the {{SPECIES_NAME}} index. All agents
(Claude Code, Codex, Mistral, …) and human collaborators read and write here — **not** in any
agent's local per-machine memory.

## How to use it

1. On any task, read [`MEMORY.md`](MEMORY.md) (the index) first.
2. When you learn something non-obvious — a decision, a constraint, a gotcha, a data quirk —
   write a **new markdown file** here and add a one-line pointer to `MEMORY.md`.
3. One fact per file. Link related memories with `[[slug]]`.

## File format

```markdown
---
name: <kebab-case-slug>
description: <one-line summary — used to judge relevance>
metadata:
  type: project | decision | reference | feedback
  author: <agent or person>
  created: YYYY-MM-DD
---

<the fact.>
**Why:** <reasoning>
**How to apply:** <when this matters>
Related: [[other-slug]]
```

## What belongs here

- `project` — goals, scope, data sources, survey list, open items.
- `decision` — modelling choices (mesh cutoff, family, spatiotemporal structure, selected
  index) and their evidence. Don't silently overwrite — supersede with a note.
- `reference` — links to the assessment, the paper, GIS sources.
- `feedback` — guidance the user has given on how to work here.

Don't record what the code or `config.yaml` already says. Record what's non-obvious.
