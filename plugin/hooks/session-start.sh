#!/usr/bin/env bash
# session-start.sh — SessionStart hook
#
# Gathers skills, config, git branch info, and pipeline state,
# then outputs a JSON payload with additional_context for the session.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  echo '{"error": "CLAUDE_PLUGIN_ROOT is not set"}' >&2
  exit 1
fi

SCRIPTS_DIR="$PLUGIN_ROOT/scripts"
SKILLS_DIR="$PLUGIN_ROOT/skills"
STATE_DIR="$PLUGIN_ROOT/state"

# -----------------------------------------------------------------------
# 0. Dependency check — report issues loudly before doing anything else
# -----------------------------------------------------------------------
DEP_WARNINGS=()

# python3 is required by all hooks for JSON parsing and config loading
if ! command -v python3 &>/dev/null; then
  DEP_WARNINGS+=("MISSING: python3 — required by all hooks for JSON parsing. Install it via your package manager (e.g. brew install python3) or via https://python.org")
fi

# git is required by guard.sh and session-start for branch detection
if ! command -v git &>/dev/null; then
  DEP_WARNINGS+=("MISSING: git — required for branch safety checks. Install it via your package manager.")
fi

# bash version: mapfile is bash 4+, but we now use a compatible while-read loop.
# Still warn if running ancient bash so users understand the context.
BASH_MAJOR="${BASH_VERSINFO[0]:-0}"
if [[ "$BASH_MAJOR" -lt 4 ]]; then
  DEP_WARNINGS+=("WARNING: bash ${BASH_VERSION} detected ($(which bash)). Some hook features work best with bash 4+. On macOS, install via: brew install bash")
fi

# merge-config.py must be executable
if [[ ! -x "$SCRIPTS_DIR/merge-config.py" ]]; then
  DEP_WARNINGS+=("WARNING: $SCRIPTS_DIR/merge-config.py is not executable. Run: chmod +x '$SCRIPTS_DIR/merge-config.py'")
fi

# -----------------------------------------------------------------------
# 1. Merged config
# -----------------------------------------------------------------------
CONFIG_JSON=$("$SCRIPTS_DIR/merge-config.py")

# -----------------------------------------------------------------------
# 2. Discover skills (filtered by project tech stack)
# -----------------------------------------------------------------------

# 2a. Auto-detect project tech stack by scanning for file extensions
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DETECTED_SKILLS=""

