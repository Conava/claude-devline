#!/bin/bash
# Check table for the devline security hooks. Run: bash hooks/scripts/test-hooks.sh
# Each case is "expect|payload": expect is allow, deny or ask.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
sandbox=$(mktemp -d)
nongit=$(mktemp -d)          # a plain parent dir holding repos, like ~/source
trap 'rm -rf "$sandbox" "$nongit"' EXIT
git -C "$sandbox" init -q
git -C "$nongit" init -q nested
mkdir -p "$nongit/nested/.devline" "$nongit/nested/build" "$nongit/plain"
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
    '{tool_name:"Bash",cwd:$d,permission_mode:"bypassPermissions",tool_input:{command:$c}}')"
}

bash_case_in() { # bash_case_in <expect> <cwd> <command>
  check "$1" validate-bash.sh "$(jq -nc --arg c "$3" --arg d "$2" \
    '{tool_name:"Bash",cwd:$d,permission_mode:"bypassPermissions",tool_input:{command:$c}}')"
}

file_case() { # file_case <expect> <tool> <path>
  check "$1" validate-write.sh "$(jq -nc --arg t "$2" --arg p "$3" \
    '{tool_name:$t,tool_input:{file_path:$p}}')"
}

# --- default mode: Claude Code's own prompt gates every call, the hook stays out ---
check allow validate-bash.sh "$(jq -nc --arg d "$sandbox" \
  '{tool_name:"Bash",cwd:$d,permission_mode:"default",tool_input:{command:"rm -rf /"}}')"

# --- legitimate work must not be interrupted ---
bash_case allow 'git -c gpg.format=ssh -c user.signingKey=/home/marlon/.ssh/id_github commit -m "x"'
bash_case allow 'ls -la ~/.ssh'
bash_case allow 'ssh-keygen -t ed25519 -f ~/.ssh/id_new -N ""'
bash_case allow 'cat ~/.ssh/id_ed25519.pub'
bash_case allow 'cat ~/.ssh/config'
bash_case allow 'ssh -i ~/.ssh/id_ed25519 -T git@github.com'
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

# --- docker escalation: asks, except handing a container your credentials ---
bash_case ask 'docker run --privileged alpine sh'
bash_case ask 'docker run --cap-add=SYS_ADMIN alpine sh'
bash_case ask 'docker run --pid=host alpine sh'
bash_case ask 'docker run -v /var/run/docker.sock:/var/run/docker.sock alpine sh'
bash_case ask 'docker run -v /:/host alpine sh'
bash_case ask 'docker run -v /etc:/etc alpine sh'
bash_case deny 'docker run -v ~/.ssh:/keys:ro alpine sh'
bash_case ask 'podman run --security-opt seccomp=unconfined alpine sh'

# --- deletes: ordinary files and folders anywhere are fine ---
bash_case allow 'rm -rf .devline'
bash_case allow 'rm -rf node_modules dist'
bash_case allow 'make clean; rm -rf dist'
bash_case allow 'rm -rf build/*'
bash_case ask 'rm -rf *'                                           # empties the repo root (the sandbox)
bash_case allow 'rm -rf /tmp/claude-scratch/old-run'
bash_case allow 'rm /tmp/report.pdf'
bash_case allow 'rm -rf /var/tmp/build-cache'
bash_case allow 'rm ~/Downloads/installer.iso'
bash_case allow 'rm -rf ~/Documents/old-project'
bash_case allow 'rm -rf ~/Documents/drafts/*'
bash_case allow 'rm -rf ~/.cache/bun'
bash_case allow 'rm -rf ~/.config/someapp'
bash_case allow 'rm -f ~/.ssh/known_hosts.old'
bash_case_in allow "$nongit" "rm -rf $nongit/plain"                 # not a git repo: still fine
bash_case_in allow "$nongit" "rm -rf $nongit"                       # the cwd itself, nothing protected
bash_case allow 'git rm -r --cached ~/.ssh'                         # index only

# --- deletes: the system, the whole home, credentials ---
bash_case deny 'rm -rf /'
bash_case deny 'rm -rf ./build /'
bash_case deny 'rm --no-preserve-root -rf /'
bash_case deny 'rm -rf /*'
bash_case deny 'rm -rf /home'
bash_case deny 'rm -rf ~'
bash_case deny 'rm -rf ~/'
bash_case deny 'rm -rf ~/*'
# shellcheck disable=SC2016  # $HOME is test input, it must stay unexpanded
bash_case deny 'rm -rf $HOME'
bash_case ask 'rm -rf ~/.config'
bash_case ask 'rm -rf /etc/nginx'
bash_case ask 'sudo rm /usr/bin/python3'
bash_case deny 'rm -rf ~/.ssh'
bash_case deny 'rm ~/.ssh/id_ed25519'
bash_case deny 'rm -rf ~/.gnupg'
bash_case deny 'rm -rf ~/.password-store'
bash_case_in ask "$nongit" "rm -rf $nongit/nested/.devline /etc/nginx"

