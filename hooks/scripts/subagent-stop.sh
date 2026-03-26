#!/bin/bash
set -euo pipefail

# Devline SubagentStop hook: log agent completion to .devline/agent-log.md
# Only fires when .devline/state.md exists (active pipeline).
# The orchestrator reads this after compaction to reconstruct agent timing.

input=$(cat)
cwd=$(printf '%s\n' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

if [[ -z "$cwd" ]]; then
  exit 0
fi

git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")

# Only log during active pipelines
if [[ ! -f "$git_root/.devline/state.md" ]]; then
  exit 0
fi

agent_type=$(printf '%s\n' "$input" | jq -r '.agent_type // "unknown"' 2>/dev/null || echo "unknown")
agent_id=$(printf '%s\n' "$input" | jq -r '.agent_id // "unknown"' 2>/dev/null || echo "unknown")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_FILE="$git_root/.devline/agent-log.md"

# Append one line per agent completion
echo "| ${agent_type} | ${agent_id} | stopped | ${timestamp} |" >> "$LOG_FILE"

exit 0
