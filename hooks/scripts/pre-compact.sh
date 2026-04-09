#!/bin/bash
set -eo pipefail
trap 'exit 0' ERR

# Devline PreCompact hook: re-inject pipeline state into context after compaction.
# If .devline/state.md exists (active pipeline), read it and output as additionalContext
# so the orchestrator can resume without manually running the recovery protocol.

input=$(cat)
cwd=$(printf '%s\n' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

if [[ -z "$cwd" ]]; then
  exit 0
fi

git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
STATE_FILE="$git_root/.devline/state.md"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

state_content=$(cat "$STATE_FILE")

# Check for orphaned fix-task files
fix_files=""
for f in "$git_root"/.devline/fix-task-*.md; do
  [[ -f "$f" ]] && fix_files="$fix_files $(basename "$f")"
done

context="## DEVLINE PIPELINE STATE (auto-injected after compaction)

Use this to resume the pipeline without running the full recovery protocol.

$state_content"

if [[ -n "$fix_files" ]]; then
  context="$context

### Orphaned Fix Files
$fix_files — resume fix cycles for these tasks."
fi

jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "PreCompact",
    additionalContext: $ctx
  }
}'
