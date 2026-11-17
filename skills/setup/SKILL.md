---
name: setup
description: This skill should be used when the user runs "/setup", "setup my project", "initialize CLAUDE.md", "create CLAUDE.md", or wants to set up the devline clarification protocol for a project. Creates a CLAUDE.md with the clarification protocol and interactively writes the devline config files (repo and user) with only non-default settings.
user-invocable: true
disable-model-invocation: true
---

# Setup

Set up the devline pipeline for a project. Up to three files are created:

1. **`CLAUDE.md`** in the project root — non-obvious project context + workflow orchestration for devline
2. **`.claude/devline.md`** — repo config, committed (only non-default values)
3. **`${CLAUDE_CONFIG_DIR:-~/.claude}/devline/config.md`** — user config for every repo (only non-default values)

Assets:
- **[assets/claude-md-template.md](assets/claude-md-template.md)** — CLAUDE.md template with 4 sections (header, workflow orchestration, core principles, project context)
- **[references/config.md](references/config.md)** — config layers, precedence, legacy files, and every key with its default and usual layer
- **[assets/repo-config-template.md](assets/repo-config-template.md)** and **[assets/user-config-template.md](assets/user-config-template.md)** — the two config file skeletons

## Process

### 0. Prerequisites

Check that required tools are installed by running `which jq`, `which git`, and `which gh`.

- **All found** → proceed silently.
- **Any missing** → list the missing tools and how to install them, then ask the user to install them before continuing. Do not proceed until all are available.

```
Missing prerequisites:
- jq: brew install jq / sudo apt install jq / sudo pacman -S jq
- git: brew install git / sudo apt install git / sudo pacman -S git
- gh: brew install gh / sudo apt install gh / sudo pacman -S github-cli
       After install: gh auth login
```

Only show the missing ones. If `gh` is missing, note that it's needed for PR creation, issue management, and GitHub API workflows.

Also check `CLAUDE_CODE_MAX_OUTPUT_TOKENS`. If it is unset or below 128000, suggest adding `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000` to the user's shell profile: the designer and other agents produce large outputs, and the default 32K limit cuts them off.

### 1. CLAUDE.md

Read `CLAUDE.md` in the working directory root.

- **Does not exist** → create with the template.
- **Exists without the content of the claude-md-template** → ask the user: **append** (add new sections) or **override** (replace with template).
- **Exists with all or part of the content of the claude-md-template** → inform the user it already has the protocol and ask: **skip**, **override**, or **optimize** (integrate protocol, remove boilerplate after quick explore, confirm before writing).

Read the template from [assets/claude-md-template.md](assets/claude-md-template.md). Present each section independently — show the default content and ask if the user wants to keep it as-is, modify it, or skip it. Assemble the final file from only the sections the user accepted or modified.

After presenting all sections, show the assembled preview using **AskUserQuestion** and write only after confirmation.

### 2. Config files

Read [references/config.md](references/config.md) for the layers, the legacy file names and the key table.

**Legacy move.** For each layer whose new file is missing but whose legacy file exists (Legacy files in the reference), show the legacy file and offer to move it to the new path. The repo file becomes committed once moved, so point out any key or prose that looks personal (models, voice, what AI may do) and offer to put it in the user file instead. Move only on a yes; on a no, leave it (skills keep reading it and remind the user).

**Which files.** Ask with AskUserQuestion: repo config, user config, both, or neither. For each chosen file:

1. If it exists, show its contents and ask: **skip**, **edit** (keep it and change what the user names), or **override**.
2. List the keys whose Layer column matches the file, grouped by owner, each with its default. Ask what to change; do not ask key by key. A key from the other layer is fine if the user wants it here.
3. Ask for prose rules no key can say: for the repo, git policy (squash merges, a PR for every change, commit size), testing approach, design system; for the user, voice and what AI may and may not do.
4. Keep only values that differ from the defaults. If nothing differs and there is no prose, say the defaults apply and write no file.
5. Fill the matching template ([repo](assets/repo-config-template.md), [user](assets/user-config-template.md)), drop the placeholder lines, show the preview with **AskUserQuestion**, and write only after confirmation. Create the directory if needed.

### 3. Recommended additions (optional)

Two optional companions make devline leaner and more capable. Offer both — the user can accept any subset. For each: check if it's already present (note it and skip if so), otherwise briefly explain it and ask whether to install. If a step fails, show the error and point to the tool's repo for manual install.

**RTK (Rust Token Killer)** — a CLI proxy that cuts token use 60-90% on common commands (git, ls, grep, test runners, builds) by filtering noise before it reaches context. devline runs many parallel agents issuing Bash commands, so the savings compound.
- Check: `which rtk`.
- If accepted:
  1. `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`
  2. `rtk init -g` — registers the auto-rewrite hook in `~/.claude/settings.json`
  3. Verify: `rtk --version`

**Ponytail** — a separate Claude Code plugin that keeps generated code minimal (YAGNI, stdlib-first, shortest working diff). It composes with devline: devline enforces the process, ponytail keeps the code lean.
- Check: whether the ponytail plugin is already enabled (look in `~/.claude/plugins` or the user's enabled plugins).
- If accepted: it's a plugin, so have the **user** run these interactive commands (this skill can't invoke `/plugin` itself):
  ```
  /plugin marketplace add DietrichGebert/ponytail
  /plugin install ponytail@ponytail
  ```

### 4. Closing Instructions

Show the following:

```
Setup complete. A few tips:

- Keep CLAUDE.md lean and accurate. Add clarifications when agents get stuck; remove stale entries.
- Do not add information that can easily be derived from code, tests, or git history.
- If you need to change agent or workflow behavior, consider cloning the devline plugin and editing agents/skills directly — CLAUDE.md should stay focused on project context.
- The config files only need non-default settings: `.claude/devline.md` for project rules (commit it), `${CLAUDE_CONFIG_DIR:-~/.claude}/devline/config.md` for personal preferences. The request beats the repo file, which beats the user file.
```
