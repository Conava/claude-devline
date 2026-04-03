# Worktree Isolation & Merge-Back Protocol

## Pre-Launch Checklist (MANDATORY)

Before launching ANY agent with `isolation: "worktree"`, run these checks in order:

1. **CWD check** — you must be in the main repo root, not inside a worktree:
   ```bash
   pwd | grep -q '\.claude/worktrees/' && echo "INSIDE_WORKTREE" || echo "ROOT_REPO"
   ```
   If `INSIDE_WORKTREE`: `cd` back to the main repo root first. If you cannot determine the main repo root, run `git worktree list` and use the first entry.

2. **Branch check** — confirm you're on the expected feature branch:
   ```bash
   git branch --show-current
   ```
   If the branch doesn't match the plan's `**Branch:**` header, stop and alert the user.

3. **Clean state check** — no uncommitted changes that would contaminate the worktree:
   ```bash
   git status --short
   ```
   If there are uncommitted changes, commit or stash them before launching agents.

## Launching Agents in Worktrees

All implementer and devops agents use `isolation: "worktree"` for parallel safety. The worktree is automatically created from the current branch HEAD by the Agent tool — there is no manual branch specification needed. **If the pre-launch checklist passes (correct CWD, correct branch, clean state), the worktree will have the correct base.**

```
Agent(subagent_type="devline:implementer", isolation="worktree", run_in_background=true, ...)
```

Fix-cycle and deferred-findings batch-fix implementers also use worktree isolation.

If the pre-launch checklist shows you're inside a worktree and cannot `cd` out: launch implementers **sequentially without isolation** (they commit directly to the current branch). Skip the merge-back protocol.

## Non-Isolated Agent Rules

When agents run without worktree isolation (e.g., after a conflict-triggered relaunch), they write directly to the feature branch. This creates critical constraints:

1. **NEVER run non-isolated agents in parallel.** They will write uncommitted changes to the same directory simultaneously, causing compilation failures, file corruption, and mixed-task commits. Launch one, wait for it to complete and commit, then launch the next.
2. **Never batch-commit mixed agent work.** If multiple agents left uncommitted changes, do NOT `git add -A && git commit`. Each task must have its own commit. Stash the mess, relaunch agents one at a time.
3. **Never use `git add -A` or `git add .`** — always stage specific files by name. Broad staging commits build caches, IDE files, and other artifacts.

## Merge-Back Protocol

After each worktree agent completes (result includes worktree path and branch name), **first verify your CWD is the main repo root** (not inside a worktree). Run `pwd` — if it contains `.claude/worktrees/`, `cd` back to the main repo root before merging.

1. **Squash-merge** the branch (one clean commit per task, no merge commits):
   ```bash
   git merge --squash <worktree-branch>
   ```
   This stages all the agent's changes without creating a merge commit. Then commit with a descriptive message:
   ```bash
   git commit -m "task-N: <short task description>"
   ```
   Use the task number and name from the plan. This produces a linear history — one commit per task, no `worktree-agent-*` branch names in the log.

   **Handling failures:**
   - **Conflict:** abort the squash-merge state (`git reset HEAD -- . && git checkout -- .`), clean up the worktree (step 2), and relaunch the implementer **without isolation** on the feature branch. Do NOT resolve conflicts yourself — not with `checkout --ours`, not with `checkout --theirs`, not by editing conflict markers. Note: `git merge --abort` does NOT work after `git merge --squash` because squash-merge doesn't create a MERGE_HEAD — use `git reset HEAD -- . && git checkout -- .` instead.
     **Root cause:** A same-wave conflict means two tasks modified the same file (usually shared resources like translation files, global CSS, route configs). After relaunching, flag this to the user and note in `.devline/state.md` that the plan has a shared-resource overlap.
   - **"Already up to date" / nothing staged after squash:** the agent committed to the feature branch directly instead of its worktree branch. Check `git log --oneline -3` — if the task's commit appears on the feature branch, it's already merged (skip squash-merge, proceed to reviewer). Clean up the worktree (step 2). **This is a worktree isolation failure** — note it in state.md so future waves are aware the branch moved.

2. **Clean up** (after commit succeeds OR on failure before relaunch):
   ```bash
   git worktree remove <worktree-path> --force 2>/dev/null
   rm -rf <worktree-path> 2>/dev/null
   git branch -D <worktree-branch> 2>/dev/null
   rm -f "/tmp/.devline-build-count-$(echo '<worktree-path>' | md5sum | cut -d' ' -f1)" 2>/dev/null
   ```
   The `rm -rf` catches cases where `git worktree remove` fails or leaves the directory behind. `git branch -D` (force delete) is required after squash-merge because git can't verify the branch was merged.

3. **Launch reviewer** on the merged code (reviewers run without worktree isolation).

If the agent result says no changes were made, the worktree is auto-cleaned — skip steps 1-3.

**All merge-back steps run as separate foreground commands.** Each must complete before the next begins.

**Clean up one worktree at a time**, by its specific path from the agent result.

**Worktree inspection safety:** Use `git -C <worktree-path>` for git commands or subshells `(cd <path> && command)` for non-git commands. Keep your working directory in the main repo.

## Killed-Agent Recovery

When you TaskStop a stuck agent or an agent completes without committing:

1. **Clean up** the worktree and branch — don't try to salvage uncommitted work:
   ```bash
   git worktree remove <worktree-path> --force 2>/dev/null
   rm -rf <worktree-path> 2>/dev/null
   git branch -D <worktree-branch> 2>/dev/null
   ```
2. **Relaunch** a fresh implementer for the same task. The new agent starts clean from the current branch state.

Do NOT inspect the worktree's diff, commit on behalf of the agent, or try to merge partial work. A failed agent means a fresh start.

## Wrong-Base Recovery

If an agent's worktree branched from the wrong commit (e.g., an old branch instead of the current HEAD):

1. **Do NOT extract diffs and apply them manually.** The agent's work was done against stale code — field mappings, imports, and logic may all be wrong even if the diff "looks right."
2. Clean up the worktree and branch (same as killed-agent recovery).
3. Run the pre-launch checklist to fix whatever caused the wrong base (usually: cwd was inside a worktree, or uncommitted changes on the branch).
4. Relaunch a fresh implementer.

## Build Isolation Instructions

When launching implementers, include in the prompt:
> Use `--no-daemon` for all build tool commands (Gradle, Maven, etc.) to avoid daemon contention. Since you are in a worktree, isolate Gradle caches by running this as your FIRST command before any build: `export GRADLE_USER_HOME="$(pwd)/.gradle-home"`. This MUST resolve to your worktree path (e.g., `/home/user/repo/.claude/worktrees/abc123/.gradle-home`), NOT the main repo path. Verify with `echo $GRADLE_USER_HOME` — if it points to the main repo, parallel builds will corrupt each other's caches.
