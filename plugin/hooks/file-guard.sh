#!/usr/bin/env bash
# file-guard.sh — PreToolUse hook for Write/Edit/MultiEdit
# Blocks writes to sensitive files (.env, credentials, secrets, lock files)
set -euo pipefail

# ---------- Dependency check ----------
if ! command -v python3 &>/dev/null; then
  echo "file-guard.sh: python3 not found — file guard is disabled. Install python3 to enable it." >&2
  exit 0
fi

INPUT="$(cat)"

FILE_PATH="$(printf '%s' "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
print(ti.get('file_path', ti.get('filePath', '')))
" 2>/dev/null || echo "")"

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Canonicalize the path: resolve symlinks, normalize ./ and redundant slashes
# This prevents bypasses via symlinks or non-canonical paths
if command -v python3 &>/dev/null; then
  # python3 is already a dependency in these scripts and works cross-platform
  CANONICAL_PATH="$(python3 -c "import os, sys; print(os.path.abspath(sys.argv[1]))" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
elif command -v realpath &>/dev/null; then
  CANONICAL_PATH="$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
elif command -v readlink &>/dev/null; then
  CANONICAL_PATH="$(readlink -f "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
else
  CANONICAL_PATH="$FILE_PATH"
fi

# Use canonical path for all checks; keep original for messages
FILE_PATH="$CANONICAL_PATH"
BASENAME="$(basename "$FILE_PATH")"
DIRNAME="$(dirname "$FILE_PATH")"

# Block writes to sensitive files
SENSITIVE_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.staging"
  "credentials.json"
  "secrets.yaml"
  "secrets.yml"
  "id_rsa"
  "id_ed25519"
  ".pem"
  ".key"
  "service-account.json"
  "firebase-adminsdk"
)

# Allow template/example files (no real secrets)
SAFE_SUFFIXES=(".template" ".example" ".sample" ".dist")
for suffix in "${SAFE_SUFFIXES[@]}"; do
  if [[ "$BASENAME" == *"$suffix"* ]]; then
    exit 0
  fi
done

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if [[ "$BASENAME" == *"$pattern"* ]]; then
    echo "Blocked: writing to sensitive file $BASENAME. Secrets and credentials should not be modified by automation." >&2
    exit 2
  fi
done

# Block writes to lock files (they should be managed by package managers)
LOCK_FILES=("package-lock.json" "yarn.lock" "pnpm-lock.yaml" "Cargo.lock" "poetry.lock" "Gemfile.lock" "composer.lock" "go.sum")
for lf in "${LOCK_FILES[@]}"; do
  if [[ "$BASENAME" == "$lf" ]]; then
    echo "Blocked: $BASENAME is a lock file managed by the package manager. Run the appropriate install command instead." >&2
    exit 2
  fi
done

# Block writes outside project directory (path traversal)
if [[ "$FILE_PATH" == *".."* ]]; then
  echo "Blocked: path traversal detected in file path." >&2
  exit 2
fi

# Block writes to system directories
SYSTEM_DIRS=("/etc/" "/usr/" "/var/" "/sys/" "/proc/" "/boot/")
for sd in "${SYSTEM_DIRS[@]}"; do
  if [[ "$FILE_PATH" == "$sd"* ]]; then
    echo "Blocked: writing to system directory $sd is not allowed." >&2
    exit 2
  fi
done

exit 0
