#!/usr/bin/env bash
# guard.sh — PreToolUse hook for Claude Code
# Intercepts Bash tool calls and blocks dangerous operations.
# Receives JSON via stdin, checks command against blocked patterns.
# Exit 0 = allow, Exit 2 = block (deny JSON on stderr).
set -euo pipefail

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
# Catches: sh -c "git push", bash -c "git push", bash <<< "git push",
#          echo "git push" | bash, eval "git push", $CMD where CMD="git push"
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

# Check both the original and unwrapped command
COMMANDS_TO_CHECK=("$COMMAND")
if [[ "$EFFECTIVE_COMMAND" != "$COMMAND" ]]; then
  COMMANDS_TO_CHECK+=("$EFFECTIVE_COMMAND")
fi

# ---------- Locate config files ----------
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DEFAULTS_CONFIG="$PLUGIN_ROOT/config/defaults.yaml"
USER_CONFIG="${HOME}/.claude-plugin-config.yaml"
PROJECT_CONFIG="${CLAUDE_PROJECT_DIR:+${CLAUDE_PROJECT_DIR}/.claude-plugin-config.yaml}"

# ---------- Parse configs with python3 ----------
# Merges config files in order: defaults < user < project (most specific wins).
# Falls back to hard-coded defaults if python3 or configs are unavailable.

