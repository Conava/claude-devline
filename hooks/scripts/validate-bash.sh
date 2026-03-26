#!/bin/bash
set -euo pipefail

# Devline security hook: validate Bash commands in bypass mode
# Blocks destructive, dangerous, and credential-leaking commands
# Reads configuration from .claude/devline.local.md if present

input=$(cat)
command=$(printf '%s\n' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
cwd=$(printf '%s\n' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

if [[ -z "$command" ]]; then
  exit 0
fi

# If cwd is a deleted worktree, resolve back to repo root
if [[ -n "$cwd" && ! -d "$cwd" ]]; then
  cwd=$(printf '%s' "$cwd" | sed 's|/\.claude/worktrees/[^/]*$||')
fi

# Redirect stderr to fd 3 for deny()/ask(), suppress grep warnings globally
exec 3>&2 2>/dev/null

deny() {
  echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\"},\"systemMessage\":\"BLOCKED: $1\"}" >&3
  exit 2
}

ask() {
  echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# =============================================================================
# CONFIGURATION
# =============================================================================

# Defaults
PROTECTED_BRANCHES='(main|master|develop|release|production|staging)'
MERGE_STYLE="squash"

# Read overrides from devline.local.md
if [[ -n "$cwd" ]]; then
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>&3 || echo "$cwd")
  LOCAL_MD="$git_root/.claude/devline.local.md"
  if [[ -f "$LOCAL_MD" ]]; then
    FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD")

    # Read protected_branches as pipe-separated regex group: (main|master|custom)
    custom_protected=$(echo "$FRONTMATTER" | grep '^protected_branches:' | sed 's/protected_branches: *//' | sed 's/^"\(.*\)"$/\1/' || true)
    if [[ -n "$custom_protected" ]]; then
      PROTECTED_BRANCHES="$custom_protected"
    fi

    # Read merge_style: squash (default), merge, rebase
    custom_merge=$(echo "$FRONTMATTER" | grep '^merge_style:' | sed 's/merge_style: *//' | sed 's/^"\(.*\)"$/\1/' || true)
    if [[ -n "$custom_merge" ]]; then
      MERGE_STYLE="$custom_merge"
    fi
  fi
fi

# Helper: check if current branch is protected
on_protected_branch() {
  if [[ -z "$cwd" ]]; then
    return 1
  fi
  local current
  current=$(git -C "$cwd" symbolic-ref --short HEAD 2>&3 || echo "")
  if [[ -z "$current" ]]; then
    return 1
  fi
  printf '%s' "$current" | grep -qPi "^$PROTECTED_BRANCHES$"
}

# Helper: get current branch name
current_branch() {
  if [[ -n "$cwd" ]]; then
    git -C "$cwd" symbolic-ref --short HEAD 2>&3 || echo ""
  fi
}

# =============================================================================
# DESTRUCTIVE FILESYSTEM OPERATIONS (always hard deny)
# =============================================================================

# Detect rm with recursive+force flags
if printf '%s' "$command" | grep -qP 'rm\s+(-[a-zA-Z]*[rf]){1,}\s'; then
  target=$(printf '%s' "$command" | grep -oP 'rm\s+(-[a-zA-Z]+\s+)*/?\K(/[^\s;|&"]+)' | head -1)

  if [[ -n "$target" ]]; then
    if [[ -n "$cwd" ]]; then
      abs_target=$(cd "$cwd" && realpath -m "$target" || echo "$target")
    else
      abs_target="$target"
    fi

    case "$abs_target" in
      /|/home|/etc|/usr|/var|/sys|/boot|/proc|/opt|/lib|/bin|/sbin|"$HOME")
        deny "Destructive rm command targeting system path ($abs_target). Not allowed."
        ;;
    esac

    if [[ -n "$cwd" ]]; then
      norm_cwd="${cwd%/}"
      if [[ "$abs_target" == "$norm_cwd" ]]; then
        deny "Cannot rm -rf the entire working directory."
      elif [[ "$abs_target" != "$norm_cwd/"* ]]; then
        deny "rm -rf targeting path outside the working directory ($abs_target). Not allowed."
      fi
    fi

    if [[ -n "$cwd" ]] && ! git -C "$cwd" rev-parse --is-inside-work-tree 2>&3 1>/dev/null; then
      deny "rm -rf in a non-git directory. Only allowed in git-protected repositories."
    fi
  fi

  if printf '%s' "$command" | grep -qP 'rm\s+(-[a-zA-Z]*[rf]){1,}\s+(\.\.|[*]|/[*])'; then
    deny "Recursive force-delete with wildcard. Too dangerous."
  fi
fi

# Block mkfs, fdisk, dd on devices
if printf '%s' "$command" | grep -qPi '(mkfs|fdisk|dd\s+.*of=/dev)'; then
  deny "Disk/partition operations not allowed."
fi

# =============================================================================
# GIT — ALWAYS BLOCKED (destructive regardless of branch)
# =============================================================================

# Force push (--force, -f, --force-with-lease)
if printf '%s' "$command" | grep -qPi 'git\s+push\s+.*(--force|--force-with-lease|\s-f(\s|$))'; then
  deny "Force push not allowed. Use normal push."
fi

# git reset --hard
if printf '%s' "$command" | grep -qPi 'git\s+reset\s+--hard'; then
  deny "git reset --hard is destructive. Use git stash or git checkout instead."
fi

# git clean -f
if printf '%s' "$command" | grep -qPi 'git\s+clean\s+(-[a-zA-Z]*f|--force)'; then
  deny "git clean -f deletes untracked files permanently. Not allowed."
fi

# git checkout --force
if printf '%s' "$command" | grep -qPi 'git\s+checkout\s+--force'; then
  deny "git checkout --force discards local changes. Not allowed."
fi

# git stash drop/clear
if printf '%s' "$command" | grep -qPi 'git\s+stash\s+(drop|clear)'; then
  deny "git stash drop/clear is destructive. Not allowed."
fi

# =============================================================================
# GIT — PROTECTED BRANCH OPERATIONS
# =============================================================================

# Block deleting protected branches (hard deny, both -d and -D)
if printf '%s' "$command" | grep -qP "git\s+branch\s+(-[a-zA-Z]*[dD])\s+$PROTECTED_BRANCHES(\s|$)"; then
  deny "Deleting protected branch not allowed."
fi

# git branch -D on non-protected branches: ask (squash-merged branches need force delete)
# git branch -d on non-protected branches: allow (safe delete, git checks merge status)
# Note: case-SENSITIVE match — -D only, not -d
if printf '%s' "$command" | grep -qP 'git\s+branch\s+(-[a-zA-Z]*D)'; then
  ask "Force-deleting a branch. This is needed after squash-merge since git can't verify the merge."
fi

# Block push to protected branches
if printf '%s' "$command" | grep -qPi "git\s+push\s+(\S+\s+)?$PROTECTED_BRANCHES(\s|$|:)"; then
  deny "Pushing to protected branch not allowed. Create a PR instead."
fi

# Block force-creating/resetting protected branches
if printf '%s' "$command" | grep -qPi "git\s+checkout\s+-B\s+$PROTECTED_BRANCHES(\s|$)"; then
  deny "Force-creating/resetting protected branch not allowed."
fi

# Block rebase on protected branches
if printf '%s' "$command" | grep -qPi 'git\s+rebase' && on_protected_branch; then
  deny "Rebasing on protected branch '$(current_branch)' not allowed."
fi

# --- Merge into protected branches ---
if printf '%s' "$command" | grep -qPi "git\s+merge\s+" && on_protected_branch; then
  branch=$(current_branch)
  case "$MERGE_STYLE" in
    squash)
      if printf '%s' "$command" | grep -qPi 'git\s+merge\s+--squash\s'; then
        ask "Squash-merging into protected branch '$branch'."
      else
        deny "Only squash merges allowed on protected branch '$branch'. Use: git merge --squash <branch>"
      fi
      ;;
    merge)
      if printf '%s' "$command" | grep -qPi 'git\s+merge\s+--no-ff\s'; then
        ask "Merging into protected branch '$branch' with merge commit."
      else
        deny "Only --no-ff merges allowed on protected branch '$branch'. Use: git merge --no-ff <branch>"
      fi
      ;;
    rebase)
      deny "Merge not allowed on protected branch '$branch' with rebase merge style. Rebase the feature branch then fast-forward."
      ;;
    *)
      ask "Merging into protected branch '$branch'."
      ;;
  esac
