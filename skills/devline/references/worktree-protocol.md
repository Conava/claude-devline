# Worktree Isolation & Merge-Back Protocol

## Launching Agents in Worktrees

All implementer and devops agents use `isolation: "worktree"` for parallel safety:

```
Agent(subagent_type="devline:implementer", isolation="worktree", run_in_background=true, ...)
```

Fix-cycle and deferred-findings batch-fix implementers also use worktree isolation.

**Worktree nesting check:** Before launching with `isolation: "worktree"`:
```bash
pwd | grep -q '\.claude/worktrees/' && echo "INSIDE_WORKTREE" || echo "ROOT_REPO"
```
If inside a worktree: launch implementers **sequentially without isolation** (they commit directly to the current branch). Skip the merge-back protocol.

## Merge-Back Protocol

After each worktree agent completes (result includes worktree path and branch name):

1. **Merge** the branch:
   ```bash
   git merge <worktree-branch> --no-edit
   ```
   Always use `git merge` — this preserves history and is atomic. If conflicts occur: resolve trivially if possible, otherwise relaunch the implementer on the feature branch without worktree isolation.

2. **Clean up** (only after merge succeeds):
   ```bash
   git worktree remove <worktree-path> --force 2>/dev/null
   git branch -d <worktree-branch> 2>/dev/null
   rm -f "/tmp/.devline-build-count-$(echo '<worktree-path>' | md5sum | cut -d' ' -f1)" 2>/dev/null
   ```

3. **Launch reviewer** on the merged code (reviewers run without worktree isolation).

If the agent result says no changes were made, the worktree is auto-cleaned — skip steps 1-3.

**All merge-back steps run as separate foreground commands.** Each must complete before the next begins.

**Clean up one worktree at a time**, by its specific path from the agent result.

**Worktree inspection safety:** Use `git -C <worktree-path>` for git commands or subshells `(cd <path> && command)` for non-git commands. Keep your working directory in the main repo.

## Killed-Agent Recovery

When you TaskStop a stuck agent, salvage uncommitted work before cleanup:

1. Commit uncommitted work:
   ```bash
   git -C <worktree-path> add -A && git -C <worktree-path> diff --cached --quiet || git -C <worktree-path> commit -m "WIP: salvage from killed agent for task N"
   ```
2. Merge the branch (now includes salvaged commit):
   ```bash
   git merge <worktree-branch> --no-edit
   ```
3. If conflicts: abort merge, clean up worktree, relaunch fresh implementer with context about previous work.
4. Clean up the worktree (after merge succeeds).
5. Decide: if salvaged work looks complete, send to review. If incomplete, relaunch to finish.

## Build Isolation Instructions

When launching implementers, include in the prompt:
> Use `--no-daemon` for all build tool commands (Gradle, Maven, etc.) to avoid daemon contention. Since you are in a worktree, isolate Gradle caches by running this as your FIRST command before any build: `export GRADLE_USER_HOME="$(pwd)/.gradle-home"`. This MUST resolve to your worktree path (e.g., `/home/user/repo/.claude/worktrees/abc123/.gradle-home`), NOT the main repo path. Verify with `echo $GRADLE_USER_HOME` — if it points to the main repo, parallel builds will corrupt each other's caches.
