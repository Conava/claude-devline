# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Personal Claude Code plugin repository. The `plugin/` folder is the actual plugin. The install script registers its absolute path in `~/.claude/plugins/installed_plugins.json` — no symlink needed, Claude Code reads directly from the repo.

**Install:** `./install.sh` (Linux/macOS) or `install.cmd` (Windows)

## Repository Structure

```
plugin/                          # THE PLUGIN — symlink target
├── .claude-plugin/plugin.json   # Plugin metadata (REQUIRED)
├── agents/                      # Agent definitions (*.md)
├── skills/                      # Skill modules (each: folder/SKILL.md)
├── commands/                    # Slash commands (*.md)
└── hooks/hooks.json             # Hook configuration
data/                            # Reference material (gitignored)
install.sh / install.cmd         # Symlink + register the plugin
```

## Plugin File Formats

All plugin content lives under `plugin/`.

### Agents (`plugin/agents/*.md`)
```yaml
---
name: agent-name
description: When and how to trigger this agent
model: sonnet              # sonnet | opus | haiku | inherit
tools: [Read, Grep, Glob]  # optional: restrict available tools
color: green               # optional: UI color
---

Agent instructions in markdown...
```

### Skills (`plugin/skills/{name}/SKILL.md`)
```yaml
---
name: skill-name
description: "Trigger conditions — when to activate this skill"
---

Skill instructions in markdown...
```
Skills can contain subdirectories: `agents/`, `scripts/`, `references/`, `assets/`.

### Commands (`plugin/commands/*.md`)
```yaml
---
description: "What this command does"
allowed-tools: Read, Edit, Glob          # optional: tool whitelist
disable-model-invocation: true           # optional: prevent direct AI invocation
argument-hint: "<arg description>"       # optional: parameter hint
---

Command instructions in markdown...
```

### Hooks (`plugin/hooks/hooks.json`)
```json
{
  "hooks": {
    "SessionStart": [{ "matcher": "startup", "hooks": [{ "type": "command", "command": "..." }] }],
    "PreToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "..." }] }],
    "PostToolUse": [{ "matcher": "...", "hooks": [...] }],
    "Stop": [{ "matcher": "...", "hooks": [...] }]
  }
}
```
Hook commands can use `${CLAUDE_PLUGIN_ROOT}` to reference the `plugin/` directory.

## Reference Material

The `data/` folder (gitignored) contains inspiration from existing plugins:
- `data/agents/` — Marketplace with 72 plugins, 112 agents, 146 skills
- `data/official/` — 14 Anthropic plugins (code-review, feature-dev, security-guidance, etc.)
- `data/superpowers/` — Core skills library (brainstorming, TDD, debugging, planning)
- `data/everything claude code/` — Comprehensive examples of all plugin patterns

Use these as templates when creating new agents, skills, or commands.