fi

# =============================================================================
# PIPELINE ARTIFACT PROTECTION
# =============================================================================

if printf '%s' "$command" | grep -qPi 'git\s+(add|stage)\s'; then
  if printf '%s' "$command" | grep -qPi '(\.devline/|\.devline\s)'; then
    deny "Pipeline artifacts (.devline/ directory) must never be staged or committed."
  fi
fi

# =============================================================================
# COMMIT MESSAGE FORMAT
# =============================================================================

if printf '%s' "$command" | grep -qP 'git\s+commit\s+.*-m\s'; then
  msg=""
  if printf '%s' "$command" | grep -qP '\-m\s+"'; then
    msg=$(printf '%s' "$command" | grep -oP '\-m\s+"\K[^"]+' | head -1)
  elif printf '%s' "$command" | grep -qP "\-m\s+'"; then
    msg=$(printf '%s' "$command" | grep -oP "\-m\s+'\K[^']+" | head -1)
  fi

  if [[ -n "$msg" && "$msg" != '$(cat'* && "$msg" != '$('* ]]; then
    first_line=$(printf '%s' "$msg" | head -1 | sed 's/^[[:space:]]*//')
    if [[ -n "$first_line" ]]; then
      custom_regex=""
      if [[ -n "$cwd" ]]; then
        git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>&3 || echo "$cwd")
        LOCAL_MD="$git_root/.claude/devline.local.md"
        if [[ -f "$LOCAL_MD" ]]; then
          custom_regex=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD" | grep '^commit_format_regex:' | sed 's/commit_format_regex: *//' | sed 's/^"\(.*\)"$/\1/' || true)
        fi
      fi

      if [[ -n "$custom_regex" ]]; then
        if ! printf '%s' "$first_line" | grep -qP "$custom_regex"; then
          custom_desc=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD" | grep '^commit_format:' | sed 's/commit_format: *//' | sed 's/^"\(.*\)"$/\1/' || true)
          deny "Commit message does not match project convention: ${custom_desc:-$custom_regex}"
        fi
      else
        if ! printf '%s' "$first_line" | grep -qP '^(feat|fix|refactor|docs|chore|test|ci|style|perf|build|revert)(\([a-zA-Z0-9._-]+\))?: .+'; then
          deny "Commit message must follow conventional format: kind(scope): details. Valid kinds: feat, fix, refactor, docs, chore, test, ci, style, perf, build, revert."
        fi
      fi
    fi
  fi
