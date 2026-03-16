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
```

---

## Section 4 — Learning & Recovery

```
## Learning & Recovery

When any of the following happens:
- The user corrects you
- You hit a problem you cannot solve on your own
- The reviewer finds significant issues

Follow this process:

1. **Stop and analyze.** Identify the root cause — not just the symptom. What went wrong, and why?
2. **Assess scope.** Is this a one-off mistake, or a pattern that could affect other work in this project?
3. **Extract the lesson.** If it applies broadly, formulate it as: pattern (what triggers it), reason (why it happens), solution (how to prevent it).
4. **Ask to persist.** Use AskUserQuestion to present the lesson and ask whether to add it to the Lessons and Memory section below, edit it first, or discard it.
5. **Never repeat it.** Review existing lessons before starting work. If a lesson already covers the situation, follow it.
```

---

## Section 5 — Project Context (user fills in)

```
## Project Context

<!-- Add non-obvious context here. Examples: -->
<!-- - Build/test/lint commands if non-standard -->
<!-- - Naming conventions not enforceable by linters -->
<!-- - Architectural decisions that differ from common patterns -->
<!-- - Required environment variables or local services -->
<!-- - Common gotchas specific to this codebase -->
```

---

## Section 6 — Lessons and Memory (empty placeholder)

```
## Lessons and Memory

<!-- Lessons are added here automatically via the Learning & Recovery process above. -->
<!-- Format: **Pattern**: ... | **Reason**: ... | **Solution**: ... -->
```
