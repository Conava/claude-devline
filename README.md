# devline

Full development lifecycle pipeline for Claude Code. Takes you from rough idea to merge-ready code with brainstorming, TDD planning, parallel implementation, in-depth review, systematic debugging, and documentation — all with strict security hooks and git workflow enforcement for bypass permissions mode.

## Features

- **Brainstorming** — Interactive refinement of rough ideas into concrete feature specs
- **TDD Planning** — Detailed plans written to disk with parallel tasks and file-based isolation
- **Parallel Implementation** — Multiple TDD implementer agents working simultaneously, reading the plan from disk
- **In-Depth Review** — Correctness, security, performance, and quality checks
- **Deep Review** — Final merge gate: security audit, credential scan, convention check, plan compliance
- **Systematic Debugging** — Scientific method: reproduce → hypothesize → test → fix
- **Documentation** — Auto-detect and update separate docs (README, API, architecture)
- **Design Intelligence** — BM25-powered design system generation from 67 styles, 161 palettes, 57 font pairings, 161 industry rules
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
  ├─ Read branching strategy from devline.local.md
  ├─ If on protected branch → create feature branch per configured format
  └─ Create .devline/ directory, ensure .gitignore
        │
  Stage 1: Brainstorm (INTERACTIVE — main context)
  ├─ Quick clarifying questions (1-3 max, or none)
  └─ Output: Concise feature specification
        │
  ══ APPROVAL GATE (configurable) ══
        │
  Stage 1.5: Design System (AUTOMATIC — if UI impact detected)
  ├─ Frontend-planner searches design intelligence database
  ├─ Matches product type → style, colors, typography, anti-patterns
  └─ Writes .devline/design-system.md for planner to consume
        │
  Stage 2: Plan (INTERACTIVE)
  ├─ Reads design system (if generated) as UI constraints
  ├─ Designs architecture, researches libraries (find-docs / ctx7)
  ├─ Creates parallel tasks (file-isolated)
  ├─ Challenges itself, recommends improvements
  ├─ Writes full plan to .devline/plan.md
  └─ Returns concise summary to conversation
        │
  ══ APPROVAL GATE (configurable) ══
        │
  ═══ AUTONOMOUS FROM HERE ═══
        │
  Stage 3: Implement + Review (PARALLEL, per task)
  ├─ Read plan from .devline/plan.md
  ├─ One implementer per task, strict TDD
  ├─ Writes tests first, implements until green
  ├─ Handles inline docs (JSDoc, docstrings)
  ├─ Reviewer runs after each task completes
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

Before any code is written, devline checks the current branch. If on a protected branch (default: main, master, develop, release, production, staging), all Write/Edit operations are blocked until a feature branch is created. Protected branches, branch naming format, and allowed kinds are all customizable via `devline.local.md`.

**Default branch format:** `{kind}/{title}` (customizable via `branch_format`)

**Default branch kinds** (customizable via `branch_kinds`):

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

The scope is optional. The entire branching strategy (naming format, allowed kinds, protected branches) and commit conventions are customizable via `devline.local.md`.

### Pipeline Artifacts

The `.devline/` directory stores pipeline working files:

| File | Purpose |
|------|---------|
| `.devline/plan.md` | Full implementation plan (written by planner, read by implementers) |
| `.devline/design-system.md` | UI design recommendations (written by frontend-planner, read by planner and implementers) |

These files are **never committed** — the security hooks block staging anything under `.devline/`. Add `.devline/` to your `.gitignore`.

## Configuration

Create `.claude/devline.local.md` in your project to customize pipeline behavior. Only include settings you want to change — all settings are optional and have sensible defaults. Run `/devline:setup` for an interactive guided setup.

The file uses YAML frontmatter between `---` delimiters. After creating or editing settings, restart Claude Code for changes to take effect.

### Settings Reference

#### Approval Gates

Control whether the pipeline pauses for your approval between stages.

| Setting | Default | Description |
|---------|---------|-------------|
| `auto_approve_brainstorm` | `false` | Skip approval gate after brainstorming |
| `auto_approve_plan` | `false` | Skip approval gate after planning |

