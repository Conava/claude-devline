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

**Question-answer loop:** The planner cannot ask the user directly (AskUserQuestion doesn't work in subagents). Instead it may return a `STATUS: NEEDS_INPUT` response with structured design questions. When this happens:
1. Present the questions to the user using **AskUserQuestion** — map each design question to an option set with the planner's recommendation marked "(Recommended)" and its alternatives as additional options
2. **Resume** the planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the planner returns more questions

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

**Per-package review loop:** After each work package is implemented, immediately launch the **reviewer** agent in the background for that package:
- Reviews correctness, security, performance, quality
- On **PASS**: mark the package as done in the progress table
- On **FAIL**: the reviewer returns a list of issues with file:line references and fix suggestions. The orchestrator then:
  1. Launches an **implementer** agent with the issue list to fix the problems
  2. Re-launches the **reviewer** on the fixed code
  3. Repeats up to 2 cycles. If still failing, escalates to the **debugger** agent
  4. If the debugger also fails, pause and ask the user for guidance

Update and display the progress table after each status change. The "Implement" pipeline task stays `in_progress` until ALL work packages have passed review.

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

**On CHANGES REQUIRED — the orchestrator reads the deep review verdict and escalates:**
- **Minor issues**: launch an **implementer** with the issue list, then re-run the deep review
- **Major issues**: launch the **planner** (foreground, with resume loop) to re-plan the affected work, then flow back through implementation → review → deep review

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

- **"I found a mistake / want to add something / fix a bug"**: Ask the user to describe the issue using AskUserQuestion (free-text). Then triage:
  - **Small, contained fix** (typo, missing edge case, minor bug in a single file): launch an **implementer** agent directly with the fix description → reviewer → back to this Complete stage
  - **Behavioral change or new functionality**: route back to **Stage 2 (Plan)** — resume the planner with the new requirement so it can create an additional work package → implementation → review → deep review → back to Complete
  - **Architectural issue or cross-cutting concern**: route back to **Stage 2 (Plan)** with instructions to revise the architecture → full pipeline re-run from implementation
  - Use your judgment to pick the lightest-weight path that addresses the issue. When in doubt, ask the user which route they prefer.

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

All fix loops are driven by the orchestrator — subagents return findings, the orchestrator launches the next agent.

- **Per-package review FAIL**: reviewer returns issues → orchestrator launches implementer → re-runs reviewer (up to 2 cycles) → debugger → user
- **Deep review minor issues**: deep review returns issues → orchestrator launches implementer → re-runs deep review
- **Deep review major issues**: deep review flags architectural issues → orchestrator launches planner (foreground) → re-plans → implementation → review → deep review
- **Test failures**: debugger agent investigates
- **All agents**: if stuck, ask the user for guidance rather than looping forever
