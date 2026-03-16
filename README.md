# devline

A Claude Code plugin that runs your entire development lifecycle — from rough idea to merge-ready code. Brainstorm interactively, generate design systems from a curated database, plan with TDD, implement in parallel, review in depth, and pass a final security audit. All with strict safety hooks so you can run in bypass permissions mode.

## What It Does

```
"Add a real-time analytics dashboard with WebSocket updates"
        │
  Brainstorm ─── clarifying questions, writes feature spec
        │
  Design System ─── searches 67 styles, 161 palettes, 57 font pairings
        │              (only if UI is involved)
  Plan ─── TDD architecture, parallel tasks, file isolation
        │
  ══ You approve here ══
        │
  Implement ─── parallel agents, strict TDD, auto-review loop
        │
  Documentation ─── updates README, API docs, architecture docs
        │
  Deep Review ─── security audit, regression check, plan compliance
        │
  Done ─── commit, merge, or iterate
```

Every finding from every review gets fixed — there is no "pass with warnings." If an implementer can't fix it after two attempts, the planner rewrites the approach.

## Install

```bash
claude plugin add devline
```

Requires Claude Code with plugin support, `jq`, and `git`.

Run `/devline:setup` in your project to create a CLAUDE.md and configure pipeline settings interactively.

## Commands

| Command | What it does |
|---------|-------------|
| `/devline <idea>` | Full pipeline — brainstorm through deep review |
| `/devline:brainstorm <idea>` | Refine an idea into a feature spec |
| `/devline:plan <spec>` | Create a TDD implementation plan |
| `/devline:implement` | Implement tasks from an existing plan |
| `/devline:review` | In-depth code review |
| `/devline:debug <error>` | Systematic root cause analysis |
| `/devline:deep-review` | Final merge-readiness audit |
| `/devline:cve-patcher <CVEs>` | Patch vulnerabilities across repos |
| `/devline:migrate <package>` | Major version migrations with breaking changes |
| `/writing` | Humanize text, draft content, translate |
| `/brand` | Brand voice, visual identity, messaging |
| `/graphic-design` | Logos, icons, banners, slides, CIP |

## Pipeline Stages

### Stage 0: Branch Setup
Reads your branching config, creates a feature branch if you're on a protected branch, sets up `.devline/` directory.

### Stage 1: Brainstorm (interactive)
Focuses on the **what** and **architecture** — not implementation details. Asks 0-4 structured questions with selectable options, then writes `.devline/brainstorm.md` capturing scope, architecture impact, UI impact, and key decisions.

### Stage 1.5: Design System (interactive, conditional)
Runs only when the brainstorm identifies UI impact. The frontend-planner searches a curated design intelligence database (67 visual styles, 161 color palettes, 57 font pairings, 161 industry-specific rules) using BM25 ranking. Checks for existing design systems in your project. May ask design questions relayed through the orchestrator. Writes `.devline/design-system.md`.

### Stage 2: Plan (interactive)
The planner reads the brainstorm spec and design system (if present), analyzes your codebase at execution-path depth, and produces a full TDD plan with:
- Parallel tasks with file-based isolation (no merge conflicts)
- Explicit dependency graph for execution ordering
- Feature-goal tests that prove the feature works end-to-end
- Proactive improvements for every file being touched
- Integration contracts (observer notifications, lifecycle hooks, state propagation)

Writes `.devline/plan.md` — the single source of truth for all implementation.

### Stage 3: Implement + Review (autonomous, parallel)
One agent per task, strict TDD (red → green → refactor). After each task, a reviewer checks for correctness, security, and performance.

**Escalation ladder:** implementer (2 attempts) → planner rewrites the approach → user guidance.

### Stage 4: Documentation (autonomous)
Updates README, API docs, and architecture docs to match the new code.

### Stage 5: Deep Review (autonomous, final gate)
Security audit, credential scanning, regression check (full test suite), feature-goal verification (end-to-end trace), plan compliance, and code quality assessment.

**Minor findings** → implementer fixes, reviewer verifies, done.
**Major findings** → implementer → debugger (root cause analysis) → planner (new approach) → restart implementation.

## Agents

| Agent | Model | Role |
|-------|-------|------|
| planner | Opus | Architecture, TDD task design, dependency graphs |
| frontend-planner | Sonnet | Design system generation from curated database |
| implementer | Sonnet | TDD implementation (test-first, one task at a time) |
| devops | Sonnet | Build systems, CI/CD, Docker, infrastructure |
| reviewer | Sonnet | Correctness, security, performance review |
| deep-review | Opus | Final gate — security audit, regression check, plan compliance |
| debugger | Opus | Scientific debugging (reproduce → hypothesize → test → fix) |
| docs-keeper | Inherit | README, API docs, architecture docs |
| dependency-patcher | Sonnet | CVE patches and version bumps |
| dependency-migrator | Opus | Complex migrations with breaking changes |

All agents except the planner and frontend-planner run in the background. All agents in bypass mode are protected by security hooks.

## Design Intelligence

The frontend-planner searches a curated CSV database using BM25 ranking:

| Domain | Records | Examples |
|--------|---------|---------|
| Visual styles | 67 | Glassmorphism, brutalism, neomorphism, material design... |
| Color palettes | 161 | Industry-matched with mood, contrast ratios, dark mode variants |
| Font pairings | 57 | Google Fonts with mood, weights, CSS imports |
| Industry rules | 161 | SaaS, fintech, healthcare, e-commerce — anti-patterns included |
| UX guidelines | Per stack | React, Vue, Flutter, SwiftUI, Jetpack Compose... |

