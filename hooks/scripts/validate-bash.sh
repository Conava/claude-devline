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

# shellcheck source=./patterns.sh
source "$(dirname "${BASH_SOURCE[0]}")/patterns.sh"

# Absolute path for a command-line argument: expands ~ and $HOME (the hook sees
# the raw string, unexpanded), strips quotes, resolves against the tool's cwd.
resolve() {
  local p="${1//\$\{HOME\}/$HOME}"
  p="${p//\$HOME/$HOME}"
  p="${p/#\~/$HOME}"
  p="${p//\"/}"
  p="${p//\'/}"
  if [[ -n "$cwd" && -d "$cwd" ]]; then
    (cd "$cwd" && realpath -m -- "$p" 2>/dev/null) || printf '%s' "$p"
  else
    realpath -m -- "$p" 2>/dev/null || printf '%s' "$p"
  fi
}

# Deny if any pattern in CONTENT_PATTERNS appears in a file about to be run.
# ponytail: one level deep — a script that invokes another script is not
# followed. Upgrade path if that ever matters: recurse with a depth counter.
scan_file() {
  local f="$1" label="$2" pat hit
  if [[ ! -f "$f" || ! -r "$f" ]]; then
    return 0
  fi
  for pat in "${CONTENT_PATTERNS[@]}"; do
    hit=$(head -c 200000 -- "$f" | grep -nPi -m1 -- "$pat" 2>&3 || true)
    if [[ -n "$hit" ]]; then
      deny "$label ($f) contains a dangerous operation and will not be run automatically: ${hit//$'\n'/ } — run it manually if that is intended."
    fi
  done
}

# =============================================================================
# DESTRUCTIVE FILESYSTEM OPERATIONS (always hard deny)
# =============================================================================

if printf '%s' "$command" | grep -qPi -- '--no-preserve-root'; then
  deny "rm --no-preserve-root exists only to delete the root filesystem. Not allowed."
fi

# Detect rm with recursive+force flags (exclude `git rm` which only affects the index)
if printf '%s' "$command" | grep -qP '(?<!git\s)rm\s+(-[a-zA-Z]*[rf]){1,}\s'; then
  # Every target, not just the first — `rm -rf ./build /` must not pass on ./build
  targets=$(printf '%s' "$command" | grep -oP '(?<!git\s)(?<![\w-])rm\s+\K[^;|&\n]+' || true)

  set -f
  for target in $targets; do
    if [[ "$target" == -* ]]; then
      continue
    fi
    abs_target=$(resolve "$target")

    case "$abs_target" in
      /|/home|/etc|/usr|/var|/sys|/boot|/proc|/dev|/opt|/lib|/lib64|/bin|/sbin|/root|/srv|/mnt|/media|/nix|/run|"$HOME"|"$HOME"/.ssh|"$HOME"/.gnupg|"$HOME"/.aws|"$HOME"/.config|"$HOME"/.local)
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
  done
  set +f

  if [[ -n "$targets" && -n "$cwd" ]] && ! git -C "$cwd" rev-parse --is-inside-work-tree 2>&3 1>/dev/null; then
    deny "rm -rf in a non-git directory. Only allowed in git-protected repositories."
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
# CONTAINER PRIVILEGE ESCALATION
# Membership in the docker group is equivalent to uid 0 on the host, so a
# container flag is a root shell. Ordinary dev usage (build, run, exec, compose,
# port publishing, project-local mounts) is untouched.
# =============================================================================

