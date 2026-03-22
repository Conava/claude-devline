---
name: implement
description: Implement tasks using TDD. Accepts a plan or specific task description. Runs implementer agents in parallel where possible.
argument-hint: "<plan or task description>"
user-invocable: true
disable-model-invocation: false
---

# Implement — TDD Implementation

Launch **implementer** agents to execute tasks using test-driven development.

## Progress Tracking

**IMPORTANT:** Create a task list at the start to track progress:

1. Create one task per plan task (e.g., "Implement: Auth module") — these are the primary tasks
2. Create "Review implementations" and "Update documentation" tasks, both with `addBlockedBy` pointing to all implementation task IDs so they appear after implementation in the list
3. Mark each task `in_progress` when starting and `completed` when done
4. If a task fails review, create a fix task with `addBlockedBy` pointing to the review task that flagged it

## With a Plan (Multiple Tasks)
If the user provides or references a plan with tasks:
1. **Validate the plan first:** Read `.devline/plan.md` and check the `**Branch:**` and `**Status:**` headers. If the branch doesn't match the current git branch or the status is `completed`, warn the user and ask whether to proceed — do not silently implement a stale plan.
2. Parse the tasks and their dependency graph
3. Launch implementer agents for all tasks that can run in parallel, each with `isolation: "worktree"` to prevent race conditions between parallel agents. **Exception:** if `pwd` contains `.claude/worktrees/`, you are inside a worktree — do NOT nest worktrees. Launch implementers **sequentially without isolation** instead (they commit directly to the current branch, skip merge-back).
4. When each worktree agent completes: **always use `git merge`** to bring changes back — NEVER `cp`/`rsync`/file copy. Merge the worktree branch (`git merge <branch> --no-edit`), confirm success, THEN clean up (`git worktree remove <path> --force && git branch -d <branch>`). Run merge and cleanup as **separate foreground commands** — never chain them with `&&` and never use `run_in_background`.
5. Wait for dependent tasks to complete before launching their dependents
6. Each implementer follows strict TDD: write tests → implement → verify

## Without a Plan (Single Task)
If the user provides a single task description:
1. Launch one implementer agent with the task
2. The implementer will write tests first, then implement

## After Implementation
For each completed task:
1. Launch the **reviewer** agent to review the implementation
2. On FAIL: send feedback to implementer for retry (max 2 retries)
3. If still failing: launch **debugger** agent for root cause analysis
4. On PASS: mark task complete

After all tasks pass review, launch the **docs-keeper** agent to update documentation.


