#!/usr/bin/env bash
# file-guard.sh — PreToolUse hook for Write/Edit/MultiEdit
# Blocks writes to sensitive files (.env, credentials, secrets, lock files)
set -euo pipefail

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
if command -v realpath &>/dev/null; then
  # Use --no-require-directory: resolve what we can even if target doesn't exist yet
  CANONICAL_PATH="$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
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
