---
name: devline
description: Start the full development pipeline from a rough idea. Runs interactively through brainstorm and planning, then autonomously through implementation, review, and documentation. This is the default pipeline for all development work unless otherwise specified. Apply to every software development task that benefits from a structured, comprehensive approach.
argument-hint: "<feature idea>"
user-invocable: true
disable-model-invocation: false
---

# Devline — Full Development Pipeline

Orchestrate the complete development lifecycle from rough idea to merge-ready code.

## Progress Tracking

**IMPORTANT:** Before starting any work, create a task list to track pipeline progress. This gives the user a clear overview of where they are in the pipeline.

Create these tasks immediately at the start using TaskCreate:

1. "Brainstorm — Refine idea into feature spec" (activeForm: "Brainstorming feature idea")
2. "Plan — Design architecture and work packages" (activeForm: "Planning implementation")
3. "Review — In-depth code review" (activeForm: "Reviewing implementation")
4. "Documentation — Update project docs" (activeForm: "Updating documentation")
5. "PR Review — Final merge-readiness check" (activeForm: "Running final PR review")
6. "Complete — Summary and next steps" (activeForm: "Wrapping up")

Mark each task as `in_progress` when starting that stage and `completed` when done.

**Work package tasks:** Do NOT create a generic "Implement" task. Instead, when the plan is approved (end of Stage 2), create one task per work package (e.g., "Implement: Auth module", "Implement: API routes") and insert them between "Plan" and "Review" using dependencies:
- Each work package task: `addBlockedBy: [plan-task-id]`
- The "Review" task: `addBlockedBy: [all work-package-task-ids]`

This keeps work packages visible as first-class items in the task list, positioned right where implementation happens in the pipeline.

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

### Stage 1: Brainstorm (Interactive — runs in main context)
Follow the **brainstorming** skill directly (do NOT launch an agent — this must be interactive in the main conversation):
- Read the user's idea and briefly scan the codebase for context
- Use AskUserQuestion with structured selectable options (1-4 questions, skip if clear)
- Write a brief in-conversation summary of decisions — do NOT create any files
- Confirm with AskUserQuestion before proceeding to planning

Everything stays in conversation context — the planner agent will read the full conversation.

### Stage 2: Plan (Interactive — foreground with resume loop)
Launch the **planner** agent in the **foreground** (NOT background). The planner will:
- Analyze the codebase and design the architecture
- Challenge its own decisions aggressively
- Identify proactive improvements for all touched code
- Break work into parallel-safe packages (file-based isolation)
- Define TDD test cases per package
- Use context7 MCP to research libraries and best practices

**Question-answer loop:** The planner cannot ask the user directly (AskUserQuestion doesn't work in subagents). Instead it may return a `STATUS: NEEDS_INPUT` response with structured design questions. When this happens:
1. Present the questions to the user using **AskUserQuestion** — map each design question to an option set with the planner's recommendation marked "(Recommended)" and its alternatives as additional options
2. **Resume** the planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the planner returns more questions

Once the planner has all answers, it will:
- **Write the full plan to `.devline/plan.md`** — this is the single source of truth
- Return a concise summary to conversation (architecture overview, work package list, key decisions)

Present the summary to the user for approval. The user can read the full plan at `.devline/plan.md` if they want details.

### Stage 3: Implement (Autonomous — background)
Once the plan is approved, launch agents **in the background** (`run_in_background: true`) for work packages that can run in parallel:
- Use **implementer** agents for feature/application work packages
- Use **devops** agent for build, CI/CD, Docker, infrastructure, and tooling work packages
- Each agent reads the plan from `.devline/plan.md` to find its assigned work package
- The planner's **Agent** field on each work package indicates which agent to use
- Each follows strict TDD: red → green → refactor
- Multiple agents run simultaneously on independent packages
- Sequential packages wait for dependencies

Run agents using `isolation: "worktree"` when working on packages that touch different areas of the codebase, or sequentially when file isolation is sufficient.

### Stage 4: Review (Autonomous — background, orchestrator-driven fix loop)
After each work package is implemented, launch the **reviewer** agent in the background:
- Reviews correctness, security, performance, quality
- On **PASS**: proceed to next stage
- On **FAIL**: the reviewer returns a list of issues with file:line references and fix suggestions. The orchestrator then:
  1. Launches an **implementer** agent with the issue list to fix the problems
  2. Re-launches the **reviewer** on the fixed code
  3. Repeats up to 2 cycles. If still failing, escalates to the **debugger** agent
  4. If the debugger also fails, pause and ask the user for guidance

### Stage 5: Documentation (Autonomous — background)
After all work packages pass review, launch the **docs-keeper** agent in the background:
- Updates README, API docs, architecture docs
- Creates new documentation for new features
- Only handles separate doc files (inline docs were handled by implementer)

### Stage 6: PR Review (Autonomous — background, Final Gate)
Launch the **pr-deep-review** agent in the background for the final comprehensive review:
- Security audit and credential scanning
- Code quality and technical debt assessment
- Convention adherence check
- Plan compliance verification (every acceptance criterion met)
- Merge readiness verdict

Check `.claude/devline.local.md` for `pr_review_strictness` setting.

**On CHANGES REQUIRED — the orchestrator reads the deep review verdict and escalates:**
- **Minor issues**: launch an **implementer** with the issue list, then re-run the **pr-deep-review**
- **Major issues**: launch the **planner** (foreground, with resume loop) to re-plan the affected work, then flow back through implementation → review → deep review

### Stage 7: Complete
When deep review approves, report completion:
- Summary of what was built
- Files created/modified
- Test results
- Any notes or follow-ups

## Frontend Auto-Detection
If any implementer modifies UI files (detected via PostToolUse hook), the **frontend-reviewer** agent is triggered automatically. Incorporate its feedback into the implementation.

## Error Recovery

All fix loops are driven by the orchestrator — subagents return findings, the orchestrator launches the next agent.

- **Reviewer FAIL**: reviewer returns issues → orchestrator launches implementer → re-runs reviewer (up to 2 cycles) → debugger → user
- **Deep review minor**: deep review returns issues → orchestrator launches implementer → re-runs deep review
- **Deep review major**: deep review flags architectural issues → orchestrator launches planner (foreground) → re-plans → implementation → review → deep review
- **Test failures**: debugger agent investigates
- **All agents**: if stuck, ask the user for guidance rather than looping forever
