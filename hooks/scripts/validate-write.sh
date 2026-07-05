#!/bin/bash
set -eo pipefail
trap 'exit 0' ERR

# Devline security hook: scan Write/Edit content for hardcoded secrets.
# Path-based blocks (system files, shell profiles, ssh config, .env writes)
# were removed on the scrub branch — those blocked legitimate dotfile/.env
# edits. This scans file CONTENT for credentials only.

input=$(cat)
file_path=$(printf '%s\n' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
content=$(printf '%s\n' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)

if [[ -z "$file_path" ]]; then
  exit 0
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
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"BLOCKED: AWS access key detected in file content. Use environment variables instead."}' >&2
    exit 2
  fi

  # Detect private keys
  if printf '%s\n' "$content" | grep -qE '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"BLOCKED: Private key detected in file content. Never commit private keys."}' >&2
    exit 2
  fi

  # Detect common secret patterns (API keys, tokens with high entropy)
  if printf '%s\n' "$content" | grep -qEi '(api_key|api_secret|secret_key|private_key|access_token|auth_token)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{20,}["\x27]'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"BLOCKED: Hardcoded secret/API key detected. Use environment variables or a secrets manager."}' >&2
    exit 2
  fi

  # Detect password assignments
  if printf '%s\n' "$content" | grep -qEi '(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'; then
    # Allow common test/example passwords
    if ! printf '%s\n' "$content" | grep -qEi '(password|passwd|pwd)\s*[:=]\s*["\x27](test|example|placeholder|changeme|password|xxx|dummy)["\x27]'; then
      echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"BLOCKED: Hardcoded password detected. Use environment variables or a secrets manager."}' >&2
      exit 2
    fi
  fi

  # Detect GitHub/GitLab tokens
  if printf '%s\n' "$content" | grep -qE '(ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,})'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"BLOCKED: GitHub/GitLab token detected in file content. Use environment variables."}' >&2
    exit 2
  fi

  # Detect JWT tokens
  if printf '%s\n' "$content" | grep -qE 'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"BLOCKED: JWT token detected in file content. Do not hardcode tokens."}' >&2
    exit 2
  fi
fi

# All checks passed
exit 0
