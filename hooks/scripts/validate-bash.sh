#!/bin/bash
set -euo pipefail

# Devline security hook: validate Bash commands in bypass mode
# Blocks destructive, dangerous, and credential-leaking commands

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

if [[ -z "$command" ]]; then
  exit 0
fi

# Redirect stderr to fd 3 for deny(), suppress grep warnings globally
exec 3>&2 2>/dev/null

deny() {
  echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\"},\"systemMessage\":\"BLOCKED: $1\"}" >&3
  exit 2
}

# =============================================================================
# DESTRUCTIVE FILESYSTEM OPERATIONS
# =============================================================================

# Detect rm with recursive+force flags
if printf '%s' "$command" | grep -qP 'rm\s+(-[a-zA-Z]*[rf]){1,}\s'; then
  # Extract the first target path (absolute paths only for system path check)
  target=$(printf '%s' "$command" | grep -oP 'rm\s+(-[a-zA-Z]+\s+)*/?\K(/[^\s;|&"]+)' | head -1)

  if [[ -n "$target" ]]; then
    # Resolve to absolute path
    if [[ -n "$cwd" ]]; then
      abs_target=$(cd "$cwd" && realpath -m "$target" || echo "$target")
    else
      abs_target="$target"
    fi

    # Block exact system paths (rm -rf /home, not rm -rf /home/user/project/subdir)
    case "$abs_target" in
      /|/home|/etc|/usr|/var|/sys|/boot|/proc|/opt|/lib|/bin|/sbin|"$HOME")
        deny "Destructive rm command targeting system path ($abs_target). Not allowed in bypass mode."
        ;;
    esac

    # Allow if target is inside the working directory
    if [[ -n "$cwd" ]]; then
      # Normalize cwd for prefix matching
      norm_cwd="${cwd%/}"
      if [[ "$abs_target" == "$norm_cwd" ]]; then
        deny "Cannot rm -rf the entire working directory."
      elif [[ "$abs_target" != "$norm_cwd/"* ]]; then
        deny "rm -rf targeting path outside the working directory ($abs_target). Not allowed in bypass mode."
      fi
    fi

    # Block rm -rf in directories that aren't git repos
    if [[ -n "$cwd" ]] && ! git -C "$cwd" rev-parse --is-inside-work-tree 2>&3 1>/dev/null; then
      deny "rm -rf in a non-git directory. Only allowed in git-protected repositories."
    fi
  fi

  # Block rm -rf with wildcard on broad paths
  if printf '%s' "$command" | grep -qP 'rm\s+(-[a-zA-Z]*[rf]){1,}\s+(\.\.|[*]|/[*])'; then
    deny "Recursive force-delete with wildcard. Too dangerous for bypass mode."
  fi
fi

# Block mkfs, fdisk, dd on devices
if printf '%s' "$command" | grep -qPi '(mkfs|fdisk|dd\s+.*of=/dev)'; then
  deny "Disk/partition operations not allowed in bypass mode."
fi

# =============================================================================
# GIT DESTRUCTIVE OPERATIONS
# =============================================================================

PROTECTED_BRANCHES='(main|master|develop|release|production|staging)'

# Block ALL force operations: push --force, push -f, --force-with-lease
if printf '%s' "$command" | grep -qPi 'git\s+push\s+.*(--force|--force-with-lease|\s-f(\s|$))'; then
  deny "Force push is not allowed in bypass mode. Use normal push or ask the user for explicit approval."
fi

# Block git reset --hard (with or without ref)
if printf '%s' "$command" | grep -qPi 'git\s+reset\s+--hard'; then
  deny "git reset --hard is destructive and not allowed in bypass mode. Use git stash or git checkout instead."
fi

# Block git clean -f (deletes untracked files)
if printf '%s' "$command" | grep -qPi 'git\s+clean\s+(-[a-zA-Z]*f|--force)'; then
  deny "git clean -f deletes untracked files permanently. Not allowed in bypass mode."
fi

