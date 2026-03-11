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

# ---------- Locate config files ----------
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DEFAULTS_CONFIG="$PLUGIN_ROOT/config/defaults.yaml"
USER_CONFIG="${HOME}/.claude-plugin-config.yaml"
PROJECT_CONFIG="${CLAUDE_PROJECT_DIR:+${CLAUDE_PROJECT_DIR}/.claude/plugin-config.yaml}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# ---------- Parse configs with python3 ----------
read_config() {
  python3 - "$DEFAULTS_CONFIG" "$USER_CONFIG" "${PROJECT_CONFIG:-}" <<'PYEOF'
import sys, json, os

def load_yaml_simple(path):
    """Minimal YAML-subset parser using python3 (PyYAML not guaranteed)."""
    if not path or not os.path.isfile(path):
        return {}
    try:
        import yaml
        with open(path) as f:
            return yaml.safe_load(f) or {}
    except ImportError:
        pass
    data = {}
    stack = [(data, -1)]
    current_key = None
    with open(path) as f:
        for line in f:
            stripped = line.rstrip()
            if not stripped or stripped.lstrip().startswith('#'):
                continue
            indent = len(line) - len(line.lstrip())
            content = stripped.lstrip()
            while len(stack) > 1 and indent <= stack[-1][1]:
                stack.pop()
            parent = stack[-1][0]
            if content.startswith('- '):
                val = content[2:].strip().strip('"').strip("'")
                # Search up the stack for the dict containing current_key.
                # The key may be an empty dict (no inline value on the key line);
                # the first list item tells us it's a list — convert it then append.
                for frame_dict, _ in reversed(stack):
                    if current_key and current_key in frame_dict:
                        target = frame_dict[current_key]
                        if isinstance(target, dict) and not target:
                            frame_dict[current_key] = []
                            target = frame_dict[current_key]
                        if isinstance(target, list):
                            target.append(val)
                        break
                continue
            if ':' in content:
                key, _, val = content.partition(':')
                key = key.strip()
                val = val.strip().strip('"').strip("'")
                if val:
                    parent[key] = val
                else:
                    parent[key] = {}
                    stack.append((parent[key], indent))
                current_key = key
    return data

def deep_get(d, *keys):
    for k in keys:
        if isinstance(d, dict):
            d = d.get(k, {})
        else:
            return []
    return d if isinstance(d, list) else []

def merge_lists(base, override):
    return override if override else base

defaults_path = sys.argv[1]
user_path = sys.argv[2]
project_path = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else ""

defaults = load_yaml_simple(defaults_path)
user_cfg = load_yaml_simple(user_path)
project_cfg = load_yaml_simple(project_path)

blocked_commands = deep_get(defaults, 'safeguards', 'blocked_commands')
blocked_patterns = deep_get(defaults, 'safeguards', 'blocked_patterns')
protected_branches = deep_get(defaults, 'git', 'protected_branches')

never_push = True
git_cfg = defaults.get('git', {})
if isinstance(git_cfg, dict):
    np = git_cfg.get('never_push', True)
    if isinstance(np, bool):
        never_push = np
    elif isinstance(np, str):
        never_push = np.lower() not in ('false', 'no', '0')

for cfg in [user_cfg, project_cfg]:
    if not cfg:
        continue
    bc = deep_get(cfg, 'safeguards', 'blocked_commands')
    bp = deep_get(cfg, 'safeguards', 'blocked_patterns')
    pb = deep_get(cfg, 'git', 'protected_branches')
    blocked_commands = merge_lists(blocked_commands, bc)
    blocked_patterns = merge_lists(blocked_patterns, bp)
    protected_branches = merge_lists(protected_branches, pb)
    g = cfg.get('git', {})
    if isinstance(g, dict) and 'never_push' in g:
        np = g['never_push']
        if isinstance(np, bool):
            never_push = np
        elif isinstance(np, str):
            never_push = np.lower() not in ('false', 'no', '0')

if not never_push:
    blocked_commands = [c for c in blocked_commands if c != 'git push']
    blocked_patterns = [p for p in blocked_patterns
                        if 'push' not in p or 'checkout' in p or 'merge' in p]

result = {
    "blocked_commands": blocked_commands,
    "blocked_patterns": blocked_patterns,
    "protected_branches": protected_branches,
    "never_push": never_push,
}
print(json.dumps(result))
PYEOF
}

CONFIG_JSON="$(read_config 2>/dev/null || echo "")"

if [[ -z "$CONFIG_JSON" ]]; then
  CONFIG_JSON='{"blocked_commands":["git push","git fetch","git pull","git clone","git ls-remote","git remote update","git submodule update --remote","rm -r /","ssh ","scp ","sftp "],"blocked_patterns":["git\\s+(push|fetch|pull|clone|ls-remote)","git\\s+remote\\s+update","git\\s+submodule\\s+update\\s+.*--remote","\\bssh\\s+","\\bscp\\s+","\\bsftp\\s+"],"protected_branches":["main","master","develop","development","staging","production","release","release/*","hotfix","trunk"]}'
fi

# ---------- Extract arrays from CONFIG_JSON ----------
BLOCKED_COMMANDS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && BLOCKED_COMMANDS+=("$line")
done < <(printf '%s' "$CONFIG_JSON" | python3 -c "
import sys,json
for c in json.load(sys.stdin).get('blocked_commands',[]):
    print(c)
" 2>/dev/null || true)

BLOCKED_PATTERNS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && BLOCKED_PATTERNS+=("$line")
done < <(printf '%s' "$CONFIG_JSON" | python3 -c "
import sys,json
for p in json.load(sys.stdin).get('blocked_patterns',[]):
    print(p)
" 2>/dev/null || true)

PROTECTED_BRANCHES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && PROTECTED_BRANCHES+=("$line")
done < <(printf '%s' "$CONFIG_JSON" | python3 -c "
import sys,json
for b in json.load(sys.stdin).get('protected_branches',[]):
    print(b)
" 2>/dev/null || true)

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
