#!/bin/bash
# Shared regex patterns for the devline security hooks.
# Sourced by validate-bash.sh and validate-write.sh — edit here, not there.
# All patterns are PCRE (grep -P).

# Command position: not preceded by a word char, '=', '.', '/' or '-'.
# Without this, 'git -c gpg.format=ssh' and '~/.ssh/id_x' match an 'ssh ' rule.
CMD='(?<![\w=./-])'

# Verbs that print or copy file contents somewhere else.
READERS='(cat|bat|tac|head|tail|less|more|nl|od|xxd|hexdump|strings|base64|grep|rg|ag|awk|sed|cut|tee|cp|scp|rsync|curl|wget|jq|python[0-9.]*|perl|ruby|node)'

# Private key material and credential stores.
#   \b(?!\.pub)  — public keys stay readable
#   \.ssh\b(?!/) — catches bulk reads of the directory (grep -r . ~/.ssh)
#                  while leaving ~/.ssh/config and known_hosts alone
CRED_PATHS='(\.ssh/(id_[A-Za-z0-9_-]+|[A-Za-z0-9_-]*_(rsa|dsa|ecdsa|ed25519))\b(?!\.pub)|\.ssh\b(?![/\w-])|\.gnupg\b(?![\w-])|\.aws/credentials|\.netrc\b|\.config/gh/hosts\.ya?ml|\.docker/config\.json|\.kube/config\b)'

# .env and friends, but not the committed templates.
ENV_PATH='(?<![\w.-])\.env\b(?!\.(example|sample|template|dist|defaults|schema))'

# Container flags that hand out host root. The docker group is uid 0.
DOCKER_ESCALATION='(--privileged|--cap-add|--device[= ]|--userns[= ]?host|--pid[= ]?host|--ipc[= ]?host|--security-opt[= ]?\s*(seccomp|apparmor)=unconfined|--security-opt[= ]?\s*label[=:]disable)'

# Verbs that would print .env contents into the transcript.
ENV_READERS='(cat|bat|tac|head|tail|less|more|nl|od|xxd|strings|grep|rg|ag|awk|sed|cut|jq|dotenv)'

# Patterns that make a file too dangerous to execute automatically. Applied to
# the CONTENT of shell scripts and compose files the command is about to run —
# otherwise `echo 'docker run --privileged' > go.sh && bash go.sh` walks past
# every rule above.
# shellcheck disable=SC2034,SC2016
CONTENT_PATTERNS=(
  "$DOCKER_ESCALATION"
  'privileged:\s*(true|yes)'
  'docker\.sock'
  '-\s+["\x27]?/:'
  '--no-preserve-root'
  '(mkfs|fdisk)\b'
  'dd\s+[^|;]*of=/dev'
  'rm\s+-[a-zA-Z]*[rf][a-zA-Z]*\s+["\x27]?(/|~|\$HOME|/(etc|usr|var|home|root|boot|lib|bin|sbin|opt|srv|dev|proc|sys))(/\*)?["\x27]?(\s|;|$)'
  "${CMD}${READERS}\s+[^;|&]*${CRED_PATHS}"
  "${CMD}${ENV_READERS}\s+[^;|&]*${ENV_PATH}"
  '(curl|wget)[^|;]*\|\s*(ba|z)?sh'
)
