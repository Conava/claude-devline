# claude-devline

Composable development pipeline for Claude Code with custom agents, skills, and safeguard hooks. Designed as a team baseline with per-user and per-project configuration.

## Installation

### Linux / macOS

```bash
git clone https://github.com/marloncard/claude-code.git ~/claude-plugins/claude-devline
cd ~/claude-plugins/claude-devline
./install.sh
source ~/.zshrc   # or ~/.bashrc
```

### Windows (PowerShell)

```powershell
git clone https://github.com/marloncard/claude-code.git $HOME\claude-plugins\claude-devline
cd $HOME\claude-plugins\claude-devline
.\install.cmd
. $PROFILE
```

The install script adds a shell alias so `claude` automatically loads the plugin via `--plugin-dir`. No marketplace registration or cache involved — the plugin runs directly from the cloned repo.

### Recommended: bypass permissions mode

The plugin's hooks (`guard.sh`, `file-guard.sh`) are the safety net — interactive permission prompts add friction without adding meaningful protection on top of them. Run Claude Code with permissions bypassed:

```json
// ~/.claude/settings.json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

Review `plugin/hooks/guard.sh` and `plugin/hooks/file-guard.sh` before enabling this. The defaults block network operations, protected branch mutations, sensitive file writes, and `rm -rf` outside the project directory. Extend the blocked command/pattern lists in your `~/.claude-plugin-config.yaml` or `repo/.claude/plugin-config.yaml` if your project has additional operations that should never run automatically.

### Updating

Pull the latest changes. No reinstall needed — changes take effect on next Claude Code restart.

```bash
cd ~/claude-plugins/claude-devline
git pull
```

### Manual usage (no install)

```bash
claude --plugin-dir /path/to/claude-code/plugin
```

### Uninstall

Remove the `# claude-devline` alias block from your shell config (`~/.zshrc`, `~/.bashrc`, or PowerShell `$PROFILE`).

## Quick Start

```
/claude-devline:pipeline add user authentication with OAuth2
```

Or just describe what you want — the pipeline skill is the default for any development task. For bug fixes, use `/claude-devline:systematic-debugging` instead — it skips design and goes straight to root cause analysis.

Skills are namespaced with `claude-devline:` prefix. Domain skills (python-patterns, frontend-design, etc.) load automatically based on file context.

## How the Pipeline Works

The full pipeline runs 9 stages. Trivial tasks (single file, obvious change) skip stages 1-2 and enter directly at implementation.

| Stage | What happens | Agent | Model |
|-------|-------------|-------|-------|
| 0. Branch safety | Creates feature branch if on a protected branch | — | — |
| 1. Brainstorm | Conversational design exploration in main chat (no agent, no design doc) | — | — |
| 2. Plan | Execution graph with task dependencies, file ownership, parallel groups | planner | opus |
| 2.5. Domain refinement | Domain experts review and own their slice of the plan (sequentially) | design/java/database agents | opus |
| 3. Implement + Review | Per-task TDD implementation in worktrees, then confidence-scored review | implementer + reviewer | sonnet |
| 4. Deep review | Security, code quality, and test coverage analysis (auto/full/targeted/light) | security/quality/coverage reviewers | opus/sonnet |
| 5. Docs update | Updates project documentation to reflect changes | docs-updater | opus |
| 6. Verification | Runs tests, linters, type checkers, build. Build failures get a fast-fix pass. | verifier + build-fixer | sonnet |
| 7. Merge prep | Generates merge commit message, PR title, cleans plan artifacts | — | — |

### Retry and Escalation Flow (Stage 3)

When a task fails review:

1. **Normal retry** — re-spawn implementer with reviewer feedback
2. **Systematic debugging (up to 2 attempts)** — spawn debugger agent (opus) for root cause analysis using four-phase methodology
3. **Escalate to planner** — planner creates a revised sub-plan with all evidence from debugging attempts

### Bug Fixes Without the Pipeline

Use `/claude-devline:systematic-debugging` for bug-fix tasks. It skips brainstorm and plan — a bug doesn't need a design, it needs diagnosis. The debugger agent (opus) follows a strict investigate-first methodology: root cause investigation → pattern analysis → hypothesis testing → implementation with regression test.

## Skills

All skills are namespaced: `/claude-devline:skill-name`.

### Pipeline Stages (individually invocable)

