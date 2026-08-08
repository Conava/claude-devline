#!/bin/bash
set -eo pipefail
trap 'exit 0' ERR

# Devline security hook: gate file access by path, and scan Write/Edit content
# for hardcoded secrets. Matched on Read|Write|Edit.
# Path-based blocks on system files, shell profiles and ssh config were removed
# on the scrub branch — those blocked legitimate dotfile edits. What remains is
# private key material and .env, which are read-blocked, not write-blocked.

input=$(cat)
tool=$(printf '%s\n' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)
file_path=$(printf '%s\n' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
content=$(printf '%s\n' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)

if [[ -z "$file_path" ]]; then
  exit 0
fi

# shellcheck source=./patterns.sh
source "$(dirname "${BASH_SOURCE[0]}")/patterns.sh"

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\"},\"systemMessage\":\"BLOCKED: $1\"}" >&2
  exit 2
}

# --- Sensitive paths ---

# Private key material and credential stores. Public keys, ~/.ssh/config and
# known_hosts do not match; keys are created with ssh-keygen, not this tool.
if printf '%s' "$file_path" | grep -qPi "$CRED_PATHS"; then
  deny "Private key material / credential store ($file_path) is off-limits. Use ls or ssh-keygen instead."
fi

# .env: creating one is fine, reading it back is not. Edit is blocked because it
# would require reading first — append from the shell with >> instead.
if [[ "$tool" != "Write" ]] && printf '%s' "$file_path" | grep -qPi "$ENV_PATH"; then
  deny ".env contents must not be read. Append with >> from the shell; .env.example is readable."
fi

# --- Detect test files (skip secret detection — test code uses fake credentials) ---
is_test_file=false
if printf '%s\n' "$file_path" | grep -qEi '(/test/|/tests/|/__tests__/|\.test\.|\.spec\.|/fixtures/|/testdata/|/test-resources/|/testFixtures/)'; then
  is_test_file=true
fi

# --- Block writing hardcoded secrets into source ---

if [[ -n "$content" && "$is_test_file" != "true" ]]; then
  # Detect AWS access keys (AKIA pattern)
  if printf '%s\n' "$content" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    deny "AWS access key detected in file content. Use environment variables instead."
  fi

  # Detect private keys
  if printf '%s\n' "$content" | grep -qE '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then
    deny "Private key detected in file content. Never commit private keys."
  fi

  # Detect common secret patterns (API keys, tokens with high entropy)
  if printf '%s\n' "$content" | grep -qEi '(api_key|api_secret|secret_key|private_key|access_token|auth_token)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{20,}["\x27]'; then
    deny "Hardcoded secret/API key detected. Use environment variables or a secrets manager."
  fi

  # Detect password assignments
  if printf '%s\n' "$content" | grep -qEi '(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'; then
    # Allow common test/example passwords
    if ! printf '%s\n' "$content" | grep -qEi '(password|passwd|pwd)\s*[:=]\s*["\x27](test|example|placeholder|changeme|password|xxx|dummy)["\x27]'; then
      deny "Hardcoded password detected. Use environment variables or a secrets manager."
    fi
  fi

  # Detect GitHub/GitLab tokens
  if printf '%s\n' "$content" | grep -qE '(ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,})'; then
    deny "GitHub/GitLab token detected in file content. Use environment variables."
  fi

  # Detect JWT tokens
  if printf '%s\n' "$content" | grep -qE 'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+'; then
    deny "JWT token detected in file content. Do not hardcode tokens."
  fi
fi

# All checks passed
exit 0
