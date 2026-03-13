#!/bin/bash
set -euo pipefail

# Devline PostToolUse hook: detect UI file changes
# Emits a system message when UI-related files are modified so the
# frontend-reviewer agent can be triggered

input=$(cat)
file_path=$(printf '%s\n' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [[ -z "$file_path" ]]; then
  exit 0
fi

# UI file patterns across frameworks and platforms
is_ui_file=false

# Web frontend (React, Vue, Angular, Svelte, etc.)
if printf '%s\n' "$file_path" | grep -qEi '\.(jsx|tsx|vue|svelte|astro)$'; then
  is_ui_file=true
fi

# CSS/styling files
if printf '%s\n' "$file_path" | grep -qEi '\.(css|scss|sass|less|styled\.[jt]sx?)$'; then
  is_ui_file=true
fi

# HTML templates
if printf '%s\n' "$file_path" | grep -qEi '\.(html|htm|ejs|hbs|pug|njk)$'; then
  is_ui_file=true
fi

# Mobile (React Native, Flutter, Swift UI, Jetpack Compose, Kotlin)
if printf '%s\n' "$file_path" | grep -qEi '(components?|screens?|views?|pages?|layouts?|widgets?|ui)/' && printf '%s\n' "$file_path" | grep -qEi '\.(dart|swift|kt|kts)$'; then
  is_ui_file=true
fi

# Desktop (JavaFX FXML, Electron, Tauri)
if printf '%s\n' "$file_path" | grep -qEi '\.(fxml|xaml)$'; then
  is_ui_file=true
fi

# UI directories (any framework)
if printf '%s\n' "$file_path" | grep -qEi '/(components?|views?|pages?|layouts?|screens?|widgets?|templates?|ui)/'; then
  if printf '%s\n' "$file_path" | grep -qEi '\.(js|ts|jsx|tsx|py|dart|swift|kt|java)$'; then
    is_ui_file=true
  fi
fi

if [[ "$is_ui_file" == "true" ]]; then
  echo "{\"systemMessage\":\"UI file modified: $file_path — Consider using the frontend-reviewer agent to review UI quality, accessibility, and responsiveness.\"}"
fi

exit 0
