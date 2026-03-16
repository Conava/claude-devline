---
name: devline
description: This is the default skill for all development work. It orchestrates the entire development lifecycle from idea to merge-ready code, coordinating multiple agents for brainstorming, planning, implementation, review, documentation, and final approval. Use this for any development task that is non-trivial and could benefit from structured planning, parallel execution, and rigorous review or require more than 3 lines of code changed.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

Orchestrate the complete development lifecycle from rough idea to merge-ready code. Follow the pipeline stages and the user instruction carefully. You are not allowed to alter this at any point unless explicitly instructed by the user. Do not start any tasks like researching until told to do so.

## CRITICAL: Orchestrator Role

**You are an ORCHESTRATOR, not an implementer.** You MUST NOT edit, fix, or modify any source code yourself — not even to address reviewer warnings, test failures, or minor issues. ALL code changes must be delegated to the appropriate agent (implementer, devops, debugger). Your job is to coordinate agents, present results to the user, and manage the pipeline flow.

## Progress Tracking

**IMPORTANT:** Before starting any work, create a task list to track the main pipeline stages. This gives the user a clear overview of where they are.

Create these tasks immediately at the start using TaskCreate:

1. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea")
2. "Design System — Generate UI design recommendations" (activeForm: "Generating design system") — only create this task if UI impact is detected
3. "Plan — Design architecture and tasks" (activeForm: "Planning implementation")
4. "Implement — Build and review tasks" (activeForm: "Implementing tasks")
5. "Documentation — Update project docs" (activeForm: "Updating documentation")
6. "Deep Review — Final quality and security audit" (activeForm: "Running deep review")
7. "Final Gate — User approval" (activeForm: "Awaiting user approval")

Mark each task as `in_progress` when starting that stage and `completed` when done.

**Task progress:** Do NOT create task list entries for individual tasks or their reviews. Instead, the orchestrator displays a **progress table** in the conversation after each task completes or changes status. Use this format:

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
- **Wave**: Derived from the dependency graph for display. Wave 1 = no dependencies, Wave 2 = depends on wave 1 tasks, etc. For visual grouping only — execution is driven by individual dependency resolution, not wave completion.
- **Deps**: Which tasks this one depends on (from the plan). "—" for no dependencies.
- Status icons: ⏳ blocked (deps not met), 🔄 in progress, ✅ done, ❌ failed

Update and re-display this table each time a task or review completes. **Important:** Always output a short text message (even just the updated table) between background agent completions — do not stay silent while agents are running. If multiple agents are running in the background and one completes, acknowledge it and re-display the table immediately. This keeps the user's status line active and visible.

## Configuration

Before starting the pipeline, check if `.claude/devline.local.md` exists in the project root and read its YAML frontmatter for pipeline settings. The following settings control approval gates:

- **`auto_approve_brainstorm`** (default: `false`) — When `true`, skip the approval gate after brainstorm and proceed directly to planning. When `false` (default), stop and wait for explicit user approval.
- **`auto_approve_plan`** (default: `false`) — When `true`, skip the approval gate after planning and proceed directly to implementation. When `false` (default), stop and wait for explicit user approval.

## Pipeline Stages

Execute these stages in order:

### Stage 0: Branch Setup (Automatic)
Before any code is written, ensure the project is on a feature branch:
1. Check if `.claude/devline.local.md` exists and read the branching strategy settings (`branch_format`, `branch_kinds`, `protected_branches`)
2. Check the current git branch
3. If on a protected branch (default: main, master, develop, release, production, staging — customizable via `protected_branches`):
   - Create a feature branch using the configured `branch_format` (default: `{kind}/{title}`, e.g., `feat/add-user-auth`, `fix/login-timeout`)
   - Use a branch kind from `branch_kinds` that matches the work (default: feat, fix, refactor, docs, chore, test, ci)
4. If already on a feature branch, continue

The `.devline/` directory is created for pipeline artifacts (plan, reviews). Add `.devline/` to `.gitignore` if not already present.

5. **Stale plan check:** If `.devline/plan.md` already exists, read its `**Branch:**` header. If it references a different branch or the `**Status:**` is `completed`, delete it and inform the user that a stale plan was cleaned up. If it references the current branch and status is `active`, ask the user whether to resume the existing plan or start fresh.

### Stage 1: Brainstorm (Interactive — runs in main context)

