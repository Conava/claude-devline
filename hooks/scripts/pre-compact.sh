#!/bin/bash
set -eo pipefail
trap 'exit 0' ERR

# Devline PreCompact hook: plain stdout becomes instructions for the
# compaction summary. Asks for a handoff-style summary in every session, plus
# devline pipeline pointers when one is active. The state file itself is
# re-injected afterwards by restore-state.sh (SessionStart, matcher compact).

input=$(cat)
cwd=$(printf '%s\n' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

cat <<'EOF'
Write this summary as a handoff to yourself: after compaction you must continue without asking the user to repeat anything and without retrying what already failed. If an earlier compaction summary is in the conversation, carry its lists below forward and add to them; never shorten them to a mention.

1. Goal and status: what the user asked for overall, what is done, what is in progress right now, and the immediate next step.
2. Everything the user pointed you to, one line each, with the context and intent it was given in: file paths, directories, log locations, URLs, repos, screenshots/images (what they showed and what the user wanted noticed), commands, error messages. Keep paths, URLs and identifiers exact. Point at a log's location rather than copying its lines, except the specific error lines the work is about.
3. What the user said: requirements, decisions, preferences and every correction of your work, with what was wrong. Quote short ones verbatim. Mark which are already written to a file (give the path) and which exist only in this conversation.
4. Attempts that failed: for the current problem, each approach tried, how it failed (error, symptom, measurement) and why, so it is not tried again. Include hypotheses ruled out and the evidence that ruled them out.
5. Working state: files changed and why, branches, worktrees, running processes or servers (with PIDs or how to find them), background agents and what each is doing, uncommitted work.
6. Open questions waiting on the user, and what each answer unblocks.
7. Skills, commands or references the next steps will need.

Point at plans, specs, commits and other files by path instead of restating them. Drop raw tool output, file dumps and dead ends that taught nothing. Never include secrets, tokens, passwords or credentials.
EOF

[[ -n "$cwd" ]] || exit 0
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
[[ -f "$git_root/.devline/state.md" ]] || exit 0

cat <<EOF

A devline pipeline is active. Its state file $git_root/.devline/state.md is re-injected after compaction, so don't copy it; do record the pipeline stage, task IDs in progress, their worktrees and fix cycles, and any decisions not yet written to state.md or the plan files.
EOF
