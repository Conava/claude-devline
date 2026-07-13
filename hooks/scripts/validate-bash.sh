#!/bin/bash
set -eo pipefail

# Safety net: if the hook crashes unexpectedly, allow the action to proceed
# rather than showing "hook error" to the user. Exit 0 = action proceeds.
trap 'exit 0' ERR

# Devline security hook: validate Bash commands in bypass mode.
# Guards against IRREVERSIBLE / destructive damage and credential exposure.
# Workflow-policy checks (commit-message format, protected-branch pushes,
# tags/releases, squash-merge, reset/clean/stash-drop) were removed on the
# scrub branch — this stops catastrophe, not process.

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
exec 3>&2 2>>/tmp/devline-hook-debug.log

deny() {
  echo "BLOCKED: $1" >&3
  exit 2
}

ask() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# =============================================================================
# DESTRUCTIVE FILESYSTEM OPERATIONS (always hard deny)
# =============================================================================

# Detect rm with recursive+force flags (exclude `git rm` which only affects the index)
if printf '%s' "$command" | grep -qP '(?<!git\s)rm\s+(-[a-zA-Z]*[rf]){1,}\s'; then
  target=$(printf '%s' "$command" | grep -oP 'rm\s+(-[a-zA-Z]+\s+)*\K([^\s;|&"]+)' | head -1 || true)

  if [[ -n "$target" ]]; then
    if [[ -n "$cwd" ]]; then
      abs_target=$(cd "$cwd" && realpath -m "$target" 2>/dev/null || echo "$target")
    else
      abs_target=$(realpath -m "$target" 2>/dev/null || echo "$target")
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
# GIT — IRREVERSIBLE HISTORY / WORKING-COPY LOSS
# =============================================================================

# Force push (--force, -f, --force-with-lease)
if printf '%s' "$command" | grep -qPi 'git\s+push\s+.*(--force|--force-with-lease|\s-f(\s|$))'; then
  deny "Force push not allowed. Use normal push."
fi

# Hard reset — discards uncommitted work irreversibly
if printf '%s' "$command" | grep -qPi 'git\s+reset\s+.*--hard'; then
  deny "git reset --hard discards uncommitted work. Stash or commit first, or run it manually."
fi

# git clean with a force flag — deletes untracked files irreversibly
if printf '%s' "$command" | grep -qPi 'git\s+clean\s+.*(--force|-\w*f)'; then
  deny "git clean -f permanently deletes untracked files. Review with 'git clean -n' first, or run it manually."
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

# =============================================================================
# GITHUB SHARED-STATE MUTATIONS (affects state outside your working copy)
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

# shellcheck disable=SC2016
# Note: TOKEN(?!S\b) excludes plural TOKENS (e.g. MAX_OUTPUT_TOKENS — an LLM
# token count, not a credential). Singular TOKEN still matches (GITHUB_TOKEN).
if printf '%s' "$command" | grep -qPi '(echo|printf|cat)\s.*\$(.*_(KEY|SECRET|TOKEN(?!S\b)|PASSWORD|CREDENTIAL|PRIVATE).*)'; then
  deny "Printing environment variables that may contain secrets."
fi

# shellcheck disable=SC2016
if printf '%s' "$command" | grep -qPi 'curl\s.*(-d|--data).*\$(.*_(KEY|SECRET|TOKEN(?!S\b)|PASSWORD).*)'; then
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

# shellcheck disable=SC2016
if printf '%s' "$command" | grep -qPi '`.*rm\s+-[a-zA-Z]*r.*`'; then
  deny "Dangerous command in backtick substitution."
fi

# All checks passed
exit 0