The output is a complete design system document with color palette (semantic roles), typography, animation timing, anti-patterns, accessibility checklist, and stack-specific guidelines.

## Security Hooks

Devline ships with PreToolUse hooks that block dangerous operations before they execute. Designed for `--dangerously-skip-permissions` mode — agents work autonomously while hooks enforce safety.

**What's blocked (85+ rules):**

| Category | Examples |
|----------|---------|
| Destructive filesystem | `rm -rf /`, paths outside working dir, non-git directories |
| Git destructive | Force push, hard reset, force clean, stash drop |
| Protected branches | Push, rebase, delete, force create, source code writes |
| Publishing | `npm publish`, `docker push`, `git tag`, `gh release create` |
| GitHub mutations | `gh pr merge`, `gh pr close`, `gh issue close` |
| Database | `DROP TABLE`, `TRUNCATE`, bulk `DELETE FROM` |
| Credentials | Hardcoded API keys, private keys, JWTs, AWS keys, GitHub tokens |
| External mutations | HTTP POST/PUT/DELETE to non-localhost, SSH, service control |
| Commit format | Conventional commits validation (customizable) |

Protected branches default to: main, master, develop, release, production, staging. Docs and config files can still be edited directly on protected branches.

## Configuration

Create `.claude/devline.local.md` with YAML frontmatter to customize behavior. Run `/devline:setup` for interactive guided setup. All settings are optional.

### Quick Examples

**Auto-approve everything:**
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

### All Settings

<details>
<summary>Approval gates</summary>

| Setting | Default | Description |
|---------|---------|-------------|
| `auto_approve_brainstorm` | `false` | Skip approval after brainstorming |
| `auto_approve_plan` | `false` | Skip approval after planning |

</details>

<details>
<summary>Branching strategy</summary>

| Setting | Default | Description |
|---------|---------|-------------|
| `branch_format` | `"{kind}/{title}"` | Branch naming format (`{kind}`, `{title}` placeholders) |
| `branch_kinds` | `"feat\|fix\|refactor\|docs\|chore\|test\|ci"` | Allowed branch kinds |
| `protected_branches` | `"(main\|master\|develop\|release\|production\|staging)"` | Protected branches (regex) |
| `merge_style` | `"squash"` | Merge into protected: `squash`, `merge`, or `rebase` |
| `direct_edit_extensions` | `"(md\|txt\|json\|yaml\|...)"` | Extensions allowed on protected branches |

</details>

<details>
<summary>Commit conventions</summary>

| Setting | Default | Description |
|---------|---------|-------------|
| `commit_format` | `"kind(scope): details"` | Human-readable format (shown in errors) |
| `commit_format_regex` | `"^(feat\|fix\|...)(\(scope\))?: .+"` | Regex for commit validation |

</details>

<details>
<summary>Framework overrides</summary>

| Setting | Default | Description |
|---------|---------|-------------|
| `test_framework` | auto-detect | e.g., `"vitest"`, `"jest"`, `"pytest"` |
| `frontend_framework` | auto-detect | e.g., `"react"`, `"vue"`, `"svelte"` |
| `doc_format` | auto-detect | e.g., `"markdown"`, `"asciidoc"` |
| `cloud_provider` | auto-detect | e.g., `"aws"`, `"gcp"`, `"azure"` |

</details>

<details>
<summary>Dependency management</summary>

| Setting | Default | Description |
|---------|---------|-------------|
| `dep_branch_strategy` | `"main"` | `"main"` = commit to default branch, `"branch"` = per-update branch |
| `dep_auto_push` | `true` | Push after verification |
| `dep_auto_commit` | `true` | Commit after verification |
| `dep_verify_build` | `true` | Run build check |
| `dep_verify_tests` | `true` | Run test suite |

CVE patcher uses `cve_` prefix, migrate uses `migrate_` prefix (same keys, independent overrides).

</details>

## Pipeline Artifacts

The `.devline/` directory stores working files during pipeline execution:

| File | Written by | Read by |
|------|-----------|---------|
| `brainstorm.md` | Brainstorm stage | Frontend-planner, planner |
| `design-system.md` | Frontend-planner | Planner, implementers |
| `plan.md` | Planner | All implementation agents |

These files are **never committed** — hooks block staging anything under `.devline/`. All three are deleted when the pipeline completes (exit, commit, or merge).

## Documentation Lookup

Agents use [Context7](https://context7.com) via `npx ctx7@latest` to fetch up-to-date library docs at planning and implementation time. No MCP server needed.

For higher rate limits, set `CONTEXT7_API_KEY` in your shell profile or run `npx -y ctx7@latest login`.

## Tips

- **Review the plan before approving** — it drives everything downstream. Push back here, not during implementation.
- **`/clear` between unrelated tasks** — stale context causes more mistakes than missing context.
- **`/compact` at ~70% context** — pass focus instructions: `/compact Focus on the API changes`.
- **Use `/devline:implement` for well-defined tasks** — skip brainstorming when you already know exactly what to build.
- **Use `/devline:debug` instead of manual debugging** — the scientific method catches root causes, not symptoms.
- **Add "think hard" for complex decisions** — matches reasoning depth to problem difficulty.

## License

MIT
