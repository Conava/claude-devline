---
name: plan
description: "Use when the user asks to 'create a plan', 'plan the implementation', 'break this into tasks', 'make an execution plan', or 'plan this work'."
argument-hint: "[task description or design doc]"
user-invocable: true
context: fork
agent: planner
---

# Standalone Plan Stage

Run the planning stage independently to produce a structured implementation plan. Accepts either a design document from a prior brainstorm or a plain task description.

## Procedure

1. **Parse arguments.** Check if an argument was provided. If it is a file path (e.g., `docs/plans/brainstorm-*.md`), treat it as the design document input. If no argument is provided, use the user's message as a plain task description.

2. **Handle missing design doc.** When no design document is available and only a task description is given, create a quick inline summary: a short problem statement, known constraints, and acceptance criteria. Store this as the working input for the planner agent.

3. **Load configuration.** Read `plugin/config/workflow.yaml` to retrieve `workflow.human_checkpoints` and planner settings such as `plan.max_task_depth`, `plan.output_dir`, and `plan.task_format`. Default output directory is `docs/plans/`.

4. **Determine interaction mode.** If `workflow.human_checkpoints` includes the plan stage (or is set to `all`), run in interactive mode. Otherwise, run autonomously.

5. **Spawn the planner agent.** Launch the planner agent with the design document or inline summary as input. The agent breaks the work into ordered, atomic tasks with estimated complexity, dependencies, and file-touch predictions.

6. **Run the chunked interaction loop (interactive mode only).** In interactive mode, enter a relay loop:
   - Present the draft plan to the user for review.
   - Collect feedback on task ordering, granularity, or missing items.
   - Re-spawn the planner agent with the updated feedback.
   - Repeat until the user approves the plan.
   In autonomous mode, the agent produces the final plan in a single pass.

7. **Save the plan.** Write the completed plan to `docs/plans/plan-<slug>.md` with metadata including timestamp, source document reference, total task count, and estimated complexity.

8. **Report and suggest next step.** Print the path to the saved plan and a task summary. Suggest the logical next step:

   > Run `/implement` or `/build` to execute this plan.
