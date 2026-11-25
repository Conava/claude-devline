#!/bin/bash
set -eo pipefail
trap 'exit 0' ERR

# Devline SessionStart/SubagentStart hook: inject the always-on conduct and
# voice rules, and the user's personal voice layer if one exists.
#
# Usage: inject-voice.sh conduct|voice|personal
#
# Each mode is a separate hook output. Claude Code turns additionalContext
# over about 10,000 characters into a short preview plus a file, and parallel
# outputs arrive in any order, so each mode must stay small and stand alone.

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
core="$root/skills/voice/core"
max=9000

input=$(cat)
event=$(printf '%s\n' "$input" | jq -r '.hook_event_name // "SessionStart"' 2>/dev/null || echo SessionStart)
cwd=$(printf '%s\n' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

# voice_dir from the YAML frontmatter of a devline config file.
voice_dir_in() {
  [[ -f "$1" ]] || return 0
  awk 'NR == 1 && !/^---$/ { exit } NR > 1 && /^---$/ { exit }
       NR > 1 && sub(/^voice_dir:[ \t]*/, "") { gsub(/^["\x27]|["\x27][ \t]*$/, ""); print; exit }' "$1"
}

personal_dir() {
  local config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}" dir repo found
  dir="$config/devline/voice"
  found=$(voice_dir_in "$config/devline/config.md")
  [[ -n "$found" ]] && dir=$found
  if [[ -n "$cwd" ]]; then
    repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
    found=$(voice_dir_in "$repo/.claude/devline.md")
    [[ -n "$found" ]] && dir=$found
  fi
  printf '%s' "${dir/#\~/$HOME}"
}

case "${1:-}" in
  conduct)
    context=$(cat "$core/conduct.md")
    ;;
  voice)
    context="$(cat "$core/voice.md")

$(cat "$core/code-comments.md")"
    ;;
  personal)
    dir=$(personal_dir)
    [[ -d "$dir" ]] || exit 0
    contexts=$(find "$dir/contexts" -maxdepth 1 -name '*.md' 2>/dev/null | sort || true)
    [[ -f "$dir/voice.md" || -n "$contexts" ]] || exit 0
    context="# Personal voice layer

The user keeps a personal voice layer in $dir. Apply it to chat replies, code comments, commit messages, PR text and email. Never apply it to fiction or scientific writing. The hard bans of the core voice still hold where this layer disagrees."
    if [[ -n "$contexts" ]]; then
      context+="

Before writing one of these kinds of text, read the matching file:
$(printf '%s\n' "$contexts" | sed 's/^/- /')"
    fi
    if [[ -f "$dir/voice.md" ]]; then
      body=$(cat "$dir/voice.md")
      if (( ${#context} + ${#body} + 2 > max )); then
        context+="

$dir/voice.md is too long to inject. Read it before your first reply."
      else
        context+="

$body"
      fi
    fi
    ;;
  *)
    echo "usage: inject-voice.sh conduct|voice|personal" >&2
    exit 0
    ;;
esac

# shellcheck disable=SC2016  # the literal placeholder text, not an expansion
context=${context//'${CLAUDE_PLUGIN_ROOT}'/$root}

jq -n --arg ev "$event" --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: $ev,
    additionalContext: $ctx
  }
}'