| Skill | What it does |
|-------|-------------|
| `pipeline` | Run the full pipeline (or describe a task in natural language) |
| `brainstorm` | Explore ideas and design solutions interactively |
| `plan` | Create an implementation plan with task dependencies |
| `implement` | Implement a single task or feature (new things) |
| `systematic-debugging` | Diagnose and fix bugs with root cause analysis (broken things) |
| `review` | Deep review: security, code quality, test coverage |
| `docs-update` | Update docs to reflect code changes (run on a feature branch or pass a commit hash — see note below) |
| `merge-prep` | Clean up artifacts, generate merge commit + PR title |

> **`docs-update` requires a diff base.** It works by comparing your current HEAD against a base ref to find what changed. Run it on a feature branch (base is auto-detected as `origin/main`) or pass an explicit commit hash or range: `/docs-update HEAD~10` or `/docs-update v1.2.0`. Running it on `main` without an argument produces no useful diff — the skill will prompt you in that case.

### Utilities

| Skill | What it does |
|-------|-------------|
| `docs-generate` | Generate comprehensive technical documentation from codebase |
| `perf-review` | Performance analysis and optimization |
| `dx-audit` | Developer experience audit |
| `error-detective` | Production error pattern and log analysis |
| `threat-modeling` | STRIDE threat modeling (explicit invocation only) |
| `tutorial-engineering` | Create pedagogical tutorials (explicit invocation only) |
| `compliance-audit` | GDPR/HIPAA/SOC2 compliance audit (explicit invocation only) |
| `skills-load` | Load domain skills ad-hoc into the main chat session |

### Writing & Content

| Skill | What it does |
|-------|-------------|
| `article-writing` | Long-form articles, guides, blog posts |
| `content-engine` | Multi-platform content campaigns (X, LinkedIn, YouTube, newsletters) |
| `humanizer` | Remove AI-writing patterns from text |
| `doc-coauthoring` | Structured co-authoring workflow for docs, specs, proposals |

### Business

| Skill | What it does |
|-------|-------------|
| `startup-analysis` | TAM/SAM/SOM, unit economics, financial modeling |
| `business-analytics` | KPIs, dashboards, cohort analysis |
| `market-research` | Competitor and market research |
| `investor-materials` | Pitch decks, investor memos, fundraising materials |
| `investor-outreach` | Investor cold emails, follow-ups, update emails |
| `hr-legal` | HR docs, legal templates (privacy policy, ToS, DPA) |
| `seo-content` | SEO-optimized content planning and writing |
| `seo-audit` | SEO site audit and recommendations |

### Domain Skills

Domain skills provide specialized knowledge for specific technologies. They all load automatically based on file types, framework markers, and directory patterns detected in the project. Use `/claude-devline:skills-load` to load any skill on demand in the current session.

api-design, backend-patterns, cloud-infrastructure, cpp-patterns, database-design, database-migrations, deployment-patterns, django-patterns, docker-patterns, e2e-testing, frontend-design, frontend-patterns, golang-patterns, java-coding-standards, jpa-patterns, postgres-patterns, python-patterns, rust-patterns, shell-patterns, springboot-patterns, swift-patterns

### Anthropic Skills (installed separately)