#### Branching Strategy

Customize branch naming, protection rules, and merge behavior.

| Setting | Default | Description |
|---------|---------|-------------|
| `branch_format` | `"{kind}/{title}"` | Branch naming format. Placeholders: `{kind}`, `{title}` |
| `branch_kinds` | `"feat\|fix\|refactor\|docs\|chore\|test\|ci"` | Allowed branch kinds (pipe-separated). Used in branch names and commit prefixes |
| `protected_branches` | `"(main\|master\|develop\|release\|production\|staging)"` | Protected branches as regex group. Write/Edit of source code is blocked on these |
| `merge_style` | `"squash"` | Merge style for protected branches: `squash`, `merge`, or `rebase` |
| `direct_edit_extensions` | `"(md\|txt\|json\|yaml\|yml\|toml\|ini\|cfg\|conf\|lock\|gitignore\|gitattributes\|editorconfig\|prettierrc\|eslintrc\|stylelintrc)"` | File extensions allowed for direct editing on protected branches (regex group) |

#### Commit Conventions

Customize commit message format and validation.

| Setting | Default | Description |
|---------|---------|-------------|
| `commit_format` | `"kind(scope): details"` | Human-readable format description (shown in error messages) |
| `commit_format_regex` | `"^(feat\|fix\|refactor\|docs\|chore\|test\|ci\|style\|perf\|build\|revert)(\\([a-zA-Z0-9._-]+\\))?: .+"` | Regex used for commit message validation |

#### Framework Detection Overrides

Override auto-detection when devline guesses wrong or you want to pin a specific framework.

| Setting | Default | Description |
|---------|---------|-------------|
| `test_framework` | auto-detect | Test framework (e.g., `"vitest"`, `"jest"`, `"pytest"`) |
| `frontend_framework` | auto-detect | Frontend framework (e.g., `"react"`, `"vue"`, `"svelte"`) |
| `doc_format` | auto-detect | Documentation format (e.g., `"markdown"`, `"asciidoc"`) |
| `cloud_provider` | auto-detect | Cloud provider (e.g., `"aws"`, `"gcp"`, `"azure"`) |

#### PR Review

Control how strict the deep review gate is.

| Setting | Default | Description |
|---------|---------|-------------|
| `pr_review_strictness` | `"block_all"` | Strictness level: `block_all`, `block_critical_warn_minor`, or `custom` |
| `pr_review_block_categories` | `["security", "credentials", "quality"]` | Categories that block merge (when strictness is `custom`) |
| `pr_review_warn_categories` | `["conventions", "debt"]` | Categories that warn but don't block (when strictness is `custom`) |

#### Dependency Management

Shared defaults for CVE patcher, EOL fixer, and other dependency tools. Each tool can override these with its own prefixed settings.

| Setting | Default | Description |
|---------|---------|-------------|
| `dep_branch_strategy` | `"main"` | `"main"` = commit to default branch, `"branch"` = create branch per update |
| `dep_auto_push` | `true` | Push automatically after verification |
| `dep_auto_commit` | `true` | Commit automatically after verification |
| `dep_verify_build` | `true` | Run build check before committing |
| `dep_verify_tests` | `true` | Run test suite before committing |

**CVE Patcher overrides** (prefix `cve_` instead of `dep_`): `cve_branch_strategy`, `cve_auto_push`, `cve_auto_commit`, `cve_verify_build`, `cve_verify_tests`. Same defaults as `dep_*`.

**Migrate overrides** (prefix `migrate_` instead of `dep_`): `migrate_branch_strategy` (default: `"branch"`), `migrate_auto_push`, `migrate_auto_commit`. Build and test verification is always on for migrations and cannot be disabled.

### Examples

**Minimal — just auto-approve the pipeline:**
```markdown
---
auto_approve_brainstorm: true
auto_approve_plan: true
---
```

**Jira ticket convention:**
```markdown
---
branch_format: "PROJ-{ticket}/{title}"
branch_kinds: "PROJ"
commit_format: "PROJ-123: description"
commit_format_regex: "^[A-Z]+-[0-9]+: .+"
---
```

