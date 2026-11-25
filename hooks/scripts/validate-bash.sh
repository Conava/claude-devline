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
permission_mode=$(printf '%s\n' "$input" | jq -r '.permission_mode // "default"' 2>/dev/null || echo "default")

if [[ -z "$command" ]]; then
  exit 0
fi

# These rules backstop unattended runs (auto-accept/bypass mode), where
# Claude Code's own per-tool prompt is off. In plain "default" mode that
# prompt already gates every Bash call, so enforcing here too is pure
# redundant friction.
if [[ "$permission_mode" == "default" ]]; then
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

# Asks are collected, not emitted at once, so a deny later in the same command
# (`rm -rf /etc/x; cat ~/.ssh/id_rsa`) still wins.
ask_reasons=()
ask() {
  ask_reasons+=("$1")
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=./patterns.sh
source "$(dirname "${BASH_SOURCE[0]}")/patterns.sh"

# Commands run over ssh act on another machine: the local-service rule doesn't
# apply there; catastrophe and credential rules still do.
remote=0
if printf '%s' "$command" | grep -qP "${CMD}ssh\s"; then
  remote=1
fi

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

# The hook's cwd is where the session started, so `cd /repo/worktree && bash
# x.sh` would otherwise resolve x.sh in the wrong checkout.
# ponytail: only a leading cd; a cd later in a chain is not followed.
if [[ "$command" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\;\|\&]+)[[:space:]]*(\&\&|\;) ]]; then
  cwd=$(resolve "${BASH_REMATCH[1]}")
fi

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
      ask "$label ($f) contains a dangerous operation: ${hit//$'\n'/ }"
      return 0
    fi
  done
}

# =============================================================================
# DESTRUCTIVE FILESYSTEM OPERATIONS (always hard deny)
# =============================================================================

if printf '%s' "$command" | grep -qPi -- '--no-preserve-root'; then
  deny "rm --no-preserve-root exists only to delete the root filesystem. Not allowed."
fi

# Deletes are allowed anywhere except where they wreck the system, the whole
# home directory, or credentials. Every rm counts, not only -rf: deleting one
# private key is as unrecoverable as deleting the directory. `git rm` only
# touches the index.
# Heredoc bodies are script text, not commands: drop them before looking for rm.
rm_command=$(printf '%s' "$command" | perl -0pe 's/(<<-?\s*([\x27"]?)(\w+)\2[^\n]*\n).*?\n[ \t]*\3[ \t]*(?=\n|$)/$1/gs')
if printf '%s' "$rm_command" | grep -qP '(?<!git\s)(?<![\w-])rm\s'; then
  # Every target, not just the first: `rm -rf ./build /` must not pass on ./build
  targets=$(printf '%s' "$rm_command" | grep -oP '(?<!git\s)(?<![\w-])rm\s+\K[^;|&\n]+' || true)

  set -f
  for target in $targets; do
    if [[ "$target" == -* ]]; then
      continue
    fi
    abs_target=$(resolve "$target")
    # A glob is judged by its directory: `rm -rf ~/*` is ~. Only a bare `*`
    # empties it; `rm *.png` removes some files, not the folder or repo.
    some_files=0
    if [[ "$abs_target" == *[*?[]* ]]; then
      [[ "$(basename -- "$abs_target")" =~ ^\.?\*$ ]] || some_files=1
      abs_target=$(dirname -- "${abs_target%%[*?[]*}x")
    fi
    # The pipeline's own work (scratch, design dirs, worktrees, caches) can always go.
    own=0
    case "$abs_target" in
      */.devline/*|*/.claude/worktrees/*|*.worktrees/*|/tmp/claude-*/*|"$HOME"/.cache/devline*/*) own=1 ;;
    esac

    case "$abs_target" in
      /|/home|"$HOME"|/etc|/usr|/var|/root|/boot|/bin|/sbin|/lib|/lib64|/proc|/sys|/dev)
        deny "rm targeting $abs_target would wreck the system or the home directory. Not allowed."
        ;;
      /opt|/srv|/mnt|/media|/nix|/run|/tmp|"$HOME"/.config|"$HOME"/.local|"$HOME"/.local/share|/etc/*|/usr/*|/boot/*|/bin/*|/sbin/*|/lib/*|/lib64/*|/root/*|/var/lib/*)
        ask "rm of $abs_target may break the system or every app's config."
        ;;
      "$HOME"/.aws|"$HOME"/.kube)
        deny "rm of a credential store ($abs_target). Not allowed."
        ;;
    esac
    if printf '%s' "$abs_target" | grep -qP "$CRED_PATHS"; then
      deny "rm of private keys or credentials ($abs_target). Not allowed."
    fi
    if (( own || some_files )); then
      :
    elif [[ -d "$abs_target" && "$abs_target" == "$HOME"/[!.]* && "$abs_target" != "$HOME"/*/* ]]; then
      ask "rm of the whole $abs_target folder."
    elif [[ -d "$abs_target/.git" ]]; then
      ask "rm of a whole git repository ($abs_target): unpushed work and untracked files are lost."
    fi
  done
  set +f
