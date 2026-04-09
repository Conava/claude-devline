#!/usr/bin/env bash
# blast-radius.sh — Lightweight grep-based blast radius analysis
# Builds a reverse dependency map from import statements, then BFS-expands
# from seed files to find all affected dependents and associated tests.
#
# Usage:
#   blast-radius.sh --target file1.ts file2.ts   # pre-implementation: "what depends on these?"
#   blast-radius.sh --changed [base]              # post-implementation: git diff → dependents
#   blast-radius.sh --changed                     # defaults to base = HEAD~1
#
# Options:
#   --depth N       BFS depth limit (default: 2)
#   --format md     Output format: md (default) or json
#   --no-tests      Skip test file association

set -euo pipefail

# --- Defaults ---
MODE=""
DEPTH=2
FORMAT="md"
SHOW_TESTS=true
BASE_REF="HEAD~1"
SEED_FILES=()

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      MODE="target"
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        SEED_FILES+=("$1")
        shift
      done
      ;;
    --changed)
      MODE="changed"
      shift
      if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        BASE_REF="$1"
        shift
      fi
      ;;
    --depth)
      shift
      DEPTH="$1"
      shift
      ;;
    --format)
      shift
      FORMAT="$1"
      shift
      ;;
    --no-tests)
      SHOW_TESTS=false
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "Usage: blast-radius.sh --target <files...> | --changed [base-ref]" >&2
  exit 1
fi

