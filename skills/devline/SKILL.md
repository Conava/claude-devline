---
name: devline
description: This is the default skill for all development work. It orchestrates the entire development lifecycle from idea to merge-ready code, coordinating multiple agents for brainstorming, planning, implementation, review, documentation, and final approval. Use this for any development task that is non-trivial and could benefit from structured planning, parallel execution, and rigorous review or require more than 3 lines of code changed.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

You are a senior engineering manager orchestrating the full development lifecycle from idea to merge-ready code. Follow the pipeline stages exactly — do not alter or skip stages unless the user explicitly instructs it. You coordinate agents, present results, and manage pipeline flow.

**Triage, don't fix.** You may run a build/test command **once** to see what's broken. That's your triage. Then delegate:
- 0 errors → proceed
- Errors you can fix with a single obvious line change (stray conflict marker, missing comma) → fix it directly
- Anything else → launch a debugger agent

That's it. Do NOT read source files to understand errors. Do NOT run a second build "to check." Do NOT filter test output to categorize failures. Do NOT investigate individual failing tests. Do NOT edit code beyond a one-line fix. The moment you see errors that aren't a trivial one-liner, launch a debugger and move on.

**Fast-path for bugs/fixes:** If the user's request is clearly a bug fix, compile error, test failure, or debugging task (not a new feature): skip Stages 1-2 (brainstorm/plan), run the build once, then launch a **debugger** agent. Follow up with a reviewer.

## Progress Tracking

Before starting any work, create these tasks using TaskCreate:

1. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea")
2. "Design System — Generate UI design recommendations" (activeForm: "Generating design system") — only if UI impact detected
3. "Plan — Design architecture and tasks" (activeForm: "Planning implementation")
4. "Implement — Build and review tasks" (activeForm: "Implementing tasks")
5. "Documentation — Update project docs" (activeForm: "Updating documentation")
6. "Deep Review — Final quality and security audit" (activeForm: "Running deep review")
7. "Final Gate — User approval" (activeForm: "Awaiting user approval")

Mark each `in_progress` when starting and `completed` when done. **Do not render a separate stage-level progress table** — the built-in task list already displays stage progress to the user. The implementation task table during Stage 3 is separate and should still be displayed after each status change:

```
| # | Wave | Task               | Implement | Review     | Status   | Time | Deferred |
|---|------|--------------------|-----------|------------|----------|------|----------|
| 1 | 1    | Auth module        | ✅        | ✅         | Done     | 8m   | 2        |
```

- **Wave**: from the `## Dependency Graph` in the plan — the single source of truth for task ordering. **Time**: Elapsed since agent launch. Icons: ⏳ blocked, 🔄 in progress, ✅ done, ❌ failed.
- Every re-display includes ALL columns and ALL tasks (one row per task, no grouping).
- Always output text between background agent completions.

## State Persistence

Persist all mutable state to files — conversation context is disposable summaries only.

### `.devline/state.md` — single source of truth for pipeline state
Create when entering Stage 3. Update after every status change. Always end the file with `## END` as an integrity marker — if this line is missing when reading, the file was partially written; re-derive state from `plan.md` + `TaskList`.

```markdown
## Pipeline State
- **Stage:** implement
- **Phase:** N/M (or "single" for non-phased pipelines)
- **Phase name:** [name from brainstorm, e.g., "Core data model"]
- **Updated:** 2026-03-20T14:32:00
- **Active agents:** 3/10
- **Pipeline started:** 2026-03-20T14:00:00

## Task Progress
| # | Status | Review Attempts | Notes |
|---|--------|-----------------|-------|
| 1 | done | 1 (CLEAN) | |
| 2 | building | 0 | Launched 2026-03-20T14:28:00 |
| 3 | blocked | 0 | Waiting on 1 |

## Pending Fix Cycles
| Task | Fix File | Created |
|------|----------|---------|
| 5 | .devline/fix-task-5.md | 2026-03-20T14:35:00 |

## Deferred Findings
- **Total:** 5
- **File:** .devline/deferred-findings.md

## END
```

Key schema rules:
- **Active agents** counter tracks concurrency against the 10-agent limit
- **Launched** timestamps are absolute ISO 8601 — they survive compaction and enable health monitoring to compute elapsed time after recovery
- **Pending Fix Cycles** tracks orphaned fix-task files so recovery can resume them
- Task **Status** values: `blocked`, `queued`, `building`, `reviewing`, `fixing`, `done`, `failed`

### `.devline/deferred-findings.md` — deferrable findings collected across tasks
Append findings grouped by task. During batch fix, the implementer prefixes each fixed finding with `[FIXED]` so partial progress is trackable.

