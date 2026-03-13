#!/bin/bash
set -euo pipefail

# Devline workflow hook: enforce feature branch before code changes
# Blocks Write/Edit on protected branches, instructs to create kind/title branch
# Reads branch/commit conventions from .claude/devline.local.md if present

input=$(cat)
file_path=$(printf '%s\n' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
cwd=$(printf '%s\n' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

if [[ -z "$file_path" || -z "$cwd" ]]; then
  exit 0
fi

# Allow writes to .devline/ directory (pipeline artifacts)
if [[ "$file_path" == *"/.devline/"* || "$file_path" == ".devline/"* ]]; then
  exit 0
fi

# Only enforce in git repositories
if ! git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

PROTECTED_BRANCHES='(main|master|develop|release|production|staging)'

current_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo "")

if [[ -z "$current_branch" ]]; then
  exit 0
fi

if printf '%s\n' "$current_branch" | grep -qEi "^$PROTECTED_BRANCHES$"; then
  # Read custom conventions from devline.local.md if present
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
  LOCAL_MD="$git_root/.claude/devline.local.md"
  branch_hint="git checkout -b kind/descriptive-title. Branch kinds: feat, fix, refactor, docs, chore, test, ci. Examples: feat/add-user-auth, fix/login-timeout, refactor/db-queries."
  commit_hint="Commits must use conventional format: kind(scope): details."

  if [[ -f "$LOCAL_MD" ]]; then
    FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD")
    custom_branch=$(echo "$FRONTMATTER" | grep '^branch_prefix:' | sed 's/branch_prefix: *//' | sed 's/^"\(.*\)"$/\1/')
    custom_commit=$(echo "$FRONTMATTER" | grep '^commit_format:' | sed 's/commit_format: *//' | sed 's/^"\(.*\)"$/\1/')
    if [[ -n "$custom_branch" ]]; then
      branch_hint="Branch convention: $custom_branch"
    fi
    if [[ -n "$custom_commit" ]]; then
      commit_hint="Commit convention: $custom_commit"
    fi
  fi

  echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\"},\"systemMessage\":\"BLOCKED: Cannot write code on protected branch '$current_branch'. Create a feature branch first. $branch_hint $commit_hint\"}" >&2
  exit 2
fi

# All checks passed
exit 0