fi

# =============================================================================
# PUBLISHING AND RELEASES (never autonomous — user runs these manually)
# =============================================================================

# Package publishing
if printf '%s' "$command" | grep -qPi '(npm\s+publish|cargo\s+publish|twine\s+upload|pip\s+upload|gem\s+push|dotnet\s+nuget\s+push|mvn\s+deploy|gradle\s+publish)'; then
  deny "Package publishing not allowed autonomously. Run this manually."
fi

# Container image push
if printf '%s' "$command" | grep -qPi '(docker\s+push|podman\s+push|buildah\s+push)'; then
  deny "Container image push not allowed autonomously. Run this manually."
fi

# Git tags and releases
if printf '%s' "$command" | grep -qPi 'git\s+tag\s'; then
  deny "Creating git tags not allowed autonomously. Run this manually."
fi
if printf '%s' "$command" | grep -qPi 'gh\s+release\s+create'; then
  deny "Creating GitHub releases not allowed autonomously. Run this manually."
fi

# =============================================================================
# GITHUB MUTATIONS (affects shared state)
# =============================================================================

# PR merge/close/reopen
if printf '%s' "$command" | grep -qPi 'gh\s+pr\s+(merge|close|reopen)'; then
  deny "Merging/closing/reopening PRs not allowed autonomously. Run this manually."
fi

# Issue close/comment/delete
if printf '%s' "$command" | grep -qPi 'gh\s+issue\s+(close|delete|comment)'; then
  deny "Modifying GitHub issues not allowed autonomously. Run this manually."
fi

# =============================================================================
# DATABASE DESTRUCTIVE OPERATIONS
# =============================================================================

# SQL destructive statements (case insensitive, across common CLI tools)
if printf '%s' "$command" | grep -qPi '(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX|VIEW)|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\S+\s*($|;|\s*--|\s+WHERE\s+1)|DELETE\s+FROM\s+\S+\s*;)'; then
  deny "Destructive database operation (DROP/TRUNCATE/bulk DELETE) not allowed autonomously."
