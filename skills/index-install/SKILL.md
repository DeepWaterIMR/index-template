---
name: index-install
description: Install or set up index-template for building sdmTMB survey indices. Use when the user says "install index-template", "install https://github.com/DeepWaterIMR/index-template", "set up index-template", or first asks to build a survey index and index-template is not yet installed. Runs onboarding: ensure BAIT, clone index-template, install skills globally, verify R packages.
---

# Install index-template

Goal: get index-template working **once per machine** so it's available in **every** project
— not copied into each repo. index-template builds on BAIT, so BAIT must be present first.

> Trigger: the user prompts *"install https://github.com/DeepWaterIMR/index-template"* (or
> similar), or asks to build a survey index with no install yet.

## Step 1 — BAIT + privacy (defer to BAIT)

index-template does **not** define its own privacy gate — it reuses BAIT's.

1. Check `~/.bait/config.json`. If BAIT is **not** installed, run BAIT's
   `bait-install` skill first (`install https://github.com/DeepWaterIMR/BAIT`). That handles
   the one-time model-training/data-retention onboarding and records `privacy_onboarded_at`.
2. If BAIT is installed and onboarding is recorded, **do not re-gate** — a short reminder that
   raw Biotic data stays local is enough. See BAIT's `biotic-privacy` skill.

## Step 2 — Clone index-template to a sensible place

Clone next to BAIT (read `bait_path` from `~/.bait/config.json` and use its parent), or another
user-space location the user prefers. **Never** clone at a filesystem root or system directory.

```bash
git clone https://github.com/DeepWaterIMR/index-template "<path>/index-template"
```

If the user started by cloning the URL into the current workspace, reuse that clone instead of
duplicating it.

## Step 3 — Install skills globally

Copy the `index-*` skills to the agent's user-level skills folder so they work in every
project (mirror how BAIT installs its skills):

- Claude Code → `~/.claude/skills/`
- Codex → `~/.codex/skills/`
- Other agents → point their project/agent instructions at `<index-template>/skills/`.

Record the install in `~/.index-template/config.json`:

```json
{ "index_template_path": "<path>/index-template", "installed_at": "<date>" }
```

## Step 4 — Verify the R toolchain

Confirm the modelling packages are installed (see `knowledge/packages.md`):

```r
for (p in c("sdmTMB", "ggOceanMaps", "sf", "quarto"))
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
if (!requireNamespace("sdmTMBexperiments", quietly = TRUE))
  remotes::install_github("DeepWaterIMR/sdmTMBexperiments")
library(sdmTMBexperiments)  # attaches ggOceanMaps
```

Confirm BAIT can reach the Biotic database (BAIT `biotic-connect`). If the database is missing,
point the user to BAIT `biotic-server-setup`.

## Done

Tell the user index-template is installed and how to start:

> *"Let's make a biomass index for `<species>` using all bottom trawl data collected during
> surveys, using index-template."*

That triggers `index-new-project`.
