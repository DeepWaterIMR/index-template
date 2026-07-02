<!-- badges / logo go here once available -->

# 📈 index-template — sdmTMB survey indices, agent-driven

**Teach your AI coding agent to build a spatiotemporal survey index for stock assessment —
for any species, on your own machine.**

index-template is a knowledge pack that turns a general coding agent (Claude Code, Codex,
Cursor, Gemini CLI, Mistral, …) into a competent assistant for building **sdmTMB** survey
indices from IMR bottom-trawl data, reproducing the method of **Vihtakari et al. (2026)**,
*ICES Journal of Marine Science*
([doi:10.1093/icesjms/fsag009](https://doi.org/10.1093/icesjms/fsag009)).

Tell your agent which species you want an index for, and it will:

1. **Ask you a short, structured questionnaire** and confirm a plan.
2. **Scaffold a new project folder** with a standard structure (`docs/`, `data/`, `R/`,
   `memory/`, `logs/`, `review/`).
3. **Compile the data** from the IMR Biotic database (and, optionally, legacy SPD files),
   applying the filtering that makes catches quantitative.
4. **Fit, validate, and report** an sdmTMB index, using helpers from
   [sdmTMBexperiments](https://github.com/DeepWaterIMR/sdmTMBexperiments) and maps from
   [ggOceanMaps](https://mikkovihtakari.github.io/ggOceanMaps/).

> **It is not a trained model.** Your data never leaves your machine and never enters any
> model's weights. The agent simply *reads this repo* while it helps you. See
> [Privacy](#-privacy-first).

## 🧰 Built on BAIT

index-template sits **on top of** [BAIT](https://github.com/DeepWaterIMR/BAIT) (the Biotic AI
Toolkit). BAIT handles Biotic **data access, the database, privacy, maps, and life-history**;
index-template adds the **sdmTMB index-building** layer. If BAIT is not installed yet, install
it first:

```
install https://github.com/DeepWaterIMR/BAIT
```

## 🔒 Privacy first

This repo is **public and contains instructions only — never data**:

- **No data and no private paths** are ever committed here. Real data and paths live only in
  the *project folder the agent generates for you*, where `data/`, `logs/`, and `review/` are
  git-ignored.
- The Biotic database lives **outside** any repo (BAIT default:
  `~/IMR_biotic_BES_database/`).
- During setup, **turn off model training / data retention** for your agent once — BAIT walks
  you through it and records the onboarding, then uses reminders rather than blocking every
  later task.

## 🚀 Quickstart

1. **Install BAIT** (if you haven't): `install https://github.com/DeepWaterIMR/BAIT`.
2. **Install index-template:**
   ```
   install https://github.com/DeepWaterIMR/index-template
   ```
   The agent runs [`index-install`](skills/index-install/SKILL.md): a privacy check → cloning
   index-template → installing the skills **globally** → verifying BAIT and the R packages
   (`sdmTMB`, `sdmTMBexperiments`, `ggOceanMaps`).
3. **Start a species index:**
   ```
   Let's make a biomass index for snabeluer (beaked redfish) using all bottom trawl data
   collected during surveys, using index-template.
   ```
   The agent runs the questionnaire, plans, scaffolds a project, and drives the four-step
   workflow.

## 🗺️ The four-step workflow

| Step | Skill | Modelled on |
|------|-------|-------------|
| Scaffold a project (questionnaire + plan) | [`index-new-project`](skills/index-new-project/SKILL.md) | spict-template scaffold interview |
| **1.** Compile & report the data | [`index-compile-data`](skills/index-compile-data/SKILL.md) | `ref-index-paper/docs/data/*` + `SI-Text-1-data` |
| **2.** Fit the first feasible model | [`index-fit-model`](skills/index-fit-model/SKILL.md) | `SI-Text-2-sdmTMB` |
| **3.** Validate / select the model | [`index-validate-model`](skills/index-validate-model/SKILL.md) | `SI-Text-3-model-selection` |
| **4.** Final report + extensions | [`index-final-report`](skills/index-final-report/SKILL.md) | `ref-assessment-index/benchmark/beaked` |

Long renders are compiled with [`index-render`](skills/index-render/SKILL.md) in a screen
session with a log in `logs/`.

## 📚 What's in this repo

- [`AGENTS.md`](AGENTS.md) / [`CLAUDE.md`](CLAUDE.md) — the agent contract.
- [`skills/`](skills/) — the `index-*` skills (installed globally).
- [`knowledge/`](knowledge/) — the shared source of truth (method, data filtering, sdmTMB,
  helpers, packages, project structure, rendering).
- [`project-template/`](project-template/) — the skeleton copied into each new project.
- [`scaffold.R`](scaffold.R) — stamps a project from `config.yaml`.
- [`examples/redfish/`](examples/redfish/) — a worked example.

## 📖 Reference

Vihtakari, M. et al. (2026). *A reproducible spatiotemporal model-based survey index for stock
assessment.* ICES Journal of Marine Science.
[doi:10.1093/icesjms/fsag009](https://doi.org/10.1093/icesjms/fsag009).