# Block git branch -D (force delete branch)
if printf '%s' "$command" | grep -qPi 'git\s+branch\s+(-[a-zA-Z]*D)'; then
  deny "git branch -D (force delete) not allowed. Use git branch -d for safe deletion."
fi

# Block git checkout --force
if printf '%s' "$command" | grep -qPi 'git\s+checkout\s+--force'; then
  deny "git checkout --force discards local changes. Not allowed in bypass mode."
fi

# Block git stash drop/clear (destructive stash operations)
if printf '%s' "$command" | grep -qPi 'git\s+stash\s+(drop|clear)'; then
  deny "git stash drop/clear is destructive. Not allowed in bypass mode."
fi

# --- Protected branch operations (main, master, develop, release, production, staging) ---

# Block push to protected branches (even non-force)
if printf '%s' "$command" | grep -qPi "git\s+push\s+(\S+\s+)?$PROTECTED_BRANCHES(\s|$|:)"; then
  deny "Pushing to protected branch not allowed without explicit user approval. Create a PR instead."
fi

# Block merge INTO protected branches (git merge X while on main)
if printf '%s' "$command" | grep -qPi "git\s+merge\s+" && [[ -n "$cwd" ]]; then
  current_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>&3 || echo "")
  if printf '%s' "$current_branch" | grep -qPi "^$PROTECTED_BRANCHES$"; then
    deny "Merging into protected branch '$current_branch' not allowed without explicit user approval."
  fi
fi

# Block committing directly on protected branches
if printf '%s' "$command" | grep -qPi 'git\s+commit\s' && [[ -n "$cwd" ]]; then
  current_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>&3 || echo "")
  if printf '%s' "$current_branch" | grep -qPi "^$PROTECTED_BRANCHES$"; then
    deny "Committing directly to protected branch '$current_branch' not allowed without explicit user approval. Create a feature branch first."
  fi
fi

# Block checking out protected branches with -B (force create/reset)
if printf '%s' "$command" | grep -qPi "git\s+checkout\s+-B\s+$PROTECTED_BRANCHES(\s|$)"; then
  deny "Force-creating/resetting protected branch not allowed."
fi

# Block deleting protected branches
if printf '%s' "$command" | grep -qPi "git\s+branch\s+(-[a-zA-Z]*[dD])\s+$PROTECTED_BRANCHES(\s|$)"; then
  deny "Deleting protected branch not allowed."
fi

# Block rebase on protected branches
if printf '%s' "$command" | grep -qPi 'git\s+rebase' && [[ -n "$cwd" ]]; then
  current_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>&3 || echo "")
  if printf '%s' "$current_branch" | grep -qPi "^$PROTECTED_BRANCHES$"; then
    deny "Rebasing on protected branch '$current_branch' not allowed. Use merge or create a feature branch."
  fi
fi

# =============================================================================
# PIPELINE ARTIFACT PROTECTION
# =============================================================================

# Block staging pipeline artifacts (.devline/ directory and plan/review docs)
if printf '%s' "$command" | grep -qPi 'git\s+(add|stage)\s'; then
  if printf '%s' "$command" | grep -qPi '(\.devline/|\.devline\s|plan\.md|review\.md|PLAN\.md|REVIEW\.md|-plan\.md|-review\.md|implementation\.plan|code\.review)(\s|$|")'; then
    deny "Pipeline artifacts (.devline/, plan/review documents) must never be staged or committed. They are ephemeral working files."
  fi
fi

# =============================================================================
# COMMIT MESSAGE FORMAT
# =============================================================================