**Emoji commits:**
```markdown
---
commit_format: "emoji description (e.g., ✨ add feature)"
commit_format_regex: "^(✨|🐛|♻️|📝|🔧|✅|🔨|🚀|⬆️|⏪) .+"
---
```

**Relaxed review for a prototype:**
```markdown
---
pr_review_strictness: "block_critical_warn_minor"
---
```

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
| `kb-tdd-workflow` | planner, implementer | TDD methodology (red/green/refactor) |
| `kb-design` | frontend-planner | Design intelligence database (BM25 search over 67 styles, 161 palettes, 57 font pairings, 161 industry rules), UI/UX guidelines, aesthetics |
| `kb-debugging` | debugger | Scientific debugging process |
| `kb-documentation` | docs-keeper | Doc creation and maintenance |
| `kb-cloud-infra` | devops | Cloud-native dev, IaC, CI/CD, containers |
| `kb-dependency-management` | dependency-patcher, dependency-migrator | Ecosystem detection, update mechanics, verification, commit workflow |
| `kb-dependency-migration` | dependency-migrator | Migration guide research, migration tool catalog, code refactoring methodology |
| `find-docs` | planner, implementer, devops, reviewer, debugger, deep-review | Up-to-date library docs via Context7 CLI (`npx ctx7@latest`) |

### Skills — Standalone

| Skill | Command | Purpose |
|-------|---------|---------|
| `brainstorm` | `/devline:brainstorm` | Interactive idea refinement (runs in main context, no agent) |
| `setup` | `/devline:setup` | Interactive project setup: CLAUDE.md + minimal settings |
| `cve-patcher` | `/devline:cve-patcher` | CVE research + orchestration, launches dependency-patcher agents |
| `migrate` | `/devline:migrate` | Migration research + orchestration, launches dependency-migrator agents |

### Agents

Agents are never invoked directly by the model — they are launched by skills or the pipeline. All agents except the planner run in the background with `bypassPermissions: true`. The planner runs in the foreground because it asks the user design questions interactively.

| Agent | Model | Background | Bypass | Domain Skills | Launched by |
|-------|-------|-----------|--------|---------------|-------------|
| frontend-planner | sonnet | Yes | Yes | kb-design, find-docs | devline (Stage 1.5, if UI impact) |
| planner | opus | No | No | kb-tdd-workflow, find-docs | devline, plan |
| implementer | sonnet | Yes | Yes | kb-tdd-workflow, find-docs | devline, implement |
| devops | sonnet | Yes | Yes | kb-cloud-infra, find-docs | devline, implement |
| reviewer | sonnet | Yes | Yes | find-docs | devline, review |
| debugger | opus | Yes | Yes | kb-debugging, find-docs | devline, debug |
| deep-review | opus | Yes | Yes | find-docs | devline, deep-review |
| docs-keeper | inherit | Yes | Yes | kb-documentation | devline |
| dependency-patcher | sonnet | Yes | Yes | kb-dependency-management | cve-patcher |
| dependency-migrator | opus | Yes | Yes | kb-dependency-management, kb-dependency-migration | migrate |

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

1. **Run `/devline:setup`** in your project to create a CLAUDE.md with the clarification protocol and interactively configure pipeline settings. Only non-default settings are written — agents stop and ask when something is unclear instead of guessing.

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

### Documentation Lookup (Context7)

Devline includes a built-in `find-docs` skill that uses the [Context7](https://context7.com) CLI to fetch up-to-date library documentation. No MCP server required — agents run `npx ctx7@latest` via Bash.

Works without authentication for basic usage. For higher rate limits, set the `CONTEXT7_API_KEY` environment variable in your shell profile:

```bash
# Add to ~/.zshrc (zsh) or ~/.bashrc (bash)
export CONTEXT7_API_KEY="your_key"
```

Then reload your shell (`source ~/.zshrc` or `source ~/.bashrc`) or restart your terminal.

Alternatively, use OAuth login:

```bash
npx -y ctx7@latest login
```

### MCP Servers

Devline works out of the box without any MCP servers. If you want to add them, keep the list short — each server adds tool descriptions to every conversation.

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
