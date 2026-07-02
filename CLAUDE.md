# CLAUDE.md — index-template (Claude Code)

This is the **Claude Code** pointer. The full agent contract is in
[`AGENTS.md`](AGENTS.md) — read it. This file only adds Claude-specific notes.

## What this repo is

A **knowledge pack** (like [BAIT](https://github.com/DeepWaterIMR/BAIT)) that teaches an
agent to build a **sdmTMB survey index** for a species and **generates a new project folder**
for it. It is installed once per machine; its skills live in `~/.claude/skills/` as
`index-*`. It is **public — never commit data or private paths here.** See the privacy
section of [`AGENTS.md`](AGENTS.md).

## Where things are

- **Skills** — `skills/index-*/SKILL.md`. Installed globally by `skills/index-install`.
- **Shared knowledge** — `knowledge/*.md` (the method, filtering, sdmTMB, helpers, packages,
  project structure, rendering).
- **Project skeleton** — `project-template/`, copied and stamped by `scaffold.R` for each new
  species project.
- **Worked example** — `examples/redfish/`.

## Claude-specific notes

- **Project memory, not local memory.** When working *inside a generated project*, use that
  project's `memory/` folder as your project memory (read `memory/MEMORY.md` first, write new
  memory files there). Do **not** use `~/.claude/projects/.../memory/` for project facts —
  that folder is only for user-level preferences/identity.
- **Skills** — when the user types `/index-...` or asks to build/validate/report an index,
  invoke the matching skill. When they ask for Biotic data access, defer to BAIT's `biotic-*`
  skills.
- **Plan mode** — after the questionnaire in `index-new-project`, use plan mode to confirm
  the approach before scaffolding and rendering.
- **Code review before render** — Quarto renders are slow; run `/code-review` on changed
  chunks and fix issues before starting a render. See `knowledge/rendering.md`.

For everything else, see [`AGENTS.md`](AGENTS.md).
