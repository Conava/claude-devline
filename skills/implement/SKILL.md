---
name: implement
description: Implement work packages using TDD. Accepts a plan or specific task description. Runs implementer agents in parallel where possible.
argument-hint: "<plan or task description>"
user-invocable: true
disable-model-invocation: false
---

# Implement — TDD Implementation

Launch **implementer** agents to execute work packages using test-driven development.

## Progress Tracking

**IMPORTANT:** Create a task list at the start to track progress:

1. Create one task per work package (e.g., "Implement: Auth module") — these are the primary tasks
2. Create "Review implementations" and "Update documentation" tasks, both with `addBlockedBy` pointing to all work package task IDs so they appear after implementation in the list
3. Mark each task `in_progress` when starting and `completed` when done
4. If a package fails review, create a fix task with `addBlockedBy` pointing to the review task that flagged it

## With a Plan (Multiple Packages)
If the user provides or references a plan with work packages:
1. Parse the work packages and their dependency graph
2. Launch implementer agents for all packages that can run in parallel
3. Wait for dependent packages to complete before launching their dependents
4. Each implementer follows strict TDD: write tests → implement → verify

## Without a Plan (Single Task)
If the user provides a single task description:
1. Launch one implementer agent with the task
2. The implementer will write tests first, then implement

## After Implementation
For each completed work package:
1. Launch the **reviewer** agent to review the implementation
2. On FAIL: send feedback to implementer for retry (max 2 retries)
3. If still failing: launch **debugger** agent for root cause analysis
4. On PASS: mark package complete

After all packages pass review, launch the **docs-keeper** agent to update documentation.

## Frontend Auto-Detection
If any modified files are UI-related (detected via PostToolUse hook), the **frontend-reviewer** agent feedback should be incorporated.