detect_project_skills() {
  python3 - "$PROJECT_DIR" "$PLUGIN_ROOT/config/skill-mappings.yaml" "$CONFIG_JSON" <<'PYEOF'
import sys, os, json, glob

project_dir = sys.argv[1]
mappings_path = sys.argv[2]
config_json = sys.argv[3]

# Parse config for skill overrides
try:
    config = json.loads(config_json)
except:
    config = {}

skills_cfg = config.get('skills', {})
always_show = skills_cfg.get('always_show', [])
enabled_override = skills_cfg.get('enabled', [])
disabled = skills_cfg.get('disabled', [])

# If explicit enabled list, use that + always_show
if enabled_override:
    result = set(always_show) | set(enabled_override)
    result -= set(disabled)
    for s in sorted(result):
        print(s)
    sys.exit(0)

# Auto-detect: scan top-level and src/ for file extensions
detected = set()
ext_to_skills = {}

# Parse skill-mappings.yaml (minimal parser)
try:
    import yaml
    with open(mappings_path) as f:
        mappings = yaml.safe_load(f) or {}
except ImportError:
    mappings = {}
    section = None
    with open(mappings_path) as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            if not line.startswith(' ') and stripped.endswith(':'):
                section = stripped[:-1]
                continue
            if section == 'file_patterns' and ':' in stripped:
                pattern, _, skills_str = stripped.partition(':')
                pattern = pattern.strip().strip('"').strip("'")
                skills_str = skills_str.strip().strip('[]')
                skills_list = [s.strip() for s in skills_str.split(',')]
                ext_to_skills[pattern] = skills_list

if 'file_patterns' in mappings:
    ext_to_skills = mappings['file_patterns']

# Scan project for file extensions and filenames (max 500 files, top 3 levels)
scanned = 0
found_exts = set()
found_names = set()
depth_globs = [
    '*', '*/*', '*/*/*',
    'src/*', 'src/*/*', 'src/*/*/*', 'src/*/*/*/*', 'src/*/*/*/*/*',
    'lib/*', 'lib/*/*', 'app/*', 'app/*/*', 'cmd/*', 'cmd/*/*',
]
for depth_glob in depth_globs:
    for f in glob.glob(os.path.join(project_dir, depth_glob)):
        if scanned > 500:
            break
        if os.path.isfile(f):
            scanned += 1
            basename = os.path.basename(f)
            _, ext = os.path.splitext(f)
            if ext:
                found_exts.add('*' + ext)
            found_names.add(basename)

# Also check for framework markers in key files
framework_markers = {}
if 'framework_markers' in mappings:
    framework_markers = mappings['framework_markers']

key_files = ['package.json', 'pom.xml', 'build.gradle', 'build.gradle.kts',
             'Cargo.toml', 'go.mod', 'pyproject.toml', 'setup.py',
             'requirements.txt', 'Gemfile', 'composer.json']
file_contents = ''
for kf in key_files:
    kf_path = os.path.join(project_dir, kf)
    if os.path.isfile(kf_path):
        try:
            with open(kf_path) as fh:
                file_contents += fh.read(4096) + '\n'
        except:
            pass

# Match file extensions and full filenames to skills
for ext_pattern, skills_list in ext_to_skills.items():
    if ext_pattern.startswith('*'):
        if ext_pattern in found_exts:
            detected.update(skills_list)
    else:
        # Full filename pattern (e.g. pom.xml, Makefile, Cargo.toml)
        if ext_pattern in found_names:
            detected.update(skills_list)

# Match framework markers
for marker, skills_list in framework_markers.items():
    # marker may contain | for alternatives
    for m in marker.split('|'):
        if m.strip() in file_contents:
            detected.update(skills_list)
            break

# Also check directory patterns
dir_patterns = {}
if 'directory_patterns' in mappings:
    dir_patterns = mappings['directory_patterns']
for dir_pat, skills_list in dir_patterns.items():
    check_path = os.path.join(project_dir, dir_pat.rstrip('/'))
    if os.path.isdir(check_path):
        detected.update(skills_list)

# Combine: always_show + detected - disabled
result = set(always_show) | detected
result -= set(disabled)

for s in sorted(result):
    print(s)
PYEOF
}

DETECTED_SKILLS=$(detect_project_skills 2>/dev/null || echo "")

