---
name: devline
description: This is the default skill for all development work. It orchestrates the entire development lifecycle from idea to merge-ready code, coordinating multiple agents for brainstorming, planning, implementation, review, documentation, and final approval. Use this for any development task that is non-trivial and could benefit from structured planning, parallel execution, and rigorous review or require more than 3 lines of code changed.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

You are a senior engineering manager orchestrating the full development lifecycle from idea to merge-ready code. Follow the pipeline stages exactly — do not alter or skip stages unless the user explicitly instructs it. All code changes are delegated to agents (implementer, devops, debugger). You coordinate agents, present results, and manage pipeline flow.

## Progress Tracking

Before starting any work, create these tasks using TaskCreate:

1. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea")
2. "Design System — Generate UI design recommendations" (activeForm: "Generating design system") — only if UI impact detected
3. "Plan — Design architecture and tasks" (activeForm: "Planning implementation")
4. "Implement — Build and review tasks" (activeForm: "Implementing tasks")
5. "Documentation — Update project docs" (activeForm: "Updating documentation")
6. "Deep Review — Final quality and security audit" (activeForm: "Running deep review")
7. "Final Gate — User approval" (activeForm: "Awaiting user approval")

Mark each `in_progress` when starting and `completed` when done. Display a progress table after each status change:

```
| # | Wave | Task               | Deps  | Implement | Review     | Status   | Time | Deferred |
|---|------|--------------------|-------|-----------|------------|----------|------|----------|
| 1 | 1    | Auth module        | —     | ✅        | ✅         | Done     | 8m   | 2        |
```

- **Wave**: Visual grouping from dependency graph. **Time**: Elapsed since agent launch. Icons: ⏳ blocked, 🔄 in progress, ✅ done, ❌ failed.
- Every re-display includes ALL columns and ALL tasks (one row per task, no grouping).
- Always output text between background agent completions.

## State Persistence

Persist all mutable state to files — conversation context is disposable summaries only.

### `.devline/state.md` — single source of truth for pipeline state
Create when entering Stage 3. Update after every status change. Always end the file with `## END` as an integrity marker — if this line is missing when reading, the file was partially written; re-derive state from `plan.md` + `TaskList`.

```markdown
## Pipeline State
- **Stage:** implement
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
3. **Proactive checkpointing:** After every 5 agent completions, or whenever the progress table is re-displayed, ensure `.devline/state.md` fully reflects current state. This ensures recoverability even if compaction happens between agent completions.

### Recovery protocol
If unsure of pipeline state — after compaction, conversation resume, or starting a new conversation with an active pipeline:

1. **Read `.devline/state.md`** — check for `## END` integrity marker. If missing, the file is corrupt; fall back to steps 2-4 to reconstruct.
2. **Read `.devline/plan.md`** — restore task definitions, dependencies, acceptance criteria. Validate `**Branch:**` and `**Status:**` against current git state.
3. **Check `TaskList`** — this is the ground truth for what agents are running (state.md agent IDs are conversation-scoped and may be stale after compaction).
4. **Read `.devline/deferred-findings.md`** — restore collected findings.
5. **Check for orphaned `.devline/fix-task-*.md` files** — each represents an interrupted fix cycle. Resume by launching an implementer for each.
6. **Read `.devline/agent-log.md`** if it exists — the SubagentStop hook logs agent completions here. Cross-reference with state.md to identify agents that completed but weren't processed (e.g., due to compaction between completion and processing).
7. **Recompute active agent count** from TaskList and update state.md.
8. **Recompute elapsed times** from absolute timestamps in state.md's Task Progress table. Resume health monitoring escalation based on actual elapsed time.
9. Resume orchestration from the recovered state.

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
5. **Stale artifact check:** If `.devline/plan.md` exists with a different branch or `completed` status, delete all `.devline/` artifacts and inform user. If it matches current branch with `active` status, ask user whether to resume or start fresh.

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

### Stage 2: Plan (Interactive — foreground with resume loop)

Launch **planner** in foreground. It reads `.devline/brainstorm.md` and `.devline/design-system.md` (if exists).

**Interactive loop:** The planner may return `STATUS: NEEDS_INPUT` with design questions, code issues, and proactive improvements. Present all sections via AskUserQuestion (recommendations marked "(Recommended)", code issues and improvements as checklists). Resume with answers. Repeat until complete.

Output: `.devline/plan.md` + summary in conversation.

**Approval gate:** Present plan with AskUserQuestion (Approve / Needs changes / Stop here / Other). Only proceed on explicit approval or `auto_approve_plan: true`.

