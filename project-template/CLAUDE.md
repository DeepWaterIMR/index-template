# CLAUDE.md — {{SPECIES_NAME}} survey index (Claude Code)

Claude Code pointer. The full contract is in [`AGENTS.md`](AGENTS.md) — read it.

- **Method & skills**: the *how* lives in the installed **index-template** knowledge pack
  (`index-*` skills) and **BAIT** (`biotic-*` skills for data access). Use them.
- **Project memory, not local memory**: use this project's [`memory/`](memory/) folder as your
  project memory. Read [`memory/MEMORY.md`](memory/MEMORY.md) first; write new memory files
  here. Do not put project facts in `~/.claude/projects/.../memory/`.
- **Config**: everything species/model-specific is in [`config.yaml`](config.yaml), read by
  `R/00_setup.R`. Edit there.
- **Slow renders**: run `/code-review` on changed chunks before rendering; render in a screen
  session with a log in `logs/`; flip compute toggles to `FALSE` after outputs exist.

For everything else, see [`AGENTS.md`](AGENTS.md).