if printf '%s' "$command" | grep -qPi "${CMD}(docker|podman|nerdctl)\b"; then
  if printf '%s' "$command" | grep -qPi -- "$DOCKER_ESCALATION"; then
    deny "Container escalation flag (--privileged / --cap-add / --device / host namespace / unconfined security-opt) grants host root. Run it manually."
  fi

  mounts=$(printf '%s' "$command" | grep -oPi '(-v|--volume)[= ]\s*\K[^\s;|&]+' || true)
  mount_flags=$(printf '%s' "$command" | grep -oPi '\-\-mount[= ]\s*\K[^\s;|&]+' | grep -oPi '(source|src)=\K[^,]+' || true)
  mounts=$(printf '%s\n%s' "$mounts" "$mount_flags")

  set -f
  for mount in $mounts; do
    # Named volumes ("pgdata:/var/lib/postgresql") are not host paths
    case "$mount" in
      /*|~*|.*|\$*) ;;
      *) continue ;;
    esac
    IFS=':' read -r mount_src _ mount_opts <<<"$mount"
    abs_mount=$(resolve "$mount_src")

    # Host root, kernel interfaces and credential stores — blocked even :ro
    case "$abs_mount" in
      /|/proc|/sys|/dev|/boot|/run/docker.sock|/var/run/docker.sock|"$HOME"/.ssh|"$HOME"/.gnupg|"$HOME"/.aws|"$HOME"/.kube)
        deny "Bind-mounting $abs_mount into a container is host root access. Not allowed."
        ;;
    esac

    # System paths are fine read-only (/etc/localtime is everywhere), not writable
    if [[ ",$mount_opts," != *",ro,"* ]]; then
      case "$abs_mount" in
        /etc|/usr|/var|/lib|/lib64|/bin|/sbin|/root|/home|"$HOME")
          deny "Writable bind mount of $abs_mount into a container. Mount it :ro, or use a project-local path."
          ;;
      esac
    fi
  done
  set +f
fi

# =============================================================================
# EXTERNAL MUTATIONS (affects systems outside the project)
# =============================================================================

# curl/wget with mutating HTTP methods to non-localhost
if printf '%s' "$command" | grep -qPi 'curl\s+.*-X\s*(POST|PUT|DELETE|PATCH)' && ! printf '%s' "$command" | grep -qPi 'curl\s+.*https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])'; then
  ask "HTTP mutation (POST/PUT/DELETE/PATCH) to external URL detected."
fi

# SSH/SCP to remote hosts. Lookbehind keeps it to command position — otherwise
# 'git -c gpg.format=ssh' (SSH commit signing) and '~/.ssh/...' paths match.
if printf '%s' "$command" | grep -qPi '(?<![\w=./-])(ssh|scp)\s+' && ! printf '%s' "$command" | grep -qPi '(?<![\w=./-])(ssh|scp)\s+.*localhost'; then
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

# Private key material and credential stores: contents are off-limits, but
# metadata (ls, stat, chmod), key creation (ssh-keygen) and use-without-reading
# (ssh -i, git's user.signingKey) all still work.
if printf '%s' "$command" | grep -qPi "${CMD}${READERS}\s+[^;|&]*${CRED_PATHS}|<\s*[^\s;|&]*${CRED_PATHS}"; then
  deny "Reading private key material or credential stores is not allowed. ls/stat/chmod and ssh-keygen are fine, as are *.pub, ~/.ssh/config and known_hosts."
fi

# .env: create and append freely, never read the contents back.
if printf '%s' "$command" | grep -qPi "${CMD}${ENV_READERS}\s+[^;|&]*${ENV_PATH}"; then
  deny ".env contents must not be read. Creating and appending (touch, >>, cp from .env.example) is allowed, and .env.example is readable."
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

# =============================================================================
# EXECUTABLE CONTENT (the file about to be run, not just the command line)
# Authoring these files is always allowed — only automatic execution is gated.
# =============================================================================

# Compose stacks, but only the subcommands that actually start containers
# (config/ps/logs stay usable on a stack this would refuse to bring up).
if printf '%s' "$command" | grep -qPi "${CMD}(docker\s+compose|docker-compose)\b[^;|&]*\b(up|run|start|create|restart|exec)\b"; then
  compose_files=$(printf '%s' "$command" | grep -oPi '(-f|--file)[= ]\s*\K[^\s;|&]+' || true)
  if [[ -z "$compose_files" ]]; then
    for candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
      if [[ -f "$(resolve "$candidate")" ]]; then
        compose_files+=$'\n'"$candidate"
      fi
    done
  fi
  set -f
  for compose_file in $compose_files; do
    scan_file "$(resolve "$compose_file")" "Compose file"
  done
  set +f
fi

# Shell scripts invoked by path
scripts=$(printf '%s' "$command" | grep -oPi "${CMD}(bash|sh|zsh|ksh|source)\s+(-[a-zA-Z]+\s+)*\K[^\s;|&]+" || true)
scripts+=$'\n'"$(printf '%s' "$command" | grep -oP '(?<![\w.-])\./[^\s;|&]+' || true)"
set -f
for script in $scripts; do
  case "$script" in
    -*) continue ;;
  esac
  scan_file "$(resolve "$script")" "Script"
done
set +f

# All checks passed
exit 0
