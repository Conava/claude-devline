---
name: devline
description: This is the default skill for all development work. It orchestrates the entire development lifecycle from idea to merge-ready code, coordinating multiple agents for brainstorming, planning, implementation, review, documentation, and final approval. Use this for any development task that is non-trivial and could benefit from structured planning, parallel execution, and rigorous review or require more than 3 lines of code changed.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

Orchestrate the full development lifecycle from idea to merge-ready code. Follow the pipeline stages exactly — do not alter or skip stages unless the user explicitly instructs it. Do not start work until told to.

## CRITICAL: Orchestrator Role

**You are an ORCHESTRATOR, not an implementer.** You MUST NOT edit any source code yourself. ALL code changes are delegated to agents (implementer, devops, debugger). You coordinate agents, present results, and manage the pipeline flow.

## Progress Tracking

Before starting any work, create these tasks using TaskCreate:

1. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea")
2. "Design System — Generate UI design recommendations" (activeForm: "Generating design system") — only create this task if UI impact is detected
3. "Plan — Design architecture and tasks" (activeForm: "Planning implementation")
4. "Implement — Build and review tasks" (activeForm: "Implementing tasks")
5. "Documentation — Update project docs" (activeForm: "Updating documentation")
6. "Deep Review — Final quality and security audit" (activeForm: "Running deep review")
7. "Final Gate — User approval" (activeForm: "Awaiting user approval")

Mark each task as `in_progress` when starting that stage and `completed` when done.

Do NOT create task list entries for individual implementation tasks. Instead, display a **progress table** after each status change:

```
## Implementation Progress

| # | Wave | Task               | Deps  | Implement | Review     | Status   | Time | Deferred |
|---|------|--------------------|-------|-----------|------------|----------|------|----------|
| 1 | 1    | Auth module        | —     | ✅        | ✅         | Done     | 8m   | 2        |
| 2 | 1    | Database layer     | —     | ✅        | 🔄 Fix #1 | Fixing   | 14m  |          |
| 3 | 1    | API routes         | —     | 🔄        |            | Building | 12m  |          |
| 4 | 2    | Frontend views     | 1, 3  | ⏳        |            | Blocked  |      |          |
| 5 | 3    | Integration tests  | 1-4   | ⏳        |            | Blocked  |      |          |
```

- **#**: Task number from the plan — one per implementer agent
- **Wave**: Visual grouping from dependency graph (Wave 1 = no deps, Wave 2 = depends on Wave 1, etc.). Execution is driven by individual dependency resolution.
- **Deps**: Task dependencies. "—" for none.
- **Time**: Elapsed time since agent launch (e.g., `3m`, `12m`, `1h 05m`). Update every time the table is re-displayed.
- Icons: ⏳ blocked, 🔄 in progress, ✅ done, ❌ failed

