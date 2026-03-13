# devline

Full development lifecycle pipeline for Claude Code. Takes you from rough idea to merge-ready code with brainstorming, TDD planning, parallel implementation, in-depth review, systematic debugging, and documentation — all with strict security hooks and git workflow enforcement for bypass permissions mode.

## Features

- **Brainstorming** — Interactive refinement of rough ideas into concrete feature specs
- **TDD Planning** — Detailed plans written to disk with parallel work packages and file-based isolation
- **Parallel Implementation** — Multiple TDD implementer agents working simultaneously, reading the plan from disk
- **In-Depth Review** — Correctness, security, performance, and quality checks
- **Deep Review** — Final merge gate: security audit, credential scan, convention check, plan compliance
- **Systematic Debugging** — Scientific method: reproduce → hypothesize → test → fix
- **Documentation** — Auto-detect and update separate docs (README, API, architecture)
- **Frontend Auto-Detection** — Automatic UI review when frontend files are modified
- **Git Workflow Enforcement** — Branch protection, conventional commits, pipeline artifact isolation
- **Security Hooks** — Strict guards for bypass mode (blocks destructive commands, credential leaks)

## Commands

| Command | Description |
|---------|-------------|
| `/devline <idea>` | Full pipeline: brainstorm → plan → implement → review → docs → PR review |
| `/devline:brainstorm <idea>` | Interactive brainstorming only |
| `/devline:plan <spec>` | Create TDD implementation plan (written to `.devline/plan.md`) |
| `/devline:implement <plan>` | TDD implementation with parallel agents |
| `/devline:review [files]` | In-depth code review |
| `/devline:debug <error>` | Systematic debugging pipeline |
| `/devline:deep-review [branch]` | Final merge-readiness deep review |
| `/devline:cve-patcher <CVEs> [--repos ...]` | Patch CVE vulnerabilities across one or many repos |
| `/devline:migrate <package> [to vX] [--repos ...]` | Complex dependency migrations with breaking changes, code refactoring, migration tools |

## Pipeline Flow

```
User types feature idea
        │
  Stage 0: Branch Setup (AUTOMATIC)
  ├─ Check current branch
  ├─ If on protected branch → create kind/title feature branch
  └─ Create .devline/ directory, ensure .gitignore
        │
  Stage 1: Brainstorm (INTERACTIVE — main context)
  ├─ Quick clarifying questions (1-3 max, or none)
  └─ Output: Concise feature specification
        │
  ══ APPROVAL GATE (configurable) ══
        │
  Stage 2: Plan (INTERACTIVE)
  ├─ Designs architecture, researches libraries (context7)
  ├─ Creates parallel work packages (file-isolated)
  ├─ Challenges itself, recommends improvements
  ├─ Writes full plan to .devline/plan.md
  └─ Returns concise summary to conversation
        │
  ══ APPROVAL GATE (configurable) ══
        │
  ═══ AUTONOMOUS FROM HERE ═══
        │
  Stage 3: Implement + Review (PARALLEL, per package)
  ├─ Read plan from .devline/plan.md
  ├─ One implementer per work package, strict TDD
  ├─ Writes tests first, implements until green
  ├─ Handles inline docs (JSDoc, docstrings)
  ├─ Reviewer runs after each package completes
  └─ FAIL → retry implementer (2x) → debugger → user
        │
  Stage 4: Docs-keeper Agent
  └─ Updates README, API docs, architecture docs
        │
  Stage 5: Deep Review (FINAL GATE)
  ├─ Security audit + credential scan
  ├─ Code quality + tech debt
  ├─ Convention adherence
  ├─ Plan compliance (every criterion met)
  └─ APPROVED or CHANGES REQUIRED
```

## Git Workflow

Devline enforces a structured git workflow to prevent accidental changes to protected branches.

### Branch Protection

Before any code is written, devline checks the current branch. If on a protected branch (main, master, develop, release, production, staging), all Write/Edit operations are blocked until a feature branch is created.

**Default branch format:** `kind/descriptive-title`

