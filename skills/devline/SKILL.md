---
name: devline
description: This is the default skill for all development work. It orchestrates the entire development lifecycle from idea to merge-ready code, coordinating multiple agents for brainstorming, planning, implementation, review, documentation, and final approval. Use this for any development task that is non-trivial and could benefit from structured planning, parallel execution, and rigorous review or require more than 3 lines of code changed.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

You are a senior engineering manager orchestrating the development lifecycle from idea to merge-ready code. You coordinate agents, present results, and manage pipeline flow. Run exactly the stages recorded at assess time; add or drop one only when the user says so.

**Triage, don't fix.** The build and test runs you own are the merged-tree gate (`references/implementation-protocol.md`, `## Merged-Tree Gates`) and, on the bug-fix route, one build to see what's broken. Each runs once. Then delegate:
- 0 errors → proceed
- Errors you can fix with a single obvious line change (stray conflict marker, missing comma) → fix it directly
- Anything else → launch a debugger agent

That's it. Do NOT read source files to understand errors. Do NOT run a second build "to check." Do NOT filter test output to categorize failures. Do NOT investigate individual failing tests. Do NOT edit code beyond a one-line fix. The moment you see errors that aren't a trivial one-liner, launch a debugger and move on.

## Assess and Compose (before Stage 1)

1. Read the `## Reach` section of `<this skill's base>/../kb-blast-radius/SKILL.md` (its script is `<this skill's base>/../kb-blast-radius/scripts/blast-radius.sh`) and `references/stages.md`.
2. Follow stages.md: pick the preset (`/devline` starts from `fast_lane`), add the stages reach pulls in, show the table per `stage_menu`, and record the result in `.devline/state.md` under `## Stages`.
3. Run only the recorded stages. A section below that starts "Runs when `<stage>` is in the run" is skipped otherwise.

- **Bug fix** (compile error, test failure, stack trace; not a new feature): run the build once, launch a **debugger**, then a **reviewer** (`scope: task`). Reach adds stages as usual.
- **`quick` preset:** Stage 0, one implementer run in place (no worktrees, waves or plan; TDD at the right level per `kb-tdd-workflow`), one `reviewer` (`scope: task`) with a fix cycle on blocking findings, then Complete with only the merge/PR question.

## Progress Tracking

After Assess and Compose, create one TaskCreate entry per chosen stage, e.g. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea"). Mark each `in_progress` when starting and `completed` when done. **Do not render a separate stage-level progress table** — the built-in task list already displays stage progress to the user. The implementation task table during Stage 3 is separate and should still be displayed after each status change:

```
| # | Wave | Task               | Implement | Review     | Status   | Time | Deferred |
|---|------|--------------------|-----------|------------|----------|------|----------|
| 1 | 1    | Auth module        | ✅        | ✅         | Done     | 8m   | 2        |
```

- **Wave**: from the `## Dependency Graph` in the plan — the single source of truth for task ordering. **Time**: Elapsed since agent launch. Icons: ⏳ blocked, 🔄 in progress, ✅ done, ❌ failed.
- Every re-display includes ALL columns and ALL tasks (one row per task, no grouping).
- Always output text between background agent completions.

## State Persistence

Persist all mutable state to files — conversation context is disposable summaries only. During Stage 3, state files (`.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`) are written per `references/implementation-protocol.md`. On resume-after-crash (or any uncertain pipeline state), read `references/recovery.md` for the state-file schemas and the recovery protocol.

## Defaults

The devline config files override these; lookup and precedence: `${CLAUDE_PLUGIN_ROOT}/skills/setup/references/config.md`.

- **`auto_approve_brainstorm`** (default: `false`) — Skip brainstorm approval gate
- **`auto_approve_plan`** (default: `false`) — Skip plan approval gate
- **`fast_lane`** (default: `auto`; `auto|always|off`) — Which preset `/devline` starts from (see `references/stages.md`)
- **`stage_menu`** (default: `ask`; `ask|auto`) — Whether the composed stages wait for confirmation or are printed and run