read_config() {
  python3 - "$DEFAULTS_CONFIG" "$USER_CONFIG" "${PROJECT_CONFIG:-}" <<'PYEOF'
import sys, json, os

def load_yaml_simple(path):
    """Minimal YAML-subset parser using python3 (PyYAML not guaranteed).
    Falls back to a very small pure-python parser that handles the subset
    we need: lists of strings under nested keys."""
    if not path or not os.path.isfile(path):
        return {}
    try:
        import yaml
        with open(path) as f:
            return yaml.safe_load(f) or {}
    except ImportError:
        pass
    # Fallback: hand-rolled parser for our simple YAML subset
    data = {}
    stack = [(data, -1)]  # (current_dict, indent)
    current_key = None
    with open(path) as f:
        for line in f:
            stripped = line.rstrip()
            if not stripped or stripped.lstrip().startswith('#'):
                continue
            indent = len(line) - len(line.lstrip())
            content = stripped.lstrip()
            # Pop stack to correct nesting level
            while len(stack) > 1 and indent <= stack[-1][1]:
                stack.pop()
            parent = stack[-1][0]
            if content.startswith('- '):
                # List item
                val = content[2:].strip().strip('"').strip("'")
                if current_key and current_key in parent:
                    if isinstance(parent[current_key], list):
                        parent[current_key].append(val)
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
                # Prepare for list values under this key
                if not val:
                    parent[key] = []
                    # But it might be a dict — we'll fix if we see sub-keys
    return data

def deep_get(d, *keys):
    for k in keys:
        if isinstance(d, dict):
            d = d.get(k, {})
        else:
            return []
    return d if isinstance(d, list) else []

def merge_lists(base, override):
    """Override list replaces base entirely if non-empty."""
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

# Read never_push (default true; only false if explicitly overridden)
never_push = True
git_cfg = defaults.get('git', {})
if isinstance(git_cfg, dict):
    np = git_cfg.get('never_push', True)
    if isinstance(np, bool):
        never_push = np
    elif isinstance(np, str):
        never_push = np.lower() not in ('false', 'no', '0')

# Merge: user overrides defaults, project overrides user
for cfg in [user_cfg, project_cfg]:
    if not cfg:
        continue
    bc = deep_get(cfg, 'safeguards', 'blocked_commands')
    bp = deep_get(cfg, 'safeguards', 'blocked_patterns')
    pb = deep_get(cfg, 'git', 'protected_branches')
    blocked_commands = merge_lists(blocked_commands, bc)
    blocked_patterns = merge_lists(blocked_patterns, bp)
    protected_branches = merge_lists(protected_branches, pb)
    # Override never_push from user/project config
    g = cfg.get('git', {})
    if isinstance(g, dict) and 'never_push' in g:
        np = g['never_push']
        if isinstance(np, bool):
            never_push = np
        elif isinstance(np, str):
            never_push = np.lower() not in ('false', 'no', '0')

# If never_push is false, remove "git push" from blocked lists
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

# Try to load config via python3; fall back to inline defaults
CONFIG_JSON="$(read_config 2>/dev/null || echo "")"

if [[ -z "$CONFIG_JSON" ]]; then
  # Hard-coded fallback if python3 is unavailable
  CONFIG_JSON='{"blocked_commands":["git push","git fetch","git pull","git clone","git ls-remote","git remote update","git submodule update --remote","git checkout main","git checkout master","git merge main","git merge master","rm -rf","rm -r /","--force","--hard","git reset","git clean","ssh ","scp ","sftp "],"blocked_patterns":["git\\s+(push|fetch|pull|clone|ls-remote)","git\\s+remote\\s+update","git\\s+submodule\\s+update\\s+.*--remote","\\bssh\\s+","\\bscp\\s+","\\bsftp\\s+","git\\s+(checkout\\s+(main|master|develop|staging|production|release|trunk)|merge\\s+(main|master|develop|staging|production|release|trunk))","rm\\s+-[rf]{2,}","--force","--hard","git\\s+(reset|clean)"],"protected_branches":["main","master","develop","development","staging","production","release","release/*","hotfix","trunk"]}'
fi

# ---------- Extract arrays from CONFIG_JSON ----------
mapfile -t BLOCKED_COMMANDS < <(printf '%s' "$CONFIG_JSON" | python3 -c "
import sys,json
for c in json.load(sys.stdin).get('blocked_commands',[]):
    print(c)
" 2>/dev/null || true)

mapfile -t BLOCKED_PATTERNS < <(printf '%s' "$CONFIG_JSON" | python3 -c "
import sys,json
for p in json.load(sys.stdin).get('blocked_patterns',[]):
    print(p)
" 2>/dev/null || true)

mapfile -t PROTECTED_BRANCHES < <(printf '%s' "$CONFIG_JSON" | python3 -c "
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
    # Support glob-style patterns like release/*
    if [[ "$branch" == "$pb" ]]; then
      return 0
    fi
    # Glob match (e.g. release/* matches release/v1.2)
    # shellcheck disable=SC2254
    case "$branch" in
      $pb) return 0 ;;
    esac
  done
  return 1
}

# ---------- Smart git merge / checkout logic ----------
# For merge and checkout commands, extract the target branch and decide:
#   - protected branch → block
#   - non-protected branch → allow (skip further blocked_commands/patterns checks)

check_smart_git() {
  local cmd="$1"

  # git merge <branch> — extract branch name
  if [[ "$cmd" =~ git[[:space:]]+merge[[:space:]]+([^[:space:]-][^[:space:]]*) ]]; then
    local target="${BASH_REMATCH[1]}"
    if is_protected_branch "$target"; then
      deny "Blocked: git merge $target is not allowed. Protected branch. Use /merge-prep when ready for PR."
    fi
    # Non-protected branch merge is explicitly allowed
    exit 0
  fi

  # git checkout <branch> — extract branch name (skip flags like -b, --)
  if [[ "$cmd" =~ git[[:space:]]+checkout[[:space:]]+([^[:space:]-][^[:space:]]*) ]]; then
    local target="${BASH_REMATCH[1]}"
    if is_protected_branch "$target"; then
      deny "Blocked: git checkout $target is not allowed. Protected branch."
    fi
    # Non-protected branch checkout is explicitly allowed
    exit 0
  fi
}

# Run smart git logic on all command variants (may exit early)
for cmd_variant in "${COMMANDS_TO_CHECK[@]}"; do
  check_smart_git "$cmd_variant"
done

# ---------- Check blocked_commands (substring match) ----------
for cmd_variant in "${COMMANDS_TO_CHECK[@]}"; do
  for bc in "${BLOCKED_COMMANDS[@]}"; do
    if [[ "$cmd_variant" == *"$bc"* ]]; then
      # Build a helpful suggestion
      suggestion=""
      case "$bc" in
        "git push"*)   suggestion=" Use /merge-prep when ready for PR." ;;
        "git fetch"*|"git pull"*|"git clone"*|"git ls-remote"*|"git remote update"*|"git submodule update --remote"*) suggestion=" Agents work locally only. No remote/network operations allowed." ;;
        "ssh "*|"scp "*|"sftp "*) suggestion=" SSH operations are not allowed. Agents work locally only." ;;
        "rm -rf"*|"rm -r /"*) suggestion=" Specify exact paths or use git clean with caution." ;;
        "git reset"*)  suggestion=" Consider git stash or git revert instead." ;;
        "git clean"*)  suggestion=" Consider git stash instead." ;;
        "--force"*)    suggestion=" Force operations are dangerous. Review changes first." ;;
        "--hard"*)     suggestion=" Consider git stash or a softer reset." ;;
      esac
      deny "Blocked: ${bc} is not allowed.${suggestion}"
    fi
  done
done

# ---------- Check blocked_patterns (regex match) ----------
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

# ---------- All checks passed ----------
exit 0