| Kind | Use for |
|------|---------|
| `feat` | New features |
| `fix` | Bug fixes |
| `refactor` | Code restructuring |
| `docs` | Documentation only |
| `chore` | Maintenance, dependencies |
| `test` | Test additions/fixes |
| `ci` | CI/CD changes |

Examples: `feat/add-user-auth`, `fix/login-timeout`, `refactor/db-queries`

### Commit Convention

All commits are validated against the conventional commits format:

```
kind(scope): description

Examples:
  feat(auth): add JWT token validation
  fix(api): resolve timeout on large payloads
  refactor(db): extract connection pooling logic
  docs(readme): update installation instructions
```

Valid kinds: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `ci`, `style`, `perf`, `build`, `revert`

The scope is optional. Both branch and commit conventions are customizable via `devline.local.md`.

### Pipeline Artifacts

The `.devline/` directory stores pipeline working files:

| File | Purpose |
|------|---------|
| `.devline/plan.md` | Full implementation plan (written by planner, read by implementers) |

These files are **never committed** — the security hooks block staging anything under `.devline/`. Add `.devline/` to your `.gitignore`.

## Configuration

Create `.claude/devline.local.md` in your project to customize behavior. Run `/devline:setup` to generate this file with all available settings.

```markdown
---
# === Approval Gates ===

# By default, the pipeline stops after brainstorming and after planning
# to wait for your explicit approval before proceeding.
# Set to true to skip the approval gate and proceed automatically.
auto_approve_brainstorm: false
auto_approve_plan: false

# === Framework Detection Overrides ===

# Test framework (default: auto-detect)
test_framework: "vitest"

# Frontend framework (default: auto-detect)
frontend_framework: "react"

# Documentation format (default: auto-detect)
doc_format: "markdown"

# Cloud provider (default: auto-detect)
cloud_provider: "aws"

# === PR Review ===

# Strictness: block_all | block_critical_warn_minor | custom
pr_review_strictness: "block_all"

# Custom categories (when strictness is "custom")
# pr_review_block_categories: ["security", "credentials", "quality"]
# pr_review_warn_categories: ["conventions", "debt"]

# === Git Conventions ===

# Branch naming convention (default: kind/descriptive-title)
# branch_prefix: "{kind}/{title}"

# Commit message format — human-readable description (shown in error messages)
# commit_format: "kind(scope): details"

# Commit message regex — used for validation (default: conventional commits)
# commit_format_regex: "^(feat|fix|refactor|docs|chore|test|ci|style|perf|build|revert)(\\([a-zA-Z0-9._-]+\\))?: .+"

# Protected branches — regex group (default: main, master, develop, release, production, staging)
# protected_branches: "(main|master|develop|release|production|staging)"

# Merge style for protected branches: squash (default), merge, rebase
# merge_style: "squash"

# File extensions allowed to be edited directly on protected branches
# direct_edit_extensions: "(md|txt|json|yaml|yml|toml|ini|cfg|conf|lock|gitignore|gitattributes|editorconfig|prettierrc|eslintrc|stylelintrc)"

# === Dependency Management (shared defaults for CVE patcher, EOL fixer, etc.) ===

# Branch strategy: "main" = commit to default branch (default), "branch" = create a branch per update
# dep_branch_strategy: "main"

# Auto-push after successful verification (default: true)
# dep_auto_push: true

# Auto-commit after successful verification (default: true)
# dep_auto_commit: true

# Run build verification before committing (default: true)
# dep_verify_build: true

# Run test suite before committing (default: true)
# dep_verify_tests: true

# === CVE Patcher (overrides dep_* defaults for CVE-specific runs) ===
# cve_branch_strategy: "main"
# cve_auto_push: true
# cve_auto_commit: true
# cve_verify_build: true
# cve_verify_tests: true

# === Migrate (overrides dep_* defaults for migration runs) ===
# migrate_branch_strategy: "branch"    # Default is "branch" for migrations (safer for large changes)
# migrate_auto_push: true
# migrate_auto_commit: true
# Note: build and test verification is always on for migrations — cannot be disabled
---
```

**Override examples:**

Jira ticket prefix convention:
```markdown
---
branch_prefix: "PROJ-{ticket}/{title}"
commit_format: "PROJ-123: description"
commit_format_regex: "^[A-Z]+-[0-9]+: .+"
---
```

