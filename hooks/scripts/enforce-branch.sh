#!/bin/bash
set -eo pipefail
trap 'exit 0' ERR

# Devline workflow hook: enforce feature branch before code changes
# Blocks Write/Edit on protected branches for source code files
# Allows non-code files (docs, configs) to be edited directly on protected branches
# Reads configuration from .claude/devline.local.md if present

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

# Defaults
ENFORCE_FEATURE_BRANCHES="false"
PROTECTED_BRANCHES='(main|master|develop|release|production|staging)'

# Files allowed to be edited directly on protected branches
# Matches by extension and specific filenames
ALLOWED_EXTENSIONS='(md|txt|json|yaml|yml|toml|ini|cfg|conf|lock|gitignore|gitattributes|editorconfig|prettierrc|eslintrc|stylelintrc)'
ALLOWED_FILES='(README|LICENSE|CHANGELOG|CONTRIBUTING|CODE_OF_CONDUCT|SECURITY|CLAUDE|Makefile|Dockerfile|Procfile|Brewfile)'

# Read overrides from devline.local.md
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
LOCAL_MD="$git_root/.claude/devline.local.md"

if [[ -f "$LOCAL_MD" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD")

  custom_enforce=$(echo "$FRONTMATTER" | grep '^enforce_feature_branches:' | sed 's/enforce_feature_branches: *//' | sed 's/^"\(.*\)"$/\1/' || true)
  if [[ -n "$custom_enforce" ]]; then
    ENFORCE_FEATURE_BRANCHES="$custom_enforce"
  fi

  custom_protected=$(echo "$FRONTMATTER" | grep '^protected_branches:' | sed 's/protected_branches: *//' | sed 's/^"\(.*\)"$/\1/' || true)
  if [[ -n "$custom_protected" ]]; then
    PROTECTED_BRANCHES="$custom_protected"
  fi

  # Read additional allowed extensions from devline.local.md
  custom_allowed=$(echo "$FRONTMATTER" | grep '^direct_edit_extensions:' | sed 's/direct_edit_extensions: *//' | sed 's/^"\(.*\)"$/\1/' || true)
  if [[ -n "$custom_allowed" ]]; then
    ALLOWED_EXTENSIONS="$custom_allowed"
  fi
fi

# Feature branch enforcement is opt-in (default: off)
# When off, users can freely edit and commit on protected branches — only push is blocked (by validate-bash.sh)
if [[ "$ENFORCE_FEATURE_BRANCHES" != "true" ]]; then
  exit 0
fi

current_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo "")

if [[ -z "$current_branch" ]]; then
  exit 0
fi

# Only enforce on protected branches
if ! printf '%s\n' "$current_branch" | grep -qEi "^$PROTECTED_BRANCHES$"; then
  exit 0
fi

# Extract filename from path
filename=$(basename "$file_path")
extension="${filename##*.}"

# Allow files with permitted extensions
if [[ "$filename" != "$extension" ]] && printf '%s' "$extension" | grep -qEi "^$ALLOWED_EXTENSIONS$"; then
  exit 0
fi

# Allow specific filenames (no extension or special names)
if printf '%s' "$filename" | grep -qEi "^$ALLOWED_FILES$"; then
  exit 0
fi

# Allow dotfiles/configs at project root
if [[ "$filename" == .* && "$filename" != ".env" ]]; then
  exit 0
fi

# Block: this is a source code file on a protected branch
branch_format="{kind}/{title}"
branch_kinds="feat, fix, refactor, docs, chore, test, ci"
commit_hint="Commits must use conventional format: kind(scope): details."

if [[ -f "$LOCAL_MD" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD")
  custom_format=$(echo "$FRONTMATTER" | grep '^branch_format:' | sed 's/branch_format: *//' | sed 's/^"\(.*\)"$/\1/' || true)
  custom_kinds=$(echo "$FRONTMATTER" | grep '^branch_kinds:' | sed 's/branch_kinds: *//' | sed 's/^"\(.*\)"$/\1/' | sed 's/|/, /g' || true)
  custom_commit=$(echo "$FRONTMATTER" | grep '^commit_format:' | sed 's/commit_format: *//' | sed 's/^"\(.*\)"$/\1/' || true)
  if [[ -n "$custom_format" ]]; then
    branch_format="$custom_format"
  fi
  if [[ -n "$custom_kinds" ]]; then
    branch_kinds="$custom_kinds"
  fi
  if [[ -n "$custom_commit" ]]; then
    commit_hint="Commit convention: $custom_commit"
  fi
fi

branch_hint="git checkout -b <branch>. Format: $branch_format. Kinds: $branch_kinds."

echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\"},\"systemMessage\":\"BLOCKED: Cannot edit source code on protected branch '$current_branch'. Create a feature branch first. $branch_hint $commit_hint\"}" >&2
exit 2