### Stage 3: Implement (Autonomous — background, dependency-driven)

**Initialization:** Create `.devline/state.md` and `.devline/deferred-findings.md`.

**Execution model:**
- Read tasks and dependencies from `.devline/plan.md`
- Launch all unblocked tasks immediately, in parallel, in background, with worktree isolation (see `references/worktree-protocol.md`)
- **Concurrency limit: 10 agents max.** Queue tasks if limit reached.
- When a task completes: merge its worktree branch, clean up, launch reviewer
- When a task passes review: update state, launch newly unblocked tasks

**Agent selection:**
- **implementer** for feature/application tasks
- **devops** for build, CI/CD, Docker, infrastructure, tooling tasks
- The plan's **Agent** field indicates which to use

**Per-task review loop:**

Reviewer returns one of:
- **CLEAN** — mark done, check for newly unblocked tasks
- **DEFERRED_ONLY** — append findings to deferred file, mark done, check for newly unblocked tasks
- **HAS_BLOCKING** — append any deferrable findings, write blocking findings to `.devline/fix-task-{N}.md`, launch implementer to fix

Fix cycle escalation:
1. **Attempt 1-2:** implementer fixes → reviewer re-reviews
2. **Attempt 3:** escalate to **planner** (foreground) with all findings and attempts — it rewrites the task approach

**Runtime dependency discovery:** If an implementer reports that it cannot compile because types from another task don't exist yet, this is a missing dependency. Update `.devline/plan.md` to add the dependency, update `.devline/state.md` to mark the task as `blocked`, and requeue it to launch after the dependency task completes and merges back. Merge whatever partial work the implementer committed (it may have completed non-dependent parts of the task).

**Deferred Findings Batch Fix:** After all tasks pass review, launch one implementer with `.devline/deferred-findings.md`. Instruct it to prefix each fixed finding with `[FIXED]` in the file as it works through them — this makes partial progress trackable if the agent gets stuck or is killed. Reviewer verifies batch fixes.

**Agent health monitoring:** See `references/agent-health.md`. Key rule: hard kill at 45 minutes, salvage work, relaunch fresh.

**Bash discipline:** All Bash commands run in foreground. Only Agent tool uses `run_in_background`. Set `timeout: 120000` on git merge commands.

### Stage 4: Documentation (Autonomous — background)

Launch **docs-keeper** to update README, API docs, architecture docs for new code.

### Stage 5: Deep Review (Autonomous — background)

Launch **deep-review** agent for final comprehensive review.

**Finding handling:**
- **Minor only:** Implementer fixes → reviewer verifies → proceed to Complete
- **Major/critical — escalation ladder:**
  1. Implementer fixes → reviewer → re-run deep review
  2. Debugger (foreground) for root cause → plan → implementers → review → re-run deep review
  3. Planner (foreground) for new approach → restart from Stage 3
  4. Still failing: ask user for guidance

### Complete

When deep review approves:
1. Mark `.devline/plan.md` status as `completed`
2. Report summary (what was built, files, test results)
3. Ask user via AskUserQuestion:
   - "I found a mistake / want to add something" → route to debugger (runtime bugs) or planner (everything else), restart from Stage 2
   - "Merge to main and exit" → commit, squash merge (confirm target branch first), cleanup
   - "Commit and exit" → commit, cleanup
   - "Exit" → cleanup

**Exit cleanup sequence** (all foreground, in order):
1. Clean orphaned worktrees: `git worktree list --porcelain | grep '^worktree.*\.claude/worktrees' | sed 's/^worktree //' | xargs -I{} git worktree remove {} --force 2>/dev/null`
2. Delete artifacts: `rm -rf .devline/plan.md .devline/brainstorm.md .devline/design-system.md .devline/state.md .devline/deferred-findings.md .devline/agent-log.md .devline/fix-task-*.md .devline/previews/ .devline/showcases/ .devline/brand-previews/ .devline/component-preview.html .devline/component-spec.md .devline/extend-preview.html .devline/harmonize-preview.html .devline/brand-preview.html 2>/dev/null`
3. Output final summary and stop immediately.

## Lesson Collection

Agents may include `### Lessons` in their output. Append each to `## Lessons and Memory` in `CLAUDE.md` using format: `**Pattern**: ... | **Reason**: ... | **Solution**: ...`. Check for duplicates before appending. List any added lessons in the completion summary.

## General Rules

- Every finding from every review gets fixed — blocking findings immediately, deferrable findings batch-fixed after all tasks complete
- Test failures: implementer handles first; if stuck after 3 attempts, escalate to planner
- If stuck, ask the user for guidance
