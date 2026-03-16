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
- **[assets/claude-md-template.md](assets/claude-md-template.md)** — CLAUDE.md template with 6 sections (header, workflow orchestration, core principles, learning & recovery, project context, lessons placeholder)
- **[assets/devline-local-template.md](assets/devline-local-template.md)** — All available pipeline settings organized in 4 batches with defaults

## Process

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

### 3. Closing Instructions

Show the following:

```
Setup complete. A few tips:

- Keep CLAUDE.md lean and accurate. Add clarifications when agents get stuck; remove stale entries.
- Do not add information that can easily be derived from code, tests, or git history.
- If you need to change agent or workflow behavior, consider cloning the devline plugin and editing agents/skills directly — CLAUDE.md should stay focused on project context.
- devline.local.md only needs non-default settings. Full settings reference is in the devline README.
- Restart Claude Code after editing devline.local.md.
```
