#!/usr/bin/env bash
# worktree-create.sh — WorktreeCreate hook for Claude Code
# Creates a git worktree branching from the local feature branch HEAD,
# rather than the remote default branch.
# Prints the absolute worktree path on stdout (required by Claude Code).
set -euo pipefail

# ---------- Dependency check ----------
if ! command -v python3 &>/dev/null; then
  echo "worktree-create.sh: python3 is required to parse worktree parameters. Install python3 (e.g. brew install python3) and restart Claude Code." >&2
  exit 1
fi

INPUT="$(cat)"

NAME="$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")"
CWD="$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['cwd'])")"

WORKTREE_DIR="${HOME}/.claude/worktrees/${NAME}"
BRANCH="worktree-${NAME}"

# Remove any stale branch from a previous aborted run
git -C "$CWD" branch -D "$BRANCH" 2>/dev/null || true

# Remove any stale worktree directory
if [[ -d "$WORKTREE_DIR" ]]; then
  git -C "$CWD" worktree remove --force "$WORKTREE_DIR" 2>/dev/null || rm -rf "$WORKTREE_DIR"
fi

# Create worktree from local HEAD (the current feature branch), not remote
git -C "$CWD" worktree add "$WORKTREE_DIR" -b "$BRANCH" HEAD >&2

echo "$WORKTREE_DIR"
