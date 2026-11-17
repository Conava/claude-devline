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
2. As each task completes: merge it back per `references/worktree-protocol.md` (stop the agent first), append its `### Integration notes` to `.devline/integration-notes.md` under the task, launch reviewer
3. **Wait until ALL Wave 1 tasks are done** (implemented + reviewed + merged). Do NOT launch any Wave 2 task early, even if its specific dependencies are met.
4. Run the wave barrier validation, then launch all tasks in the next wave. Repeat.

**One task = one agent.** Never assign multiple tasks to a single agent — not "complete 2.6 + 2.7 + 2.9," not "fix tasks 3 and 4," not "handle the remaining gaps." Each agent gets exactly one task from the plan, implements it, and stops. If three tasks need doing, launch three agents. Never split one task across multiple agents either.

## Agent and Model Selection

- **implementer** for feature/application tasks, including build, CI/CD, Docker, infrastructure, and tooling
- **debugger** for fixing failing tests or unexpected behavior
- The plan's **Agent** and **Model** fields indicate which to use. Pass the model to the Agent tool's `model` parameter.

## Mandatory Review

**Every task gets a reviewer agent.** The merge-review sequence is atomic: merge → launch reviewer → wait for verdict. A task is NOT done until the reviewer returns CLEAN or DEFERRED_ONLY. No exceptions — not for "trivial" tasks, not for DDL-only changes, not for config changes, not for enum additions. The orchestrator does NOT review code itself. Reading files and grepping to "verify" is not a review. Only a reviewer agent verdict (CLEAN / HAS_BLOCKING / DEFERRED_ONLY) can mark a task's Review column as ✅. If you find yourself writing "no review needed" or "clean implementation, task done" without having launched a reviewer — you are violating the pipeline.

## Per-Task Review Loop

Reviewer returns one of:
- **CLEAN** — mark done, check for newly unblocked tasks
- **DEFERRED_ONLY** — append findings to deferred file, mark done, check for newly unblocked tasks
- **HAS_BLOCKING** — append any deferrable findings, write blocking findings to `.devline/fix-task-{N}.md`, launch implementer to fix

Specialist reviews: after per-task review is CLEAN or DEFERRED_ONLY, a task whose `**Reach:**` names categories also gets the matching `focus:` reviewer (`security scan` → `security`, `resource profiling` → `resources`, `optimization pass` → `optimization`, `best-practices review` → `best-practices`). Which categories pull in which stages is defined in `references/stages.md`. The task is done after the specialist verdicts too; their findings follow the same loop.

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

## Agent Briefs

The agent's own definition owns how it works and what it reports. A brief carries facts only:

- plan path and task name (for quick, the task text)
- base SHA the worktree was created from
- owned files, and files owned by other tasks in the same wave
- env files to symlink into the worktree
- scratch directory `<scratchpad>/task-N/`
- the build lock command from `references/worktree-protocol.md`
- integration notes from the tasks it depends on, copied from `.devline/integration-notes.md`
- the path of `.devline/tasks/N/partial.patch`, if a killed predecessor left one
- for a specialist review, `focus: <name>`

A brief never prescribes TDD steps, a report format or "report X and Y": the agent's own output format stands. Fix briefs (`fix-task-N.md`) for UI tasks also name the reduced-motion, no-JS and keyboard-focus paths to recheck.

A workaround added mid-wave (a shim, a changed helper, a renamed file) is sent to every running agent it affects.

## Merged-Tree Gates

After a wave's merges and before the final commit, the main session runs typecheck, build and the full suite once on the merged tree, through the build lock. Red: launch a debugger; do not run a second build or diagnose yourself. Record the results in `.devline/state.md`.

## Agent Health Monitoring

See `references/agent-health.md`. Key rule: hard kill at 45 minutes, salvage work, relaunch fresh.

## Orchestrator Discipline

The orchestrator launches agents, merges worktree branches, launches reviewers, tracks state and talks to the user.
- **DO:** run the pre-launch checklist and merge-back per `references/worktree-protocol.md`, run the merged-tree gates, launch reviewers after each merge, update state.md, relaunch failed agents
- **DON'T:** each of these is a violation; stop and launch the appropriate agent instead:
  - **Assign multiple tasks to one agent.** One agent, one task.
  - **Diagnose errors yourself.** A red gate goes to a debugger, not to a second build, filtered output, single tests or source reading.
  - **Make multi-line code changes.** More than one line: delegate.
  - **Commit for a worktree agent.** One that left no commit failed: relaunch it. Agents running in place never commit; the main session commits after review, once every launched agent has stopped.
  - **Commit while an agent may still be running.** Every agent is finished or stopped, and `git status --short` shows only the intended change, immediately before a commit. Run `git status --short` in the main checkout after each agent too.
  - **Batch-commit mixed agent work or use `git add -A` / `git add .`.** Stage specific files; stash mixed leftovers and relaunch agents one at a time.
  - **Resolve merge conflicts.** Follow the conflict step in `references/worktree-protocol.md` and flag the shared-resource overlap to the user so the plan can be corrected.
  - **Inspect diffs to extract or apply fixes.** If the worktree is on the wrong base, its work is invalid: clean up and relaunch.
  - **Run `git diff` to see what an agent did.** The reviewer does that.
  - **Review code yourself or skip reviews.** The reviewer reviews; the merged-tree gates are a separate, required check.
  - **Run non-isolated agents in parallel.** They run one at a time; see `references/worktree-protocol.md`.
  - **Publish an agent's claim unchecked.** A count or "this test does X" from a report is reproduced by a command in the main session before it enters a summary or PR body.

## Bash Discipline

All Bash commands run in foreground. Only Agent tool uses `run_in_background`. Set `timeout: 120000` on git merge commands.