Emoji commit convention:
```markdown
---
commit_format: "emoji description (e.g., ✨ add feature)"
commit_format_regex: "^(✨|🐛|♻️|📝|🔧|✅|🔨|🚀|⬆️|⏪) .+"
---
```

After creating or editing settings, restart Claude Code for changes to take effect.

## Security Hooks

Devline includes strict security hooks for bypass permissions mode. All hooks run as PreToolUse checks — commands are blocked before execution.

Rules are either **deny** (hard block, cannot proceed) or **ask** (prompts for user confirmation in bypass mode).

### Destructive Filesystem Protection (deny)

| Rule | What it blocks |
|------|---------------|
| System paths | `rm -rf /`, `/home`, `/etc`, `/usr`, `/var`, `/sys`, `/boot`, `/proc`, `/opt`, `/lib`, `/bin`, `/sbin`, `~` |
| Outside working dir | `rm -rf` targeting any path outside the current working directory |
| Non-git directories | `rm -rf` in directories not protected by git |
| Wildcards | `rm -rf *`, `rm -rf ..`, `rm -rf /*` |
| Disk operations | `mkfs`, `fdisk`, `dd of=/dev/` |

### Git Destructive Operations (deny)

| Rule | What it blocks |
|------|---------------|
| Force push | `git push --force`, `--force-with-lease`, `-f` |
| Hard reset | `git reset --hard` |
| Force clean | `git clean -f` |
| Force checkout | `git checkout --force` |
| Stash destruction | `git stash drop`, `git stash clear` |

`git branch -D` on non-protected branches triggers **ask** (needed for squash-merged branches where `-d` fails). On protected branches it's a hard **deny**.

### Protected Branch Operations

Operations on protected branches (main, master, develop, release, production, staging). The behavior varies — some are hard blocks, others prompt for confirmation:

| Rule | Behavior | Details |
|------|----------|---------|
| Push | deny | Any push to protected branches (even non-force) |
| Commit | ask | Direct commits while on a protected branch |
| Merge into | depends | Controlled by `merge_style` setting (see below) |
| Rebase | deny | `git rebase` while on a protected branch |
| Force create | deny | `git checkout -B main` |
| Delete | deny | `git branch -d main`, `git branch -D main` |
| Write/Edit | deny | Source code writes only — docs, configs, and dotfiles are allowed (see below) |

**Merge style enforcement** (configurable via `merge_style` in `devline.local.md`):

| Style | Allowed command | Other merge commands |
|-------|----------------|---------------------|
| `squash` (default) | `git merge --squash` (ask) | deny |
| `merge` | `git merge --no-ff` (ask) | deny |
| `rebase` | None (rebase the feature branch, then fast-forward) | deny |

**Write/Edit on protected branches** — only source code files are blocked. These are allowed directly:
- Extensions: `md`, `txt`, `json`, `yaml`, `yml`, `toml`, `ini`, `cfg`, `conf`, `lock`, `gitignore`, `gitattributes`, `editorconfig`, `prettierrc`, `eslintrc`, `stylelintrc` (customizable via `direct_edit_extensions`)
- Filenames: `README`, `LICENSE`, `CHANGELOG`, `CONTRIBUTING`, `CODE_OF_CONDUCT`, `SECURITY`, `CLAUDE`, `Makefile`, `Dockerfile`, `Procfile`, `Brewfile`
- Root dotfiles (except `.env`)

### Pipeline Artifact Protection (deny)

| Rule | What it blocks |
|------|---------------|
| Staging `.devline/` | `git add .devline/plan.md`, `git add .devline/` |

### Publishing and Releases (deny)

| Rule | What it blocks |
|------|---------------|
| Package publishing | `npm publish`, `cargo publish`, `twine upload`, `gem push`, `dotnet nuget push`, `mvn deploy`, `gradle publish` |
| Container push | `docker push`, `podman push`, `buildah push` |
| Git tags | `git tag` |
| GitHub releases | `gh release create` |

### GitHub Mutations (deny)

