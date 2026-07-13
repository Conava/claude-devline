#!/usr/bin/env bash
set -euo pipefail

# devline one-command installer.
#
# Installs Claude Code (if missing), the devline plugin, and the recommended
# companions (RTK, Ponytail, Basic Memory). Cross-platform: Linux (apt, pacman,
# dnf, zypper, apk), macOS (Homebrew), and Windows via WSL or Git Bash.
#
# Safe to re-run — every step checks first, and optional steps warn-and-continue
# instead of aborting. Missing UNDERLYING tools (a package manager, uv, node, jq,
# git, gh, Claude Code) are offered before installing; the devline plugin and the
# companions install by default (gate them with --minimal / --skip-*).
#
# Review this script before running it. Usage:
#   bash install.sh                 # everything (prompts before installing missing tools)
#   bash install.sh --yes           # assume "yes" to every prompt (non-interactive / CI)
#   bash install.sh --minimal       # devline only, no companions
#   bash install.sh --skip-rtk --skip-ponytail --skip-memory   # skip specific companions
#
# On Windows: run inside WSL (recommended) or Git Bash. No native PowerShell installer.

# ---- flags ------------------------------------------------------------------
MINIMAL=0; SKIP_RTK=0; SKIP_PONYTAIL=0; SKIP_MEMORY=0; ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --minimal)       MINIMAL=1 ;;
    --skip-rtk)      SKIP_RTK=1 ;;
    --skip-ponytail) SKIP_PONYTAIL=1 ;;
    --skip-memory)   SKIP_MEMORY=1 ;;
    -y|--yes)        ASSUME_YES=1 ;;
    -h|--help)       grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[devline] unknown option: $arg (ignored)" ;;
  esac
done

# ---- helpers ----------------------------------------------------------------
log()  { printf '[devline] %s\n' "$*"; }
warn() { printf '[devline] WARNING: %s\n' "$*" >&2; }

# Run an optional step: warn and continue on failure, never abort the script.
step() {
  local desc="$1"; shift
  if "$@"; then return 0; else warn "$desc failed — continuing (see the tool's repo for manual install)."; return 0; fi
}

# Ask before installing an underlying tool. Yes if --yes or no TTY; else prompt.
confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ -e /dev/tty ] || return 0
  local ans=""
  printf '[devline] %s [Y/n] ' "$1" > /dev/tty
  read -r ans < /dev/tty || return 0
  case "$ans" in [nN]|[nN][oO]) return 1 ;; *) return 0 ;; esac
}

INSTALLED=(); NOTES=(); CLAUDE_JUST_INSTALLED=0

# sudo only when not already root and sudo exists.
SUDO=""
if [ "$(id -u 2>/dev/null || echo 0)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

# ---- OS / package-manager detection -----------------------------------------
OS="$(uname -s)"
PM=""
case "$OS" in
  Darwin) command -v brew >/dev/null 2>&1 && PM=brew ;;
  Linux)  for c in apt-get pacman dnf zypper apk; do command -v "$c" >/dev/null 2>&1 && { PM="$c"; break; }; done ;;
  MINGW*|MSYS*|CYGWIN*) for c in winget scoop choco pacman; do command -v "$c" >/dev/null 2>&1 && { PM="$c"; break; }; done ;;
esac

# macOS with no Homebrew → offer to install it (the default PM there).
if [ "$OS" = "Darwin" ] && [ -z "$PM" ] && confirm "Homebrew is not installed (recommended on macOS). Install it now?"; then
  step "install Homebrew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; PM=brew; break; }; done
fi
log "OS: $OS, package manager: ${PM:-none detected}"

