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

| # | Wave | Task               | Deps  | Implement | Review     | Status   |
|---|------|--------------------|-------|-----------|------------|----------|
| 1 | 1    | Auth module        | —     | ✅        | ✅         | Done     |
| 2 | 1    | Database layer     | —     | ✅        | 🔄 Fix #1 | Fixing   |
| 3 | 1    | API routes         | —     | 🔄        |            | Building |
| 4 | 2    | Frontend views     | 1, 3  | ⏳        |            | Blocked  |
| 5 | 3    | Integration tests  | 1-4   | ⏳        |            | Blocked  |
```

- **#**: Task number from the plan — one per implementer agent
- **Wave**: Visual grouping from dependency graph (Wave 1 = no deps, Wave 2 = depends on Wave 1, etc.). Execution is driven by individual dependency resolution.
- **Deps**: Task dependencies. "—" for none.
- Icons: ⏳ blocked, 🔄 in progress, ✅ done, ❌ failed

Re-display this table after every status change. Always output text between background agent completions — never stay silent while agents run.

## Configuration

Read `.claude/devline.local.md` (if it exists) for pipeline settings:

- **`auto_approve_brainstorm`** (default: `false`) — Skip approval gate after brainstorm
- **`auto_approve_plan`** (default: `false`) — Skip approval gate after plan

## Pipeline Stages

Execute these stages in order:

### Stage 0: Branch Setup (Automatic)
Ensure the project is on a feature branch:
1. Read branching settings from `.claude/devline.local.md` if it exists (`branch_format`, `branch_kinds`, `protected_branches`)
2. If on a protected branch (default: main, master, develop, release, production, staging): create a feature branch using `branch_format` (default: `{kind}/{title}`)
3. If already on a feature branch, continue
4. Create `.devline/` directory and add it to `.gitignore` if not present

5. **Stale artifact check:** If `.devline/plan.md` already exists, read its `**Branch:**` header. If it references a different branch or the `**Status:**` is `completed`, delete it (and `.devline/brainstorm.md` and `.devline/design-system.md` if present) and inform the user that stale artifacts were cleaned up. If it references the current branch and status is `active`, ask the user whether to resume the existing plan or start fresh. Also clean up orphaned `.devline/brainstorm.md` or `.devline/design-system.md` files from previous runs if no matching plan exists.

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
- If the user selects "Stop here", delete `.devline/brainstorm.md` and end the pipeline gracefully.
- If the user selects "Other", read their free-text input and follow their instruction
- Only proceed to Stage 1.5 (if UI impact) or Stage 2 on explicit approval or an "Other" instruction that implies approval.

### Stage 1.5: Design System (Interactive — foreground, conditional)

**Trigger:** Read `.devline/brainstorm.md` — if the "UI Impact" section shows "UI touched: yes", run this stage.

**Skip** this stage entirely if the feature is purely backend, API, infrastructure, or tooling with no user-facing UI.

Launch the **frontend-planner** agent in the **foreground**. Tell it to read `.devline/brainstorm.md` as its starting point. It will:
- Read `.devline/brainstorm.md` for product context, platform, UI scope, and aesthetic direction
- Search the design intelligence database (67 styles, 161 palettes, 57 font pairings, 161 industry rules) using BM25 ranking
- Check for existing design systems in the project

**Interactive loop:** Like the planner, the frontend-planner cannot ask the user directly. It may return a `STATUS: NEEDS_INPUT` response containing:
- **Design Questions** — aesthetic choices, color direction, typography preferences, or layout decisions that need user input
- **Conflicts Found** — existing design system elements that conflict with the brainstorm direction

When this happens:
1. Present the questions to the user using **AskUserQuestion** — map each to an option set with the frontend-planner's recommendation marked "(Recommended)"
2. **Resume** the frontend-planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the frontend-planner returns more questions

Once it has all answers, it will:
- Write the design system to `.devline/design-system.md`
- Return a brief summary (style direction, color palette, typography pairing, key anti-patterns)

When complete, inform the user: "Design system generated — [style direction] with [color mood] palette. Full details at `.devline/design-system.md`." Then proceed to Stage 2.

### Stage 2: Plan (Interactive — foreground with resume loop)
Launch the **planner** agent in the **foreground**. Tell it to read `.devline/brainstorm.md` for the feature spec, and `.devline/design-system.md` if it exists (it will exist when Stage 1.5 ran). The planner will:
- Read `.devline/brainstorm.md` for the feature spec, scope boundaries, and architecture impact
- Read `.devline/design-system.md` (if present) for design constraints, color palette, typography, and anti-patterns
- Analyze the codebase and design the architecture
- Challenge its own decisions aggressively
- Identify proactive improvements for all touched code
- Break work into small, focused tasks with explicit dependencies
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
- If the user selects "Stop here", delete `.devline/plan.md`, `.devline/brainstorm.md`, and `.devline/design-system.md` (if present), then end the pipeline gracefully.
- If the user selects "Other", read their free-text input and follow their instruction.
- Only proceed to Stage 3 on explicit approval or an "Other" instruction that implies approval.

### Stage 3: Implement (Autonomous — background, dependency-driven)
Once the plan is approved, execute tasks based on their dependency graph:

**Execution model:**
- Read all tasks from `.devline/plan.md` and their dependencies
- Launch all tasks with no unresolved dependencies immediately, in parallel, in the background (`run_in_background: true`)
- When a task completes its full review cycle (CLEAN), check if any blocked tasks are now unblocked (all their dependencies are done and reviewed) and launch those immediately

**Agent selection:**
- Use **implementer** agents for feature/application tasks
- Use **devops** agent for build, CI/CD, Docker, infrastructure, and tooling tasks
- The planner's **Agent** field on each task indicates which agent to use
- Assign each agent its task number and tell it to read the plan from `.devline/plan.md`
- Each follows strict TDD: red → green → refactor

**Per-task review loop:** After each task is implemented, launch the **reviewer** agent in the background.

The reviewer returns either **CLEAN** (zero findings) or **HAS_FINDINGS** (list of issues). **ALL findings — regardless of severity — must be sent back to an implementer for fixing.** There is no "pass with warnings."

The fix cycle works as follows:

1. **Reviewer returns CLEAN**: mark the task as done in the progress table. Check if any blocked tasks are now unblocked and launch them.
2. **Reviewer returns HAS_FINDINGS**: launch an **implementer** agent with:
   - The original task from the plan (so it has full context of what was being built)
   - The complete list of reviewer findings with file:line references and fix suggestions
   - Instruction to fix ALL findings, not just critical ones
3. After the implementer fixes the findings, re-launch the **reviewer** on the fixed code
4. **If the reviewer returns HAS_FINDINGS again (attempt 2)**: launch another **implementer** with the new findings plus context from both previous attempts
5. **If the reviewer returns HAS_FINDINGS a third time (attempt 3 — escalate to planner)**: Relaunch the **planner** agent with:
   - The original task
   - All findings from all review attempts
   - All fix attempts from implementers
   The planner investigates why the task is failing review and rewrites the task in `.devline/plan.md` with a new implementation approach. This is a critical escalation — it means the original implementation approach isn't working and a new plan is needed to get it over the finish line.

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

- **"Exit"**: Delete `.devline/plan.md`, `.devline/brainstorm.md`, and `.devline/design-system.md` (if present), then end the pipeline.

- **"Commit and exit"**: Stage and commit all changes on the feature branch (follow the standard git commit protocol — review changes, draft message, create commit). Then delete `.devline/plan.md`, `.devline/brainstorm.md`, and `.devline/design-system.md` (if present), then end the pipeline.

- **"Merge to main and exit"**: Stage and commit all changes on the feature branch. Then:
  1. Draft a squash merge commit message summarizing the entire feature (not individual commits). Present it to the user via AskUserQuestion with the draft as context and options to approve, edit, or provide their own message.
  2. Squash merge into main: `git checkout main && git merge --squash <branch> && git commit -m "<approved message>"`.
  3. Delete `.devline/plan.md`, `.devline/brainstorm.md`, and `.devline/design-system.md` (if present), then end the pipeline.

  **Before merging, confirm the target branch with the user if it's not obvious.**

## General Rules

- **Every finding from every review gets fixed — there is no "pass with warnings."**
- **Test failures during implementation**: implementer handles first; if stuck after 3 attempts, escalate to planner
- **All agents**: if stuck, ask the user for guidance rather than looping forever