# --- Resolve project root ---
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# --- Collect seed files ---
if [[ "$MODE" == "changed" ]]; then
  mapfile -t SEED_FILES < <(git diff --name-only "$BASE_REF" 2>/dev/null || git diff --name-only HEAD 2>/dev/null || true)
  if [[ ${#SEED_FILES[@]} -eq 0 ]]; then
    # Also check unstaged/untracked
    mapfile -t SEED_FILES < <(git diff --name-only 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)
  fi
fi

if [[ ${#SEED_FILES[@]} -eq 0 ]]; then
  echo "No seed files found." >&2
  exit 0
fi

# --- Collect all source files ---
SOURCE_EXTENSIONS="ts,tsx,js,jsx,mjs,cjs,py,go,rs,java,kt,rb,php,c,h,cpp,hpp,cs,vue,svelte"

collect_source_files() {
  local IFS=','
  local exts=($SOURCE_EXTENSIONS)
  for ext in "${exts[@]}"; do
    find . -name "*.${ext}" \
      -not -path "*/node_modules/*" \
      -not -path "*/.git/*" \
      -not -path "*/vendor/*" \
      -not -path "*/dist/*" \
      -not -path "*/build/*" \
      -not -path "*/__pycache__/*" \
      -not -path "*/target/*" \
      -not -path "*/.devline/*" \
      2>/dev/null
  done | sort -u | sed 's|^\./||'
}

mapfile -t ALL_FILES < <(collect_source_files)

if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
  echo "No source files found." >&2
  exit 0
fi

# --- Build import map ---
# For each file, extract what local files it imports.
# Output: "importer -> imported" pairs (file paths relative to root)

declare -A REVERSE_DEPS  # imported_file -> space-separated list of importers

resolve_import_path() {
  local from_file="$1"
  local import_path="$2"
  local from_dir
  from_dir=$(dirname "$from_file")

  # Strip quotes and semicolons
  import_path=$(echo "$import_path" | sed "s/['\";,]//g" | xargs)

  # Skip non-relative imports (third-party packages)
  if [[ "$import_path" != .* && "$import_path" != /* ]]; then
    return
  fi

  # Resolve relative path
  local resolved
  resolved=$(cd "$ROOT" && realpath --relative-to=. "${from_dir}/${import_path}" 2>/dev/null || echo "")

  if [[ -z "$resolved" ]]; then
    return
  fi

  # Try common extensions if no extension present
  if [[ "$resolved" != *.* ]]; then
    for ext in ts tsx js jsx mjs py go rs java kt rb php; do
      if [[ -f "${resolved}.${ext}" ]]; then
        echo "${resolved}.${ext}"
        return
      fi
    done
    # Try index files
    for ext in ts tsx js jsx; do
      if [[ -f "${resolved}/index.${ext}" ]]; then
        echo "${resolved}/index.${ext}"
        return
      fi
    done
  else
    if [[ -f "$resolved" ]]; then
      echo "$resolved"
    fi
  fi
}

extract_imports() {
  local file="$1"
  local ext="${file##*.}"

  case "$ext" in
    ts|tsx|js|jsx|mjs|cjs|vue|svelte)
      # JS/TS: import ... from '...', require('...'), import('...')
      grep -oP "(?:from\s+['\"])([^'\"]+)(?:['\"])|(?:require\s*\(\s*['\"])([^'\"]+)(?:['\"])|(?:import\s*\(\s*['\"])([^'\"]+)(?:['\"])" "$file" 2>/dev/null \
        | grep -oP "(?<=['\"])[^'\"]+(?=['\"])" \
        | while read -r imp; do
            resolve_import_path "$file" "$imp"
          done
      ;;
    py)
      # Python: from .foo import bar, from ..foo import bar, from package.module import bar
      grep -oP "(?:from\s+)(\.+\w[\w.]*)" "$file" 2>/dev/null \
        | sed 's/^from\s*//' \
        | while read -r imp; do
            # Convert dot notation to path
            local rel_path
            rel_path=$(echo "$imp" | sed 's/\./\//g')
            resolve_import_path "$file" "./${rel_path}"
          done
      ;;
    go)
      # Go: import "module/internal/pkg"
      # Only match imports within the module (contain ./ or known module prefix)
      local mod_path=""
      if [[ -f go.mod ]]; then
        mod_path=$(head -1 go.mod | awk '{print $2}')
      fi
      if [[ -n "$mod_path" ]]; then
        grep -oP "\"${mod_path}/([^\"]+)\"" "$file" 2>/dev/null \
          | grep -oP "(?<=\"${mod_path}/)([^\"]+)" \
          | while read -r imp; do
              if [[ -d "$imp" ]]; then
                echo "$imp"
              fi
            done
      fi
      ;;
    rs)
      # Rust: use crate::foo::bar, mod foo
      grep -oP "(?:use\s+crate::)(\w[\w:]*)" "$file" 2>/dev/null \
        | sed 's/use crate:://' \
        | while read -r imp; do
            local rel_path
            rel_path=$(echo "$imp" | sed 's/::/\//g')
            resolve_import_path "$file" "./${rel_path}"
          done
      grep -oP "(?:mod\s+)(\w+)\s*;" "$file" 2>/dev/null \
        | sed 's/mod //' | sed 's/;//' \
        | while read -r imp; do
            resolve_import_path "$file" "./${imp}"
          done
      ;;
    java|kt)
      # Java/Kotlin: import com.package.Class
      # Map to file path heuristic: com/package/Class.java
      grep -oP "(?:import\s+)[\w.]+" "$file" 2>/dev/null \
        | sed 's/^import\s*//' \
        | while read -r imp; do
            local rel_path
            rel_path=$(echo "$imp" | sed 's/\./\//g')
            for e in java kt; do
              if [[ -f "src/main/java/${rel_path}.${e}" ]]; then
                echo "src/main/java/${rel_path}.${e}"
              elif [[ -f "src/main/kotlin/${rel_path}.${e}" ]]; then
                echo "src/main/kotlin/${rel_path}.${e}"
              fi
            done
          done
      ;;
    rb)
      # Ruby: require_relative '...'
      grep -oP "(?:require_relative\s+['\"])([^'\"]+)" "$file" 2>/dev/null \
        | grep -oP "(?<=['\"])[^'\"]+" \
        | while read -r imp; do
            resolve_import_path "$file" "./${imp}"
          done
      ;;
    php)
      # PHP: use App\Namespace\Class, require/include
      grep -oP "(?:require|include)(?:_once)?\s+['\"]([^'\"]+)" "$file" 2>/dev/null \
        | grep -oP "(?<=['\"])[^'\"]+" \
        | while read -r imp; do
            resolve_import_path "$file" "$imp"
          done
      ;;
    c|h|cpp|hpp)
      # C/C++: #include "local.h" (quotes = local, angles = system)
      grep -oP '#include\s+"([^"]+)"' "$file" 2>/dev/null \
        | grep -oP '(?<=")[^"]+' \
        | while read -r imp; do
            resolve_import_path "$file" "$imp"
          done
      ;;
    cs)
      # C#: using statements don't map well to files without project analysis
      # Skip — too namespace-heavy for grep-based analysis
      ;;
  esac
}

# Build the reverse dependency map
for file in "${ALL_FILES[@]}"; do
  while read -r imported; do
    [[ -z "$imported" ]] && continue
    if [[ -n "${REVERSE_DEPS[$imported]:-}" ]]; then
      REVERSE_DEPS[$imported]+=" $file"
    else
      REVERSE_DEPS[$imported]="$file"
    fi
  done < <(extract_imports "$file")
done

# --- BFS from seed files ---
declare -A VISITED
declare -A LEVEL  # file -> depth at which it was discovered

# Normalize seed files (strip ./ prefix)
NORMALIZED_SEEDS=()
for f in "${SEED_FILES[@]}"; do
  f="${f#./}"
  if [[ -f "$f" ]]; then
    NORMALIZED_SEEDS+=("$f")
    VISITED[$f]=1
    LEVEL[$f]=0
  fi
done

# BFS queue: (file, current_depth)
QUEUE=()
for f in "${NORMALIZED_SEEDS[@]}"; do
  QUEUE+=("$f:0")
done

DEPENDENTS=()

while [[ ${#QUEUE[@]} -gt 0 ]]; do
  # Dequeue
  entry="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")

  current_file="${entry%%:*}"
  current_depth="${entry##*:}"

  if [[ $current_depth -ge $DEPTH ]]; then
    continue
  fi

  next_depth=$((current_depth + 1))

  # Get reverse deps for this file
  deps="${REVERSE_DEPS[$current_file]:-}"
  for dep in $deps; do
    if [[ -z "${VISITED[$dep]:-}" ]]; then
      VISITED[$dep]=1
      LEVEL[$dep]=$next_depth
      DEPENDENTS+=("$dep")
      QUEUE+=("$dep:$next_depth")
    fi
  done
done

# --- Find associated test files ---
TEST_FILES=()

if [[ "$SHOW_TESTS" == true ]]; then
  for f in "${NORMALIZED_SEEDS[@]}" "${DEPENDENTS[@]}"; do
    base="${f%.*}"
    ext="${f##*.}"
    dir=$(dirname "$f")
    name=$(basename "$base")

    # Common test file patterns
    candidates=(
      "${base}.test.${ext}"
      "${base}.spec.${ext}"
      "${base}_test.${ext}"
      "${dir}/test_${name}.${ext}"
      "${dir}/__tests__/${name}.test.${ext}"
      "${dir}/__tests__/${name}.spec.${ext}"
      "${base}_test.go"
      "tests/test_${name}.py"
      "test/${name}_test.rb"
    )

    for candidate in "${candidates[@]}"; do
      if [[ -f "$candidate" && -z "${VISITED[$candidate]:-}" ]]; then
        VISITED[$candidate]=1
        TEST_FILES+=("$candidate")
      fi
    done
  done
fi

# --- Output ---
# Categorize dependents by depth
declare -A DEPTH_1=()
declare -A DEPTH_2_PLUS=()

for dep in "${DEPENDENTS[@]}"; do
  lvl="${LEVEL[$dep]:-0}"
  if [[ $lvl -eq 1 ]]; then
    DEPTH_1[$dep]=1
  else
    DEPTH_2_PLUS[$dep]=1
  fi
done

if [[ "$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"seed_files\": ["
  first=true
  for f in "${NORMALIZED_SEEDS[@]}"; do
    $first || echo ","
    printf '    "%s"' "$f"
    first=false
  done
  echo ""
  echo "  ],"
  echo "  \"direct_dependents\": ["
  first=true
  for f in "${!DEPTH_1[@]}"; do
    $first || echo ","
    printf '    "%s"' "$f"
    first=false
  done
  echo ""
  echo "  ],"
  echo "  \"transitive_dependents\": ["
  first=true
  for f in "${!DEPTH_2_PLUS[@]}"; do
    $first || echo ","
    printf '    "%s"' "$f"
    first=false
  done
  echo ""
  echo "  ],"
  echo "  \"test_files\": ["
  first=true
  for f in "${TEST_FILES[@]}"; do
    $first || echo ","
    printf '    "%s"' "$f"
    first=false
  done
  echo ""
  echo "  ],"
  echo "  \"total_affected\": $((${#NORMALIZED_SEEDS[@]} + ${#DEPENDENTS[@]} + ${#TEST_FILES[@]}))"
  echo "}"
else
  echo "## Blast Radius Analysis"
  echo ""
  echo "**Seed files** (${#NORMALIZED_SEEDS[@]}):"
  for f in "${NORMALIZED_SEEDS[@]}"; do
    echo "- \`$f\`"
  done
  echo ""

  if [[ ${#DEPTH_1[@]} -gt 0 ]]; then
    echo "**Direct dependents** (${#DEPTH_1[@]}) — files that import a seed file:"
    for f in "${!DEPTH_1[@]}"; do
      echo "- \`$f\`"
    done
    echo ""
  fi

  if [[ ${#DEPTH_2_PLUS[@]} -gt 0 ]]; then
    echo "**Transitive dependents** (${#DEPTH_2_PLUS[@]}) — depth 2+:"
    for f in "${!DEPTH_2_PLUS[@]}"; do
      echo "- \`$f\`"
    done
    echo ""
  fi

  if [[ ${#TEST_FILES[@]} -gt 0 ]]; then
    echo "**Associated tests** (${#TEST_FILES[@]}):"
    for f in "${TEST_FILES[@]}"; do
      echo "- \`$f\`"
    done
    echo ""
  fi

  total=$((${#NORMALIZED_SEEDS[@]} + ${#DEPENDENTS[@]} + ${#TEST_FILES[@]}))
  echo "**Total affected files:** ${total}"

  if [[ ${#DEPENDENTS[@]} -eq 0 && ${#TEST_FILES[@]} -eq 0 ]]; then
    echo ""
    echo "_No dependents found. These files may be leaf nodes or use patterns not captured by import analysis._"
  fi
fi
