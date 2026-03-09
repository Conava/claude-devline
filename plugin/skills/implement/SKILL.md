---
name: implement
description: "Use when the user asks to 'implement this', 'code this', 'build this task', 'write the code', or wants to implement a single task without the full pipeline."
argument-hint: "[task description]"
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Bash, Grep, Glob
---

# Standalone Implement Stage

Run the implementation stage independently to write code for a single task or plan. Includes branch safety, domain skill detection, and an automatic review pass on completion.

**Note:** If the user is asking to fix a bug, diagnose an issue, or investigate unexpected behavior (not implement a new feature), use `/systematic-debugging` instead. That skill spawns the debugger agent (opus) for root cause analysis and skips brainstorm+plan. Use `/implement` for building new things; use `/systematic-debugging` for fixing broken things.

## Procedure

1. **Parse arguments.** Check if an argument was provided. If it is a path to a plan file (e.g., `docs/plans/plan-*.md`), load it as structured input. Otherwise, treat the user's message as an ad-hoc task description.

2. **Branch safety check (Stage 0).** Before any code changes, verify the current Git branch. If on a protected branch (`main`, `master`, `develop`, or any branch listed in `plugin/config/workflow.yaml` under `git.protected_branches`), create a feature branch with a descriptive name derived from the task. Confirm the branch switch before proceeding.

3. **Auto-detect domain skills.** Read `plugin/config/skill-mappings.yaml` and cross-reference with the files the task is expected to touch. Load any matching domain skills (e.g., if touching `*.tsx` files, load the React skill; if touching `Dockerfile`, load the Docker skill). If the user invoked `/skills` or explicitly mentioned specific skills, load those instead.

4. **Determine isolation mode.** If working from a structured plan, set isolation to `worktree` so changes happen in a Git worktree and do not affect the working tree. For ad-hoc tasks, work directly in the current tree.

5. **Spawn the implementer agent.** Launch the implementer agent with the task input, loaded domain skills, and isolation setting. The agent writes code, creates or modifies files, and runs any available lint or type-check commands.

6. **Spawn the reviewer agent.** After the implementer returns, automatically spawn a reviewer agent scoped to the files that were changed. The reviewer checks for correctness, style consistency, and obvious issues. Relay any findings back in the final report.

7. **Report results.** Print a summary of files created or modified, the review findings (if any), and the current branch name. If working from a plan, indicate which task was completed and what remains.