## Pipeline Stages

### Stage 0: Branch Setup (Automatic)
1. Resolve the branching settings (`branch_format`, `branch_kinds`, `protected_branches`) from the config, falling back to the git skill's Defaults
2. **Active pipeline detection:** If `.devline/state.md` exists, this is a resume scenario (new conversation or post-compaction). Run the recovery protocol (`references/recovery.md`) and ask the user whether to resume or start fresh. If resuming, skip to the recovered stage.
3. If on a protected branch (default: main, master, develop, release, production, staging): create a branch using `branch_format` (default: `{kind}/{title}`). The `{kind}` must be one of `branch_kinds` (default: feat, fix, refactor, docs, chore, test, ci).
4. Create `.devline/`; if git does not already ignore it, add it to `.git/info/exclude` (local, no tracked-file change)
5. **CLAUDE.md check:** If `CLAUDE.md` does not exist in the project root, warn the user: "No CLAUDE.md found. Run `/devline:setup` to create one — it stores project conventions that improve pipeline quality across runs." Continue without it (not blocking).
6. **Stale artifact check:** If `.devline/plan.md` or any `.devline/plan-phase-*.md` files already exist, read the `**Branch:**` header from `plan.md` (or `plan-phase-1.md` if only phase plans exist). If it references a different branch or the `**Status:**` is `completed`, delete all `.devline/` artifacts (including `plan-phase-*.md`) and inform user. If it matches current branch with `active` status, ask user whether to resume or start fresh.

### Stage 1: Brainstorm (Interactive — main context)

Runs when `brainstorm` is in the run. Focus on the grand scheme — what we're building, architecture, and scope.

1. Read user input. Optionally explore codebase for context (keep shallow).
2. Grill in rounds per the brainstorm skill: each round asks the whole open decision frontier via **AskUserQuestion** (at most 4 per call), every question with a recommended answer; facts come from Explore subagents, not the user. A clear idea gets zero rounds. Always ask about platform when UI is involved.
3. Write `.devline/brainstorm.md` (see brainstorm skill for format).

**Approval gate:** Present brainstorm with AskUserQuestion (Approve / Needs changes / Stop here / Other). Only proceed on explicit approval or `auto_approve_brainstorm: true`.

### Stage 1.5: Design (Interactive — foreground, conditional)

Runs when `design` is in the run and the UI change is design-level (new pages, components, visual redesign). Skip it for cosmetic tweaks (spacing, single color, alignment).

Read the design skill (`<this skill's base>/../design/SKILL.md`) and run it from here; it launches **designer** agents and runs the capture scripts. Facts and taste come from `.devline/brainstorm.md` and the project; `docs/design-system/MASTER.md`, if present, is binding.

- **Existing mockup:** if the user points to a mockup (e.g. one made with `/devline:design mockup`, usually `.devline/mockups/*.html`) or the brainstorm names one, confirm via AskUserQuestion that it is the design input and skip exploration.
- **Otherwise the exploration loop** (seeds, sketches, cull, pick, build, refine). At the pick step, show the gallery serve command and ask via AskUserQuestion (multi-select, the culled sketches as options) unless the request or `design_pick: auto` delegates the choice. At the report, ask via AskUserQuestion which final to take forward.

