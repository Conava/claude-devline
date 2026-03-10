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

Review `plugin/hooks/guard.sh` and `plugin/hooks/file-guard.sh` before enabling this. The defaults block network operations, protected branch mutations, sensitive file writes, and `rm -rf` outside the project directory. Extend the blocked command/pattern lists in your `~/.claude-plugin-config.yaml` or `repo/.claude-plugin-config.yaml` if your project has additional operations that should never run automatically.

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

The full pipeline runs 8 stages. Trivial tasks (single file, obvious change) skip stages 1-2 and enter directly at implementation.

| Stage | What happens | Agent | Model |
|-------|-------------|-------|-------|
| 0. Branch safety | Creates feature branch if on a protected branch | — | — |
| 1. Brainstorm | Conversational design exploration in main chat (no agent, no design doc) | — | — |
| 2. Plan | Execution graph with task dependencies, file ownership, parallel groups | planner | opus |
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

> **Some skills not included.** `pdf`, `docx`, `pptx`, and `xlsx` are licensed by Anthropic and cannot be redistributed. Download them from the [claude-code-skills](https://github.com/anthropics/claude-code-skills) repo and place them in `plugin/skills/`.

### Pipeline Stages (individually invocable)

| Skill | What it does |
|-------|-------------|
| `pipeline` | Run the full pipeline (or describe a task in natural language) |
| `brainstorm` | Explore ideas and design solutions interactively |
| `plan` | Create an implementation plan with task dependencies |
| `implement` | Implement a single task or feature (new things) |
| `systematic-debugging` | Diagnose and fix bugs with root cause analysis (broken things) |
| `review` | Deep review: security, code quality, test coverage |
| `docs-update` | Update docs to reflect code changes |
| `merge-prep` | Clean up artifacts, generate merge commit + PR title |

### Management

| Skill | What it does |
|-------|-------------|
| `skills-list` | List all available domain skills |
| `skills-load` | Load domain skills ad-hoc by name or technology |
| `claude-md-management` | Audit and improve CLAUDE.md files |

### Standalone Utilities

| Skill | What it does |
|-------|-------------|
| `docs-generate` | Generate comprehensive technical documentation |
| `perf-review` | Performance review of code changes |
| `dx-audit` | Developer experience audit |
| `error-detective` | Investigate error patterns and logs |
| `cloud-infrastructure` | Cloud/infrastructure review |
| `threat-modeling` | Security threat modeling (explicit invocation only) |
| `tutorial-engineering` | Create technical tutorials (explicit invocation only) |
| `compliance-audit` | Regulatory compliance review (explicit invocation only) |

### Business

| Skill | What it does |
|-------|-------------|
| `startup-analysis` | Startup viability and strategy analysis |
| `business-analytics` | Business metrics and data analysis |
| `market-research` | Market and competitor research |
| `investor-materials` | Pitch decks and investor materials |
| `investor-outreach` | Investor communication strategy |
| `hr-legal` | HR and legal document review |
| `seo-content` | SEO-optimized content creation |
| `seo-audit` | SEO audit and recommendations |
| `article-writing` | Long-form article writing |
| `content-engine` | Content strategy and production |
| `humanizer` | Remove AI-generated writing patterns from text |

### Domain Skills

Domain skills provide specialized knowledge for specific technologies. They load automatically based on file types being touched, or load them manually:

```
/claude-devline:skills-load kotlin and api design
/claude-devline:frontend-design
```

**18 domain skills:** api-design, backend-patterns, cpp-patterns, database-design, database-migrations, deployment-patterns, django-patterns, docker-patterns, e2e-testing, frontend-design, frontend-patterns, golang-patterns, java-coding-standards, jpa-patterns, postgres-patterns, python-patterns, rust-patterns, springboot-patterns

**8 LSP skills:** clangd-lsp, csharp-lsp, gopls-lsp, jdtls-lsp, kotlin-lsp, pyright-lsp, rust-analyzer-lsp, typescript-lsp

**Additional:** shell-patterns, swift-patterns, cloud-infrastructure

## Agents

15 specialized agents with models and tools defined in YAML frontmatter.

| Agent | Model | Isolation | Purpose |
|-------|-------|-----------|---------|
| planner | opus | — | Execution graph with dependencies + file ownership |
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

**Permissions:** Implementer and debugger use `bypassPermissions` mode — hooks enforce safety, not interactive prompts. Other agents use `acceptEdits`.

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
3. **`repo/.claude-plugin-config.yaml`** — Project/team overrides

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
# repo/.claude-plugin-config.yaml
project_structure:
  architecture: docs/arch/system-overview.md
  api_spec: src/main/resources/openapi.yaml
  decisions: docs/adr/
  design_docs: docs/designs/
```

Default paths: `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `docs/`, `docs/architecture.md`, `docs/api/openapi.yaml`, `docs/plans/`, `docs/decisions/`, `docs/runbooks/`.

### Example: fully autonomous team config

```yaml
# repo/.claude-plugin-config.yaml
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
