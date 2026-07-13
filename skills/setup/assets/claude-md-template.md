# CLAUDE.md Template

Each section below is presented independently during setup. The user can keep, modify, or skip each one. Only accepted/modified sections are included in the final file.

---

## Section 1 — Header & Philosophy

```
# CLAUDE.md

This file is the single source of non-obvious project context — things that cannot be figured out from the code, tests, or git history alone. Do not add anything here that is already discoverable or obvious.
```

---

## Section 2 — Workflow Orchestration

```
## Workflow Orchestration

### Pipeline First
- Use `/devline` for any non-trivial task (3+ steps or architectural decisions). It handles brainstorming, planning, parallel implementation, review, and documentation.
- Use `/devline:implement` only for small, well-scoped tasks where the plan is obvious.
- If something goes sideways during implementation, stop and re-plan — do not patch forward.

### Subagent Strategy
- Use subagents liberally to keep the main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents — one task per subagent for focused execution.
```

---

## Section 3 — Core Principles

```
## Core Principles

- **Simplicity First**: Make every change as simple as possible.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Demand Elegance**: For non-trivial changes, pause and ask "is there a more elegant way?" If a fix feels hacky, implement the elegant solution. Skip this for simple, obvious fixes — don't over-engineer.
- **Minimize Output Noise**: When running commands that may produce large output (test suites, logs, builds), proactively use `| grep`, `| head`, or flags like `--quiet`/`--failed-only` to filter results. Only run unfiltered if filtered output is insufficient.
```

---

## Section 4 — Project Context (user fills in)

```
## Project Context

<!-- Add non-obvious context here. Examples: -->
<!-- - Build/test/lint commands if non-standard -->
<!-- - Naming conventions not enforceable by linters -->
<!-- - Architectural decisions that differ from common patterns -->
<!-- - Required environment variables or local services -->
<!-- - Common gotchas specific to this codebase -->
```