fi

# =============================================================================
# EXTERNAL MUTATIONS (affects systems outside the project)
# =============================================================================

# curl/wget with mutating HTTP methods to non-localhost
if printf '%s' "$command" | grep -qPi 'curl\s+.*-X\s*(POST|PUT|DELETE|PATCH)' && ! printf '%s' "$command" | grep -qPi 'curl\s+.*https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])'; then
  ask "HTTP mutation (POST/PUT/DELETE/PATCH) to external URL detected."
fi

# SSH/SCP to remote hosts
if printf '%s' "$command" | grep -qPi '(ssh|scp)\s+' && ! printf '%s' "$command" | grep -qPi '(ssh|scp)\s+.*localhost'; then
  ask "Remote SSH/SCP connection detected."
fi

# Systemctl/service commands
if printf '%s' "$command" | grep -qPi '(systemctl|service)\s+(start|stop|restart|enable|disable)'; then
  deny "System service control not allowed autonomously."
fi

# =============================================================================
# CREDENTIAL AND SECRET EXPOSURE
# =============================================================================

if printf '%s' "$command" | grep -qPi '(curl|wget)\s.*\|\s*(ba|z|fi)?sh'; then
  ask "Piping curl/wget to shell executes arbitrary code from the internet."
fi

if printf '%s' "$command" | grep -qPi '(echo|printf|cat)\s.*\$(.*_(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL|PRIVATE).*)'; then
  deny "Printing environment variables that may contain secrets."
fi

if printf '%s' "$command" | grep -qPi 'curl\s.*(-d|--data).*\$(.*_(KEY|SECRET|TOKEN|PASSWORD).*)'; then
  deny "Sending secrets to external URL detected."
fi

# =============================================================================
# PROCESS AND SYSTEM MANIPULATION
# =============================================================================

if printf '%s' "$command" | grep -qPi 'kill\s+-9\s+1(\s|$)'; then
  deny "Cannot kill PID 1 (init/systemd)."
fi

if printf '%s' "$command" | grep -qPi 'chmod\s+(-R\s+)?777'; then
  deny "chmod 777 makes files world-writable. Use more restrictive permissions."
fi

if printf '%s' "$command" | grep -qPi 'authorized_keys'; then
  deny "Modifying SSH authorized_keys is not allowed."
fi

# =============================================================================
# COMMAND INJECTION PATTERNS
# =============================================================================

if printf '%s' "$command" | grep -qPi ';\s*rm\s'; then
  deny "Potential command injection pattern detected (;rm)."
fi

if printf '%s' "$command" | grep -qPi '`.*rm\s+-[a-zA-Z]*r.*`'; then
  deny "Dangerous command in backtick substitution."
fi

# =============================================================================
# BUILD INVOCATION BUDGET
# Agents sometimes run expensive build/test commands too many times.
# The instruction-level budget (15 invocations) is unreliable — Sonnet forgets.
# This hook enforces it at infrastructure level. Counter is per working directory
# (each worktree gets its own budget). Stored in /tmp, not committed.
# =============================================================================

BUILD_CMD_PATTERN='(gradlew|gradle|mvn |mvnw |npm\s+test|npx\s+jest|yarn\s+test|pnpm\s+test|cargo\s+test|go\s+test|dotnet\s+test|pytest|python.*-m\s+pytest|phpunit|bundle\s+exec\s+rspec)'

if printf '%s' "$command" | grep -qPi "$BUILD_CMD_PATTERN"; then
  MAX_INVOCATIONS=12
  WARN_AT=10
  dir_hash=$(printf '%s' "$cwd" | md5sum | cut -d' ' -f1)
  COUNTER_FILE="/tmp/.devline-build-count-${dir_hash}"

  count=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
  count=$((count + 1))
  echo "$count" > "$COUNTER_FILE"

  if [[ $count -gt $MAX_INVOCATIONS ]]; then
    deny "Build invocation budget exceeded (${count}/${MAX_INVOCATIONS}). Commit what you have, document remaining failures, and report back. To reset: delete ${COUNTER_FILE}"
  elif [[ $count -ge $WARN_AT ]]; then
    # Allow but warn via stderr (visible to agent)
    echo "WARNING: Build invocation ${count}/${MAX_INVOCATIONS}. Budget almost exhausted." >&3
  fi
fi

# All checks passed
exit 0