# pkg_install <generic-name> — map to the detected PM and install.
pkg_install() {
  local pkg="$1" m="$1"
  case "$PM" in
    apt-get) case "$pkg" in node) m=nodejs;; esac; $SUDO apt-get update -qq && $SUDO apt-get install -y "$m" ;;
    pacman)  case "$pkg" in node) m=nodejs;; gh) m=github-cli;; esac; $SUDO pacman -S --noconfirm "$m" ;;
    dnf)     case "$pkg" in node) m=nodejs;; esac; $SUDO dnf install -y "$m" ;;
    zypper)  case "$pkg" in node) m=nodejs;; esac; $SUDO zypper --non-interactive install "$m" ;;
    apk)     case "$pkg" in node) m=nodejs;; gh) m=github-cli;; esac; $SUDO apk add "$m" ;;
    brew)    case "$pkg" in node) m=node;; esac; brew install "$m" ;;
    winget)  case "$pkg" in git) m=Git.Git;; jq) m=jqlang.jq;; gh) m=GitHub.cli;; node) m=OpenJS.NodeJS;; uv) m=astral-sh.uv;; curl) m=cURL.cURL;; *) m="$pkg";; esac
             winget install -e --id "$m" --accept-source-agreements --accept-package-agreements ;;
    scoop)   scoop install "$pkg" ;;
    choco)   choco install -y "$pkg" ;;
    *)       warn "no known package manager — install '$pkg' manually"; return 1 ;;
  esac
}

# ensure_tool <cmd> <human> — offer to install a missing underlying tool.
ensure_tool() {
  local cmd="$1" human="$2"
  command -v "$cmd" >/dev/null 2>&1 && { log "present: $cmd"; return 0; }
  [ -n "$PM" ] || { warn "$human missing and no package manager detected — install it manually."; return 1; }
  if confirm "$human is needed and missing. Install via $PM?"; then
    step "install $human" pkg_install "$cmd"; command -v "$cmd" >/dev/null 2>&1
  else
    return 1
  fi
}

# uv — package manager first (widely packaged), official astral installer as fallback.
ensure_uv() {
  command -v uv >/dev/null 2>&1 && { log "present: uv"; return 0; }
  if [ -n "$PM" ] && confirm "uv (Python tool, needed for Basic Memory) is missing. Install via $PM?"; then
    if step "install uv ($PM)" pkg_install uv && command -v uv >/dev/null 2>&1; then return 0; fi
    warn "uv not available via $PM — falling back to the official installer."
  fi
  if confirm "Install uv via the official astral.sh installer?"; then
    step "install uv (astral)" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    export PATH="$HOME/.local/bin:$PATH"; command -v uv >/dev/null 2>&1
  else
    return 1
  fi
}

# ---- prerequisites ----------------------------------------------------------
ensure_tool git  "git"  || warn "git is required for most devline features."
ensure_tool curl "curl" || true
ensure_tool jq   "jq"   || warn "jq is required by devline's hooks."
ensure_tool gh   "GitHub CLI (gh)" || warn "gh is optional — needed for PR/issue features. https://cli.github.com/"

# ---- Claude Code (official installer first, npm fallback) -------------------
if command -v claude >/dev/null 2>&1; then
  log "Claude Code already installed"
elif confirm "Claude Code is not installed. Install it (official installer)?"; then
  step "install Claude Code" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
  if ! command -v claude >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    warn "official installer didn't put 'claude' on PATH — trying npm."
    step "install Claude Code (npm)" bash -c 'npm install -g @anthropic-ai/claude-code'
  fi
  if command -v claude >/dev/null 2>&1; then CLAUDE_JUST_INSTALLED=1; NOTES+=("Run 'claude' once to authenticate (browser login)."); fi
fi

have_claude() { command -v claude >/dev/null 2>&1; }
have_claude || warn "claude CLI not on PATH — skipping plugin/MCP steps. Re-run after installing + authenticating Claude Code."

# ---- devline plugin (installs by default) ----------------------------------
if have_claude; then
  log "installing devline plugin"
  claude plugin marketplace add Conava/claude-devline || true
  claude plugin install devline@devline || true
  INSTALLED+=("devline plugin")
fi

