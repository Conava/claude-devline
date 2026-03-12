#!/usr/bin/env bash
# session-start.sh — SessionStart hook
#
# Outputs a JSON payload with SKILL USAGE RULES and optional branch warning.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  echo '{"error": "CLAUDE_PLUGIN_ROOT is not set"}' >&2
  exit 1
fi

# -----------------------------------------------------------------------
# 1. Build SKILL USAGE RULES context (static — literal \n sequences)
# -----------------------------------------------------------------------
CONTEXT="SKILL USAGE RULES (mandatory — no exceptions):\nNever implement code, fix bugs, or make code changes directly in the main session. All development work goes through a skill.\n- Bug, error, crash, unexpected behavior, test failure → MUST use: systematic-debugging\n- New feature, refactor, task implementation → MUST use: pipeline or implement\n- Code review request → MUST use: review\n- Documentation update → MUST use: docs-update or docs-generate\nInvoke the matching skill via the Skill tool BEFORE doing anything else — including asking clarifying questions. Announce it first: \"I'm using the [skill-name] skill to [one-line purpose].\" Once loaded, follow it exactly.\n\nAvailable skills:\n"

# Append skill names from SKILL.md frontmatter
SKILLS_DIR="$PLUGIN_ROOT/skills"
if [[ -d "$SKILLS_DIR" ]]; then
  for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
    [[ -f "$skill_file" ]] || continue
    skill_name=""
    skill_desc=""
    disable_model_invocation="false"
    in_frontmatter=0
    while IFS= read -r line; do
      if [[ "$line" == "---" ]]; then
        if [[ $in_frontmatter -eq 1 ]]; then break; fi
        in_frontmatter=1
        continue
      fi
      if [[ $in_frontmatter -eq 1 ]]; then
        if [[ "$line" =~ ^name:[[:space:]]*(.*) ]]; then
          skill_name="${BASH_REMATCH[1]%\"}"
          skill_name="${skill_name#\"}"
          skill_name="${skill_name%\'}"
          skill_name="${skill_name#\'}"
        fi
        if [[ "$line" =~ ^disable-model-invocation:[[:space:]]*(.*) ]]; then
          disable_model_invocation="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
          raw="${BASH_REMATCH[1]%\"}"
          raw="${raw#\"}"
          raw="${raw%\'}"
          raw="${raw#\'}"
          raw="${raw#|}"
          raw="${raw#|-}"
          raw="${raw#>}"
          skill_desc="${raw## }"
        fi
      fi
    done < "$skill_file"
    if [[ -n "$skill_name" ]]; then
      if [[ "$disable_model_invocation" == "true" ]]; then
        CONTEXT="${CONTEXT}- ${skill_name}\n"
      else
        CONTEXT="${CONTEXT}- ${skill_name}: ${skill_desc}\n"
      fi
    fi
  done
fi

# -----------------------------------------------------------------------
# 2. Branch warning — hardcoded protected branch list
# -----------------------------------------------------------------------
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
for protected in main master production; do
  if [[ "$CURRENT_BRANCH" == "$protected" ]]; then
    CONTEXT="${CONTEXT}\nWARNING: You are on protected branch '${CURRENT_BRANCH}'. Create a feature branch before making changes."
    break
  fi
done

# -----------------------------------------------------------------------
# 3. JSON-escape CONTEXT and output hook payload
# -----------------------------------------------------------------------
# Escape backslashes first, then double-quotes, then convert real newlines to \n
ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | tr -d '\n')
# Remove trailing \n added by awk for the last (empty) line
ESCAPED="${ESCAPED%\\n}"

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ESCAPED"