| Rule | What it blocks |
|------|---------------|
| PR state changes | `gh pr merge`, `gh pr close`, `gh pr reopen` |
| Issue mutations | `gh issue close`, `gh issue delete`, `gh issue comment` |

### Database Destructive Operations (deny)

| Rule | What it blocks |
|------|---------------|
| Schema destruction | `DROP TABLE`, `DROP DATABASE`, `DROP SCHEMA`, `DROP INDEX`, `DROP VIEW` |
| Data destruction | `TRUNCATE TABLE`, bulk `DELETE FROM` |

### External Mutations (ask)

| Rule | What it prompts for |
|------|---------------------|
| HTTP mutations | `curl -X POST/PUT/DELETE/PATCH` to non-localhost URLs |
| Remote access | `ssh`, `scp` to non-localhost hosts |

Service control (`systemctl start/stop/restart/enable/disable`) is a hard **deny**.

### Credential & Secret Protection (deny)

| Rule | What it blocks |
|------|---------------|
| Pipe to shell | `curl \| bash`, `wget \| sh` |
| Print secrets | `echo $API_KEY`, `printf $SECRET_TOKEN` |
| Exfiltrate secrets | `curl -d $TOKEN` to external URLs |
| Hardcoded AWS keys | `AKIA...` patterns in file writes |
| Private keys | `-----BEGIN PRIVATE KEY-----` in file writes |
| API tokens | Hardcoded `api_key=`, `secret_key=` in file writes |
| Passwords | Hardcoded `password=` assignments (allows test/example values) |
| GitHub/GitLab tokens | `ghp_`, `gho_`, `glpat-` patterns |
| JWTs | `eyJ...` token patterns in file writes |
| Env file secrets | Writing real secrets to `.env` files |
| System files | Writing to `/etc/`, `/sys/`, `/proc/`, shell profiles |
| SSH config | Modifying `.ssh/config`, `authorized_keys` |

### System Protection (deny)

| Rule | What it blocks |
|------|---------------|
| Kill init | `kill -9 1` |
| World-writable | `chmod 777` |
| SSH keys | Modifying `authorized_keys` |
| Command injection | `;rm` patterns, dangerous backtick substitution |

### Commit Message Validation

