#!/bin/bash
# Check table for the devline security hooks. Run: bash hooks/scripts/test-hooks.sh
# Each case is "expect|payload": expect is allow, deny or ask.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
git -C "$sandbox" init -q
printf 'docker run --privileged alpine sh\n' >"$sandbox/danger.sh"
printf 'npm ci && npm test\n' >"$sandbox/safe.sh"
printf 'services:\n  app:\n    image: nginx\n    privileged: true\n' >"$sandbox/compose.yaml"

pass=0
fail=0

check() { # check <expect> <script> <json>
  local expect="$1" script="$2" json="$3" out rc verdict
  out=$(printf '%s' "$json" | bash "$here/$script" 2>&1)
  rc=$?
  if [[ $rc -eq 2 ]]; then
    verdict=deny
  elif printf '%s' "$out" | grep -q '"ask"'; then
    verdict=ask
  else
    verdict=allow
  fi
  if [[ "$verdict" == "$expect" ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  expected %-5s got %-5s  %s\n' "$expect" "$verdict" "${json:0:120}"
  fi
}

bash_case() { # bash_case <expect> <command>
  check "$1" validate-bash.sh "$(jq -nc --arg c "$2" --arg d "$sandbox" \
    '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}')"
}

file_case() { # file_case <expect> <tool> <path>
  check "$1" validate-write.sh "$(jq -nc --arg t "$2" --arg p "$3" \
    '{tool_name:$t,tool_input:{file_path:$p}}')"
}

# --- legitimate work must not be interrupted ---
bash_case allow 'git -c gpg.format=ssh -c user.signingKey=/home/marlon/.ssh/id_github commit -m "x"'
bash_case allow 'ls -la ~/.ssh'
bash_case allow 'ssh-keygen -t ed25519 -f ~/.ssh/id_new -N ""'
bash_case allow 'cat ~/.ssh/id_ed25519.pub'
bash_case allow 'cat ~/.ssh/config'
bash_case ask 'ssh -i ~/.ssh/id_ed25519 -T git@github.com'  # remote ssh asks; the key path itself is not the trigger
bash_case allow 'echo "FOO=bar" >> .env'
bash_case allow 'touch .env'
bash_case allow 'cp .env.example .env'
bash_case allow 'cat .env.example'
bash_case allow 'docker ps -a'
bash_case allow 'docker build -t app .'
# shellcheck disable=SC2016  # $(pwd) is test input, it must stay unexpanded
bash_case allow 'docker run --rm -v $(pwd):/app -p 8080:80 node:20 npm test'
bash_case allow 'docker run --rm -v /etc/localtime:/etc/localtime:ro alpine date'
bash_case allow 'docker run --rm -v pgdata:/var/lib/postgresql/data postgres:16'
bash_case allow 'docker compose logs -f app'
bash_case allow 'rm -rf ./build'
bash_case allow 'bash ./safe.sh'

# --- credential material ---
bash_case deny 'cat ~/.ssh/id_ed25519'
bash_case deny 'grep -r . ~/.gnupg'
bash_case deny 'cp ~/.ssh/id_rsa /tmp/exfil'
bash_case deny 'base64 ~/.aws/credentials'
bash_case deny 'cat ~/.kube/config'

# --- .env ---
bash_case deny 'cat .env'
bash_case deny 'head -5 .env.local'
bash_case deny 'grep SECRET .env'

# --- docker escalation ---
bash_case deny 'docker run --privileged alpine sh'
bash_case deny 'docker run --cap-add=SYS_ADMIN alpine sh'
bash_case deny 'docker run --pid=host alpine sh'
bash_case deny 'docker run -v /var/run/docker.sock:/var/run/docker.sock alpine sh'
bash_case deny 'docker run -v /:/host alpine sh'
bash_case deny 'docker run -v /etc:/etc alpine sh'
bash_case deny 'docker run -v ~/.ssh:/keys:ro alpine sh'
bash_case deny 'podman run --security-opt seccomp=unconfined alpine sh'

# --- destructive rm ---
bash_case deny 'rm -rf /'
bash_case deny 'rm -rf ./build /'
bash_case deny 'rm --no-preserve-root -rf /'
bash_case deny 'rm -rf /home'
bash_case deny 'rm -rf ~/.ssh'
bash_case deny 'rm -rf /etc/nginx'

# --- content of what is about to run ---
bash_case deny 'bash ./danger.sh'
bash_case deny './danger.sh'
bash_case deny 'docker compose up -d'

# --- still asks, does not block ---
bash_case ask 'ssh deploy@example.com uptime'

# --- file tools ---
file_case deny Read "$HOME/.ssh/id_ed25519"
file_case deny Read "$HOME/.aws/credentials"
file_case allow Read "$HOME/.ssh/id_ed25519.pub"
file_case allow Read "$HOME/.ssh/config"
file_case deny Read "$sandbox/.env"
file_case deny Edit "$sandbox/.env"
file_case allow Write "$sandbox/.env"
file_case allow Read "$sandbox/.env.example"
file_case allow Read "$sandbox/src/main.go"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