#### 1. Understand the Idea
Read the user's input. Launch parallel background agents to explore the codebase  for context: tech stack, existing patterns, relevant code to build on and to gather information about what the user wants to achieve and how to best achieve that. Every agent returns a concise summary of its findings to the conversation. Use these summaries to build your understanding of the user's intent and the codebase context.

#### 2. Clarify with Structured Questions
Use **AskUserQuestion** with concrete selectable options — avoid open-ended text questions unless necessary.

- Ask **1-4 questions per AskUserQuestion call**
- **Scale questions to ambiguity:** A clear, specific idea needs only 1-2 questions on genuinely open decisions. A vague idea needs more. Don't ask about things with obvious answers or industry-standard defaults — just state your assumption in the summary.
- Every question MUST have **2-4 concrete options** with labels and descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive (e.g., "which platforms?")
- Use `multiSelect: false` for single-choice decisions (e.g., "what visual tone?")
- If the idea is already clear enough, skip questions entirely
- Add a recommended option first with "(Recommended)" in the label when there's a clear best choice and explain them briefly
- **Always ask about platform** when the feature involves a UI — never assume

#### 3. Summarize Understanding
After receiving answers, write a brief **in-conversation summary** (NOT a file) that captures:
- What we're building
- Key decisions made
- Scope boundaries
- Aesthetic direction (if UI is involved)
- Any assumptions made and decisions you made without asking

**Do NOT write any files, documents, or specs.** The planner agent will read the full conversation context.

**Approval gate:** Unless `auto_approve_brainstorm` is `true` in `.claude/devline.local.md`, stop here and present the brainstorm summary to the user with an explicit approval question:

```json
{
  "question": "Brainstorm complete. Approve this feature spec to proceed to planning?",
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

- If the user selects "Needs changes", loop back to adjust the summary and re-confirm.
- If the user selects "Stop here", end the pipeline gracefully.
- If the user selects "Other", read their free-text input and follow their instruction
- Only proceed to Stage 1.5 (if UI impact) or Stage 2 on explicit approval or an "Other" instruction that implies approval.

### Stage 1.5: Design System (Automatic — background, conditional)

**Trigger:** Run this stage if the brainstorm summary indicates UI components will be created, changed, or redesigned. Look for mentions of: UI, frontend, components, screens, views, pages, forms, dashboards, layouts, modals, navigation, or any visual/interactive elements.

**Skip** this stage entirely if the feature is purely backend, API, infrastructure, or tooling with no user-facing UI.

Launch the **frontend-planner** agent in the **background**. It will:
- Analyze the feature spec to determine product type, platform, and aesthetic direction
- Search the design intelligence database (67 styles, 161 palettes, 57 font pairings, 161 industry rules) using BM25 ranking
- Check for existing design systems in the project
- Write a design system recommendation to `.devline/design-system.md`

**Wait for completion before proceeding to Stage 2.** The planner needs the design system as input.

When complete, briefly inform the user: "Design system generated — [style direction] with [color mood] palette. Full details at `.devline/design-system.md`." Do not ask for approval — this is an automatic stage. The user can review and override during planning.

### Stage 2: Plan (Interactive — foreground with resume loop)
Launch the **planner** agent in the **foreground**. The planner will:
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
- If the user selects "Stop here", end the pipeline gracefully.
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
- **Feature goal verification** — verify the actual goals of the plan were achieved end-to-end. Not just that implementers wrote passing tests, but that the feature actually works as intended. This is the most important check — green unit tests mean nothing if the feature doesn't function.
- Quality verdict with severity-classified findings

The deep review classifies every finding as either **minor** (style, small quality issues, minor tech debt) or **major/critical** (security, correctness bugs, regressions, unmet feature goals, broken functionality).

**Handling findings by severity:**

**Minor findings only (no major/critical):**
Launch a single **implementer** agent with all minor findings. After the implementer fixes them, launch a normal **reviewer** to verify the fixes. Once the reviewer returns CLEAN, proceed to Complete. This is the fast path — minor issues don't warrant a full deep review re-run.

**Major or critical findings — escalation ladder:**

1. **Attempt 1 — implementer fixes**: Launch **implementer** agents for the major findings (one per affected task, matched by file ownership), followed by a reviewer, that can verify the fixes or provide additional feedback to restart the implementer. After all fixes, re-run the full **deep review**.
2. **Attempt 2 — debugger investigates**: If the deep review still has major findings, launch the **debugger** agent (foreground). The debugger investigates root causes. Present the plan for approval. On approval, launch implementers for the debugger's tasks → normal review cycle → re-run deep review.
3. **Attempt 3 — planner replans**: If major findings persist, launch the **planner** agent (foreground) to re-examine the failing area and produce a fundamentally different implementation approach. Present the new plan for approval. On approval, **restart from Stage 3** with the new plan → implement → review → deep review.
4. **After replanned pipeline still has major findings at deep review**: The pipeline has exhausted all escalation options. **Stop and ask the user for guidance.** Present all remaining findings and the history of fix attempts.

### Complete
When deep review approves with no findings:
1. **Mark the plan as completed:** Update `.devline/plan.md` — change `**Status:** active` to `**Status:** completed`. This prevents accidental reuse by implementers in future conversations.
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

- **"I found a mistake / want to add something / fix a bug"**: Ask the user to describe the issue using AskUserQuestion (free-text).
  For any non-trivial issue, **reset the pipeline back to Stage 2 (Plan)**.
  Choose which agent runs Stage 2 based on the nature of the issue:
  - **Debugger as planner** — for runtime bugs, crashes, errors, wrong output, things that "don't work" with observable symptoms. The debugger investigates root causes, then writes a fix plan to `.devline/plan.md`.
  - **Planner** — for everything else: missing features, UI issues, behavioral changes, new requirements, "this should also do X." The planner analyzes the issue and writes updated tasks to `.devline/plan.md`.

  **When resetting the pipeline**, use TaskUpdate to mark all stages from Stage 2 onward as not completed (set status back to `pending`): Plan, Implement, Documentation, Deep Review, Final Gate. This makes it visually clear to the user that the pipeline is running through those stages again.

  After Stage 2 completes and the plan is approved, the full pipeline continues: Stage 3 (implement) → Stage 3 review loop → Stage 4 (docs) → Stage 5 (deep review) → back to Complete. The pipeline only ends when the user selects an exit or commit option.

- **"Exit"**: Delete `.devline/plan.md` and end the pipeline.

- **"Commit and exit"**: Stage and commit all changes on the feature branch (follow the standard git commit protocol — review changes, draft message, create commit). Then delete `.devline/plan.md` and end the pipeline.

- **"Merge to main and exit"**: Stage and commit all changes on the feature branch. Then:
  1. Draft a squash merge commit message summarizing the entire feature (not individual commits). Present it to the user via AskUserQuestion with the draft as context and options to approve, edit, or provide their own message.
  2. Squash merge into main: `git checkout main && git merge --squash <branch> && git commit -m "<approved message>"`.
  3. Delete `.devline/plan.md` and end the pipeline.
  **Before merging, confirm the target branch with the user if it's not obvious.**

## Error Recovery

All fix loops are driven by the orchestrator — subagents return findings, the orchestrator launches the next agent. **Every finding from every review gets fixed — there is no "pass with warnings."**

**Per-task review escalation (Stage 3):**
1. **Attempt 1**: reviewer returns HAS_FINDINGS → implementer fixes (with plan context + findings) → re-review
2. **Attempt 2**: still HAS_FINDINGS → implementer fixes again (with all prior context) → re-review
3. **Attempt 3 (escalate to planner)**: still HAS_FINDINGS → relaunch **planner** with the original task, all findings, and all fix attempts. The planner rewrites the task with a new implementation approach. Launch implementer with the new task → review → same cycle.

**Deep review escalation (Stage 5) — severity-based:**
- **Minor findings**: single implementer → normal reviewer → done (no deep review re-run)
- **Major/critical findings**: implementer → deep review → debugger → deep review → planner (full replan) → restart pipeline → if still failing at deep review, ask user

**User-reported issues at Complete stage — ALL reset to Stage 2:**
- **Runtime bugs** (crashes, errors, wrong output) → Stage 2 with **debugger as planner** → Stage 3 → review → deep review → Complete
- **Everything else** (missing features, UI issues, new requirements) → Stage 2 with **planner** → Stage 3 → review → deep review → Complete
- The pipeline only ends when the user selects Exit, Commit and exit, or Commit, merge, and exit.

**General:**
- **Test failures during implementation**: implementer handles first; if stuck after 3 attempts, escalate to planner
- **All agents**: if stuck, ask the user for guidance rather than looping forever