Commit messages are validated against the conventional commits format by default, or against a custom regex specified in `.claude/devline.local.md`. Heredoc-style commits (used by Claude Code's `Co-Authored-By` pattern) are allowed through since they can't be reliably parsed.

### Frontend Auto-Detection

When any implementer modifies UI files (detected via PostToolUse hook), the frontend-reviewer agent is triggered automatically for accessibility and quality checks.

## Architecture

### Invocation Rules

No agent is ever invoked randomly. All invocation flows through either the `/devline` pipeline or an explicit skill command. Two exceptions allow auto-invocation by the model:

- **implement** — fires automatically when the user makes a precise implementation request with defined scope
- **debug** — fires automatically when the user describes a bug, error, or unexpected behavior

All other launcher skills require explicit invocation (`/devline:plan`, `/devline:review`, `/devline:deep-review`).

### Skills — Launcher Skills (start agents)

These skills are user-facing entry points. They contain no domain logic — only instructions on which agent to launch and how to determine scope.

| Skill | Command | Agent | Auto-invoke? |
|-------|---------|-------|-------------|
| `devline` | `/devline` | orchestrates all | No |
| `plan` | `/devline:plan` | planner | No |
| `implement` | `/devline:implement` | implementer(s) | Yes — precise requests |
| `review` | `/devline:review` | reviewer | No |
| `debug` | `/devline:debug` | debugger | Yes — bug reports |
| `deep-review` | `/devline:deep-review` | deep-review | No |

### Skills — Domain Logic (`dl-*`, injected into agents)

These are never invoked directly. They provide methodology and domain knowledge to agents via the `skills:` field in agent frontmatter.

| Skill | Injected into | Purpose |
|-------|--------------|---------|
| `dl-tdd-workflow` | planner, implementer | TDD methodology (red/green/refactor) |
| `dl-frontend-dev` | planner, implementer, frontend-reviewer | UI/UX design, aesthetics, anti-AI-slop |
| `dl-debugging` | debugger | Scientific debugging process |
| `dl-documentation` | docs-keeper | Doc creation and maintenance |
| `dl-cloud-infra` | devops | Cloud-native dev, IaC, CI/CD, containers |
| `dl-dependency-management` | dependency-patcher, dependency-migrator | Ecosystem detection, update mechanics, verification, commit workflow |
| `dl-dependency-migration` | dependency-migrator | Migration guide research, migration tool catalog, code refactoring methodology |

### Skills — Standalone

| Skill | Command | Purpose |
|-------|---------|---------|
| `brainstorm` | `/devline:brainstorm` | Interactive idea refinement (runs in main context, no agent) |
| `setup` | `/devline:setup` | Initialize CLAUDE.md with clarification protocol |
| `cve-patcher` | `/devline:cve-patcher` | CVE research + orchestration, launches dependency-patcher agents |
| `migrate` | `/devline:migrate` | Migration research + orchestration, launches dependency-migrator agents |

### Agents

Agents are never invoked directly by the model — they are launched by skills or the pipeline. All agents except the planner run in the background with `bypassPermissions: true`. The planner runs in the foreground because it asks the user design questions interactively.

| Agent | Model | Background | Bypass | Domain Skills | Launched by |
|-------|-------|-----------|--------|---------------|-------------|
| planner | opus | No | No | dl-tdd-workflow, dl-frontend-dev | devline, plan |
| implementer | sonnet | Yes | Yes | dl-tdd-workflow, dl-frontend-dev | devline, implement |
| devops | sonnet | Yes | Yes | dl-cloud-infra | devline, implement |
| reviewer | sonnet | Yes | Yes | — | devline, review |
| debugger | opus | Yes | Yes | dl-debugging | devline, debug |
| deep-review | opus | Yes | Yes | — | devline, deep-review |
| frontend-reviewer | sonnet | Yes | Yes | dl-frontend-dev | PostToolUse hook (auto) |
| docs-keeper | inherit | Yes | Yes | dl-documentation | devline |
| dependency-patcher | sonnet | Yes | Yes | dl-dependency-management | cve-patcher |
| dependency-migrator | opus | Yes | Yes | dl-dependency-management, dl-dependency-migration | migrate |

## Installation

```bash
# Install from marketplace
claude plugin add devline

# Or install from a local directory
claude plugin add /path/to/devline
```

## Requirements

- Claude Code with plugin support
- `jq` for hook scripts
- Git for version control and branch enforcement

## Usage Guide

### Getting Started

1. **Run `/devline:setup`** in your project to generate a CLAUDE.md with the clarification protocol. This teaches agents to stop and ask when something is unclear instead of guessing.

2. **Start with `/devline <your idea>`** for a full pipeline run. Describe what you want in plain language — the brainstormer will ask clarifying questions, then hand off to planning and autonomous implementation.

3. **Use individual commands** when you only need part of the pipeline: `/devline:review` after manual edits, `/devline:debug` for a stubborn bug, `/devline:deep-review` before merging.

### Effective Development Workflow

**Let the pipeline run autonomously.** After brainstorming and approving the plan, stages 3-6 run in the background without intervention. You can keep working or watch progress via the task list.

**Review the plan before approving.** The planner writes a full plan to `.devline/plan.md`. Read it — the plan drives everything downstream. Push back on design decisions here, not during implementation.

**Answer design questions thoughtfully.** The planner returns structured questions with recommendations and alternatives. Your answers shape the architecture. When unsure, go with the recommendation.

**Use `/devline:implement` for small, well-defined tasks.** Skip brainstorming and planning when you already know exactly what needs to happen — e.g., "add input validation to the registration form using zod."

**Use `/devline:debug` for bugs, not manual debugging.** The debugger follows a systematic scientific method (reproduce → hypothesize → test → fix) that catches root causes instead of papering over symptoms.

### Context Management

Context is your most valuable resource. A full 200k window degrades Claude's performance as it fills up. Manage it actively.

**`/clear` between unrelated tasks.** This is the single most impactful habit. Switching from auth work to CSS fixes? Clear first. Stale context causes more mistakes than missing context.

**`/compact` mid-task when context grows.** Use it around 70% capacity. Pass focus instructions to preserve what matters:
```
/compact Focus on the API endpoint changes and test failures
```

**Don't fight — restart.** If Claude has been corrected twice on the same issue, the context is polluted with failed approaches. `/clear` and rewrite a better prompt incorporating what you learned.

**Document and clear for long sessions.** On large features spanning many files, have Claude write progress to a scratch file, `/clear`, then resume from the documented state. This keeps context fresh without losing progress.

### CLAUDE.md Best Practices

Your CLAUDE.md is injected into every conversation. Keep it lean — every line costs tokens.

**Include only what Claude can't figure out by reading code:**
- Build/test/lint commands (`npm run test:unit`, `pytest -x`)
- Non-obvious conventions (naming patterns, file organization rules)
- Architectural decisions that differ from common patterns
- Environment setup (required env vars, local services)
- Common gotchas specific to your codebase

**Do not include:**
- Standard language conventions Claude already knows
- File-by-file codebase descriptions (Claude can read the code)
- Rules enforceable by linters — never send an LLM to do a linter's job
- Information that changes frequently

**Keep it under 100 lines.** If you need more, use progressive disclosure — reference separate docs:
```markdown
For database schema details: see docs/schema.md
For deployment: see docs/deploy.md
```

**Maintain it as a living document.** When Claude makes a wrong assumption, add the correction to CLAUDE.md so no agent makes the same mistake again. The `/devline:setup` clarification protocol automates this — agents will prompt you to add non-obvious context when they encounter surprises.

### MCP Servers

Devline works out of the box without any MCP servers. If you want to add them, keep the list short — each server adds tool descriptions to every conversation.

**Recommended:**

| Server | Why | Install |
|--------|-----|---------|
| **Context7** | Real-time library docs — the planner and implementer use it to research APIs and best practices | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` |

**Optional:**

| Server | Why | Install |
|--------|-----|---------|
| **GitHub** | Manage PRs, issues, and CI checks without leaving Claude | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |

Avoid adding more than 2-3 MCP servers. Claude Code's tool search feature lazy-loads tool schemas, but each server still adds baseline overhead. If you're building a web frontend, consider Playwright MCP for E2E testing — but add it per-project, not globally.

### Tips for Effective Use

**Give Claude verification.** The highest-leverage thing you can do is give Claude a way to check its own work. Tests are ideal — devline's TDD approach handles this by default. For UI work, provide screenshots or mockups.

**Match thinking depth to problem difficulty.** Add "think hard" or "ultrathink" to your prompt for complex architectural decisions. Don't waste reasoning budget on simple tasks.

**Use subagents for investigation.** When you need to understand how something works before changing it, ask Claude to investigate via a subagent. This keeps your main context clean:
```
Use a subagent to investigate how our payment system handles refunds
and what error codes the Stripe webhook returns.
```

**Create shell aliases for speed:**
```bash
alias c="claude"
alias cc="claude --continue"
alias cr="claude --resume"
```

**Use `--continue` and `--resume` for persistent work.** `claude --continue` picks up your most recent conversation. `claude --resume` lets you choose from recent sessions — treat them like branches for different workstreams.

**Escape early, not late.** Press `Esc` the moment Claude goes in the wrong direction. Press `Esc Esc` to rewind to a checkpoint. Letting Claude finish a wrong approach wastes context and often makes correction harder.

### Bypass Permissions Mode

Devline is designed for `--dangerously-skip-permissions` mode. The security hooks provide guardrails — branch protection, credential scanning, destructive command blocking — so agents can work autonomously without approval prompts slowing them down.

**Before enabling bypass mode:**
1. Run `/devline:setup` to create CLAUDE.md with the clarification protocol
2. Verify the hooks are installed (`ls .claude-plugin/hooks/`)
3. Review the [Security Hooks](#security-hooks) section to understand what's protected
4. Use a sandboxed environment for maximum safety

**In bypass mode, the hooks are your safety net.** They block force pushes, hard resets, credential leaks, writes to protected branches, and staging of pipeline artifacts. This is strict by design — the agents run with full autonomy, so the guards must be absolute.

## License

MIT