# --- secrets: never read, move, overwrite or change ---
bash_case deny 'sudo cat /etc/shadow'
bash_case deny 'mv ~/.ssh/id_rsa /tmp/'
bash_case deny 'shred -u ~/.ssh/id_ed25519'
bash_case deny 'echo x > ~/.ssh/id_ed25519'
bash_case deny 'passwd'
bash_case deny 'echo "marlon:hunter2" | sudo chpasswd'
bash_case deny 'env'
bash_case deny 'printenv | grep -i key'
bash_case deny 'printenv GITHUB_TOKEN'
bash_case allow 'cat /etc/passwd'
bash_case allow 'cat ~/.ssh/known_hosts'
bash_case allow 'env NODE_ENV=test npm test'
bash_case allow 'printenv PATH'
bash_case allow 'ls ~/.password-store'

# --- content of what is about to run: a human looks first ---
bash_case ask 'bash ./danger.sh'
bash_case ask './danger.sh'
bash_case ask 'docker compose up -d'

# --- ssh: remote work allowed, catastrophe and credential rules still apply ---
bash_case allow 'ssh deploy@example.com uptime'
bash_case allow "ssh vps 'sudo systemctl restart nginx'"
bash_case allow "ssh vps 'rm -rf /srv/app/old'"
bash_case allow 'scp build.tar vps:/srv/app/'
bash_case deny "ssh vps 'rm -rf /etc'"
bash_case deny "ssh vps 'cat ~/.ssh/id_ed25519'"
bash_case ask 'sudo systemctl restart nginx'

# --- the strip in between: possibly fine, possibly not, or acting in your name ---
bash_case allow 'git push --force-with-lease origin feat/x'
bash_case ask 'git push --force origin main'
bash_case ask 'git push origin +main'
bash_case allow 'git push -u origin feat/x'
bash_case ask 'git reset --hard HEAD~1'
bash_case ask 'git clean -fd'
bash_case allow 'git clean -n'
bash_case ask 'npm publish'
bash_case ask 'gh pr merge 12 --squash'
bash_case ask 'gh issue comment 5 --body "done"'
bash_case allow 'gh pr create --fill'
bash_case allow 'gh pr view 12'
bash_case ask 'psql -c "DROP TABLE users"'
bash_case ask 'docker volume rm pgdata'
bash_case ask 'docker system prune -a --volumes'
bash_case allow 'docker system prune -f'
bash_case allow 'systemctl --user restart pipewire'
bash_case allow 'systemctl status nginx'
bash_case ask 'chmod -R 777 public'
bash_case allow 'chmod 777 /tmp/socket-dir'
bash_case allow 'chmod 600 ~/.ssh/authorized_keys'
bash_case allow 'cat ~/.ssh/authorized_keys'
bash_case ask 'echo "ssh-ed25519 AAAA x" >> ~/.ssh/authorized_keys'
bash_case ask 'crontab -r'
bash_case allow 'crontab -l'
bash_case ask 'rm -rf ~/Documents'
bash_case_in ask "$nongit" "rm -rf $nongit/nested"                 # a whole repository
bash_case_in allow "$nongit" "rm -rf $nongit/nested/build"
bash_case deny 'rm -rf /etc/nginx; cat ~/.ssh/id_rsa'             # an ask never masks a later deny

# --- secrets printed by tools ---
bash_case deny 'gh auth token'
bash_case deny 'pass show email/work'
bash_case deny 'secret-tool lookup service github'
bash_case deny 'kubectl get secret db-creds -o yaml'
bash_case deny 'gcloud auth print-access-token'
bash_case deny 'cat ~/.git-credentials'
bash_case deny 'cat ~/.pgpass'
bash_case allow 'pass ls'
bash_case allow 'kubectl get secrets'
bash_case allow 'gh auth status'

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
file_case deny Read /etc/shadow
file_case deny Read "$HOME/.password-store/email.gpg"
file_case deny Edit "$HOME/.ssh/id_ed25519"
file_case allow Read /etc/passwd
file_case allow Edit "$HOME/.ssh/config"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
