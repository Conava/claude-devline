---
name: implement
description: "Use when the user asks to 'implement this', 'code this', 'build this task', 'write the code', or wants to implement a single task without the full pipeline."
argument-hint: "[task description]"
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Bash, Grep, Glob
---

# Standalone Implement Stage

Run the implementation stage independently to write code for a single task or plan. Includes branch safety, worktree-isolated implementation, and an automatic review pass on completion.

**Note:** If the user is asking to fix a bug, diagnose an issue, or investigate unexpected behavior (not implement a new feature), use `/systematic-debugging` instead. That skill spawns the debugger agent (opus) for root cause analysis and skips brainstorm+plan. Use `/implement` for building new things; use `/systematic-debugging` for fixing broken things.

## Procedure

1. **Parse arguments.** Check if an argument was provided. If it is a path to a plan file (e.g., `docs/plans/plan-*.md`), load it as structured input. Otherwise, treat the user's message as an ad-hoc task description.

2. **Branch safety check.** Before any code changes, verify the current Git branch. If on a protected branch (`main`, `master`, `develop`, or any branch listed in config under `git.protected_branches`), create a feature branch with a descriptive name derived from the task. Confirm the branch switch before proceeding.

3. **Record pre-implementation state.** Save the current commit hash (`git rev-parse HEAD`) for the reviewer to diff against later.

4. **Spawn the implementer agent.** Launch the implementer agent with the task input. The agent has `isolation: worktree` in its frontmatter — Claude Code auto-creates a worktree and auto-merges changes back to the current branch when the agent finishes. Domain skills are loaded via frontmatter.

5. **Spawn the reviewer agent.** After the implementer returns and changes are auto-merged, spawn the reviewer agent. Pass the pre-implementation commit hash so it can run `git diff <pre-commit>...HEAD` to review the changes.

6. **On PASS** — report results. Print a summary of files changed and the current branch name.

7. **On FAIL** — report the reviewer's findings. Ask the user whether to retry (re-spawn implementer with feedback), revert (`git revert`), or escalate.

8. **Report results.** Print a summary of files created or modified, the review findings (if any), and the current branch name. If working from a plan, indicate which task was completed and what remains.