fi

# Block mkfs, fdisk, dd on devices
if printf '%s' "$command" | grep -qPi '(mkfs|fdisk|dd\s+.*of=/dev)'; then
  deny "Disk/partition operations not allowed."
fi

# =============================================================================
# GIT — IRREVERSIBLE HISTORY / WORKING-COPY LOSS
# =============================================================================

# Bare force push overwrites whatever is on the remote. --force-with-lease is
# the normal way to update a rebased branch: it refuses if someone else pushed.
if printf '%s' "$command" | grep -qPi 'git\s+push\b(?![^;|&]*--force-with-lease)[^;|&]*(--force(?![-\w])|\s-f(\s|$)|\s\+[\w/.-]+)'; then
  ask "Bare force push overwrites the remote branch; --force-with-lease is safer."
fi

# Hard reset — discards uncommitted work irreversibly
if printf '%s' "$command" | grep -qPi 'git\s+reset\s+.*--hard'; then
  ask "git reset --hard discards uncommitted work."
fi

# git clean with a force flag — deletes untracked files irreversibly
if printf '%s' "$command" | grep -qPi 'git\s+clean\s+.*(--force|-\w*f)'; then
  ask "git clean -f permanently deletes untracked files (check with git clean -n)."
fi

# =============================================================================
# PUBLISHING AND RELEASES (never autonomous — user runs these manually)
# =============================================================================

# Package publishing
if printf '%s' "$command" | grep -qPi '(npm\s+publish|cargo\s+publish|twine\s+upload|pip\s+upload|gem\s+push|dotnet\s+nuget\s+push|mvn\s+deploy|gradle\s+publish)'; then
  ask "Publishing a package is public and can't be undone."
fi

# Container image push
if printf '%s' "$command" | grep -qPi '(docker\s+push|podman\s+push|buildah\s+push)'; then
  ask "Pushing a container image publishes it."
fi

# =============================================================================
# GITHUB SHARED-STATE MUTATIONS (affects state outside your working copy)
# =============================================================================

# PR merge/close/reopen
if printf '%s' "$command" | grep -qPi 'gh\s+pr\s+(merge|close|reopen)'; then
  ask "Merging/closing/reopening a PR acts in your name on GitHub."
fi

# Issue close/comment/delete
if printf '%s' "$command" | grep -qPi 'gh\s+issue\s+(close|delete|comment)'; then
  ask "Commenting on/closing/deleting an issue acts in your name on GitHub."
fi

# =============================================================================
# DATABASE DESTRUCTIVE OPERATIONS
# =============================================================================

# SQL destructive statements (case insensitive, across common CLI tools)
if printf '%s' "$command" | grep -qPi '(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX|VIEW)|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\S+\s*($|;|\s*--|\s+WHERE\s+1)|DELETE\s+FROM\s+\S+\s*;)'; then
  ask "Destructive database operation (DROP/TRUNCATE/bulk DELETE)."
fi

# =============================================================================
# CONTAINER PRIVILEGE ESCALATION
# Membership in the docker group is equivalent to uid 0 on the host, so a
# container flag is a root shell. Ordinary dev usage (build, run, exec, compose,
# port publishing, project-local mounts) is untouched.
# =============================================================================

