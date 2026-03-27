#!/bin/bash
set -euo pipefail

# Usage: ./release.sh <version>
# Example: ./release.sh 0.3.0
#
# Bumps version in plugin.json and marketplace.json, commits, tags, and pushes.

if [ $# -ne 1 ]; then
  echo "Usage: ./release.sh <version>"
  echo "Example: ./release.sh 0.3.0"
  exit 1
fi

VERSION="$1"

# Validate semver-ish format
if ! printf '%s' "$VERSION" | grep -qP '^\d+\.\d+\.\d+(-\w+(\.\w+)*)?$'; then
  echo "Error: version must be semver (e.g., 0.3.0 or 1.0.0-beta.1)"
  exit 1
fi

# Check for clean working tree
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or stash changes first."
  exit 1
fi

# Check tag doesn't already exist
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Error: tag v$VERSION already exists"
  exit 1
fi

# Bump version in both JSON files
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  jq --arg v "$VERSION" '
    if .version then .version = $v else . end |
    if .plugins then .plugins |= map(if .version then .version = $v else . end) else . end
  ' "$f" > tmp.json && mv tmp.json "$f"
done

git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: release v$VERSION"
git tag "v$VERSION"
git push origin main --tags

echo "Released v$VERSION"