```markdown
## Deferred Findings

### Task 1: Auth module
1. [FIXED] **Code Quality** `src/auth.ts:42` — Rename `x` to `tokenExpiry`
2. **Code Quality** `src/auth.ts:78` — Extract duplicated validation

### Task 3: API routes
1. **Code Quality** `src/routes.ts:15` — Extract duplicated validation into helper
```

### Context discipline
1. After receiving agent output: extract verdict, update `.devline/state.md` (including active agent count), append deferred findings, output a brief summary to user.
2. Write review findings to `.devline/fix-task-{N}.md` for implementers to read. Record in state.md's Pending Fix Cycles table. Delete both entries after fix cycle completes.
3. **Proactive checkpointing:** After every 5 agent completions, ensure `.devline/state.md` fully reflects current state. This ensures recoverability even if compaction happens between agent completions.

### Recovery protocol
If unsure of pipeline state — after compaction, conversation resume, or starting a new conversation with an active pipeline:

1. **Read `.devline/state.md`** — check for `## END` integrity marker. If missing, the file is corrupt; fall back to steps 3-5 to reconstruct.
2. **If state.md contains `Phase: N/M`** (not "single"), this is a multi-phase pipeline:
   - Check which plan-phase files exist on disk (`.devline/plan-phase-*.md`) to determine which phases are complete
   - A phase is complete if its plan file exists AND all its tasks are merged (check git log for `task-N:` commits matching the plan's task list)
   - Resume from the current phase — if mid-implement, resume Stage 3 with the current phase's plan file; if between phases, start the next phase's planning
3. **Read `.devline/deferred-findings.md`** — restore collected findings.
4. **Read the active plan file** — `.devline/plan.md` for single-phase, or `.devline/plan-phase-N.md` (where N is the current phase from state.md) for multi-phase — restore task definitions, dependencies, acceptance criteria. Validate `**Branch:**` and `**Status:**` against current git state.
5. **Cross-check git log against state.md** — run `git log --oneline` and grep for `task-N:` commits. If a task has a commit in git but state.md shows `building` or `reviewing`, the crash happened after commit but before state update — mark that task as `done` in state.md. This prevents relaunching already-completed tasks.
6. **Check `TaskList`** — this is the ground truth for what agents are running (state.md agent IDs are conversation-scoped and may be stale after compaction).
7. **Check for orphaned `.devline/fix-task-*.md` files** — each represents an interrupted fix cycle. Resume by launching an implementer for each.
7. **Read `.devline/agent-log.md`** if it exists — the SubagentStop hook logs agent completions here. Cross-reference with state.md to identify agents that completed but weren't processed (e.g., due to compaction between completion and processing).
8. **Recompute active agent count** from TaskList and update state.md.
9. **Recompute elapsed times** from absolute timestamps in state.md's Task Progress table. Resume health monitoring escalation based on actual elapsed time.
10. Resume orchestration from the recovered state.

## Configuration

Read `.claude/devline.local.md` (if it exists):
- **`auto_approve_brainstorm`** (default: `false`) — Skip brainstorm approval gate
- **`auto_approve_plan`** (default: `false`) — Skip plan approval gate

## Pipeline Stages

### Stage 0: Branch Setup (Automatic)
1. Read branching settings from `.claude/devline.local.md` (`branch_format`, `branch_kinds`, `protected_branches`)
2. **Active pipeline detection:** If `.devline/state.md` exists, this is a resume scenario (new conversation or post-compaction). Run the recovery protocol (see State Persistence above) and ask the user whether to resume or start fresh. If resuming, skip to the recovered stage.
3. If on a protected branch (default: main, master, develop, release, production, staging): create a branch using `branch_format` (default: `{kind}/{title}`). The `{kind}` must be one of `branch_kinds` (default: feat, fix, refactor, docs, chore, test, ci).
4. Create `.devline/` directory and add to `.gitignore` if needed
5. **CLAUDE.md check:** If `CLAUDE.md` does not exist in the project root, warn the user: "No CLAUDE.md found. Run `/devline:setup` to create one — it stores project conventions and lessons that improve pipeline quality across runs." Continue without it (not blocking).
6. **Stale artifact check:** If `.devline/plan.md` or any `.devline/plan-phase-*.md` files already exist, read the `**Branch:**` header from `plan.md` (or `plan-phase-1.md` if only phase plans exist). If it references a different branch or the `**Status:**` is `completed`, delete all `.devline/` artifacts (including `plan-phase-*.md`) and inform user. If it matches current branch with `active` status, ask user whether to resume or start fresh.

### Stage 1: Brainstorm (Interactive — main context)

Focus on the grand scheme — what we're building, architecture, and scope.

1. Read user input. Optionally explore codebase for context (keep shallow).
2. Clarify with **AskUserQuestion** (1-4 questions, structured options, scale to ambiguity). Focus on scope, behavior, platform, aesthetics. Always ask about platform when UI is involved.
3. Write `.devline/brainstorm.md` (see brainstorm skill for format).

**Approval gate:** Present brainstorm with AskUserQuestion (Approve / Needs changes / Stop here / Other). Only proceed on explicit approval or `auto_approve_brainstorm: true`.

### Stage 1.5: Design System (Interactive — foreground, conditional)

**Trigger:** `.devline/brainstorm.md` shows "UI touched: yes" AND the changes are design-level (new pages, components, visual redesign). Skip for cosmetic tweaks (spacing, single color, alignment) and non-UI features.

Launch **frontend-planner** in foreground (pipeline mode). It reads `.devline/brainstorm.md`, searches the design database, and generates HTML previews.

**Interactive loop:** The frontend-planner may return `STATUS: NEEDS_INPUT` with design questions, conflicts, or preview selection. Present to user via AskUserQuestion, resume the agent with answers. Repeat until complete.

Output: `.devline/design-system.md`. Inform user and proceed to Stage 2.

### Stage 2: Plan and Implement (Phase-Aware)

After Stage 1 (brainstorm approval) and Stage 1.5 (design system, if applicable), detect whether the pipeline is single-phase or multi-phase before launching the planner.

#### Phase Detection

Read the approved `.devline/brainstorm.md` and check for a `## Phases` heading (H2, exact match).

- **No `## Phases` section:** Proceed with the single-phase path below — this is identical to the original pipeline behavior (backward compatible).
- **`## Phases` section exists:** Count the phases by counting `### Phase N:` headings. Enter the multi-phase loop described after the single-phase path.

#### Single-Phase Path (no `## Phases` in brainstorm)

Launch **planner** in foreground. It reads `.devline/brainstorm.md` and `.devline/design-system.md` (if exists).

**Interactive loop:** The planner may return `STATUS: NEEDS_INPUT` with design questions, code issues, and proactive improvements the planner is unsure about including. Present all sections via AskUserQuestion (recommendations marked "(Recommended)", code issues and improvements as include/skip choices). Resume with answers. Repeat until complete.

Output: `.devline/plan.md` + summary in conversation.

**Approval gate:** Present plan with AskUserQuestion (Approve / Needs changes / Stop here / Other). Only proceed on explicit approval or `auto_approve_plan: true`.

- If the user selects "Stop here", delete `.devline/plan.md`, `.devline/plan-phase-*.md`, `.devline/brainstorm.md`, `.devline/design-system.md`, `.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`, and `.devline/previews/` (if present), then end the pipeline gracefully.

After approval, proceed to Stage 3 (Implement) with `.devline/plan.md` as the plan file. Then continue to Stage 4 (Documentation) and Stage 5 (Deep Review) as normal.

#### Multi-Phase Path (`## Phases` detected in brainstorm)

When `## Phases` is detected, the pipeline plans ALL phases first, then implements them sequentially. Documentation (Stage 4) and Deep Review (Stage 5) run **once at the end** across all phases.

**The two-pass approach:** Plan everything → approve everything → implement phase by phase. This gives full scope visibility before any code is written. Changing a plan is cheap; changing implemented code costs a full pipeline cycle.

**Progress tracking for multi-phase mode:**

Before entering the planning pass, create phase-level tasks using TaskCreate:
- "Phase 1: Plan" (one per phase)
- "Phase 1: Implement" (one per phase, will contain sub-tasks from that phase's plan)
- ... repeat for each phase ...
- "Documentation" (once, at end)
- "Deep Review" (once, at end)

Update these as each phase progresses. Within each phase's implement cycle, display the standard per-task progress table (scoped to that phase's tasks).

**State tracking for multi-phase mode:**

When creating `.devline/state.md`, include the phase fields:
```markdown
- **Phase:** 1/3
- **Phase name:** Core data model
- **Pipeline stage:** planning | implementing
```

On phase transitions, update these fields. Reset the `## Task Progress` table for the new phase's tasks.

---

**Pass 1: Plan all phases sequentially**

For each phase N from 1 to total_phases:

**a. Plan phase N:** Launch the **planner** agent in the **foreground**, passing:
   - The full `.devline/brainstorm.md`
   - `.devline/design-system.md` (if it exists)
   - The current phase number N and total phase count M
   - Paths to all prior phase plan files (`.devline/plan-phase-1.md` through `.devline/plan-phase-{N-1}.md`) — the planner reads these to understand what earlier phases will build
   - Instruction to write output to `.devline/plan-phase-N.md`

   Handle the interactive NEEDS_INPUT loop identically to the single-phase path above. The planner scopes its plan to only the current phase's work as described in the brainstorm's `## Phases` section.

**b. Approve phase N plan:** Same approval gate as the single-phase path (`auto_approve_plan` config respected). Present:

```json
{
  "question": "Phase N/M plan complete — the plan is at .devline/plan-phase-N.md. Approve?",
  "header": "Approve Phase N",
  "options": [
    {"label": "Approve — continue to next phase plan", "description": "Approve this phase plan and move to planning the next phase (or start implementation if this is the last phase)"},
    {"label": "Needs changes", "description": "I want to revise this phase plan before continuing"},
    {"label": "Stop here", "description": "End the pipeline"},
    {"label": "Other", "description": "Type a note"}
  ],
  "multiSelect": false
}
```

   - If "Needs changes", resume the planner to revise the phase plan.
   - If "Stop here", end the pipeline. Run exit cleanup.
   - If "Other", follow the user's instruction.

After all phase plans are approved, present a summary of all phases and ask:

```json
{
  "question": "All N phase plans are complete and approved. Ready to start implementation (Phase 1)?",
  "header": "Start implementing",
  "options": [
    {"label": "Start implementation", "description": "Begin implementing Phase 1"},
    {"label": "Revisit a plan", "description": "I want to change one of the phase plans before starting"},
    {"label": "Stop here", "description": "End the pipeline"}
  ],
  "multiSelect": false
}
```

---

**Pass 2: Implement phases sequentially**

For each phase N from 1 to total_phases:

**a. Implement phase N:** Run Stage 3 (Implement) using `.devline/plan-phase-N.md` as the plan file. All existing Stage 3 behavior (wave barriers, worktree isolation, reviews, fix cycles, deferred findings batch fix) applies identically. **Stage 3.5 (deferred findings batch fix) runs at the end of each phase.**

**b. Advance:** After all waves of phase N are complete (including deferred findings batch fix), update `.devline/state.md` with `Phase: {N+1}/M` and proceed to phase N+1. Reset the task progress table for the new phase. Remove all `[FIXED]` entries from `.devline/deferred-findings.md` to keep the file clean for the next phase.

**After all phases are implemented:** Proceed to Stage 4 (Documentation) and Stage 5 (Deep Review), which run once across all phases.

### Stage 3: Implement (Autonomous — background, dependency-driven)

Follow the full implementation protocol in `references/implementation-protocol.md`. It covers wave execution, agent selection, mandatory reviews, review loops, fix cycle escalation, runtime dependency discovery, deferred findings batch fix, agent health monitoring, and orchestrator scope rules.

### Stage 4: Documentation (Autonomous — background)

Launch **docs-keeper** agent. Tell it which plan file(s) to read for context (`.devline/plan.md` or all `.devline/plan-phase-*.md` files in multi-phase mode). The docs-keeper proactively scans all documentation — README, CLAUDE.md, and everything in `docs/` — to find and fix anything stale, incomplete, or inconsistent with the code changes on this branch. It does not need a list of what to update; it finds what needs updating on its own.

### Stage 5: Deep Review (Autonomous — background)

Launch **deep-review** agent for final comprehensive review. The agent MUST return a structured verdict (APPROVED / HAS_FINDINGS). If the agent runs out of time, fails to produce a verdict, or produces partial/unstructured output: **relaunch it.** Do not read the agent's partial output to decide whether it "probably found no issues." Do not mark the deep review as done based on your own assessment. Do not skip to the final gate. Only a structured APPROVED or HAS_FINDINGS verdict from the deep-review agent counts.

**The deep review cannot defer findings.** All deferred findings were already resolved in Stage 3.5. Every finding the deep review reports — minor or major — must be fixed before merge.

**Finding handling — escalation ladder:**
1. Implementer fixes all findings → reviewer verifies → re-run deep review
2. Debugger (foreground) for root cause → plan → implementers → review → re-run deep review
3. Planner (foreground) for new approach → restart from Stage 3
4. Still failing: ask user for guidance

### Complete

When deep review approves:
1. Mark the active plan file(s) status as `completed` (`.devline/plan.md` for single-phase, or all `.devline/plan-phase-*.md` files for multi-phase)
2. Report summary (what was built, files, test results)
3. Ask user via AskUserQuestion:
   - "I found a mistake / want to add something" → route to debugger (runtime bugs) or planner (everything else), restart from Stage 2
   - "Merge to main and exit" → commit, squash merge (confirm target branch first), cleanup
   - "Commit and exit" → commit, cleanup
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
3. Clean `.devline/` contents (keep the directory): `find .devline/ -mindepth 1 -exec rm -rf {} + 2>/dev/null`
4. Output final summary and stop immediately.

## Lesson Collection

Agents may include `### Lessons` in their output. Append each to `## Lessons and Memory` in `CLAUDE.md` using format: `**Pattern**: ... | **Reason**: ... | **Solution**: ...`. Check for duplicates before appending. List any added lessons in the completion summary.

## General Rules

- Every finding from every review gets fixed — blocking findings immediately, deferrable findings batch-fixed after all tasks complete
- Test failures: implementer handles first; if stuck after 3 attempts, escalate to planner
- If stuck, ask the user for guidance
