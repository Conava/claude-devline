#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugin"
PLUGINS_DIR="$HOME/.claude/plugins"
INSTALLED_FILE="$PLUGINS_DIR/installed_plugins.json"
PLUGIN_NAME="marlon-claude-plugin"

if [ ! -d "$PLUGINS_DIR" ]; then
    echo "Error: $PLUGINS_DIR does not exist. Is Claude Code installed?"
    exit 1
fi

# Register in installed_plugins.json
if [ ! -f "$INSTALLED_FILE" ]; then
    echo '{"version":2,"plugins":{}}' > "$INSTALLED_FILE"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
ENTRY=$(cat <<EOF
{
  "scope": "user",
  "installPath": "$PLUGIN_DIR",
  "version": "0.1.0",
  "installedAt": "$TIMESTAMP",
  "lastUpdated": "$TIMESTAMP"
}
EOF
)

# Use jq if available, otherwise use python
if command -v jq &>/dev/null; then
    jq --arg name "$PLUGIN_NAME" --argjson entry "$ENTRY" \
        '.plugins[$name] = [$entry]' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" \
        && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
elif command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$INSTALLED_FILE') as f:
    data = json.load(f)
data['plugins']['$PLUGIN_NAME'] = [json.loads('''$ENTRY''')]
with open('$INSTALLED_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
else
    echo "Warning: Neither jq nor python3 found. Please manually add '$PLUGIN_NAME' to $INSTALLED_FILE"
    exit 0
fi

echo "Registered $PLUGIN_NAME (path: $PLUGIN_DIR) in $INSTALLED_FILE"
echo "Done! Restart Claude Code to load the plugin."
