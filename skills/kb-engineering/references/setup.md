# Setting up a project's verification

Read by `/devline:verify-setup`. The goal is a verification recipe that fits this project, not one imposed harness. Every part is an offer: propose, explain why and what it costs, and write only what the user picks.

## Native mechanism (Claude Code 2.1.286 and later)

- A project skill named `verify` at `.claude/skills/verify/SKILL.md` replaces the bundled `/verify`, is committed with the project, and is followed by other agents.
- When a session starts with that skill present, Claude Code is told to run it right before each commit. Docs-only and tests-only commits are excepted.
- So the recipe's default path must stay fast. Heavy scenarios go in a separate section that runs on request.
- `/run-skill-generator` records launch recipes as `.claude/skills/run-<name>/`. If one exists, reference it from the recipe instead of duplicating the launch steps.
- Check the installed version with `claude --version`. On an older version the file still works as documentation and for `/verify`, but nothing runs it before commits.

## 1. Inventory (report what exists before proposing anything)

- **Stack:** detect it with the stack table in `SKILL.md` and note which checklists apply.
- **Gate:** Makefile or justfile targets, package scripts, Gradle or Maven tasks, pre-commit hooks, and the CI workflows. Note exactly which command CI runs.
- **Existing verification:** `.claude/skills/verify/`, `.claude/skills/run-*/`, the commands section of `CLAUDE.md`, any e2e or harness directory.
- **External dependencies:** database, broker, upstream APIs, GPU, display, audio, keyring. Each one needs a fake, a container or a sandbox in the proposal.
- **Tools present:** list what is installed and what is missing. Name missing system packages for the user; never install them.

## 2. Proposal menu

Offer only parts that fit the findings. Give each a recommendation, the reason and the cost (time per run, new files, new tools).

1. **One gate command** that CI runs verbatim: lint, typecheck, tests in shuffled order with the seed printed, race detector or sanitizers where the stack has them, build. Cost: low. Almost always worth it.
2. **A sandboxed real-app run** for the stack: private HOME, XDG dirs and runtime dir, generated fixtures, started by PID, stopped by PID. Use the stack checklist's "Verify it" section as the starting point. Cost: medium; this is where tests alone miss broken startups.
3. **Fakes for each external dependency** with injectable delay and failure: an in-process fake or a control file the fake re-reads per request (`delay`, `fail`), or toxiproxy for real protocols. Cost: medium; worth it for any dependency that can be slow or down.
4. **What to drive and which screenshots to read** for anything with a UI: the key journeys, the screenshots the agent must open and describe, the input to drive for feel.
5. **Logs to scan** and the failure patterns (error, warning, fatal, the toolkit's own markers). Scan every log the run writes. Allowlist only noise the project cannot fix, one entry per line with a reason.
6. **Budgets recorded from a measured baseline**: peak memory, memory growth, idle CPU, VRAM, startup time, latency, frame gaps. Measure first, then set the limit with headroom; the project owns the number. Offer `helpers/procbudget.py` for process-tree PSS, growth, CPU and VRAM. Cost: medium; skip for tools where no budget matters.
7. **A changed-file to scenario map** when there are several scenarios, so the fast path runs only what the diff can affect. A change to the harness itself runs everything.

## 3. The recipe file

Write `.claude/skills/verify/SKILL.md` from this template, keeping only the parts the user picked. Replace the bracketed text with project-specific commands; no placeholder may remain.

```markdown
---
name: verify
description: Verify changes to [project] by running the real app and its checks. Run before each commit and at branch review.
---

# Verify [project]

## Fast path

Before each commit. Affected checks only, under about 1-2 minutes.

1. [gate command or its fast subset, e.g. lint, typecheck, tests for the changed packages]
2. [sandboxed run of the scenarios the changed files affect, via the changed-file map]
3. [log scan over every log the run wrote]

## Full sweep

On request and at branch review. Everything the fast path skips.

1. [full gate command, the same one CI runs]
2. [every scenario, with budgets]
3. [fault injection: slow, failing and killed dependencies]

## Environment

- Sandbox: [private HOME and XDG dirs, runtime dir, display or compositor, fixtures]. Never the user's live session or config.
- Tools required: [list]. Missing tools are reported, not installed.
- Start processes yourself and stop them by PID.

## What working looks like

- [exit codes, output markers, the screenshots to open and what each should show, budget lines within limits, a clean log scan]

## Known noise

Allowlisted log lines. Each entry needs a reason; remove entries that no longer match.

- [pattern]: [why it cannot be fixed]
```

## 4. CI parity

- The gate and the fast path call the same scripts, so a green recipe means a green CI.
- Put scripts in the project's own script directory (`tools/`, `scripts/`, `bin/`). A copied helper keeps its `SPDX-License-Identifier` header.
- Add the commands to the project's `CLAUDE.md` commands section when it has one.
- When contributing to someone else's project, reuse their scripts and CI. Keep devline-only pieces under `.claude/` and ask before adding files that would land in an upstream PR.

## 5. Hand-over

- Run the fast path once and show the evidence: commands with exit codes, output directory, screenshots read, log-scan result, budget numbers.
- Give the user the exact command to try it and what working looks like.
- Leave all changes uncommitted for the user to review unless told otherwise.
