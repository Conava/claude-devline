---
name: claude-md-management
description: "Use when the user asks to 'audit CLAUDE.md', 'improve CLAUDE.md', 'check CLAUDE.md quality', 'update project memory', or 'revise CLAUDE.md'. Also triggered when discussing CLAUDE.md maintenance or project memory optimization."
user-invocable: true
context: fork
agent: docs-updater
---

# CLAUDE.md Quality Audit

Run the docs-updater agent in CLAUDE.md quality audit mode (Mode 2 in the agent's system prompt).

Audit, score, and improve all CLAUDE.md files across the project. These files serve as project memory — they must be accurate, concise, and actionable.

## Task

1. **Discover** all CLAUDE.md files: project root, `.claude/`, monorepo packages
2. **Score** each on the 100-point rubric (Commands 20, Architecture 20, Non-Obvious 15, Conciseness 15, Currency 15, Actionability 15)
3. **Report** quality grades with per-category breakdown
4. **Fix** files scoring below B — propose changes, verify against code, apply after approval
5. **Cross-reference** — ensure CLAUDE.md points to the project's architecture doc, API spec, and ADRs if they exist (check `project_structure` config paths)

$ARGUMENTS