# Enforce conventional commit format: kind(scope): details
# Reads custom commit_format from .claude/devline.local.md if present
if printf '%s' "$command" | grep -qP 'git\s+commit\s+.*-m\s'; then
  # Extract message from simple -m "msg" or -m 'msg' (skip heredoc/subshell)
  msg=""
  if printf '%s' "$command" | grep -qP '\-m\s+"'; then
    msg=$(printf '%s' "$command" | grep -oP '\-m\s+"\K[^"]+' | head -1)
  elif printf '%s' "$command" | grep -qP "\-m\s+'"; then
    msg=$(printf '%s' "$command" | grep -oP "\-m\s+'\K[^']+" | head -1)
  fi

  # Skip heredoc/subshell messages (can't reliably parse)
  if [[ -n "$msg" && "$msg" != '$(cat'* && "$msg" != '$('* ]]; then
    first_line=$(printf '%s' "$msg" | head -1 | sed 's/^[[:space:]]*//')
    if [[ -n "$first_line" ]]; then
      # Check for custom commit format regex in devline.local.md
      custom_regex=""
      if [[ -n "$cwd" ]]; then
        git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>&3 || echo "$cwd")
        LOCAL_MD="$git_root/.claude/devline.local.md"
        if [[ -f "$LOCAL_MD" ]]; then
          custom_regex=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD" | grep '^commit_format_regex:' | sed 's/commit_format_regex: *//' | sed 's/^"\(.*\)"$/\1/')
        fi
      fi

      if [[ -n "$custom_regex" ]]; then
        if ! printf '%s' "$first_line" | grep -qP "$custom_regex"; then
          custom_desc=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$LOCAL_MD" | grep '^commit_format:' | sed 's/commit_format: *//' | sed 's/^"\(.*\)"$/\1/')
          deny "Commit message does not match project convention: ${custom_desc:-$custom_regex}"
        fi
      else
        # Default: conventional commits
        if ! printf '%s' "$first_line" | grep -qP '^(feat|fix|refactor|docs|chore|test|ci|style|perf|build|revert)(\([a-zA-Z0-9._-]+\))?: .+'; then
          deny "Commit message must follow conventional format: kind(scope): details. Valid kinds: feat, fix, refactor, docs, chore, test, ci, style, perf, build, revert. Example: feat(auth): add JWT token validation"
        fi
      fi
    fi
  fi
fi

# =============================================================================
# CREDENTIAL AND SECRET EXPOSURE
# =============================================================================

# Block curl/wget piped to bash/sh
if printf '%s' "$command" | grep -qPi '(curl|wget)\s.*\|\s*(ba)?sh'; then
  deny "Piping curl/wget output to shell is a security risk."
fi

# Block printing env vars that likely contain secrets
if printf '%s' "$command" | grep -qPi '(echo|printf|cat)\s.*\$(.*_(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL|PRIVATE).*)'; then
  deny "Printing environment variables that may contain secrets."
fi

# Block exfiltration patterns: sending env/secrets to external URLs
if printf '%s' "$command" | grep -qPi 'curl\s.*(-d|--data).*\$(.*_(KEY|SECRET|TOKEN|PASSWORD).*)'; then
  deny "Sending secrets to external URL detected."
fi

# =============================================================================
# PROCESS AND SYSTEM MANIPULATION
# =============================================================================

# Block kill -9 on system processes
if printf '%s' "$command" | grep -qPi 'kill\s+-9\s+1(\s|$)'; then
  deny "Cannot kill PID 1 (init/systemd)."
fi

# Block chmod 777 (world-writable)
if printf '%s' "$command" | grep -qPi 'chmod\s+(-R\s+)?777'; then
  deny "chmod 777 makes files world-writable. Use more restrictive permissions."
fi

# Block adding SSH keys to authorized_keys
if printf '%s' "$command" | grep -qPi 'authorized_keys'; then
  deny "Modifying SSH authorized_keys is not allowed in bypass mode."
fi

# =============================================================================
# COMMAND INJECTION PATTERNS
# =============================================================================

# Block semicolon followed by rm (injection pattern)
if printf '%s' "$command" | grep -qPi ';\s*rm\s'; then
  deny "Potential command injection pattern detected (;rm)."
fi

# Block backtick command substitution with dangerous commands
if printf '%s' "$command" | grep -qPi '`.*rm\s+-[a-zA-Z]*r.*`'; then
  deny "Dangerous command in backtick substitution."
fi

# All checks passed
exit 0