# 2b. Build filtered skill listing
# Skills with disable-model-invocation: true are listed by name only (no description injected)
# — they're explicit-invocation skills and don't need to prime Claude's auto-suggestion.
SKILLS_LINES=""
if [[ -d "$SKILLS_DIR" ]]; then
  for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
    [[ -f "$skill_file" ]] || continue

    skill_name=""
    skill_desc=""
    disable_model_invocation="false"
    in_frontmatter=0
    while IFS= read -r line; do
      if [[ "$line" == "---" ]]; then
        if [[ $in_frontmatter -eq 1 ]]; then
          break
        fi
        in_frontmatter=1
        continue
      fi
      if [[ $in_frontmatter -eq 1 ]]; then
        if [[ "$line" =~ ^name:[[:space:]]*(.*) ]]; then
          skill_name="${BASH_REMATCH[1]}"
          skill_name="${skill_name%\"}"
          skill_name="${skill_name#\"}"
          skill_name="${skill_name%\'}"
          skill_name="${skill_name#\'}"
        fi
        if [[ "$line" =~ ^disable-model-invocation:[[:space:]]*(.*) ]]; then
          disable_model_invocation="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
          raw="${BASH_REMATCH[1]}"
          # Strip quotes and block scalar indicator (|, |-, >)
          raw="${raw%\"}"
          raw="${raw#\"}"
          raw="${raw%\'}"
          raw="${raw#\'}"
          raw="${raw#|}"
          raw="${raw#|-}"
          raw="${raw#>}"
          raw="$(echo "$raw" | tr -s ' ' | sed 's/^[[:space:]]*//')"
          skill_desc="$raw"
        elif [[ $in_frontmatter -eq 1 && -z "$skill_desc" && "$line" =~ ^[[:space:]]+(.*) ]]; then
          # Continuation line for block scalar description
          cont="${BASH_REMATCH[1]}"
          cont="$(echo "$cont" | tr -s ' ' | sed 's/^[[:space:]]*//')"
          if [[ -n "$cont" ]]; then
            skill_desc="$cont"
          fi
        fi
      fi
    done < "$skill_file"

    if [[ -n "$skill_name" ]]; then
      # Filter: only show if in detected skills list (or if detection failed, show all)
      if [[ -z "$DETECTED_SKILLS" ]] || echo "$DETECTED_SKILLS" | grep -qx "$skill_name"; then
        if [[ "$disable_model_invocation" == "true" ]]; then
          # Explicit-invocation only: list name without description to save context
          SKILLS_LINES="${SKILLS_LINES}- ${skill_name}\n"
        else
          SKILLS_LINES="${SKILLS_LINES}- ${skill_name}: ${skill_desc}\n"
        fi
      fi
    fi
  done
fi

