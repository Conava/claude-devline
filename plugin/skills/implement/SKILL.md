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

2. **Branch safety check.** Before any code changes, verify the current Git branch. If on a protected branch (`main`, `master`, `develop`, or any branch listed in config under `git.protected_branches`), create a feature branch with a descriptive name derived from the task. Confirm the branch switch before proceeding.

3. **Set up an isolated worktree.**

   a. **Choose a directory** — check in this priority order:
      - `.worktrees/` exists in the project root → use it
      - `worktrees/` exists in the project root → use it
      - CLAUDE.md mentions a worktree directory preference → use it
      - Otherwise default to `.claude/worktrees/`

   b. **Verify gitignored** (for any project-local directory — not needed for paths already outside the repo):
      ```
      git check-ignore -q <dir>
      ```
      If not ignored: add the directory to `.gitignore`, commit the change, then proceed.

   c. **Create the worktree:**
      ```
      git worktree add <dir>/<task-slug> -b task-<task-slug> HEAD
      ```
      Derive `<task-slug>` from the task description (lowercase, hyphens, max 40 chars). Record the absolute worktree path.

4. **Resolve domain skills.** Before spawning the implementer, determine which domain skills apply:
   - Read `${CLAUDE_PLUGIN_ROOT}/config/skill-mappings.yaml`.
   - Identify the files the task will likely touch (from the task description or plan). Match their extensions and directories against `file_patterns` and `directory_patterns` in the mappings.
   - For each matched skill, read the full content of `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/SKILL.md`.
   - Collect the content of all matched skills as inline context to pass to the implementer.

5. **Spawn the implementer agent.** Launch the implementer agent with the task input, the absolute worktree path, and the inline domain skill content from step 4. The agent reads files, writes code, runs tests, self-reviews, and commits — all within the worktree.

6. **Spawn the reviewer agent.** After the implementer returns, compute the diff:
   ```
   git diff <current-branch>...task-<task-slug>
   ```
   Spawn the reviewer agent with the diff, implementation summary, and the absolute worktree path. The reviewer reads files and runs tests from that path.

7. **On PASS — merge and clean up:**
   ```
   git merge --no-ff task-<task-slug> -m "feat(<task-slug>): <description>"
   git worktree remove <dir>/<task-slug> --force
   git branch -D task-<task-slug>
   ```
   If `git worktree remove` fails: run `git worktree prune`, then `git branch -D task-<task-slug>`.

8. **On FAIL** — leave the worktree in place and report the reviewer's findings. Ask the user whether to retry (re-spawn implementer with feedback), abandon (clean up worktree), or escalate.

9. **Report results.** Print a summary of files created or modified, the review findings (if any), and the current branch name. If working from a plan, indicate which task was completed and what remains.