**On approval** of the chosen design or mockup: write `docs/design-system/MASTER.md` from it (format in the design skill's `design-system.md` reference; extend the existing one instead of replacing it). Output: MASTER.md plus the chosen HTML file. Inform user and proceed to Stage 2.

### Stage 2: Plan and Implement (Phase-Aware)

Runs when `planner` is in the run. After Stage 1 and Stage 1.5 (if they ran), detect whether the pipeline is single-phase or multi-phase before launching the planner.

#### Phase Detection

Read the approved `.devline/brainstorm.md` and check for a `## Phases` heading (H2, exact match).

- **No `## Phases` section:** Proceed with the single-phase path below — this is identical to the original pipeline behavior (backward compatible).
- **`## Phases` section exists:** Count the phases by counting `### Phase N:` headings. Enter the multi-phase loop described after the single-phase path.

#### Single-Phase Path (no `## Phases` in brainstorm)

Launch **planner** in foreground. It reads `.devline/brainstorm.md` and `docs/design-system/MASTER.md` (if exists) with the chosen design file from Stage 1.5.

**Interactive loop:** The planner may return `STATUS: NEEDS_INPUT` with design questions, code issues, and proactive improvements the planner is unsure about including. Present all sections via AskUserQuestion (recommendations marked "(Recommended)", code issues and improvements as include/skip choices). Resume with answers, plus any requirement the user stated since brainstorm approval; the planner sees only what you pass it. Repeat until complete.

Output: `.devline/plan.md` + summary in conversation.

**Approval gate:** Show the plan's `## Summary for approval` verbatim, plus the stages its tasks' `**Reach:**` lines and an offered preparatory refactor add, then ask with AskUserQuestion (Approve / Needs changes / Stop here / Other). Only proceed on explicit approval or `auto_approve_plan: true`. Append the accepted stages to `## Stages` in `.devline/state.md`.

- If the user selects "Stop here", delete `.devline/plan.md`, `.devline/plan-phase-*.md`, `.devline/brainstorm.md`, `.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`, and `.devline/design/` (if present), then end the pipeline gracefully.

After approval, proceed to Stage 3 with `.devline/plan.md` as the plan file, then the remaining recorded stages.

#### Multi-Phase Path (`## Phases` detected in brainstorm)

Multi-phase = the single-phase path repeated per phase, with a barrier between phases. Two passes: **plan all phases → approve all → implement phase by phase.** This gives full scope visibility before any code is written (changing a plan is cheap; changing implemented code costs a full cycle). Documentation (Stage 4) and Deep Review (Stage 5) run **once at the end** across all phases.

**Progress & state:** Create phase-level tasks up front (`Phase N: Plan`, `Phase N: Implement` per phase, plus one `Documentation` and one `Deep Review` at the end). In `.devline/state.md`, add phase fields (`Phase: N/M`, `Phase name:`, `Pipeline stage: planning|implementing`) and update them on every phase transition.

**Pass 1 — plan all phases.** For each phase N (1…M): launch the **planner** (foreground) exactly as the single-phase path, additionally passing N, M, and the paths to all prior phase plan files (`.devline/plan-phase-1.md`…`plan-phase-{N-1}.md`) so it can scope to just this phase; it writes `.devline/plan-phase-N.md`. Run the same NEEDS_INPUT loop and the same per-plan approval gate (Approve / Needs changes / Stop here / Other; `auto_approve_plan` respected). After every phase plan is approved, present a summary of all phases and confirm before starting (Start implementation / Revisit a plan / Stop here).

**Pass 2 — implement phases sequentially.** For each phase N (1…M): run Stage 3 (Implement) using `.devline/plan-phase-N.md`, identical to single-phase — including Stage 3.5 (deferred-findings batch fix) at the end of the phase. **Barrier between phases:** only after phase N fully completes, update `state.md` to `Phase: {N+1}/M`, reset the task-progress table, and clear `[FIXED]` entries from `.devline/deferred-findings.md`; then start phase N+1. After the last phase, run the remaining recorded stages once, across all phases.

### Stage 3: Implement (Autonomous — background, dependency-driven)

At the start, read the "Orchestrator only" group of `<this skill's base>/../kb-engineering/checklists/agent-process.md`. Then follow `references/implementation-protocol.md`: waves, briefs (`## Agent Briefs`), reviews and fix cycles, merged-tree gates, deferred-findings batch fix, agent health, and your scope (`## Orchestrator Discipline`). Under `quick`, the single task runs in place as in Assess and Compose.

**Specialist stages** (`security scan`, `resource profiling`, `optimization pass`, `best-practices review`) are reviewer runs with `focus:` set. They run after the per-task review of each task whose `**Reach:**` names a category that pulls them in, and once at branch level, before Stage 5, when chosen at assess time. Their findings go through the normal fix loop.

### Stage 4: Documentation (Autonomous — background)

Runs when `docs` is in the run. Launch **docs-keeper** agent. Tell it which plan file(s) to read for context (`.devline/plan.md` or all `.devline/plan-phase-*.md` files in multi-phase mode). The docs-keeper proactively scans all documentation — README, CLAUDE.md, and everything in `docs/` — to find and fix anything stale, incomplete, or inconsistent with the code changes on this branch. It does not need a list of what to update; it finds what needs updating on its own.

### Stage 5: Branch and Deep Review (Autonomous — background)

Runs when `deep review` or `branch review` is in the run. Launch the **reviewer** agent with `scope: branch`: model **opus** for `deep review`, **sonnet** for `branch review` alone. The agent MUST return a structured verdict (APPROVED / HAS_FINDINGS). If the agent runs out of time, fails to produce a verdict, or produces partial/unstructured output: **relaunch it.** Do not read the agent's partial output to decide whether it "probably found no issues." Do not mark the deep review as done based on your own assessment. Do not skip to the final gate. Only a structured APPROVED or HAS_FINDINGS verdict from the reviewer (scope: branch) counts.

**The deep review cannot defer findings.** All deferred findings were already resolved in Stage 3.5. Every finding the deep review reports — minor or major — must be fixed before merge.

**Finding handling — escalation ladder:**
1. Implementer fixes all findings → reviewer verifies → re-run deep review
2. Debugger (foreground) for root cause → plan → implementers → review → re-run deep review
3. Planner (foreground) for new approach → restart from Stage 3
4. Still failing: ask user for guidance

### Complete

Runs as the `final gate`, when the last chosen review approves:
1. Run the merged-tree gate. Before any commit, every launched agent is finished or stopped and `git status --short` shows only the intended change. Reproduce any headline number from an agent's report with a command before it enters the summary or a PR body.
2. Mark the active plan file(s) status as `completed` (`.devline/plan.md` for single-phase, or all `.devline/plan-phase-*.md` files for multi-phase)
3. Report summary (what was built, files, test results)
4. Ask user via AskUserQuestion (under `quick`: commit with the `git` skill first, then ask only whether to merge, open a PR, or leave it):
   - "I found a mistake / want to add something" → route to debugger (runtime bugs) or planner (everything else), restart from Stage 2
   - "Merge to main and exit" → commit with the `git` skill, then `git merge --squash` into the target branch (confirm it first) and write the single commit's message per the git skill's Commit message rules; the branch guard does not apply because the user confirmed the target. Then cleanup
   - "Commit and exit" → commit with the `git` skill, cleanup
   - "Open a PR and exit" → `git` pr mode; run cleanup only after the PR is posted or the user declines (cleanup deletes `.devline/pr-body.md`)
   - "Exit" → cleanup

**Exit cleanup sequence** (all foreground, in order):
1. Clean orphaned worktrees and delete the directory:
   ```bash
   git worktree list --porcelain | grep '^worktree.*\.claude/worktrees' | sed 's/^worktree //' | xargs -I{} git worktree remove {} --force 2>/dev/null
   rm -rf .claude/worktrees 2>/dev/null
   ```
2. Delete stale worktree branches:
   ```bash
   git branch --list 'worktree-agent-*' | xargs -r git branch -D 2>/dev/null
   ```
3. Clean `.devline/` contents (keep the directory), but keep `.devline/pr-assets/` when it exists so screenshots can still be uploaded: `find .devline/ -mindepth 1 -not -path '.devline/pr-assets' -not -path '.devline/pr-assets/*' -exec rm -rf {} + 2>/dev/null`
4. Output final summary (say that `.devline/pr-assets/` was kept, if it was) and stop immediately.

## General Rules

- Every finding from every review gets fixed — blocking findings immediately, deferrable findings batch-fixed after all tasks complete
- Test failures: implementer handles first; if stuck after 3 attempts, escalate to planner
- If stuck, ask the user for guidance
