---
name: devline
description: Start the full development pipeline from a rough idea. Runs interactively through brainstorm and planning, then autonomously through implementation, review, and documentation. This is the default pipeline for all development work unless otherwise specified. Apply to every software development task that benefits from a structured, comprehensive approach.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

Orchestrate the complete development lifecycle from rough idea to merge-ready code.

## CRITICAL: Orchestrator Role

**You are an ORCHESTRATOR, not an implementer.** You MUST NOT edit, fix, or modify any source code yourself — not even to address reviewer warnings, test failures, or minor issues. ALL code changes must be delegated to the appropriate agent (implementer, devops, debugger). Your job is to coordinate agents, present results to the user, and manage the pipeline flow.

## Progress Tracking

**IMPORTANT:** Before starting any work, create a task list to track the main pipeline stages. This gives the user a clear overview of where they are.

Create these tasks immediately at the start using TaskCreate:

1. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea")
2. "Plan — Design architecture and work packages" (activeForm: "Planning implementation")
3. "Implement — Build and review work packages" (activeForm: "Implementing work packages")
4. "Documentation — Update project docs" (activeForm: "Updating documentation")
5. "Deep Review — Final quality and security audit" (activeForm: "Running deep review")
6. "Final Gate — User approval" (activeForm: "Awaiting user approval")

Mark each task as `in_progress` when starting that stage and `completed` when done.

**Work package progress:** Do NOT create task list entries for individual work packages or their reviews. Instead, the orchestrator displays a **progress table** in the conversation after each work package completes or changes status. Use this format:

```
## Implementation Progress

| # | Group | Work Package       | Implement | Review     | Status   |
|---|-------|--------------------|-----------|------------|----------|
| 1 | 1     | Auth module        | ✅        | ✅         | Done     |
| 2 | 1     | Database layer     | ✅        | 🔄 Fix #1 | Fixing   |
| 3 | 2     | API routes         | 🔄        |            | Building |
| 4 | 2     | Frontend views     | 🔄        |            | Building |
| 5 | 3     | Integration tests  | ⏳        |            | Waiting  |
```

- **#**: Task number — one per implementer agent, sequential
- **Group**: Parallel execution group — derived from the plan's dependency graph. Group 1 = all packages with no dependencies (run first, in parallel). Group 2 = packages that depend on Group 1 (run next, in parallel). Group 3 = depends on Group 2, etc. Order the table by group, then by task number within each group.
- Status icons: ⏳ waiting, 🔄 in progress, ✅ done, ❌ failed

Update and re-display this table each time a work package or review completes. **Important:** Always output a short text message (even just the updated table) between background agent completions — do not stay silent while agents are running. If multiple agents are running in the background and one completes, acknowledge it and re-display the table immediately. This keeps the user's status line active and visible.

## Configuration

Before starting the pipeline, check if `.claude/devline.local.md` exists in the project root and read its YAML frontmatter for pipeline settings. The following settings control approval gates:

- **`auto_approve_brainstorm`** (default: `false`) — When `true`, skip the approval gate after brainstorm and proceed directly to planning. When `false` (default), stop and wait for explicit user approval.
- **`auto_approve_plan`** (default: `false`) — When `true`, skip the approval gate after planning and proceed directly to implementation. When `false` (default), stop and wait for explicit user approval.

If the file does not exist or a setting is missing, treat it as `false` (approval required).

## Pipeline Stages

Execute these stages in order:

### Stage 0: Branch Setup (Automatic)
Before any code is written, ensure the project is on a feature branch:
1. Check if `.claude/devline.local.md` exists and read `branch_prefix` and `commit_format` overrides
2. Check the current git branch
3. If on a protected branch (main, master, develop, release, production, staging):
   - Create a feature branch using the convention `kind/descriptive-title` (e.g., `feat/add-user-auth`, `fix/login-timeout`)
   - Use the branch kind that matches the work: feat, fix, refactor, docs, chore, test, ci
   - If `branch_prefix` is set in `devline.local.md`, use that format instead
4. If already on a feature branch, continue

