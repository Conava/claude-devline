---
name: plan
description: Create a detailed TDD implementation plan with parallel work packages from a feature spec or description.
argument-hint: "<feature spec or description>"
user-invocable: true
disable-model-invocation: true
---

# Plan — Feature Spec to Implementation Plan

Launch the **planner** agent in the **foreground** with the user's feature specification or description.

## Question-Answer Loop

The planner may return a `STATUS: NEEDS_INPUT` response with structured design questions instead of a finished plan. When this happens:

1. Present the questions to the user using **AskUserQuestion** — map each design question to an option set with the planner's recommendation marked "(Recommended)" and its alternatives as additional options
2. **Resume** the planner agent (using the `resume` parameter with its agent ID) with the user's answers
3. Repeat if the planner returns more questions

## After Planning

Once the planner has all answers, it will:
1. Write the full plan to `.devline/plan.md`
2. Return a concise summary (architecture overview, work packages, key decisions)

Present the summary to the user for approval. The full plan lives at `.devline/plan.md` — implementers read it directly from disk.

This skill does NOT automatically continue into implementation. To proceed, run `/devline:implement` with the approved plan, or `/devline` for the full pipeline.
