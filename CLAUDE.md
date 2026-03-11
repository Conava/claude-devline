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
│   ├── hooks.json                   # Hook config (6 hook types)
│   ├── session-start.sh             # Injects merged config + skill descriptions
│   ├── guard.sh                     # Blocks dangerous Bash operations
│   ├── file-guard.sh                # Blocks writes to sensitive/lock files
│   ├── auto-format.sh               # Runs project formatters after writes
│   ├── worktree-create.sh            # Copies hooks/config into new worktrees
│   ├── notify.sh                    # Logs permission/idle prompts
│   └── session-end.sh               # No-op stub
├── scripts/
│   └── merge-config.py              # Merges YAML configs (defaults → user → repo)
├── agents/                          # 23 agents with model/tools in frontmatter
└── skills/                          # 49 skills (8 pipeline, 18 domain, 3 management, 5 business, 10 extended, 5 business-ops)
data/                                # Reference material (gitignored)
docs/plans/                          # Pipeline artifacts (temporary, never committed)
```

## Pipeline (invoked via `/build` or natural language)

Stage 0: Branch safety → Stage 1: Brainstorm (main chat Q&A, no agent) → Stage 2: Plan (opus) → Stage 2.5: Domain agent refinement (design/java/python/rust/cpp/database/api/deployment agents, sequential) → Stage 3: Implement per group (sonnet, worktrees, `run_in_background`) + batch review → Stage 4: Deep review (holistic + specialist reviewers) → Stage 5: Docs update → Stage 6: Verification → Stage 7: Merge prep

Trivial tasks skip stages 1-2. Bug-fix tasks use `/systematic-debugging` which skips brainstorm+plan and goes straight to diagnosis via the debugger agent (opus).

### Stage skills (individually invocable)

`/brainstorm`, `/plan`, `/implement`, `/review`, `/docs-update`, `/merge-prep`, `/systematic-debugging`, `/skills-list`, `/skills-load`, `/claude-md-management`

### Additional standalone skills

`/docs-generate`, `/perf-review`, `/dx-audit`, `/error-detective`, `/cloud-infrastructure`, `/threat-modeling` (explicit only), `/tutorial-engineering` (explicit only), `/compliance-audit` (explicit only), `/startup-analysis` (explicit only), `/business-analytics` (explicit only), `/hr-legal` (explicit only), `/seo-content` (explicit only), `/seo-audit` (explicit only)

## Configuration Layering

1. `plugin/config/defaults.yaml` — ships with plugin
2. `~/.claude-plugin-config.yaml` — personal overrides
3. `repo/.claude/plugin-config.yaml` — project/team overrides

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
| `design_docs` | `docs/plans/` | Pipeline artifacts (temporary, never committed) |
| `decisions` | `docs/decisions/` | Architecture Decision Records (ADRs) |
| `runbooks` | `docs/runbooks/` | Operational runbooks |

## Agents (plugin/agents/)

| Agent | Model | Isolation | Purpose |
|-------|-------|-----------|---------|
| planner | opus | — | Comprehensive plan document with dependencies + domain skills. Verifies library APIs via Context7 |
| design-agent | opus | — | Stage 2.5: UI/UX, React, CSS, visual design, theme-factory |
| java-agent | opus | — | Stage 2.5: Java, Spring Boot, JPA, Spring Security, backend patterns |
| python-agent | opus | — | Stage 2.5: Python, Django, FastAPI, Celery, pytest |
| rust-agent | opus | — | Stage 2.5: Rust, Actix/Axum, ownership design, async concurrency |
| cpp-agent | opus | — | Stage 2.5: C/C++, RAII, CMake, GoogleTest, service architecture |
| database-agent | opus | — | Stage 2.5: schema design, migrations, indexing, query optimization |
| api-agent | opus | — | Stage 2.5: REST contract, URL design, error format, versioning, pagination |
| deployment-agent | opus | — | Stage 2.5: CI/CD, Docker, Kubernetes, Terraform, health checks, observability |
| implementer | sonnet | worktree | TDD-first implementation with domain skill loading |
| reviewer | sonnet | — | Per-task confidence-scored review. Verifies library API usage via Context7 |
| security-reviewer | opus | — | OWASP top 10 systematic check |
| code-quality-reviewer | sonnet | — | Clean code, type design, simplification |
| test-coverage-reviewer | sonnet | — | Behavioral coverage, silent failure detection |
| docs-updater | opus | — | Living document updates (tier model, active pruning, deferred findings) |
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
- **WorktreeCreate**: Copies hook scripts and config into new worktrees
- **Notification**: Logs permission and idle prompts
- **SessionEnd**: No-op stub

## Key Design Decisions

- Agents can't spawn agents — main chat orchestrates all agent dispatch
- Brainstorm runs in main chat (no agent spawn, no design doc) — confirms approach via Q&A, passes summary to planner as inline context
- Implementer and debugger use `permissionMode: bypassPermissions` — hooks are the safety net, not permission prompts
- Implementers spawn with `run_in_background: true` — root session never handles commits (worktree auto-merge)
- Implementer scope is strictly bounded: plan task section is sole source of truth, no exploring beyond `touches` list, reports BLOCKED on scope violations
- Plan and review docs are temporary artifacts — never committed, cleaned up with `rm -f` in Stage 7
- Worktree isolation per implementation task, merge to feature branch after review
- Tasks with overlapping files never run in parallel (planner enforces shared infrastructure files and compilation dependencies)
- Per-task review retry flow: normal retry → systematic debugging via debugger agent (up to 2 attempts) → escalate to planner with cumulative evidence
- `/implement` for building new things; `/systematic-debugging` for fixing broken things (skips brainstorm+plan)
- Planner, reviewer, and debugger verify external library APIs via Context7 MCP to prevent hallucinated or deprecated API usage
- Docs-updater uses tier model (Tier 1 always current, Tier 2 on change, Tier 3 on demand) with active pruning and deferred findings lifecycle
- Domain agents (Stage 2.5) run sequentially after the planner — each takes ownership of their domain slice, challenges decisions, edits the plan, and signals complete before the next runs. Planner does a final validation pass after all domain agents complete.
- Domain agents are foreground (not background) — each must complete before the next starts, since they build on each other's refinements
