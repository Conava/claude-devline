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

1. **Load configuration.** Read the plugin config to retrieve `workflow.human_checkpoints`. Default output directory is `docs/plans/`.

2. **Determine interaction mode.** If `workflow.human_checkpoints` includes `brainstorm`, run in interactive mode. Otherwise, run in autonomous mode.

3. **Spawn the brainstorm agent.** Pass the user's problem statement and any referenced files. The brainstorm agent will auto-detect if domain skills are missing and trigger `/skills-load` as needed.

4. **Run the interaction loop.** In interactive mode:
   - Receive the agent's questions or trade-off proposals.
   - Present them to the user and collect answers.
   - Re-spawn the brainstorm agent with the full Q&A history in context.
   - Repeat until the agent produces a design document.
   In autonomous mode, let the agent run to completion in a single pass.

5. **Save the design document.** Write the final design doc to `docs/plans/brainstorm-<slug>.md`, where `<slug>` is derived from the problem statement.

6. **Report and suggest next step.** Print the path to the saved design doc and its summary. Suggest the logical next step:

   > Run `/plan` to create an implementation plan from this design document.