if printf '%s' "$command" | grep -qPi "${CMD}(docker|podman|nerdctl)\b"; then
  if printf '%s' "$command" | grep -qPi -- "$DOCKER_ESCALATION"; then
    ask "Container escalation flag (--privileged / --cap-add / --device / host namespace / unconfined security-opt) grants host root."
  fi

  if printf '%s' "$command" | grep -qPi '(volume\s+(rm|prune)|system\s+prune\b[^;|&]*--volumes)'; then
    ask "Deleting container volumes deletes the data in them (databases, uploads)."
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
      "$HOME"/.ssh|"$HOME"/.gnupg|"$HOME"/.aws|"$HOME"/.kube|"$HOME"/.password-store)
        deny "Mounting $abs_mount into a container exposes credentials. Not allowed."
        ;;
      /|/proc|/sys|/dev|/boot|/run/docker.sock|/var/run/docker.sock)
        ask "Bind-mounting $abs_mount into a container gives it host root access."
        ;;
    esac

    # System paths are fine read-only (/etc/localtime is everywhere), not writable
    if [[ ",$mount_opts," != *",ro,"* ]]; then
      case "$abs_mount" in
        /etc|/usr|/var|/lib|/lib64|/bin|/sbin|/root|/home|"$HOME")
          ask "Writable bind mount of $abs_mount into a container (mount it :ro if it only reads)."
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

# System services on this machine (display manager, network) can take the
# session down. User services (--user) are the user's own.
if ((!remote)) && ! printf '%s' "$command" | grep -qP 'systemctl\s[^;|&]*--user' && printf '%s' "$command" | grep -qPi '(systemctl|service)\s+(\S+\s+)?(start|stop|restart|enable|disable)'; then
  ask "Controlling a system service can take the session or network down."
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

if printf '%s' "$command" | grep -qPi "${CMD}(mv|shred|truncate|dd)\s+[^;|&]*${CRED_PATHS}|>\s*[^\s;|&]*${CRED_PATHS}"; then
  deny "Moving, overwriting or destroying private keys or credential stores is not allowed."
fi

if printf '%s' "$command" | grep -qPi "${CMD}(passwd|chpasswd|chage)\b|${CMD}usermod\s[^;|&]*(-p|--password)\b"; then
  deny "Changing user passwords is not allowed."
fi

# Commands whose job is to print a stored secret or token.
if printf '%s' "$command" | grep -qPi "${CMD}(gh\s+auth\s+token|secret-tool\s+lookup|git\s+credential\s+fill|docker-credential-\S+\s+get|gcloud\s+auth\s+(application-default\s+)?print-(access|identity)-token|az\s+account\s+get-access-token|aws\s+configure\s+get\s+\S*(secret|key)|vault\s+(kv\s+get|read)|kubectl\s+get\s+secrets?\b[^;|&]*(-o|--output)|gpg\s+[^;|&]*(--decrypt|--export-secret))|${CMD_START}pass(\s+show)?\s+(?!ls\b|find\b|--help\b)[\w./-]+"; then
  deny "Printing a stored secret or token is not allowed. Use it in place (e.g. via an env var the tool reads) without displaying it."
fi

# Dumping the environment prints every secret in it; `env FOO=1 cmd` is fine.
if printf '%s' "$command" | grep -qP "${CMD}(env|printenv)\s*(\$|[;|&>])|${CMD}printenv\s+\w*(KEY|SECRET|TOKEN(?!S\b)|PASSWORD|CREDENTIAL|PRIVATE)"; then
  deny "Dumping environment variables would expose secrets. Check a single non-secret variable instead."
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

if printf '%s' "$command" | grep -qPi 'chmod\s+(-\w*R\w*|--recursive)\s+[0-7]?777'; then
  ask "Recursive chmod 777 makes a whole tree world-writable."
fi

if printf '%s' "$command" | grep -qP "${CMD}crontab\s+(-\w*r|--remove)"; then
  ask "crontab -r removes every cron job of the user."
fi

# Writing authorized_keys grants ssh logins; reading it and chmod are harmless.
if printf '%s' "$command" | grep -qP "(>|${CMD}(tee|cp|mv|rm|truncate|install|ln)\b|${CMD}(sed|perl)\s+[^;|&]*-i)[^;|&]*authorized_keys"; then
  ask "Writing authorized_keys grants ssh access to whoever holds that key."
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

if ((${#ask_reasons[@]})); then
  jq -nc --arg r "$(printf '%s ' "${ask_reasons[@]}")" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
fi
exit 0