> These skills are licensed by Anthropic and cannot be redistributed. Download from the [claude-code-skills](https://github.com/anthropics/claude-code-skills) repo and place in `plugin/skills/`.

| Skill | What it does |
|-------|-------------|
| `pdf` | Read, extract, combine, split, OCR PDFs |
| `docx` | Create and edit Word documents |
| `pptx` | Create and edit PowerPoint presentations |
| `xlsx` | Create and edit spreadsheets |
| `canvas-design` | Visual art and poster design (PNG/PDF output) |
| `algorithmic-art` | Generative art with p5.js |
| `theme-factory` | Apply visual themes to slides, docs, HTML artifacts |
| `brand-guidelines` | Anthropic brand colors and typography |
| `claude-api` | Build apps with the Anthropic SDK |
| `mcp-builder` | Build MCP servers (Python/TypeScript) |
| `skill-creator` | Create, modify, and benchmark skills |
| `webapp-testing` | Test local web apps with Playwright |
| `web-artifacts-builder` | Complex HTML artifacts with React + Tailwind + shadcn |
| `internal-comms` | Internal communication templates (status reports, newsletters) |

## Agents

23 specialized agents with models and tools defined in YAML frontmatter.

| Agent | Model | Isolation | Purpose |
|-------|-------|-----------|---------|
| planner | opus | — | Execution graph with dependencies + file ownership |
| design-agent | opus | — | Domain planning: UI/UX, React, CSS, visual design, theme-factory (Stage 2.5) |
| java-agent | opus | — | Domain planning: Java, Spring Boot, JPA, Spring Security, backend patterns (Stage 2.5) |
| python-agent | opus | — | Domain planning: Python, Django, FastAPI, Celery, pytest (Stage 2.5) |
| rust-agent | opus | — | Domain planning: Rust, Actix/Axum, ownership design, concurrency (Stage 2.5) |
| cpp-agent | opus | — | Domain planning: C/C++, RAII, CMake, GoogleTest (Stage 2.5) |
| database-agent | opus | — | Domain planning: schema design, migrations, indexing, PostgreSQL (Stage 2.5) |
| api-agent | opus | — | Domain planning: REST contract, URL design, error format, versioning (Stage 2.5) |
| deployment-agent | opus | — | Domain planning: CI/CD, Docker, Kubernetes, Terraform, observability (Stage 2.5) |
| implementer | sonnet | worktree | TDD-first implementation with domain skill loading |
| reviewer | sonnet | — | Per-task confidence-scored review |
| security-reviewer | opus | — | OWASP top 10 systematic check |
| code-quality-reviewer | sonnet | — | Clean code, type design, simplification |
| test-coverage-reviewer | sonnet | — | Behavioral coverage, silent failure detection |
| docs-updater | opus | — | Living document updates (tier model, active pruning) |
| docs-reviewer | opus | — | Documentation accuracy review |
| debugger | opus | — | Systematic root cause analysis (four-phase methodology) |
| verifier | sonnet | — | Hard gate — evidence-based verification |
| build-fixer | sonnet | — | Surgical build/type error fixes with minimal diffs |
| code-simplifier | sonnet | worktree | Refactoring for clarity without changing behavior |
| database-reviewer | sonnet | — | SQL, schema, migration, and ORM quality review |
| docs-architect | sonnet | — | Comprehensive technical documentation generation |
| legacy-modernizer | sonnet | — | Incremental migrations using strangler fig pattern |

**Model selection:** Opus for reasoning-heavy tasks (planning, debugging, security review, docs update). Sonnet for speed-sensitive tasks (implementation, basic review, code quality). Models are set in agent frontmatter, not config.

**Isolation:** Implementer and code-simplifier use git worktrees for isolated changes. Implementers spawn with `run_in_background: true` and auto-merge on completion. Debugger works in the current branch (debugs where the bug lives).

**Permissions:** All pipeline execution agents use `bypassPermissions` — hooks enforce safety, not interactive prompts. Planning and domain agents (planner, design/java/python/rust/cpp/database/api/deployment agents) use `acceptEdits` since they interact with the user.

> **Background agents require `bypassPermissions`.** All pipeline execution agents run with `run_in_background: true` and cannot pause to prompt for permission — they will stall indefinitely if `defaultMode` is not set to `bypassPermissions`. The pipeline will not function correctly without it. See [Recommended: bypass permissions mode](#recommended-bypass-permissions-mode) above.

## MCP Integration

Three agents integrate with Context7 MCP for verifying external library documentation:

- **Planner**: Queries current library docs before writing task descriptions — prevents plans from referencing deprecated or hallucinated APIs
- **Reviewer**: Verifies that library API usage in implementations matches current documentation
- **Debugger**: Checks library docs during investigation — catches version mismatch root causes

These agents call `mcp__context7__resolve-library-id` and `mcp__context7__query-docs` automatically when external libraries are involved. Requires Context7 MCP server to be configured (see Recommended MCP Servers below).

## Configuration

Config is layered (deep merge, most specific wins):

1. **`plugin/config/defaults.yaml`** — Plugin defaults (ships with plugin)
2. **`~/.claude-plugin-config.yaml`** — Personal overrides
3. **`repo/.claude/plugin-config.yaml`** — Project/team overrides

### What you can configure

| Section | Options |
|---------|---------|
| `git` | Commit format, branch prefixes, protected branches, merge commit template, PR title format |
| `code` | Test approach (tdd/test-after/none), untestable strategies |
| `review` | Confidence threshold (0.0-1.0), deep review mode (auto/full/targeted/light), review agents |
| `workflow` | Interactive stages (`human_checkpoints`), max parallel tasks, verification commands |
| `safeguards` | Additional blocked commands/patterns (additive only — can't remove defaults) |
| `project_structure` | Paths where agents find/write docs, specs, plans, ADRs |
| `skills` | `always_show`, `enabled`, `disabled` lists for skill visibility |

### Project structure paths

Agents use configured paths to locate documentation. Override per-project:

```yaml
# repo/.claude/plugin-config.yaml
project_structure:
  architecture: docs/arch/system-overview.md
  api_spec: src/main/resources/openapi.yaml
  decisions: docs/adr/
  design_docs: docs/designs/
```

Default paths: `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `docs/`, `docs/architecture.md`, `docs/api/openapi.yaml`, `docs/plans/`, `docs/decisions/`, `docs/runbooks/`.

### Example: fully autonomous team config

```yaml
# repo/.claude/plugin-config.yaml
git:
  commit_format: gitmoji
  branch_prefixes: [feat/, fix/, chore/]
workflow:
  human_checkpoints: []        # no interactive brainstorm/plan
  max_parallel_tasks: 6
code:
  test_approach: tdd
review:
  deep_review_mode: full       # always run all 3 opus reviewers
  confidence_threshold: 0.85
```

### Example: personal overrides

```yaml
# ~/.claude-plugin-config.yaml
workflow:
  human_checkpoints: [brainstorm]  # interactive brainstorm, autonomous plan
skills:
  disabled: [seo-content, hr-legal]
```

### Model selection

Models are defined in agent frontmatter files (`plugin/agents/*.md`), not in config. To change a model, create an override agent file at the user or project level (see Customizing Agents and Skills).

## Safeguards

The plugin uses hooks to enforce safety at multiple levels.

**PreToolUse (Bash)** — blocks dangerous commands:
- `git push` (any form)
- `git checkout/merge` to protected branches (main, master, develop, staging, production, release, trunk)
- `rm -rf`, `git reset --hard`, `--force`, `git clean`
- Task→feature branch merges are allowed

**PreToolUse (Write/Edit)** — blocks sensitive file writes:
- `.env`, credentials, private keys, service accounts
- Lock files (package-lock.json, yarn.lock, Cargo.lock, etc.)
- System directories and path traversal

**PostToolUse (Write/Edit)** — auto-formats files after writes:
- Detects and runs project-appropriate formatters (prettier, ruff, gofmt, rustfmt, etc.)

**Other hooks:**
- **SessionStart**: Merges config layers, injects skill descriptions, detects tech stack
- **WorktreeCreate**: Copies hook scripts and config into new worktrees
- **Notification**: Logs permission and idle prompts
- **SessionEnd**: No-op stub

## Customizing Agents and Skills

**Do not modify the default agents or skills directly.** Your changes will be overwritten when you update the plugin.

Instead, create override files at the user or project level. Higher-priority locations win: project > user > plugin.

- **User-level** (all your projects): `~/.claude/agents/` or `~/.claude/skills/`
- **Project-level** (one repo): `.claude/agents/` or `.claude/skills/`

For example, to use opus for the implementer agent:

```bash
# Copy the default agent
mkdir -p ~/.claude/agents
cp plugin/agents/implementer.md ~/.claude/agents/

# Edit your copy — change model: sonnet to model: opus
```

## Adding Content

### New agent

Create `plugin/agents/my-agent.md` with YAML frontmatter:

```yaml
---
name: my-agent
description: What it does
model: sonnet          # or opus
tools: Read, Write, Edit, Bash, Grep, Glob
permissionMode: acceptEdits
maxTurns: 40
memory: project
---

# Agent prompt here
```

### New skill

Create `plugin/skills/my-skill/SKILL.md` with frontmatter:

```yaml
---
name: my-skill
description: "When to use this skill"
argument-hint: "[optional argument description]"
user-invocable: true              # shows in / menu
disable-model-invocation: false   # true = only manual invocation
allowed-tools: Read, Grep, Glob   # optional tool restrictions
---

# Skill content here
```

For auto-detection, add file/framework mappings in `plugin/config/skill-mappings.yaml`:

```yaml
file_patterns:
  "*.rb": [ruby-patterns]

framework_markers:
  "Rails|ActiveRecord": [rails-patterns]

directory_patterns:
  "app/models/": [rails-patterns]
```

## Recommended MCP Servers

The plugin works well with these MCP servers. Add them per-user:

```bash
# Context7 — library documentation lookup (used by planner, reviewer, debugger)
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY"

# GitHub — PR/issue management (requires gh auth login)
claude mcp add --scope user --transport sse github https://api.githubcopilot.com/mcp/

# PostgreSQL — database schema inspection and queries
claude mcp add --scope user postgres -- \
  npx -y @modelcontextprotocol/server-postgres $POSTGRES_CONNECTION_STRING
```
