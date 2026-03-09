---
name: brainstorm
description: "Use when the user explicitly asks to 'brainstorm', 'explore ideas', 'discuss approaches', 'design discussion', or 'think through' a problem without wanting the full pipeline."
argument-hint: "[topic or problem]"
user-invocable: true
context: fork
agent: brainstorm
---

# Standalone Brainstorm Stage

Run the brainstorm stage independently, outside the full development pipeline. This is for open-ended design exploration and idea generation on a specific problem or feature request.

## Procedure

1. **Load configuration.** Read `plugin/config/workflow.yaml` to retrieve `workflow.human_checkpoints` and any brainstorm-specific settings (e.g., `brainstorm.max_rounds`, `brainstorm.output_dir`). Default output directory is `docs/plans/`.

2. **Create a state file.** Initialize a temporary state file at `.claude/state/brainstorm-<timestamp>.json` to track the chunked interaction. The state file holds the evolving design context, questions asked, answers received, and current iteration count.

3. **Determine interaction mode.** If `workflow.human_checkpoints` includes the brainstorm stage (or is set to `all`), run in interactive mode. Otherwise, run in autonomous mode where the agent produces a complete design doc without pausing for input.

4. **Spawn the brainstorm agent.** Launch the brainstorm agent with the state file path and the user's problem statement as input. Pass any relevant context files the user mentioned. The brainstorm agent will auto-detect if domain skills are missing for the technologies involved and trigger `/skills-load` to load and persist them.

5. **Run the chunked interaction loop.** In interactive mode, enter a relay loop:
   - Receive the agent's design questions or trade-off proposals.
   - Present them to the user and collect answers.
   - Update the state file with the new context.
   - Re-spawn the brainstorm agent with the updated state file.
   - Repeat until the agent signals that the design doc is ready or the user explicitly approves the current draft.
   In autonomous mode, let the agent run to completion in a single pass.

6. **Save the design document.** Write the final design doc to `docs/plans/brainstorm-<slug>.md`, where `<slug>` is derived from the problem statement. Include a metadata header with timestamp, interaction mode used, and number of rounds completed.

7. **Report and suggest next step.** Print the path to the saved design doc and its summary. Suggest the logical next step:

   > Run `/plan` to create an implementation plan from this design document.
