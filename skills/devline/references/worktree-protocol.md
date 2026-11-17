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

4. **Disk check** — a parallel wave fills `/tmp` and the repo disk quickly:
   ```bash
   df -h /tmp "$(git rev-parse --show-toplevel)"
   ```
   If either has less than about 5 GB free, warn the user and ask before launching.

5. **Record the base SHA** — pass it in every agent brief so the agent can verify its worktree starts from it:
   ```bash
   git rev-parse HEAD
   ```

## Launching Agents in Worktrees

All implementer agents use `isolation: "worktree"` for parallel safety. The worktree is automatically created from the current branch HEAD by the Agent tool — there is no manual branch specification needed. **If the pre-launch checklist passes (correct CWD, correct branch, clean state), the worktree will have the correct base.**

```
Agent(subagent_type="devline:implementer", isolation="worktree", run_in_background=true, ...)
```

Fix-cycle and deferred-findings batch-fix implementers also use worktree isolation.

If the pre-launch checklist shows you're inside a worktree and cannot `cd` out: launch implementers **sequentially without isolation** (they never commit; see Non-Isolated Agent Rules). Skip the merge-back protocol.

## Non-Isolated Agent Rules

When agents run without worktree isolation (sequential fallback, quick lane, or a conflict-triggered relaunch), they write to the feature branch working tree. They never commit.

1. **NEVER run non-isolated agents in parallel.** They write to the same directory simultaneously, causing compilation failures and file corruption. Launch one, wait for it to stop, then launch the next.
2. **The orchestrator commits** after the task is reviewed, once every agent has stopped and `git status --short` shows only the intended files. One commit per task.
3. **Never use `git add -A` or `git add .`** — stage specific files by name. Broad staging commits build caches, IDE files, and other artifacts.

## Merge-Back Protocol

After each worktree agent completes (result includes worktree path and branch name), **first verify your CWD is the main repo root** (not inside a worktree). Run `pwd` — if it contains `.claude/worktrees/`, `cd` back to the main repo root before merging.

0. **Isolation check:** `git -C <main> status --short` must show nothing new. New changes or untracked files mean the agent wrote to the wrong tree: treat it as an isolation failure (see below) and do not merge.

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
   - **"Already up to date" / nothing staged after squash:** the agent worked in the main checkout instead of its worktree. Check `git status --short` and `git log --oneline -3`. **This is a worktree isolation failure** — note it in state.md, clean up the worktree (step 2), and do not merge or commit that work; relaunch the task without isolation.

2. **Clean up** (after commit succeeds OR on failure before relaunch). First `TaskStop` any agent still running for this worktree; a running agent keeps the worktree locked and can edit files after removal starts. Then copy the evidence out, since it dies with the worktree:
   ```bash
   mkdir -p .devline/tasks/N && cp -r <worktree-path>/.devline/out/. .devline/tasks/N/ 2>/dev/null
   ```
   Then remove:
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

When you TaskStop a stuck agent or an agent stops without committing:

1. **Save the partial work as a patch**, without reading it:
   ```bash
   mkdir -p .devline/tasks/N
   git -C <worktree-path> diff HEAD > .devline/tasks/N/partial.patch
   git -C <worktree-path> ls-files --others --exclude-standard > .devline/tasks/N/partial-untracked.txt
   ```
   Append each untracked file to `partial.patch` as a new-file hunk, or keep the list. Copy `<worktree-path>/.devline/out/` to `.devline/tasks/N/` too.
2. **Clean up** the worktree and branch (Merge-Back step 2).
3. **Relaunch** a fresh implementer for the same task. Its brief points at `partial.patch` as work to evaluate, not trust: it may reuse what holds up and must redo the rest.

Never merge, apply or commit the partial work yourself.

## Wrong-Base Recovery

If an agent's worktree branched from the wrong commit (e.g., an old branch instead of the current HEAD):

1. **Do NOT extract diffs and apply them manually.** The agent's work was done against stale code — field mappings, imports, and logic may all be wrong even if the diff "looks right."
2. Clean up the worktree and branch (Merge-Back step 2).
3. Run the pre-launch checklist to fix whatever caused the wrong base (usually: cwd was inside a worktree, or uncommitted changes on the branch).
4. Relaunch a fresh implementer.

## Build Isolation Instructions

Each agent keeps its caches and toolchain root inside its own worktree. When launching implementers, include in the prompt:
> Use `--no-daemon` for all build tool commands (Gradle, Maven, etc.) to avoid daemon contention. Keep caches in your worktree: as your FIRST command, run `export GRADLE_USER_HOME="$(pwd)/.gradle-home"` (or the equivalent for your build tool) and verify with `echo $GRADLE_USER_HOME` that it points inside your worktree, not the main repo; parallel builds corrupt each other's caches otherwise. Run heavy builds and full suites through `nice -n 19 flock /tmp/<repo>-build.lock <command>`. Builds write to the worktree or `~/.cache/<repo>`, not `/tmp`.
