---
name: index-update
description: Update index-template to the latest version — git pull the index-template repo and re-sync the index-* skills into the global skills folder. Use when the user says "update index-template", "pull the latest index-template", or asks for newer index-building recipes/skills.
---

# Update index-template

Goal: pull the latest index-template and re-sync its skills, mirroring BAIT's `bait-update`.

## Step 1 — Locate the install

Read `index_template_path` from `~/.index-template/config.json`. If there is no config or no
git repo there, tell the user to run `index-install` first and stop.

## Step 2 — Pull

```bash
git -C "<index_template_path>" fetch --quiet
git -C "<index_template_path>" pull --ff-only
```

If the working tree has local changes, report them and let the user decide — don't discard
work.

## Step 3 — Re-sync skills globally

Copy the updated `skills/index-*` into the agent's user-level skills folder
(`~/.claude/skills/` for Claude Code, `~/.codex/skills/` for Codex), overwriting the old
copies. Only touch `index-*` skills — leave BAIT's `biotic-*` skills alone.

## Step 4 — Report

Summarise what changed (new/updated skills or knowledge files) from the git log since the last
pull, and remind the user that existing generated projects are unaffected — they can adopt new
guidance on their next task.
