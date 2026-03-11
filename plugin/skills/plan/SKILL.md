---
name: plan
description: "Use when the user asks to 'create a plan', 'plan the implementation', 'break this into tasks', 'make an execution plan', or 'plan this work'."
argument-hint: "[task description or design doc]"
user-invocable: true
---

# Standalone Plan Stage

Run the planning stage independently to produce a structured implementation plan. Accepts either a design document from a prior brainstorm or a plain task description.

## Procedure

1. **Parse arguments.** Check if an argument was provided. If it is a file path (e.g., `docs/plans/brainstorm-*.md`), treat it as the design document input. If no argument is provided, use the user's message as a plain task description.

2. **Handle missing design doc.** When no design document is available and only a task description is given, create a quick inline summary: a short problem statement, known constraints, and acceptance criteria. Store this as the working input for the planner agent.

3. **Read configuration.** Check `workflow.human_checkpoints` from the session config. If it includes `plan` (or is set to `all`), run in **interactive mode**. Otherwise, run **autonomously**.

4. **Spawn the planner agent.** Use the Agent tool to spawn the **planner** agent. Pass the design document path (or inline summary) as context. In autonomous mode, include "autonomous" in the prompt so the agent produces the plan in one pass without asking questions.

5. **Relay and approval loop (interactive mode).** When the planner agent returns:
   - Present its **full output** to the user verbatim — task breakdown, groupings, dependency decisions, and any questions. Do not summarise or filter.
   - If the planner asked questions, collect the user's answers and re-spawn the planner with the full Q&A history appended to context.
   - If the planner produced a draft plan, ask the user: **"Does this plan look good, or do you want changes?"**
   - Collect feedback and re-spawn the planner with the feedback appended.
   - Repeat until the user explicitly approves the plan.

6. **Save the plan.** The planner writes the plan to `docs/plans/YYYY-MM-DD-<slug>-plan.md`. Commit: `git add docs/plans/...-plan.md && git commit -m "docs: add implementation plan for <task>"`.

7. **Report and suggest next step.** Print the path to the saved plan and a task summary. Suggest the logical next step:

   > Run `/implement` or `/build` to execute this plan.
