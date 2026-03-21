#!/bin/bash
set -euo pipefail

# Devline security hook: validate Write/Edit operations in bypass mode
# Blocks writing credentials, secrets, and sensitive content to files

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

# --- Block writing to sensitive system files ---

if printf '%s\n' "$file_path" | grep -qEi '^/(etc|sys|proc|boot|usr/sbin)/'; then
  echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Writing to system paths is not allowed in bypass mode."}' >&2
  exit 2
fi

# Block overwriting shell profiles
if printf '%s\n' "$file_path" | grep -qEi '(\.bashrc|\.zshrc|\.profile|\.bash_profile|\.zprofile)$'; then
  echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Modifying shell profiles is not allowed in bypass mode."}' >&2
  exit 2
fi

# Block writing to SSH config
if printf '%s\n' "$file_path" | grep -qEi '\.ssh/(config|authorized_keys|known_hosts|id_)'; then
  echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Modifying SSH configuration is not allowed in bypass mode."}' >&2
  exit 2
fi

# --- Block writing hardcoded secrets ---

if [[ -n "$content" && "$is_test_file" != "true" ]]; then
  # Detect AWS access keys (AKIA pattern)
  if printf '%s\n' "$content" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: AWS access key detected in file content. Use environment variables instead."}' >&2
    exit 2
  fi

  # Detect private keys
  if printf '%s\n' "$content" | grep -qE '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then
    echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Private key detected in file content. Never commit private keys."}' >&2
    exit 2
  fi

  # Detect common secret patterns (API keys, tokens with high entropy)
  if printf '%s\n' "$content" | grep -qEi '(api_key|api_secret|secret_key|private_key|access_token|auth_token)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{20,}["\x27]'; then
    echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Hardcoded secret/API key detected. Use environment variables or a secrets manager."}' >&2
    exit 2
  fi

  # Detect password assignments
  if printf '%s\n' "$content" | grep -qEi '(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'; then
    # Allow common test/example passwords
    if ! printf '%s\n' "$content" | grep -qEi '(password|passwd|pwd)\s*[:=]\s*["\x27](test|example|placeholder|changeme|password|xxx|dummy)["\x27]'; then
      echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Hardcoded password detected. Use environment variables or a secrets manager."}' >&2
      exit 2
    fi
  fi

  # Detect GitHub/GitLab tokens
  if printf '%s\n' "$content" | grep -qE '(ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,})'; then
    echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: GitHub/GitLab token detected in file content. Use environment variables."}' >&2
    exit 2
  fi

  # Detect JWT tokens
  if printf '%s\n' "$content" | grep -qE 'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+'; then
    echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: JWT token detected in file content. Do not hardcode tokens."}' >&2
    exit 2
  fi
fi

# --- Block writing to .env files (should use .env.example instead) ---

if printf '%s\n' "$file_path" | grep -qE '\.env$' && ! printf '%s\n' "$file_path" | grep -qE '\.env\.(example|template|sample)$'; then
  if [[ -n "$content" ]] && printf '%s\n' "$content" | grep -qEi '(KEY|SECRET|TOKEN|PASSWORD)\s*=\s*[^\s$]'; then
    echo '{"hookSpecificOutput":{"permissionDecision":"deny"},"systemMessage":"BLOCKED: Writing secrets to .env file. Use .env.example with placeholder values instead."}' >&2
    exit 2
  fi
fi

# All checks passed
exit 0