# ---- RTK (official installer first, brew fallback) -------------------------
if [ "$MINIMAL" -eq 0 ] && [ "$SKIP_RTK" -eq 0 ]; then
  if command -v rtk >/dev/null 2>&1; then
    log "RTK already installed"; INSTALLED+=("RTK (already present)")
  else
    log "installing RTK"
    step "install RTK" bash -c 'curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh'
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v rtk >/dev/null 2>&1 && [ "$PM" = brew ]; then step "install RTK (brew)" bash -c 'brew install rtk-ai/tap/rtk'; fi
    if command -v rtk >/dev/null 2>&1; then step "rtk init -g" rtk init -g; INSTALLED+=("RTK"); fi
  fi
else
  log "skipping RTK"
fi

# ---- Ponytail plugin (installs by default) ---------------------------------
if [ "$MINIMAL" -eq 0 ] && [ "$SKIP_PONYTAIL" -eq 0 ]; then
  if have_claude; then
    log "installing Ponytail plugin"
    claude plugin marketplace add DietrichGebert/ponytail || true
    claude plugin install ponytail@ponytail || true
    INSTALLED+=("Ponytail plugin")
  fi
else
  log "skipping Ponytail"
fi

# ---- Basic Memory (installs by default; offers uv if missing) --------------
if [ "$MINIMAL" -eq 0 ] && [ "$SKIP_MEMORY" -eq 0 ]; then
  log "installing Basic Memory"
  if ensure_uv; then
    export PATH="$HOME/.local/bin:$PATH"
    step "uv tool install basic-memory" uv tool install basic-memory
    # Per-session MCP wrapper — quoted heredoc so nothing expands at write time.
    mkdir -p "$HOME/.claude/mcp"
    cat > "$HOME/.claude/mcp/basic-memory-cwd.sh" <<'WRAPPER'
#!/usr/bin/env bash
# Per-session Basic Memory MCP server, bound to the current repo's project.
# One stdio server per Claude session (in that session's cwd) → each session
# pins to its own repo via --project, so parallel sessions never clobber a
# shared "active project".
export PATH="$HOME/.local/bin:$PATH"
repo=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$repo" ]; then
  name=$(basename "$repo")
  if ! basic-memory project list 2>/dev/null | grep -qw "$name"; then
    mkdir -p "$repo/memory"
    basic-memory project add "$name" "$repo/memory" >/dev/null 2>&1 || true
  fi
  exec basic-memory mcp --project "$name"
fi
exec basic-memory mcp
WRAPPER
    chmod +x "$HOME/.claude/mcp/basic-memory-cwd.sh"
    log "wrote $HOME/.claude/mcp/basic-memory-cwd.sh"
    if have_claude; then
      claude mcp remove basic-memory >/dev/null 2>&1 || true
      step "register basic-memory MCP" claude mcp add --scope user basic-memory -- bash "$HOME/.claude/mcp/basic-memory-cwd.sh"
      claude plugin marketplace add basicmachines-co/basic-memory-plugins || true
      claude plugin install basic-memory@basicmachines-co || true
    fi
    INSTALLED+=("Basic Memory (per-session MCP wrapper)")
  else
    warn "uv unavailable — skipped Basic Memory. Install uv, then re-run."
  fi
else
  log "skipping Basic Memory"
fi

# ---- summary ----------------------------------------------------------------
echo
log "===== install summary ====="
if [ "${#INSTALLED[@]}" -eq 0 ]; then
  log "nothing new installed"
else
  for item in "${INSTALLED[@]}"; do log "installed: $item"; done
fi
echo
log "Next steps:"
[ "$CLAUDE_JUST_INSTALLED" -eq 1 ] && log "  1. Run 'claude' once to authenticate (browser login)."
log "  * Restart Claude Code so new MCP servers and plugins load."
log "  * Run '/devline:setup' inside each project to configure it."
case "$OS" in MINGW*|MSYS*|CYGWIN*) log "  * On Windows, WSL gives the smoothest experience if anything above failed." ;; esac
for note in "${NOTES[@]-}"; do [ -n "$note" ] && log "  note: $note"; done