# -----------------------------------------------------------------------
# 3. Check for active pipeline state
# -----------------------------------------------------------------------
PIPELINE_MSG=""
if [[ -d "$STATE_DIR" ]]; then
  for state_file in "$STATE_DIR"/*.json; do
    [[ -f "$state_file" ]] || continue

    # Parse state file: find run_id, top-level status, current running stage, and task description
    PIPELINE_INFO=$(python3 - "$state_file" <<'PYEOF' 2>/dev/null || echo "")
import json, sys
try:
    with open(sys.argv[1]) as f:
        state = json.load(f)
    status = state.get('status', '')
    if status not in ('running', 'paused', 'pending'):
        sys.exit(0)
    run_id = state.get('run_id', 'unknown')
    task_desc = state.get('task_description', '')
    branch = state.get('branch', '')
    # Find the currently active stage
    stages = state.get('stages', {})
    active_stage = next(
        (name for name, s in stages.items()
         if isinstance(s, dict) and s.get('status') in ('running', 'paused')),
        None
    )
    if not active_stage:
        # Fall back to last completed stage + 1
        stage_order = ['brainstorm', 'plan', 'implement', 'docs', 'deep_review', 'verification', 'merge_prep']
        completed = [name for name in stage_order if isinstance(stages.get(name), dict) and stages[name].get('status') == 'complete']
        active_stage = stage_order[len(completed)] if len(completed) < len(stage_order) else 'unknown'
    desc_snippet = task_desc[:60] + ('...' if len(task_desc) > 60 else '')
    print(f'{run_id}|{status}|{active_stage}|{branch}|{desc_snippet}')
except Exception:
    pass
PYEOF

    if [[ -n "$PIPELINE_INFO" ]]; then
      IFS='|' read -r run_id pip_status active_stage branch task_desc <<< "$PIPELINE_INFO"
      PIPELINE_MSG="Active pipeline (${pip_status}): '${task_desc}' on branch '${branch}', stage=${active_stage}. Run ID: ${run_id}. Resume by telling me to continue or use /pipeline."
      break  # report the first active pipeline found
    fi
  done
fi

# -----------------------------------------------------------------------
# 4. Check git branch against protected branches
# -----------------------------------------------------------------------
BRANCH_WARNING=""
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

if [[ -n "$CURRENT_BRANCH" && -n "$CONFIG_JSON" ]]; then
  # Extract protected_branches array values from JSON config
  # Using python for reliable JSON parsing since we already depend on it
  PROTECTED=$( python3 -c "
import json, sys
cfg = json.loads(sys.stdin.read())
branches = cfg.get('safeguards', {}).get('protected_branches', [])
for b in branches:
    print(b)
" <<< "$CONFIG_JSON" 2>/dev/null || true )

  while IFS= read -r branch; do
    if [[ -n "$branch" && "$CURRENT_BRANCH" == "$branch" ]]; then
      BRANCH_WARNING="WARNING: You are on protected branch '${CURRENT_BRANCH}'. Create a feature branch before making changes."
      break
    fi
  done <<< "$PROTECTED"
fi

# -----------------------------------------------------------------------
# 5. Config summary
# -----------------------------------------------------------------------
CONFIG_SUMMARY=$( python3 -c "
import json, sys
cfg = json.loads(sys.stdin.read())

parts = []
testing = cfg.get('testing', {})
approach = testing.get('approach', testing.get('strategy', ''))
if approach:
    parts.append('Test approach: ' + str(approach))

workflow = cfg.get('workflow', {})
checkpoints = workflow.get('human_checkpoints', [])
if checkpoints:
    parts.append('Human checkpoints: ' + ', '.join(str(c) for c in checkpoints))

git_cfg = cfg.get('git', {})
commit_fmt = git_cfg.get('commit_format', '')
if commit_fmt:
    parts.append('Commit format: ' + str(commit_fmt))

print('; '.join(parts) if parts else '')
" <<< "$CONFIG_JSON" 2>/dev/null || true )

# -----------------------------------------------------------------------
# 6. Build additional_context
# -----------------------------------------------------------------------
CONTEXT=""

if [[ "${#DEP_WARNINGS[@]}" -gt 0 ]]; then
  CONTEXT+="PLUGIN DEPENDENCY ISSUES — hooks may not work correctly:\n"
  for warn in "${DEP_WARNINGS[@]}"; do
    CONTEXT+="  • ${warn}\n"
  done
  CONTEXT+="\n"
fi

if [[ -n "$SKILLS_LINES" ]]; then
  CONTEXT+="SKILL USAGE RULES (mandatory — no exceptions):\n"
  CONTEXT+="Never implement code, fix bugs, or make code changes directly in the main session. All development work goes through a skill.\n"
  CONTEXT+="- Bug, error, crash, unexpected behavior, test failure → MUST use: systematic-debugging\n"
  CONTEXT+="- New feature, refactor, task implementation → MUST use: pipeline or implement\n"
  CONTEXT+="- Code review request → MUST use: review\n"
  CONTEXT+="- Documentation update → MUST use: docs-update or docs-generate\n"
  CONTEXT+="Invoke the matching skill via the Skill tool BEFORE doing anything else — including asking clarifying questions. Announce it first: \"I'm using the [skill-name] skill to [one-line purpose].\" Once loaded, follow it exactly.\n"
  CONTEXT+="\nAvailable skills:\n${SKILLS_LINES}"
fi

if [[ -n "$BRANCH_WARNING" ]]; then
  [[ -n "$CONTEXT" ]] && CONTEXT+="\n"
  CONTEXT+="${BRANCH_WARNING}"
fi

if [[ -n "$PIPELINE_MSG" ]]; then
  [[ -n "$CONTEXT" ]] && CONTEXT+="\n"
  CONTEXT+="${PIPELINE_MSG}"
fi

if [[ -n "$CONFIG_SUMMARY" ]]; then
  [[ -n "$CONTEXT" ]] && CONTEXT+="\n"
  CONTEXT+="${CONFIG_SUMMARY}"
fi

# Resolve escape sequences
CONTEXT_RESOLVED=$(printf '%b' "$CONTEXT")

# -----------------------------------------------------------------------
# 7. Output JSON
# -----------------------------------------------------------------------
python3 -c "
import json, sys
ctx = sys.stdin.read()
payload = {
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': ctx
    }
}
json.dump(payload, sys.stdout, indent=2)
print()
" <<< "$CONTEXT_RESOLVED"
