#!/usr/bin/env bash
# auto-format.sh — PostToolUse hook for Write/Edit/MultiEdit
# Runs project-appropriate formatter on the modified file.
set -euo pipefail

# ---------- Dependency check ----------
if ! command -v python3 &>/dev/null; then
  echo "auto-format.sh: python3 not found — auto-formatter is disabled. Install python3 to enable it." >&2
  exit 0
fi

INPUT="$(cat)"

FILE_PATH="$(printf '%s' "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
print(ti.get('file_path', ti.get('filePath', '')))
" 2>/dev/null || echo "")"

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Run formatter with warning on failure (never block the tool call)
run_fmt() {
  local name="$1"; shift
  if ! "$@" 2>/dev/null; then
    echo "Warning: $name failed for $FILE_PATH" >&2
  fi
}

# Resolve a tool: prefer project-local (npx/node_modules), then global
find_node_tool() {
  local tool="$1"
  if [[ -f "$PROJECT_DIR/node_modules/.bin/$tool" ]]; then
    echo "$PROJECT_DIR/node_modules/.bin/$tool"
  elif command -v "$tool" &>/dev/null; then
    echo "$tool"
  fi
}

# Check if the project actually uses a formatter (has a config file for it)
has_prettier_config() {
  [[ -f "$PROJECT_DIR/.prettierrc" ]] || \
  [[ -f "$PROJECT_DIR/.prettierrc.json" ]] || \
  [[ -f "$PROJECT_DIR/.prettierrc.js" ]] || \
  [[ -f "$PROJECT_DIR/.prettierrc.cjs" ]] || \
  [[ -f "$PROJECT_DIR/.prettierrc.yaml" ]] || \
  [[ -f "$PROJECT_DIR/.prettierrc.yml" ]] || \
  [[ -f "$PROJECT_DIR/.prettierrc.toml" ]] || \
  [[ -f "$PROJECT_DIR/prettier.config.js" ]] || \
  [[ -f "$PROJECT_DIR/prettier.config.cjs" ]] || \
  (command -v python3 &>/dev/null && [[ -f "$PROJECT_DIR/package.json" ]] && \
   python3 -c "import json; d=json.load(open('$PROJECT_DIR/package.json')); exit(0 if 'prettier' in d.get('devDependencies',{}) or 'prettier' in d.get('dependencies',{}) else 1)" 2>/dev/null)
}

has_eslint_config() {
  [[ -f "$PROJECT_DIR/.eslintrc" ]] || \
  [[ -f "$PROJECT_DIR/.eslintrc.js" ]] || \
  [[ -f "$PROJECT_DIR/.eslintrc.cjs" ]] || \
  [[ -f "$PROJECT_DIR/.eslintrc.json" ]] || \
  [[ -f "$PROJECT_DIR/.eslintrc.yml" ]] || \
  [[ -f "$PROJECT_DIR/eslint.config.js" ]] || \
  [[ -f "$PROJECT_DIR/eslint.config.mjs" ]] || \
  [[ -f "$PROJECT_DIR/eslint.config.cjs" ]]
}

has_ruff_config() {
  [[ -f "$PROJECT_DIR/ruff.toml" ]] || \
  [[ -f "$PROJECT_DIR/.ruff.toml" ]] || \
  (command -v python3 &>/dev/null && [[ -f "$PROJECT_DIR/pyproject.toml" ]] && \
   grep -q '\[tool\.ruff\]' "$PROJECT_DIR/pyproject.toml" 2>/dev/null)
}

has_clang_format_config() {
  [[ -f "$PROJECT_DIR/.clang-format" ]] || \
  [[ -f "$PROJECT_DIR/_clang-format" ]]
}

# Detect and run appropriate formatter (only if project uses it)
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs|mts|cts|json|css|scss|less|html|md|yaml|yml)
    # Prettier — only run if project has prettier configured
    if has_prettier_config; then
      PRETTIER_BIN="$(find_node_tool prettier)"
      if [[ -n "$PRETTIER_BIN" ]]; then
        run_fmt prettier "$PRETTIER_BIN" --write "$FILE_PATH"
      fi
    fi
    # ESLint for JS/TS files — only if project has eslint configured
    if [[ "$EXT" =~ ^(ts|tsx|js|jsx|mjs|cjs|mts|cts)$ ]] && has_eslint_config; then
      ESLINT_BIN="$(find_node_tool eslint)"
      if [[ -n "$ESLINT_BIN" ]]; then
        run_fmt eslint "$ESLINT_BIN" --fix "$FILE_PATH"
      fi
    fi
    ;;
  py|pyi)
    # Ruff (preferred) or Black
    if has_ruff_config && command -v ruff &>/dev/null; then
      run_fmt "ruff format" ruff format "$FILE_PATH"
      run_fmt "ruff check" ruff check --fix "$FILE_PATH"
    elif [[ -f "$PROJECT_DIR/pyproject.toml" ]] && grep -q '\[tool\.black\]' "$PROJECT_DIR/pyproject.toml" 2>/dev/null && command -v black &>/dev/null; then
      run_fmt black black --quiet "$FILE_PATH"
    elif command -v ruff &>/dev/null; then
      # Ruff works well without config, use as fallback for Python projects
      run_fmt "ruff format" ruff format "$FILE_PATH"
      run_fmt "ruff check" ruff check --fix "$FILE_PATH"
    fi
    # isort — check if not handled by ruff already
    if ! has_ruff_config && command -v isort &>/dev/null; then
      run_fmt isort isort --quiet "$FILE_PATH"
    fi
    ;;
  go)
    # gofmt is standard for all Go projects (no config needed)
    if command -v gofmt &>/dev/null; then
      run_fmt gofmt gofmt -w "$FILE_PATH"
    fi
    if command -v goimports &>/dev/null; then
      run_fmt goimports goimports -w "$FILE_PATH"
    fi
    ;;
  rs)
    # rustfmt is standard for all Rust projects
    if command -v rustfmt &>/dev/null; then
      run_fmt rustfmt rustfmt "$FILE_PATH"
    fi
    ;;
  java|kt|kts)
    if [[ "$EXT" == "java" ]] && command -v google-java-format &>/dev/null; then
      run_fmt google-java-format google-java-format --replace "$FILE_PATH"
    elif [[ "$EXT" =~ ^(kt|kts)$ ]] && command -v ktlint &>/dev/null; then
      run_fmt ktlint ktlint --format "$FILE_PATH"
    fi
    ;;
  c|h|cpp|cc|cxx|hpp|hxx)
    # Only run clang-format if project has a config
    if has_clang_format_config && command -v clang-format &>/dev/null; then
      run_fmt clang-format clang-format -i "$FILE_PATH"
    fi
    ;;
  cs)
    if command -v dotnet-format &>/dev/null; then
      run_fmt dotnet-format dotnet format --include "$FILE_PATH"
    fi
    ;;
  rb)
    if [[ -f "$PROJECT_DIR/.rubocop.yml" ]] && command -v rubocop &>/dev/null; then
      run_fmt rubocop rubocop --autocorrect "$FILE_PATH"
    fi
    ;;
esac

exit 0