The `.devline/` directory is created for pipeline artifacts (plan, reviews). Add `.devline/` to `.gitignore` if not already present.

5. **Stale plan check:** If `.devline/plan.md` already exists, read its `**Branch:**` header. If it references a different branch or the `**Status:**` is `completed`, delete it and inform the user that a stale plan was cleaned up. If it references the current branch and status is `active`, ask the user whether to resume the existing plan or start fresh.

### Stage 1: Brainstorm (Interactive — runs in main context)
Follow the **brainstorming** skill directly (do NOT launch an agent — this must be interactive in the main conversation):
- Read the user's idea and briefly scan the codebase for context
- Use AskUserQuestion with structured selectable options (1-4 questions, skip if clear)
- Write a brief in-conversation summary of decisions — do NOT create any files
- Confirm with AskUserQuestion before proceeding

Everything stays in conversation context — the planner agent will read the full conversation.

**Approval gate:** Unless `auto_approve_brainstorm` is `true` in `.claude/devline.local.md`, stop here and present the brainstorm summary to the user with an explicit approval question:

```json
{
  "question": "Brainstorm complete. Approve this feature spec to proceed to planning?",
  "header": "Approve Brainstorm",
  "options": [
    {"label": "Approve — proceed to planning", "description": "The planner will design the architecture based on this spec"},
    {"label": "Needs changes", "description": "I want to revise something before planning begins"},
    {"label": "Stop here", "description": "End the pipeline, I only needed the brainstorm"}
  ],
  "multiSelect": false
}
```

- If the user selects "Needs changes", loop back to adjust the summary and re-confirm.
- If the user selects "Stop here", end the pipeline gracefully.
- Only proceed to Stage 2 on explicit approval.

### Stage 2: Plan (Interactive — foreground with resume loop)
Launch the **planner** agent in the **foreground** (NOT background). The planner will:
- Analyze the codebase and design the architecture
- Challenge its own decisions aggressively
- Identify proactive improvements for all touched code
- Break work into right-sized packages (file-isolated for parallel, sequenced for shared files)
- Define TDD test cases per package
- Use context7 MCP to research libraries and best practices

