---
name: setup
description: This skill should be used when the user runs "/setup", "setup my project", "initialize CLAUDE.md", "create CLAUDE.md", or wants to set up the devline clarification protocol for a project. Creates a CLAUDE.md with the clarification protocol and interactively generates a minimal devline.local.md with only non-default settings.
user-invocable: true
disable-model-invocation: true
---

# Setup

Set up the devline pipeline for a project. Two files are created:

1. **`CLAUDE.md`** in the project root — non-obvious project context + workflow orchestration for devline
2. **`.claude/devline.local.md`** — pipeline settings (only non-default values)

Assets:
- **[assets/claude-md-template.md](assets/claude-md-template.md)** — CLAUDE.md template with 4 sections (header, workflow orchestration, core principles, project context)
- **[assets/devline-local-template.md](assets/devline-local-template.md)** — All available pipeline settings organized in 4 batches with defaults

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

### 1. CLAUDE.md

Read `CLAUDE.md` in the working directory root.

- **Does not exist** → create with the template.
- **Exists without the content of the claude-md-template** → ask the user: **append** (add new sections) or **override** (replace with template).
- **Exists with all or part of the content of the claude-md-template** → inform the user it already has the protocol and ask: **skip**, **override**, or **optimize** (integrate protocol, remove boilerplate after quick explore, confirm before writing).

Read the template from [assets/claude-md-template.md](assets/claude-md-template.md). Present each section independently — show the default content and ask if the user wants to keep it as-is, modify it, or skip it. Assemble the final file from only the sections the user accepted or modified.

After presenting all sections, show the assembled preview using **AskUserQuestion** and write only after confirmation.

### 2. devline.local.md

Check if `.claude/devline.local.md` exists.

- **Exists** → inform the user, show current contents, ask: **skip**, **override** (replace), or **merge** (add missing settings from what they configure below).
- **Does not exist** → proceed with interactive setup.

Read the settings template from [assets/devline-local-template.md](assets/devline-local-template.md). Walk through all 4 batches. For each batch:

1. Show the batch name, list every setting with its default value
2. Ask: "Do you want to change anything in this batch, or keep all defaults?"
3. If they want changes, ask what they want — do not ask for each setting individually
4. Record only the settings that differ from defaults

After all batches, collect only the non-default settings. If no settings were changed, inform the user that defaults will be used and no file is needed — do **not** create an empty or all-defaults file.

If there are non-default settings, assemble the file using the output format from the template. Show the preview using **AskUserQuestion** and write only after confirmation. Create `.claude/` directory if needed.

### 3. Recommended additions (optional)

Three optional companions make devline leaner and more capable. Offer all three — the user can accept any subset. For each: check if it's already present (note it and skip if so), otherwise briefly explain it and ask whether to install. If a step fails, show the error and point to the tool's repo for manual install.

**RTK (Rust Token Killer)** — a CLI proxy that cuts token use 60-90% on common commands (git, ls, grep, test runners, builds) by filtering noise before it reaches context. devline runs many parallel agents issuing Bash commands, so the savings compound.
- Check: `which rtk`.
- If accepted:
  1. `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`
  2. `rtk init -g` — registers the auto-rewrite hook in `~/.claude/settings.json`
  3. Verify: `rtk --version`

**Basic Memory** — local-first, per-project memory stored as plain Markdown you commit to the repo, retrieved on demand so it never bloats context. Gives agents persistent, cross-session recall of project decisions and corrections. Works in any Claude Code session, not just devline.
- Check: `which basic-memory`.
- If accepted (multi-session-safe setup — each Claude session binds to its own repo's `memory/` project via a per-session MCP wrapper, so parallel sessions never clobber a shared "active project"):
  1. `uv tool install basic-memory`
  2. Write the per-session MCP wrapper to `~/.claude/mcp/basic-memory-cwd.sh` (create `~/.claude/mcp/` if needed) and `chmod +x` it, with exactly this content:
     ```bash
     #!/usr/bin/env bash
     # Per-session Basic Memory MCP server, bound to the current repo's project.
     # One stdio server per Claude session (in that session's cwd) → each session
     # pins to its own repo via --project, so parallel sessions never clobber a
     # shared "active project".
     export PATH="$HOME/.local/bin:$PATH"
     repo=$(git rev-parse --show-toplevel 2>/dev/null)
     if [ -n "$repo" ]; then
       name=$(basename "$repo")
       if ! basic-memory project list 2>/dev/null | grep -qw "$name"; then
         mkdir -p "$repo/memory"
         basic-memory project add "$name" "$repo/memory" >/dev/null 2>&1 || true
       fi
       exec basic-memory mcp --project "$name"
     fi
     exec basic-memory mcp
     ```
  3. `claude mcp add --scope user basic-memory -- bash ~/.claude/mcp/basic-memory-cwd.sh`
  4. Optionally add its official Claude Code plugin (`basic-memory@basicmachines-co`) for session-start recall + the `memory-defrag`/`memory-reflect` consolidation skills.
- For a full machine setup, the repo's `install.sh` does all of this plus devline + the other companions.

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
- devline.local.md only needs non-default settings. Full settings reference is in the devline README.
- Restart Claude Code after editing devline.local.md.
```
