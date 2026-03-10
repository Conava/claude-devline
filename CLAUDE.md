# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Composable Claude Code plugin with a full development pipeline. The `plugin/` folder is the plugin — registered via `./install.sh` in `~/.claude/plugins/installed_plugins.json`.

## Repository Structure

```
plugin/                              # The plugin (registered path)
├── .claude-plugin/plugin.json       # Plugin manifest
├── config/
│   ├── defaults.yaml                # Default conventions, safeguards, workflow settings
│   └── skill-mappings.yaml          # File/framework → domain skill auto-detection
├── hooks/
│   ├── hooks.json                   # Hook config (8 hook types)
│   ├── session-start.sh             # Injects merged config + skill descriptions
│   ├── guard.sh                     # Blocks dangerous Bash operations
│   ├── file-guard.sh                # Blocks writes to sensitive/lock files
│   ├── auto-format.sh               # Runs project formatters after writes
│   ├── notify.sh                    # Logs permission/idle prompts
│   └── session-end.sh               # No-op stub
├── scripts/
│   └── merge-config.py              # Merges YAML configs (defaults → user → repo)
├── agents/                          # 16 agents with model/tools in frontmatter
└── skills/                          # 49 skills (8 pipeline, 18 domain, 3 management, 5 business, 10 extended, 5 business-ops)
data/                                # Reference material (gitignored)
docs/plans/                          # Design docs and plans (per-feature, temporary)
```

## Pipeline (invoked via `/build` or natural language)

Stage 0: Branch safety → Stage 1: Brainstorm (opus) → Stage 2: Plan (opus) → Stage 3: Implement+Review per task (sonnet, worktrees) → Stage 4: Deep review (holistic compliance + specialist reviewers) → Stage 5: Docs update (records unresolved findings from review doc) → Stage 6: Verification → Stage 7: Merge prep

Trivial tasks skip stages 1-2. Bug-fix tasks use `/systematic-debugging` which skips brainstorm+plan and goes straight to diagnosis via the debugger agent (opus).

### Stage skills (individually invocable)

`/brainstorm`, `/plan`, `/implement`, `/review`, `/docs-update`, `/merge-prep`, `/systematic-debugging`, `/skills-list`, `/skills-load`, `/claude-md-management`

### Additional standalone skills

`/docs-generate`, `/perf-review`, `/dx-audit`, `/error-detective`, `/cloud-infrastructure`, `/threat-modeling` (explicit only), `/tutorial-engineering` (explicit only), `/compliance-audit` (explicit only), `/startup-analysis` (explicit only), `/business-analytics` (explicit only), `/hr-legal` (explicit only), `/seo-content` (explicit only), `/seo-audit` (explicit only)

## Configuration Layering

1. `plugin/config/defaults.yaml` — ships with plugin
2. `~/.claude-plugin-config.yaml` — personal overrides
3. `repo/.claude-plugin-config.yaml` — project/team overrides

Deep merge. Safeguard overrides are additive only. Models are set in agent frontmatter, not config.

## Project Structure (`project_structure` config)

Agents use configured paths to find and write documentation. Default paths (override per-project):

| Key | Default | Purpose |
|-----|---------|---------|
| `readme` | `README.md` | Project readme |
| `claude_md` | `CLAUDE.md` | Claude Code project memory |
| `changelog` | `CHANGELOG.md` | Release changelog |
| `docs_dir` | `docs/` | Documentation root |
| `architecture` | `docs/architecture.md` | System architecture |
| `api_spec` | `docs/api/openapi.yaml` | API specification |
| `design_docs` | `docs/plans/` | Design docs and plans (pipeline artifacts) |
| `decisions` | `docs/decisions/` | Architecture Decision Records (ADRs) |
| `runbooks` | `docs/runbooks/` | Operational runbooks |

## Agents (plugin/agents/)

| Agent | Model | Isolation | Purpose |
|-------|-------|-----------|---------|
| brainstorm | opus | — | Chunked interactive design exploration |
| planner | opus | — | Execution graph with dependencies + file ownership. Verifies library APIs via Context7 |
| implementer | sonnet | worktree | TDD-first implementation with domain skill loading |
| reviewer | sonnet | — | Per-task confidence-scored review. Verifies library API usage via Context7 |
| security-reviewer | opus | — | OWASP top 10 systematic check |
| code-quality-reviewer | opus | — | Clean code, type design, simplification |
| test-coverage-reviewer | opus | — | Behavioral coverage, silent failure detection |
| docs-updater | sonnet | — | Living document updates |
| docs-reviewer | opus | — | Documentation accuracy review |
| debugger | opus | — | Systematic root cause analysis (four-phase methodology). Checks library docs via Context7 |
| verifier | sonnet | — | Hard gate — evidence-based verification |
| build-fixer | sonnet | — | Surgical build/type error fixes with minimal diffs |
| code-simplifier | sonnet | worktree | Refactoring for clarity without changing behavior |
| database-reviewer | sonnet | — | SQL, schema, migration, and ORM quality review |
| docs-architect | sonnet | — | Comprehensive technical documentation generation |
| legacy-modernizer | sonnet | — | Incremental migrations using strangler fig pattern |

## MCP Integration

Agents can use any MCP tools available in the user's environment. Three agents have explicit Context7 integration for verifying library/API documentation:

- **Planner** (Step 2.5): Resolves library IDs and queries current docs before writing task descriptions. Prevents plans from referencing deprecated or hallucinated APIs.
- **Reviewer** (checklist item 6): Verifies that newly introduced library API usage matches current documentation. Flags wrong signatures and deprecated APIs.
- **Debugger** (Phase 2, step 5): Checks current library docs when investigating bugs — catches version mismatch root causes.

Context7 tools used: `mcp__context7__resolve-library-id`, `mcp__context7__query-docs`

## Adding Domain Skills

1. Create `plugin/skills/<name>/SKILL.md` with frontmatter (`name`, `description`)
2. Add file/framework mappings to `plugin/config/skill-mappings.yaml`
3. Implementer auto-detects and loads relevant skills per task

## Hooks

- **SessionStart**: Merges config, injects skill descriptions, detects project tech stack, checks branch safety
- **PreToolUse (Bash)**: Blocks `git push`, `--force`, `rm -rf`, protected branch checkout/merge, `git reset`, `git clean`. Allows task→feature branch merges.
- **PreToolUse (Write/Edit)**: Blocks writes to sensitive files (`.env`, credentials, keys), lock files, system directories, and path traversal
- **PostToolUse (Write/Edit)**: Runs project-appropriate formatters (prettier, ruff, gofmt, rustfmt, etc.)
- **UserPromptSubmit**: Warns about sensitive files and destructive operations
- **Notification**: Logs permission and idle prompts
- **SessionEnd**: No-op stub

## Key Design Decisions

- Agents can't spawn agents — main chat orchestrates all agent dispatch
- Chunked interaction for brainstorm/plan: agent asks 1-3 questions per round, Q&A tracked in context
- Worktree isolation per implementation task, merge to feature branch after review
- Tasks with overlapping files never run in parallel (planner enforces)
- Per-task review retry flow: normal retry → systematic debugging via debugger agent (up to 2 attempts) → escalate to planner with cumulative evidence
- `/implement` for building new things; `/systematic-debugging` for fixing broken things (skips brainstorm+plan)
- Plan artifacts available during PR review, deleted before merge
- Planner, reviewer, and debugger verify external library APIs via Context7 MCP to prevent hallucinated or deprecated API usage