**Interactive loop:** The planner cannot ask the user directly (AskUserQuestion doesn't work in subagents). Instead it may return a `STATUS: NEEDS_INPUT` response containing any combination of:
- **Design Questions** — architectural or behavioral choices that need user input
- **Code Issues Found** — bugs, flaws, or tech debt discovered in the blast radius that the user should decide whether to fix
- **Proactive Improvements** — enhancements the planner wants to include in the plan for the user to approve or reject

When this happens:
1. Present ALL sections to the user using **AskUserQuestion** — for design questions, map each to an option set with the planner's recommendation marked "(Recommended)" and its alternatives as additional options. For code issues and proactive improvements, present them as checklists the user can approve/reject.
2. **Resume** the planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the planner returns more questions or findings — the planner is encouraged to iterate multiple times to refine the plan to a high standard

Once the planner has all answers, it will:
- **Write the full plan to `.devline/plan.md`** — this is the single source of truth
- Return a concise summary to conversation (architecture overview, work package list, key decisions)

**Approval gate:** Unless `auto_approve_plan` is `true` in `.claude/devline.local.md`, stop here and present the plan summary to the user with an explicit approval question:

```json
{
  "question": "Plan complete — the full plan is at .devline/plan.md. Approve to start implementation?",
  "header": "Approve Plan",
  "options": [
    {"label": "Approve — start implementation", "description": "Launch implementer agents for all work packages"},
    {"label": "Needs changes", "description": "I want to revise the plan before implementation"},
    {"label": "Stop here", "description": "End the pipeline, I only needed the plan"}
  ],
  "multiSelect": false
}
```

- If the user selects "Needs changes", resume the planner agent with the user's feedback to revise the plan.
- If the user selects "Stop here", end the pipeline gracefully.
- Only proceed to Stage 3 on explicit approval.

### Stage 3: Implement (Autonomous — background, includes per-package review)
Once the plan is approved, launch agents **in the background** (`run_in_background: true`) for work packages that can run in parallel:
- Use **implementer** agents for feature/application work packages
- Use **devops** agent for build, CI/CD, Docker, infrastructure, and tooling work packages
- Each agent reads the plan from `.devline/plan.md` to find its assigned work package
- The planner's **Agent** field on each work package indicates which agent to use
- Each follows strict TDD: red → green → refactor
- Multiple agents run simultaneously on independent packages
- Sequential packages wait for dependencies

Run agents using `isolation: "worktree"` when working on parallel packages that touch different areas of the codebase. For sequential packages that share files, run them in order on the same branch — each builds on the previous one's changes.

**Per-package review loop:** After each work package is implemented, immediately launch the **reviewer** agent in the background for that package. The reviewer returns either **CLEAN** (zero findings) or **HAS_FINDINGS** (list of issues). **ALL findings — regardless of severity — must be sent back to an implementer for fixing.** There is no "pass with warnings."

The fix cycle works as follows:

1. **Reviewer returns CLEAN**: mark the package as done in the progress table
2. **Reviewer returns HAS_FINDINGS**: launch an **implementer** agent with:
   - The original work package from the plan (so it has full context of what was being built)
   - The complete list of reviewer findings with file:line references and fix suggestions
   - Instruction to fix ALL findings, not just critical ones
3. After the implementer fixes the findings, re-launch the **reviewer** on the fixed code
4. **If the reviewer returns HAS_FINDINGS again (attempt 2)**: launch another **implementer** with the new findings plus context from both previous attempts
5. **If the reviewer returns HAS_FINDINGS a third time (attempt 3 — escalate to debugger)**: the implementer has failed to resolve the issues. **The debugger replaces the planner** — it investigates the root causes and writes a new fix plan to `.devline/plan.md`. Launch the **debugger** agent (foreground, like the planner) with:
   - The original work package from the plan
   - All reviewer findings from all attempts
   - All implementer fix attempts and what they changed
6. The debugger returns a fix plan summary. Present it for approval (same flow as Stage 2 plan approval).
7. On approval, **restart the pipeline from Stage 3** using the debugger's plan — launch implementers for the debugger's work packages → reviewers → same fix cycle
8. **If the debugger's plan also fails after the full escalation ladder**: pause the pipeline and ask the user for guidance

Update and display the progress table after each status change. The "Implement" pipeline task stays `in_progress` until ALL work packages have a CLEAN review.

### Stage 4: Documentation (Autonomous — background)
After all work packages pass review, launch the **docs-keeper** agent in the background:
- Updates README, API docs, architecture docs
- Creates new documentation for new features
- Only handles separate doc files (inline docs were handled by implementer)

### Stage 5: Deep Review (Autonomous — background, Final Gate)
Launch the **deep-review** agent in the background for the final comprehensive review:
- Security audit and credential scanning
- Code quality and technical debt assessment
- Convention adherence check
- Plan compliance verification (every acceptance criterion met)
- Quality verdict

Check `.claude/devline.local.md` for `pr_review_strictness` setting.

**On HAS_FINDINGS — ALL findings get sent to an implementer for fixing.** The same escalation ladder applies as in per-package review:

1. **Deep review returns APPROVED**: proceed to Complete
2. **Deep review returns HAS_FINDINGS**: launch an **implementer** with:
   - The relevant work package(s) from the plan that the findings relate to (match findings to packages by file ownership)
   - The complete list of deep review findings with file:line references and fix suggestions
3. After fixes, re-launch the **deep-review**
4. **If HAS_FINDINGS persists after 2 implementer attempts**: escalate to the **debugger** (foreground). The debugger investigates root causes and writes a fix plan to `.devline/plan.md`. Present the plan for approval, then restart from Stage 3 with the debugger's plan.
5. **If the debugger's plan also fails**: pause and ask the user for guidance

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
    {"label": "Exit", "description": "Delete plan and end the pipeline"},
    {"label": "Commit and exit", "description": "Commit the feature, delete plan, and end the pipeline"},
    {"label": "Commit, merge to main, and exit", "description": "Commit the feature, merge to main, delete plan, and end the pipeline"}
  ],
  "multiSelect": false
}
```

**Handling each option:**

- **"I found a mistake / want to add something / fix a bug"**: Ask the user to describe the issue using AskUserQuestion (free-text). Then **reset the pipeline back to Stage 2 (Plan)**. Every user-reported finding — no matter how small — goes through proper planning before implementation.

  Choose which agent runs Stage 2 based on the nature of the issue:
  - **Debugger as planner** — for runtime bugs, crashes, errors, wrong output, things that "don't work" with observable symptoms. The debugger investigates root causes, then writes a fix plan to `.devline/plan.md`.
  - **Planner** — for everything else: missing features, UI issues, behavioral changes, new requirements, "this should also do X." The planner analyzes the issue and writes updated work packages to `.devline/plan.md`.

  **When resetting the pipeline**, use TaskUpdate to mark all stages from Stage 2 onward as not completed (set status back to `pending`): Plan, Implement, Documentation, Deep Review, Final Gate. This makes it visually clear to the user that the pipeline is running through those stages again.

  After Stage 2 completes and the plan is approved, the full pipeline continues: Stage 3 (implement) → Stage 3 review loop → Stage 4 (docs) → Stage 5 (deep review) → back to Complete. The pipeline only ends when the user selects an exit or commit option.

- **"Exit"**: Delete `.devline/plan.md` and end the pipeline.

- **"Commit and exit"**: Stage and commit all changes on the feature branch (follow the standard git commit protocol — review changes, draft message, create commit). Then delete `.devline/plan.md` and end the pipeline.

- **"Commit, merge to main, and exit"**: Stage and commit all changes on the feature branch. Then:
  1. Draft a squash merge commit message summarizing the entire feature (not individual commits). Present it to the user via AskUserQuestion with the draft as context and options to approve, edit, or provide their own message.
  2. Squash merge into main: `git checkout main && git merge --squash <branch> && git commit -m "<approved message>"`.
  3. Delete `.devline/plan.md` and end the pipeline.
  **Before merging, confirm the target branch with the user if it's not obvious.**

## Frontend Auto-Detection
If any implementer modifies UI files (detected via PostToolUse hook), the **frontend-reviewer** agent is triggered automatically. Incorporate its feedback into the implementation.

## Error Recovery

All fix loops are driven by the orchestrator — subagents return findings, the orchestrator launches the next agent. **Every finding from every review gets fixed — there is no "pass with warnings."**

**Escalation ladder (same for per-package review and deep review):**
1. **Attempt 1**: reviewer/deep-review returns HAS_FINDINGS → implementer fixes (with plan context + findings) → re-review
2. **Attempt 2**: still HAS_FINDINGS → implementer fixes again (with all prior context) → re-review
3. **Attempt 3 (escalate to debugger-as-planner)**: still HAS_FINDINGS → **debugger replaces planner**. The debugger:
   - Receives: original work package, all findings from all attempts, all implementer fix attempts
   - Investigates root causes (does NOT fix code itself)
   - Writes a fix plan to `.devline/plan.md` (same format as planner)
   - Returns summary for approval
   - On approval, pipeline restarts from Stage 3: implementers execute the debugger's plan → reviewers review → same escalation ladder
4. **After debugger's plan fails**: pause and ask the user for guidance

**User-reported issues at Complete stage — ALL reset to Stage 2:**
- **Runtime bugs** (crashes, errors, wrong output) → Stage 2 with **debugger as planner** → Stage 3 → review → deep review → Complete
- **Everything else** (missing features, UI issues, new requirements) → Stage 2 with **planner** → Stage 3 → review → deep review → Complete
- The pipeline only ends when the user selects Exit, Commit and exit, or Commit, merge, and exit.

**General:**
- **Test failures during implementation**: implementer handles first; if stuck after 3 attempts, escalate to debugger-as-planner
- **All agents**: if stuck, ask the user for guidance rather than looping forever
