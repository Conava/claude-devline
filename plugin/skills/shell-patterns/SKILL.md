---
name: shell-patterns
description: "Production-grade shell scripting patterns for Bash and POSIX sh. Defensive programming, error handling, safe file operations, testing with Bats, and CI/CD integration."
user-invocable: false
---

# Shell Scripting Patterns

## Bash Strict Mode Template

Every Bash script should start with:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

cleanup() {
  # Remove temp files, restore state
  [[ -d "${TMPDIR:-}" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT
trap 'echo "Error at ${BASH_SOURCE[0]}:${LINENO}: exit $?" >&2' ERR
```

## Safety Patterns

### Variables
- `readonly` for constants: `readonly VERSION="1.0.0"`
- `local` for function variables: `local -r name="$1"`
- Quote all expansions: `"$var"`, `"${array[@]}"`
- Default values: `"${VAR:-default}"` (use default) vs `"${VAR:=default}"` (assign default)

### File Operations
- **Atomic writes**: Write to temp file, then `mv` (atomic rename on same filesystem)
- **Safe temp files**: `TMPDIR=$(mktemp -d)` with `trap 'rm -rf "$TMPDIR"' EXIT`
- **NUL-safe iteration**: `find . -print0 | while IFS= read -r -d '' file; do ...; done`
- **Permission checks**: `[[ -r "$file" ]]` before reading, `[[ -w "$dir" ]]` before writing

### Input Validation
- Validate numeric input: `[[ "$val" =~ ^[0-9]+$ ]]`
- Never use `eval` with user input
- Sanitize path inputs: reject `..`, absolute paths when expecting relative
- Use `--` to end option parsing: `rm -- "$file"`

### Process Management
- Timeout external commands: `timeout 30 curl ...`
- Check command availability: `command -v jq >/dev/null 2>&1 || { echo "jq required"; exit 1; }`
- Background jobs: track PIDs, use `wait` for cleanup

## Argument Parsing

```bash
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <input>

Options:
  -o, --output FILE   Output file (default: stdout)
  -v, --verbose       Enable verbose output
  -h, --help          Show this help
  --version           Show version
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) output="$2"; shift 2 ;;
    -v|--verbose) verbose=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) echo "$VERSION"; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) break ;;
  esac
done
```

## Logging

```bash
readonly LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
  local level="$1"; shift
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  case "$level" in
    DEBUG) [[ "$LOG_LEVEL" == "DEBUG" ]] && echo "[$timestamp] DEBUG: $*" >&2 ;;
    INFO)  echo "[$timestamp] INFO: $*" >&2 ;;
    WARN)  echo "[$timestamp] WARN: $*" >&2 ;;
    ERROR) echo "[$timestamp] ERROR: $*" >&2 ;;
  esac
}
```

## POSIX sh Constraints

When writing for maximum portability (#!/bin/sh):
- No arrays — use positional parameters or newline-delimited strings
- No `[[ ]]` — use `[ ]` with proper quoting
- No process substitution `<()` — use temp files or pipes
- No `local` — use naming conventions to avoid collisions
- No `+=` — use `var="$var addition"`
- No `${var//pattern/replace}` — use `sed`
- No `source` — use `.`
- Use `printf` over `echo` for portability

## Testing with Bats

```bash
#!/usr/bin/env bats

setup() {
  TMPDIR="$(mktemp -d)"
  # Source the script under test
  source "$BATS_TEST_DIRNAME/../script.sh"
}

teardown() {
  rm -rf "$TMPDIR"
}

@test "validates input file exists" {
  run validate_input "/nonexistent"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}
```

## CI/CD Checklist

- Run `shellcheck --enable=all` on all `.sh` files
- Format with `shfmt -i 2 -ci -bn`
- Test with Bats framework
- Matrix test on Bash 4.4, 5.0, 5.2 if supporting multiple versions