**Table format is mandatory.** Every re-display MUST include ALL columns (#, Wave, Task, Deps, Implement, Review, Status, Time, Deferred). Every task gets its own row — NEVER group multiple tasks into a single row (e.g., never write `7,10-12 | Test consolidation`). The table always shows ALL tasks, not just the ones that changed.

Re-display this table after every status change. Always output text between background agent completions — never stay silent while agents run.

## State Persistence (Context Survival)

**Problem:** Long pipeline sessions generate substantial context from agent outputs, progress updates, and health checks. Context compaction will discard this, losing track of pipeline state. The solution: persist all mutable state to files, keep only brief summaries in conversation.

### State file: `.devline/state.md`

This is the **single source of truth** for pipeline state. Create it when entering Stage 3 and update it after **every status change** (task started, review verdict, fix cycle, escalation, completion).

```markdown
## Pipeline State
- **Stage:** implement
- **Updated:** 2026-03-20T14:32:00

## Task Progress
| # | Status | Review Attempts | Notes |
|---|--------|-----------------|-------|
| 1 | done | 1 (CLEAN) | |
| 2 | fixing | 2 (HAS_BLOCKING, HAS_BLOCKING) | Escalating to planner |
| 3 | building | 0 | Agent launched 14:28 |
| 4 | blocked | 0 | Waiting on 1, 3 |

## Running Agents
| Task | Agent ID | Type | Launched | Purpose |
|------|----------|------|----------|---------|
| 3 | abc123 | implementer | 14:28 | Initial implementation |

## Deferred Findings Count
Total: 5 (see .devline/deferred-findings.md)
```

### Deferred findings file: `.devline/deferred-findings.md`

Append deferrable findings here as they arrive — do NOT keep them in conversation context.

```markdown
## Deferred Findings

### Task 1: Auth module
1. **Code Quality** `src/auth.ts:42` — Variable `x` should be renamed to `tokenExpiry`
   - **Severity:** suggestion
   - **Fix:** Rename `x` to `tokenExpiry`

### Task 3: API routes
1. **Code Quality** `src/routes.ts:15` — Extract duplicated validation into helper
   - **Severity:** suggestion
   - **Fix:** Create `validateParams()` helper used by both endpoints
```

### Context discipline rules

1. **After receiving any agent output:** extract the actionable verdict, update `.devline/state.md`, append any deferred findings to `.devline/deferred-findings.md`, then output a **brief summary** to the user (verdict + 1-2 sentences). Do NOT paste full agent outputs into conversation context.
2. **Progress table:** display it to the user after status changes (it's useful for them), but the authoritative state lives in `.devline/state.md`, not in conversation history.
3. **Health check results:** summarize in one line ("Task 3 agent responded, making progress on test setup"). Do not preserve full agent responses.
4. **Review findings sent to implementer:** write them to a temporary file (`.devline/fix-task-{N}.md`) and tell the implementer to read it, rather than inlining all findings in the agent prompt. Delete the file after the fix cycle completes.

### Recovery protocol (post-compaction)

If you find yourself unsure of pipeline state — whether after compaction, a conversation resume, or any gap — execute this recovery sequence before taking any action:

1. Read `.devline/state.md` — restores task statuses, review attempts, running agents
2. Read `.devline/deferred-findings.md` — restores collected deferrable findings
3. Read `.devline/plan.md` — restores the task list, dependencies, and acceptance criteria
4. Check running background agents with `TaskList` — reconcile with the agent table in state.md
5. Resume orchestration from the recovered state

**This is not optional.** If you cannot recall the current stage or task statuses, you MUST read state files before proceeding. Do not guess or reconstruct from fragments of compacted context.

## Configuration

Read `.claude/devline.local.md` (if it exists) for pipeline settings:

- **`auto_approve_brainstorm`** (default: `false`) — Skip approval gate after brainstorm
- **`auto_approve_plan`** (default: `false`) — Skip approval gate after plan

## Pipeline Stages

Execute these stages in order:

### Stage 0: Branch Setup (Automatic)
Ensure the project is on a non-protected branch:
1. Read branching settings from `.claude/devline.local.md` if it exists (`branch_format`, `branch_kinds`, `protected_branches`)
2. If on a protected branch (default: main, master, develop, release, production, staging): create a branch using `branch_format` (default: `{kind}/{title}`). The `{kind}` MUST be one of `branch_kinds` (default: `feat|fix|refactor|docs|chore|test|ci`) — use these exact values, not synonyms (e.g., `feat/`, not `feature/`)
3. If already on a feature branch, continue
4. Create `.devline/` directory and add it to `.gitignore` if not present

5. **Stale artifact check:** If `.devline/plan.md` already exists, read its `**Branch:**` header. If it references a different branch or the `**Status:**` is `completed`, delete it (and `.devline/brainstorm.md`, `.devline/design-system.md`, `.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`, and `.devline/previews/` if present) and inform the user that stale artifacts were cleaned up. If it references the current branch and status is `active`, ask the user whether to resume the existing plan or start fresh — if resuming, read `.devline/state.md` to restore pipeline state (this enables mid-session recovery). Also clean up orphaned `.devline/brainstorm.md`, `.devline/design-system.md`, `.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`, or `.devline/previews/` files from previous runs if no matching plan exists.

### Stage 1: Brainstorm (Interactive — runs in main context)

Focus on the **grand scheme** — what we're building, the architecture, and scope. Not implementation details.

#### 1. Understand the Idea
Read the user's input. Optionally launch parallel background agents to briefly explore the codebase for context: what exists today, architectural boundaries, and whether UI is involved. Keep exploration shallow — just enough to understand the landscape.

#### 2. Clarify with Structured Questions
Use **AskUserQuestion** with concrete selectable options — avoid open-ended text questions unless necessary.

- Ask **1-4 questions per AskUserQuestion call**
- **Scale questions to ambiguity:** A clear idea needs 0-1 questions. A vague idea needs 2-4. Don't ask about things with obvious defaults — state assumptions in the brainstorm document.
- Every question MUST have **2-4 concrete options** with labels and descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive (e.g., "which platforms?")
- Use `multiSelect: false` for single-choice decisions (e.g., "what visual tone?")
- If the idea is already clear enough, skip questions entirely
- Add a recommended option first with "(Recommended)" in the label when there's a clear best choice and explain them briefly
- **Always ask about platform** when the feature involves a UI — never assume

**Focus questions on:** scope, user-facing behavior, platform, aesthetic direction, integration points.
**Do NOT ask about:** implementation details, error handling, testing approaches, performance strategies.

#### 3. Write Brainstorm Document
After receiving answers, write `.devline/brainstorm.md` capturing:
- What we're building (high-level)
- Architecture impact (which layers/services/components are involved)
- **UI impact** (explicitly: yes/no, what's affected, platform, aesthetic direction)
- Scope boundaries (in/out)
- Key decisions and assumptions
- Open questions for the planner

This file is the brainstorm output — the planner reads it as input alongside the conversation context.

**Approval gate:** Unless `auto_approve_brainstorm` is `true` in `.claude/devline.local.md`, stop here and present the brainstorm to the user with an explicit approval question:

```json
{
  "question": "Brainstorm written to .devline/brainstorm.md. Approve to proceed to planning?",
  "header": "Approve Brainstorm",
  "options": [
    {"label": "Approve — proceed to planning", "description": "The planner will design the architecture based on this spec"},
    {"label": "Needs changes", "description": "I want to revise something before planning begins"},
    {"label": "Stop here", "description": "End the pipeline, I only needed the brainstorm"},
    {"label": "Other", "description": "Type a note — e.g., add something small and auto-approve, or any other instruction"}
  ],
  "multiSelect": false
}
```

- If the user selects "Needs changes", update `.devline/brainstorm.md` and re-confirm.
- If the user selects "Stop here", delete `.devline/brainstorm.md` and `.devline/previews/` (if present), then end the pipeline gracefully.
- If the user selects "Other", read their free-text input and follow their instruction
- Only proceed to Stage 1.5 (if UI impact) or Stage 2 on explicit approval or an "Other" instruction that implies approval.

### Stage 1.5: Design System (Interactive — foreground, conditional)

**Trigger:** Read `.devline/brainstorm.md` — if the "UI Impact" section shows "UI touched: yes", evaluate the **scope** of UI changes:

- **Design-level changes** → run this stage. Examples: new pages, new components, visual redesign, new feature with significant UI, new visual identity, layout restructuring.
- **Cosmetic tweaks** → **skip** this stage and proceed directly to Stage 2. Examples: adjust spacing/padding, move an element, change a single color value, tweak font size, reorder existing elements, fix alignment. The planner can handle these without a full design system.

**Skip** this stage entirely if the feature is purely backend, API, infrastructure, or tooling with no user-facing UI.

Launch the **frontend-planner** agent in the **foreground**. Tell it to read `.devline/brainstorm.md` as its starting point (pipeline mode). If the brainstorm or user specifies a number of preview options (e.g., "I want 8 options"), include that count in the prompt — it overrides the default of 3. It will:
- Read `.devline/brainstorm.md` for product context, platform, UI scope, and aesthetic direction
- Search the design intelligence database (67 styles, 161 palettes, 57 font pairings, 160 animated components, 161 industry rules) using BM25 ranking
- Check for existing design systems in the project
- Generate N HTML preview files for different style directions (default 3, overridable)

**Interactive loop:** Like the planner, the frontend-planner cannot ask the user directly. It may return a `STATUS: NEEDS_INPUT` response containing:
- **Design Questions** — aesthetic choices, color direction, typography preferences, or layout decisions that need user input
- **Conflicts Found** — existing design system elements that conflict with the brainstorm direction
- **Preview Selection** — paths to `.devline/previews/*.html` files for the user to compare and choose from

When this happens:
1. Present the questions to the user using **AskUserQuestion** — map each to an option set with the frontend-planner's recommendation marked "(Recommended)"
2. For **preview selection**: tell the user to open the HTML files in their browser to compare, then present the options (e.g., "Option A — Glassmorphism with cool tones", "Option B — Minimal with warm earth tones", "Option C — Bold with high contrast"). Include a "None — try different directions" option.
3. **Resume** the frontend-planner agent (using the `resume` parameter with its agent ID) with the user's answers
4. Repeat if the frontend-planner returns more questions

Once it has all answers and the user has chosen a direction, it will:
- Write the design system to `.devline/design-system.md`
- Return a brief summary (style direction, color palette, typography pairing, key anti-patterns)

Note: `.devline/previews/` is kept so the user can reference them during planning and implementation. They are cleaned up with all other `.devline/` artifacts at pipeline exit.

When complete, inform the user: "Design system generated — [style direction] with [color mood] palette. Full details at `.devline/design-system.md`." Then proceed to Stage 2.

### Stage 2: Plan (Interactive — foreground with resume loop)
Launch the **planner** agent in the **foreground**. Tell it to read `.devline/brainstorm.md` for the feature spec, and `.devline/design-system.md` if it exists (it will exist when Stage 1.5 ran). The planner will:
- Read `.devline/brainstorm.md` for the feature spec, scope boundaries, and architecture impact
- Read `.devline/design-system.md` (if present) for design constraints, color palette, typography, and anti-patterns
- Analyze the codebase and design the architecture
- Challenge its own decisions aggressively
- Identify proactive improvements for all touched code
- Break work into **granular tasks** (5–15 minutes each for an implementer) with explicit dependencies — hundreds of tasks are expected for large features
- Define TDD test cases per task

**Interactive loop:** The planner cannot ask the user directly. Instead it may return a `STATUS: NEEDS_INPUT` response containing any combination of:
- **Design Questions** — architectural or behavioral choices that need user input
- **Code Issues Found** — bugs, flaws, or tech debt discovered in the blast radius that the user should decide whether to fix
- **Proactive Improvements** — enhancements the planner wants to include in the plan for the user to approve or reject

When this happens:
1. Present ALL sections to the user using **AskUserQuestion** — for design questions, map each to an option set with the planner's recommendation marked "(Recommended)" and its alternatives as additional options. For code issues and proactive improvements, present them as checklists the user can approve/reject.
2. **Resume** the planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the planner returns more questions or findings — the planner is encouraged to iterate multiple times to refine the plan to a high standard

Once the planner has all answers, it will:
- **Write the full plan to `.devline/plan.md`** — this is the single source of truth for all subsequent stages.
- Return a concise summary to conversation (architecture overview, task list with dependencies, key decisions)

**Approval gate:** Unless `auto_approve_plan` is `true` in `.claude/devline.local.md`, stop here and present the plan summary to the user with an explicit approval question:

```json
{
  "question": "Plan complete — the full plan is at .devline/plan.md. Approve to start implementation?",
  "header": "Approve Plan",
  "options": [
    {"label": "Approve — start implementation", "description": "Launch implementer agents for all tasks"},
    {"label": "Needs changes", "description": "I want to revise the plan before implementation"},
    {"label": "Stop here", "description": "End the pipeline, I only needed the plan"},
    {"label": "Other", "description": "Type a note — e.g., add something small and auto-approve, or any other instruction"}
  ],
  "multiSelect": false
}
```

- If the user selects "Needs changes", resume the planner agent with the user's feedback to revise the plan.
- If the user selects "Stop here", delete `.devline/plan.md`, `.devline/brainstorm.md`, `.devline/design-system.md`, `.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`, and `.devline/previews/` (if present), then end the pipeline gracefully.
- If the user selects "Other", read their free-text input and follow their instruction.
- Only proceed to Stage 3 on explicit approval or an "Other" instruction that implies approval.

### Stage 3: Implement (Autonomous — background, dependency-driven)
Once the plan is approved, execute tasks based on their dependency graph:

**Initialization:** Create `.devline/state.md` and `.devline/deferred-findings.md` with all tasks in their initial state (blocked or ready). This is the first write — from this point, update state files after every status change.

**Execution model:**
- Read all tasks from `.devline/plan.md` and their dependencies
- Launch all tasks with no unresolved dependencies immediately, in parallel, in the background (`run_in_background: true`), each with **worktree isolation** (see below)
- When a task completes: merge its worktree branch back, clean up the worktree, then launch the reviewer
- When a task completes its full review cycle (CLEAN or DEFERRED_ONLY), update `.devline/state.md`, check if any blocked tasks are now unblocked (all their dependencies are done and reviewed) and launch those immediately
- **Track launch time** for every agent — record in `.devline/state.md` when each agent was launched

**Worktree Isolation (mandatory for all implementer/devops agents):**

All implementer and devops agents MUST be launched with `isolation: "worktree"`. This gives each agent an isolated copy of the repository, preventing parallel agents from overwriting each other's changes or triggering race conditions.

```
Agent(subagent_type="devline:implementer", isolation="worktree", run_in_background=true, ...)
```

**Merge-back protocol — after each agent completes:**

The agent result includes the worktree path and branch name. Execute these steps sequentially:

1. **Merge** the worktree branch into the current feature branch:
   ```bash
   git merge <worktree-branch> --no-edit
   ```
2. **If merge conflicts occur:** resolve trivially if possible (e.g., both sides added to the same list), otherwise note the conflict and relaunch the implementer on the feature branch (without worktree isolation) to resolve manually.
3. **Clean up** the worktree and branch:
   ```bash
   git worktree remove <worktree-path> --force 2>/dev/null
   git branch -d <worktree-branch> 2>/dev/null
   ```
4. **Then** launch the reviewer — it runs on the merged code in the main working directory (no worktree needed for reviewers since they only read and run tests).

**Important:** If the agent result says no changes were made, the worktree is auto-cleaned — skip steps 1-3.

Fix-cycle implementers (relaunched after reviewer finds blocking issues) also use `isolation: "worktree"` and follow the same merge-back protocol. The deferred-findings batch-fix implementer also uses worktree isolation.

**Agent selection:**
- Use **implementer** agents for feature/application tasks
- Use **devops** agent for build, CI/CD, Docker, infrastructure, and tooling tasks
- The planner's **Agent** field on each task indicates which agent to use
- Assign each agent its task number and tell it to read the plan from `.devline/plan.md`
- Each follows strict TDD: red → green → refactor
- **Build isolation:** When launching implementer agents, always include this instruction in the prompt: "Use `--no-daemon` for all build tool commands (Gradle, Maven, etc.) to avoid daemon contention with parallel agents." This is critical for projects with 5+ parallel agents.

**Agent health monitoring:**

Background agents can get stuck — most commonly on build tool daemon contention (Gradle, Maven), infinite test retry loops, or compilation errors from concurrent file edits. The orchestrator MUST actively monitor and enforce hard time limits.

1. **Progress table with elapsed time:** The `Time` column in the progress table (defined above) shows elapsed time since agent launch. Update it every time the table is re-displayed. Add escalation icons to the Status column as described below.

2. **Time-based escalation ladder:**
   - **Under 20 minutes**: no action needed — normal operation.
   - **20 minutes**: send a `SendMessage` nudge: "Status check — what's your progress and are you blocked?" Add ⚠️ to the progress table.
   - **30 minutes**: actively investigate — check what files the agent has written/modified, query it via `SendMessage` for a detailed status. Add 🐌 to the progress table. If the agent is clearly making progress (new files appearing, tests running), let it continue.
   - **45 minutes**: consider killing and relaunching. If the agent has made no meaningful progress since the 30-minute check (no new files, same error loop, no response to nudges), `TaskStop` and relaunch with a fresh agent. If it IS making progress but slowly, let it continue to the hard limit. Add 🔁 to the progress table if killed.
   - **1 hour — hard kill.** No exceptions. `TaskStop` the agent and relaunch with a fresh agent. Include what the previous agent wrote (check files) and the blocker (if known), with instruction to take a different approach. Update `.devline/state.md`.
   - If a task fails on its **second relaunch** (three total attempts): escalate to the user — the task likely has a systemic blocker that needs human input.

   **This is the #1 enforcement failure.** Previous runs had agents running 1-2+ hours because nudges were sent but kills were not. The 1-hour hard kill is non-negotiable — a fresh agent with context from the previous attempt is ALWAYS more productive than an agent stuck in a loop.

3. **Proactive check-ins between completions:** If no agent has completed in 15 minutes, proactively check on all running agents (don't wait for a completion event to trigger monitoring). Query each running agent for status and display an updated progress table to the user.

4. **Common stuck patterns and responses:**
   - **Build daemon contention** (Gradle lock errors, "Could not connect to daemon", cache corruption): the replacement agent must use `--no-daemon`. Tell it explicitly: "The previous agent got stuck on Gradle daemon contention. Use `./gradlew --no-daemon` for ALL build commands."
   - **Test retry loops** (same test failing 3+ times): the replacement agent should check if the test itself is wrong or if there's a real bug, not just re-run the same test.
   - **Compilation errors from other agents' edits**: the replacement agent should pull the latest state of all files before starting, as other agents may have changed shared dependencies.
   - **Agent completed but no notification**: if files exist for a task but no agent completion was received, check with `TaskList`. If the agent is gone, treat the task as complete and send it to review.

5. **Do NOT work around stuck agents by editing code yourself.** You are the orchestrator — you do not write code. If an agent is stuck, kill it and relaunch a fresh one. If the fresh agent is also stuck, escalate to the user. Never bypass the agent model by making "quick fixes" directly.

**Per-task review loop:** After each task is implemented, launch the **reviewer** agent in the background.

The reviewer returns one of three verdicts:
- **CLEAN** — zero findings
- **HAS_BLOCKING** — at least one blocking finding (may also include deferrable findings)
- **DEFERRED_ONLY** — only deferrable findings (minor quality, style, suggestions)

**Deferred findings collection:** When a reviewer returns deferrable findings (in either `HAS_BLOCKING` or `DEFERRED_ONLY` verdicts), append them to `.devline/deferred-findings.md` under the task's heading. Do NOT keep these in conversation context.

The fix cycle works as follows:

1. **Reviewer returns CLEAN**: update `.devline/state.md`, mark the task as done in the progress table. Check if any blocked tasks are now unblocked and launch them.
2. **Reviewer returns DEFERRED_ONLY**: append deferrable findings to `.devline/deferred-findings.md`, update `.devline/state.md`, then mark the task as done. The task is not blocked — deferrable findings don't impact dependent tasks. Check if any blocked tasks are now unblocked and launch them.
3. **Reviewer returns HAS_BLOCKING**: append any deferrable findings to `.devline/deferred-findings.md`, then write the blocking findings to `.devline/fix-task-{N}.md` and launch an **implementer** agent with:
   - The original task from the plan (so it has full context of what was being built)
   - Instruction to read `.devline/fix-task-{N}.md` for the blocking findings to fix
   - Update `.devline/state.md` with the new review attempt
4. After the implementer fixes the blocking findings, delete `.devline/fix-task-{N}.md`, re-launch the **reviewer** on the fixed code
5. **If the reviewer returns HAS_BLOCKING again (attempt 2)**: write new findings to `.devline/fix-task-{N}.md`, launch another **implementer** pointing to that file, plus context from previous attempts
6. **If the reviewer returns HAS_BLOCKING a third time (attempt 3 — escalate to planner)**: Relaunch the **planner** agent with:
   - The original task
   - All blocking findings from all review attempts (reference the fix-task file history)
   - All fix attempts from implementers
   The planner investigates why the task is failing review and rewrites the task in `.devline/plan.md` with a new implementation approach. This is a critical escalation — it means the original implementation approach isn't working and a new plan is needed to get it over the finish line.

**Deferred Findings Batch Fix:** After ALL tasks have passed review (CLEAN or DEFERRED_ONLY), and before proceeding to Stage 4 (Documentation):
1. If `.devline/deferred-findings.md` has findings: launch a single **implementer** and tell it to read `.devline/deferred-findings.md` for the complete list of all deferred findings across all tasks
2. After the implementer finishes, launch the **reviewer** to verify the batch fixes — this review follows the same fix cycle rules above (if blocking issues are introduced during the batch fix, they must be fixed immediately)
3. If there are no deferred findings: proceed directly to Stage 4

Update and display the progress table after each status change. The "Implement" pipeline task stays `in_progress` until ALL tasks have a CLEAN review.

### Stage 4: Documentation (Autonomous — background)
After all tasks pass review, launch the **docs-keeper** agent in the background:
- Updates README, API docs, architecture docs
- Creates new documentation for new features
- Only handles separate doc files (inline docs were handled by implementer)
- Ensures no documentation is left outdated or missing for the new code

### Stage 5: Deep Review (Autonomous — background, Final Gate)
Launch the **deep-review** agent in the background.

The deep-review performs the final comprehensive review:
- Security audit and credential scanning
- Code quality and technical debt assessment
- Convention adherence check
- **Regression check** — verify all previously working functionality still works (run the full test suite, check for broken behavior)
- **Feature goal verification** — verify the feature actually works end-to-end, not just that unit tests pass
- Quality verdict with severity-classified findings

Findings are classified as **minor** (style, quality, debt) or **major/critical** (security, correctness, regressions, unmet goals).

**Handling findings by severity:**

**Minor findings only:** Launch a single **implementer** with all minor findings → **reviewer** to verify → proceed to Complete (no deep review re-run).

**Major or critical findings — escalation ladder:**

1. **Attempt 1 — implementer**: Launch implementers for major findings (one per affected task by file ownership) → reviewer → re-run **deep review**
2. **Attempt 2 — debugger**: Launch **debugger** (foreground) for root cause analysis → present plan → implementers → review → re-run deep review
3. **Attempt 3 — planner**: Launch **planner** (foreground) for new approach → present plan → **restart from Stage 3**
4. **Still failing**: Stop and ask the user for guidance with all findings and fix history

### Complete
When deep review approves with no findings:
1. Mark `.devline/plan.md` status as `completed`
2. Report completion summary:
   - Summary of what was built
   - Files created/modified
   - Test results
3. **Ask the user what to do next** using AskUserQuestion:

```json
{
  "question": "Pipeline complete — all reviews passed. What would you like to do?",
  "header": "Pipeline Complete",
  "options": [
    {"label": "I found a mistake / want to add something / fix a bug", "description": "Describe the issue and I'll route it to the right stage"},
    {"label": "Merge to main and exit", "description": "Commit the feature, merge to main, delete plan, and end the pipeline"},
    {"label": "Commit and exit", "description": "Commit the feature, delete plan, and end the pipeline"},
    {"label": "Exit", "description": "Delete plan and end the pipeline"}
  ],
  "multiSelect": false
}
```

**Handling each option:**

- **"I found a mistake / want to add something / fix a bug"**: Ask the user to describe the issue (free-text). Reset pipeline to Stage 2:
  - **Runtime bugs** (crashes, errors, wrong output) → **debugger as planner**
  - **Everything else** (missing features, UI, new requirements) → **planner**

  Use TaskUpdate to mark Stage 2 onward as `pending`. After plan approval, continue: Stage 3 → 4 → 5 → Complete.

- **"Exit"**: Delete `.devline/plan.md`, `.devline/brainstorm.md`, `.devline/design-system.md`, and `.devline/previews/` (if present), then end the pipeline.

- **"Commit and exit"**: Stage and commit all changes on the feature branch (follow the standard git commit protocol — review changes, draft message, create commit). Then delete `.devline/plan.md`, `.devline/brainstorm.md`, `.devline/design-system.md`, `.devline/state.md`, `.devline/deferred-findings.md`, `.devline/fix-task-*.md`, and `.devline/previews/` (if present), then end the pipeline.

- **"Merge to main and exit"**: Stage and commit all changes on the feature branch. Then:
  1. Draft a squash merge commit message summarizing the entire feature (not individual commits). Present it to the user via AskUserQuestion with the draft as context and options to approve, edit, or provide their own message.
  2. Squash merge into main: `git checkout main && git merge --squash <branch> && git commit -m "<approved message>"`.
  3. Delete `.devline/plan.md`, `.devline/brainstorm.md`, `.devline/design-system.md`, and `.devline/previews/` (if present), then end the pipeline.

  **Before merging, confirm the target branch with the user if it's not obvious.**

## Lesson Collection

Agents (implementer, reviewer, deep-review) may include a `### Lessons` section in their output when they discover non-obvious codebase patterns worth remembering.

**When you receive agent output with lessons:**
1. Append each lesson to the `## Lessons and Memory` section of `CLAUDE.md` in the project root
2. Use the format already in that section: `**Pattern**: ... | **Reason**: ... | **Solution**: ...`
3. Before appending, check if a similar lesson already exists — update it rather than duplicating
4. Do not ask for approval — the agent already analyzed the issue and determined it's a broader pattern

**In the completion summary**, list any lessons that were added during this pipeline run so the user is aware.

## General Rules

- **Every finding from every review gets fixed** — blocking findings are fixed immediately; deferrable findings (minor quality, style, suggestions) are collected and batch-fixed by a single implementer after all tasks complete. There is no "ignore and move on."
- **Test failures during implementation**: implementer handles first; if stuck after 3 attempts, escalate to planner
- **All agents**: if stuck, ask the user for guidance rather than looping forever
