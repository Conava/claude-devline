---
name: plan
description: Create a detailed TDD implementation plan with parallel tasks from a feature spec or description.
argument-hint: "<feature spec or description>"
user-invocable: true
disable-model-invocation: true
---

# Plan — Feature Spec to Implementation Plan

Launch the **planner** agent in the **foreground** with the user's feature specification or description.

## Interactive Loop

The planner may return a `STATUS: NEEDS_INPUT` response instead of a finished plan. This response can contain any combination of:
- **Design Questions** — architectural or behavioral choices that need user input
- **Code Issues Found** — bugs, flaws, or tech debt discovered in the blast radius that the user should decide whether to fix
- **Proactive Improvements** — enhancements the planner wants to include for the user to approve or reject

When this happens:

1. Present ALL sections to the user using **AskUserQuestion** — for design questions, map each to an option set with the planner's recommendation marked "(Recommended)" and its alternatives as additional options. For code issues and proactive improvements, present them as checklists the user can approve/reject.
2. **Resume** the planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the planner returns more questions or findings — the planner is encouraged to iterate multiple times to refine the plan

## After Planning

Once the planner has all answers, it will:
1. Write the full plan to `.devline/plan.md`
2. Return a concise summary (architecture overview, tasks, key decisions)

Present the summary to the user for approval. The full plan lives at `.devline/plan.md` — implementers read it directly from disk.

This skill does NOT automatically continue into implementation. To proceed, run `/devline:implement` with the approved plan, or `/devline` for the full pipeline.
