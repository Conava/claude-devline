# Implementation Protocol — Stage 3

## Plan File

In single-phase mode, this stage reads `.devline/plan.md`. In multi-phase mode, it reads `.devline/plan-phase-N.md` for the current phase. All references to "the plan" below apply to whichever file is active.

## Initialization

Create `.devline/state.md` and `.devline/deferred-findings.md` (if they don't already exist from a prior phase) with all tasks in their initial state (blocked or ready). In multi-phase mode, reset the task progress table for the new phase's tasks. Update state files after **every status change**.

## Execution Model — Wave-Based (STRICT)

Execution proceeds in **waves** as defined in the `## Dependency Graph` section of the active plan file — the single source of truth for task ordering. Tasks within a wave run in parallel; waves run sequentially.

**⚠️ WAVE BARRIER: You MUST complete an entire wave (all tasks implemented + reviewed + merged) before launching ANY task from the next wave. Never launch multiple waves simultaneously. Never rationalize launching the next wave early because "the tasks are independent" or "migrations are already done."**

**Wave barrier validation (mandatory before launching any wave):** Before launching tasks for Wave N (where N > 1), read `.devline/state.md` and verify that EVERY task from waves 1 through N-1 has status `done`. If any prior-wave task is not `done`, do NOT launch Wave N — wait for the incomplete tasks to finish first. This is a programmatic check, not a judgment call.

1. Launch all Wave 1 tasks in parallel (background, worktree isolation — see `references/worktree-protocol.md`)
2. As each task completes: squash-merge its worktree branch (`git merge --squash` + `git commit -m "task-N: <desc>"`), launch reviewer
3. **Wait until ALL Wave 1 tasks are done** (implemented + reviewed + merged). Do NOT launch any Wave 2 task early, even if its specific dependencies are met.
4. Run the wave barrier validation, then launch all tasks in the next wave. Repeat.

**One task = one agent.** Never assign multiple tasks to a single agent — not "complete 2.6 + 2.7 + 2.9," not "fix tasks 3 and 4," not "handle the remaining gaps." Each agent gets exactly one task from the plan, implements it, and stops. If three tasks need doing, launch three agents. Never split one task across multiple agents either.

## Agent and Model Selection

- **implementer** for feature/application tasks
- **devops** for build, CI/CD, Docker, infrastructure, tooling tasks
- **debugger** for fixing failing tests or unexpected behavior
- The plan's **Agent** and **Model** fields indicate which to use. Pass the model to the Agent tool's `model` parameter.

## Mandatory Review

**Every task gets a reviewer agent.** The merge-review sequence is atomic: merge → launch reviewer → wait for verdict. A task is NOT done until the reviewer returns CLEAN or DEFERRED_ONLY. No exceptions — not for "trivial" tasks, not for DDL-only changes, not for config changes, not for enum additions. The orchestrator does NOT review code itself. Reading files and grepping to "verify" is not a review. Only a reviewer agent verdict (CLEAN / HAS_BLOCKING / DEFERRED_ONLY) can mark a task's Review column as ✅. If you find yourself writing "no review needed" or "clean implementation, task done" without having launched a reviewer — you are violating the pipeline.

## Per-Task Review Loop

Reviewer returns one of:
- **CLEAN** — mark done, check for newly unblocked tasks
- **DEFERRED_ONLY** — append findings to deferred file, mark done, check for newly unblocked tasks
- **HAS_BLOCKING** — append any deferrable findings, write blocking findings to `.devline/fix-task-{N}.md`, launch implementer to fix

Fix cycle escalation:
1. **Attempt 1-2:** implementer fixes → reviewer re-reviews
2. **Attempt 3:** escalate to **planner** (foreground) with all findings and attempts — it rewrites the task approach

## Runtime Dependency Discovery

If an implementer reports that it cannot compile because types from another task don't exist yet, this is a missing dependency. Update the active plan file to add the dependency, update `.devline/state.md` to mark the task as `blocked`, and requeue it to launch after the dependency task completes and merges back. Merge whatever partial work the implementer committed (it may have completed non-dependent parts of the task).

## Stage 3.5: Deferred Findings Batch Fix (after last wave of each phase)

After ALL waves are complete (every task implemented + reviewed + merged) for the current plan:

1. Check `.devline/deferred-findings.md` — if empty or all findings already marked `[FIXED]`, skip this step. In single-phase mode, proceed to Stage 4. In multi-phase mode, return to the multi-phase loop to advance to Phase N+1 (or proceed to Stage 4 if this was the final phase).
2. Launch one implementer with `.devline/deferred-findings.md` as its task. Instruct it to prefix each fixed finding with `[FIXED]` in the file as it works through them — this makes partial progress trackable if the agent gets stuck or is killed.
3. Launch reviewer to verify the batch fixes.
4. Only after the reviewer returns CLEAN or DEFERRED_ONLY (with zero remaining unfixed findings): in single-phase mode, proceed to Stage 4 (Documentation). In multi-phase mode, return to the multi-phase loop to advance to Phase N+1 (or proceed to Stage 4 if this was the final phase).

The deep review is the final quality gate — it cannot defer findings. All deferrable work must be resolved before it runs.

## Agent Health Monitoring

See `references/agent-health.md`. Key rule: hard kill at 45 minutes, salvage work, relaunch fresh.

## Orchestrator Scope — What You Do and Don't Do

The orchestrator's job is: launch agents, merge worktree branches, launch reviewers, track state, and communicate with the user. That's it.
- **DO:** run the pre-launch checklist (see `references/worktree-protocol.md`), squash-merge worktree branches (`git merge --squash` + `git commit`), clean up worktrees, launch reviewer after merge, update state.md, relaunch failed agents
- **DON'T:** The following are violations — if you catch yourself doing any of these, stop and launch the appropriate agent instead:
  - **Assign multiple tasks to one agent** — never "complete 2.6 + 2.7 + 2.9" or "fix the remaining gaps." One agent, one task.
  - **Investigate errors beyond one build** — run the build once to see what's broken. Do NOT run a second build, filter output, run individual tests, or read source files to diagnose. Launch a debugger.
  - **Multi-line code changes** — if the fix is more than one line, delegate it.
  - **Commit on behalf of agents** — if the agent didn't commit, it failed. Relaunch it.
  - **Batch-commit mixed agent work** — if multiple agents left uncommitted changes, do NOT `git add -A && git commit`. Stash the mess, relaunch agents one at a time.
  - **Use `git add -A` or `git add .`** — always stage specific files. Broad staging commits build caches and artifacts.
  - **Resolve merge conflicts** — no `checkout --ours`, no `checkout --theirs`, no editing conflict markers. Reset the squash-merge state (`git reset HEAD -- . && git checkout -- .` — note: `git merge --abort` does not work after `git merge --squash`), clean up the worktree, and relaunch the agent without isolation so it works against the current branch state (which now includes the conflicting task's code). A merge conflict between two same-wave tasks means the dependency graph has a shared-resource file overlap (usually translation files, global CSS, or route configs). After relaunching, flag this to the user so the plan can be corrected for future runs.
  - **Inspect diffs to extract/apply fixes** — if the worktree is on the wrong base, the agent's work is invalid. Clean up and relaunch.
  - **Run `git diff` to "check what the agent did"** — the reviewer does this, not you.
  - **Run tests to "verify" a merge** — the reviewer does this. Not you. Not "just a quick check." Launch the reviewer.
  - **Run non-isolated agents in parallel** — agents without worktree isolation write to the same directory. They MUST run one at a time: launch, wait for commit, then launch the next. See `references/worktree-protocol.md` for details.
  - **Skip reviews** — every task gets a reviewer, no exceptions. A task is not "done" until the reviewer returns a verdict. Do not rationalize skipping reviews for "trivial" tasks, "clean" implementations, or tasks that "obviously" work because tests passed during implementation.

## Bash Discipline

All Bash commands run in foreground. Only Agent tool uses `run_in_background`. Set `timeout: 120000` on git merge commands.
