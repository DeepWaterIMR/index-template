---
name: architecture
description: How index-template is organised and the key design decisions.
metadata:
  type: project
  author: claude
  created: 2026-07-02
---

# Architecture

index-template is a **BAIT-style vendor-neutral knowledge pack + generator**, decided with the
user (not a clone-and-fill repo).

- **Installed once per machine**; `index-*` skills copied to `~/.claude/skills` and
  `~/.codex/skills`. Install path recorded in `~/.index-template/config.json`.
- **Sits on top of BAIT** — BAIT owns Biotic data access/privacy/maps/life-history
  (`biotic-*`); index-template adds the sdmTMB index layer. It reuses BAIT's privacy gate
  (`~/.bait/config.json`), it does not define its own.
- **Generates a separate project folder** per species via `scaffold.R` + `project-template/`.
  Delivery model = generator; scaffolding = hybrid (config stamps identity/paths, agent adapts
  analytical qmd content).

Layout: `AGENTS.md`/`CLAUDE.md` (contract), `skills/index-*` (8 skills), `knowledge/*.md`
(7 shared-truth files), `project-template/` (skeleton), `scaffold.R`, `examples/redfish/`,
`cookbook/`, `memory/`.

**Boundary:** call generic helpers from `sdmTMBexperiments`; never duplicate package internals
here. Reference data (species/surveys/gear) comes from the Biotic database via BAIT.

**Scaffold mechanics:** only identity tokens (`{{SPECIES_NAME/SLUG/LATIN}}`) are stamped;
every analytical setting lives in `config.yaml` and is read at run time by
`project-template/R/00_setup.R`. `docs/SPECIES/` and `SPECIES-*` filenames are renamed to the
slug.

Related: [[reference-sources]], [[conventions]].
