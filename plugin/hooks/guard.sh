#!/usr/bin/env bash
# guard.sh — PreToolUse hook for Claude Code
# Intercepts Bash tool calls and blocks dangerous operations.
# Three tiers:
#   1. Always blocked: network ops (push/fetch/pull/clone/ssh), rm -r /
#   2. Branch-aware: --force, --hard, git reset, git clean — only on protected branches
#   3. Path-aware: rm -rf — only outside the project directory
# Exit 0 = allow, Exit 2 = block (message on stderr).
set -eo pipefail

# ---------- Dependency check ----------
if ! command -v python3 &>/dev/null; then
  echo "guard.sh: python3 not found — bash guard is disabled. Install python3 to enable it." >&2
  exit 0
fi

# ---------- Read stdin (the hook payload) ----------
INPUT="$(cat)"

TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")"

# Only inspect Bash tool calls
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND="$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")"

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ---------- Unwrap shell wrappers to detect bypass attempts ----------
EFFECTIVE_COMMAND="$COMMAND"

# Unwrap: sh -c "..." / bash -c "..."
if [[ "$COMMAND" =~ (ba)?sh[[:space:]]+-c[[:space:]]+[\"\'](.+)[\"\'] ]]; then
  EFFECTIVE_COMMAND="${BASH_REMATCH[2]}"
fi

# Unwrap: bash <<< "..." / bash <<< '...'
if [[ "$COMMAND" =~ (ba)?sh[[:space:]]+\<\<\<[[:space:]]*[\"\']?([^\"\']+)[\"\']? ]]; then
  EFFECTIVE_COMMAND="${BASH_REMATCH[2]}"
fi

# Detect: echo "..." | bash / echo "..." | sh
if [[ "$COMMAND" =~ echo[[:space:]]+[\"\']([^\"\']+)[\"\'][[:space:]]*\|[[:space:]]*(ba)?sh ]]; then
  EFFECTIVE_COMMAND="${BASH_REMATCH[1]}"
fi

# Detect: eval "..."
if [[ "$COMMAND" =~ eval[[:space:]]+[\"\'](.+)[\"\'] ]]; then
  EFFECTIVE_COMMAND="${BASH_REMATCH[1]}"
fi

COMMANDS_TO_CHECK=("$COMMAND")
if [[ "$EFFECTIVE_COMMAND" != "$COMMAND" ]]; then
  COMMANDS_TO_CHECK+=("$EFFECTIVE_COMMAND")
fi

# ---------- Locate project directory ----------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# ---------- Hardcoded blocked lists (from defaults.yaml, which was deleted) ----------
BLOCKED_COMMANDS=(
  "git push"
  "git fetch"
  "git pull"
  "git clone"
  "git ls-remote"
  "git remote update"
  "git submodule update --remote"
  "rm -r /"
  "ssh "
  "scp "
  "sftp "
)

BLOCKED_PATTERNS=(
  'git\s+(push|fetch|pull|clone|ls-remote)'
  'git\s+remote\s+update'
  'git\s+submodule\s+update\s+.*--remote'
  '\bssh\s+'
  '\bscp\s+'
  '\bsftp\s+'
)

PROTECTED_BRANCHES=(
  "main"
  "master"
  "develop"
  "development"
  "staging"
  "production"
  "release"
  "trunk"
)

# ---------- Helper: deny and exit ----------
deny() {
  echo "$1" >&2
  exit 2
}

# ---------- Helper: check if branch is protected ----------
is_protected_branch() {
  local branch="$1"
  for pb in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$branch" == "$pb" ]]; then
      return 0
    fi
    # shellcheck disable=SC2254
    case "$branch" in
      $pb) return 0 ;;
    esac
  done
  return 1
}

# ---------- Get current branch (cached) ----------
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"

# ---------- Helper: check if path is inside project ----------
is_inside_project() {
  local target="$1"
  # Resolve to absolute path (using python3 for cross-platform compatibility)
  local resolved
  resolved="$(python3 -c "import os, sys; print(os.path.abspath(os.path.join(sys.argv[1], sys.argv[2])))" "$PROJECT_DIR" "$target" 2>/dev/null || echo "$target")"
  local project_abs
  project_abs="$(python3 -c "import os, sys; print(os.path.abspath(sys.argv[1]))" "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")"
  [[ "$resolved" == "$project_abs"* ]]
}

# ==========================================================
# TIER 1: Always blocked (network ops, root deletion)
# ==========================================================
for cmd_variant in "${COMMANDS_TO_CHECK[@]}"; do
  for bc in "${BLOCKED_COMMANDS[@]}"; do
    if [[ "$cmd_variant" == *"$bc"* ]]; then
      suggestion=""
      case "$bc" in
        "git push"*)   suggestion=" Use /merge-prep when ready for PR." ;;
        "git fetch"*|"git pull"*|"git clone"*|"git ls-remote"*|"git remote update"*|"git submodule update --remote"*) suggestion=" Agents work locally only. No remote/network operations allowed." ;;
        "ssh "*|"scp "*|"sftp "*) suggestion=" SSH operations are not allowed. Agents work locally only." ;;
        "rm -r /"*) suggestion=" Root deletion is never allowed." ;;
      esac
      deny "Blocked: ${bc} is not allowed.${suggestion}"
    fi
  done
done

for cmd_variant in "${COMMANDS_TO_CHECK[@]}"; do
  for bp in "${BLOCKED_PATTERNS[@]}"; do
    if printf '%s' "$cmd_variant" | python3 -c "
import sys,re
pattern = sys.argv[1]
line = sys.stdin.read()
try:
    sys.exit(0 if re.search(pattern, line) else 1)
except re.error as e:
    print(f'Warning: invalid safeguard regex pattern: {pattern!r}: {e}', file=sys.stderr)
    sys.exit(1)
" "$bp" 2>/dev/null; then
      deny "Blocked: command matches prohibited pattern. Review safeguards config for details."
    fi
  done
done

# ==========================================================
# TIER 2: Branch-aware (only blocked on protected branches)
# git checkout/merge protected, --force, --hard, git reset, git clean
# ==========================================================
for cmd_variant in "${COMMANDS_TO_CHECK[@]}"; do

  # git merge <branch> — block only if target is protected
  if [[ "$cmd_variant" =~ git[[:space:]]+merge[[:space:]]+([^[:space:]-][^[:space:]]*) ]]; then
    local_target="${BASH_REMATCH[1]}"
    if is_protected_branch "$local_target"; then
      deny "Blocked: git merge $local_target is not allowed. Protected branch. Use /merge-prep when ready for PR."
    fi
    # Non-protected merge: allow and skip further checks
    exit 0
  fi

  # git checkout <branch> — block only if target is protected
  if [[ "$cmd_variant" =~ git[[:space:]]+checkout[[:space:]]+([^[:space:]-][^[:space:]]*) ]]; then
    local_target="${BASH_REMATCH[1]}"
    if is_protected_branch "$local_target"; then
      deny "Blocked: git checkout $local_target is not allowed. Protected branch."
    fi
    exit 0
  fi

  # --force, --hard, git reset, git clean — block only on protected branches
  if [[ -n "$CURRENT_BRANCH" ]] && is_protected_branch "$CURRENT_BRANCH"; then
    if [[ "$cmd_variant" == *"--force"* ]]; then
      deny "Blocked: --force is not allowed on protected branch '$CURRENT_BRANCH'."
    fi
    if [[ "$cmd_variant" == *"--hard"* ]]; then
      deny "Blocked: --hard is not allowed on protected branch '$CURRENT_BRANCH'."
    fi
    if [[ "$cmd_variant" =~ git[[:space:]]+(reset|clean) ]]; then
      deny "Blocked: git ${BASH_REMATCH[1]} is not allowed on protected branch '$CURRENT_BRANCH'."
    fi
  fi
done

# ==========================================================
# TIER 3: Path-aware (rm -rf only blocked outside project)
# ==========================================================
for cmd_variant in "${COMMANDS_TO_CHECK[@]}"; do
  if [[ "$cmd_variant" =~ rm[[:space:]]+-[rf]{2,}[[:space:]]+(.+) ]]; then
    # Extract all path arguments (split on space, skip flags)
    paths_str="${BASH_REMATCH[1]}"
    for target_path in $paths_str; do
      # Skip flags
      [[ "$target_path" == -* ]] && continue
      if ! is_inside_project "$target_path"; then
        deny "Blocked: rm -rf outside project directory is not allowed. Target: $target_path"
      fi
    done
  fi
done

# ---------- All checks passed ----------
exit 0
