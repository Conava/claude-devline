---
name: implement
description: Implement tasks using TDD. Accepts a plan or specific task description. Runs implementer agents in parallel where possible.
argument-hint: "<plan or task description>"
user-invocable: true
disable-model-invocation: false
---

# Implement — Implementation Preset

Run preset `implement` from [stages.md](../devline/references/stages.md): implementers from an existing plan, per-task review, docs. Reach can add stages.

## Progress Tracking

**IMPORTANT:** Create a task list at the start to track progress:

1. Create one task per plan task (e.g., "Implement: Auth module") — these are the primary tasks
2. Create "Review implementations" and "Update documentation" tasks, both with `addBlockedBy` pointing to all implementation task IDs so they appear after implementation in the list
3. Mark each task `in_progress` when starting and `completed` when done
4. If a task fails review, create a fix task with `addBlockedBy` pointing to the review task that flagged it

## With a Plan (Multiple Tasks)
If the user provides or references a plan with tasks:

The plan file may be either `.devline/plan.md` (single-phase) or `.devline/plan-phase-N.md` (multi-phase, where N is the phase number). This skill accepts an optional plan file path parameter — when specified, use that path; when not specified, default to `.devline/plan.md`.

1. **Validate the plan first:** Read the plan file (`.devline/plan.md` or the specified `.devline/plan-phase-N.md`) and check the `**Branch:**` and `**Status:**` headers. If the branch doesn't match the current git branch or the status is `completed`, warn the user and ask whether to proceed — do not silently implement a stale plan.
2. Parse the tasks and their dependency graph
3. Run the tasks as `implementation-protocol.md` and `worktree-protocol.md` describe (links below): pre-launch checklist, parallel worktree agents or one at a time inside a worktree, briefs, merging, and merged-tree gates.
4. Wait for dependent tasks to complete before launching their dependents.

Rules live in [implementation-protocol.md](../devline/references/implementation-protocol.md) (`## Agent Briefs`, `## Merged-Tree Gates`) and [worktree-protocol.md](../devline/references/worktree-protocol.md). Implementers don't commit in place; the main session commits.

## Without a Plan (Single Task)
If the user provides a single task description:
1. Launch one implementer agent with a brief per `## Agent Briefs`, passing the task text

## After Implementation
For each completed task:
1. Launch the **reviewer** agent to review the implementation
2. On FAIL: send feedback to implementer for retry (max 2 retries)
3. If still failing: launch **debugger** agent for root cause analysis
4. On PASS: mark task complete

After all tasks pass review, launch the **docs-keeper** agent to update documentation.


