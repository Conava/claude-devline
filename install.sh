#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugin"
PLUGIN_NAME="claude-devline"

# Validate plugin exists
if [ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    echo "Error: Plugin manifest not found at $PLUGIN_DIR/.claude-plugin/plugin.json"
    exit 1
fi

# Detect shell config file
SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
    zsh)  RC_FILE="$HOME/.zshrc" ;;
    bash) RC_FILE="$HOME/.bashrc" ;;
    *)    RC_FILE="" ;;
esac

ALIAS_LINE="alias claude='claude --plugin-dir \"$PLUGIN_DIR\"'"
MARKER="# $PLUGIN_NAME"

if [[ -n "$RC_FILE" && -f "$RC_FILE" ]]; then
    # Remove old entry if present
    if grep -qF "$MARKER" "$RC_FILE" 2>/dev/null; then
        # Remove the marker line and the alias line after it
        sed -i "/$MARKER/,+1d" "$RC_FILE"
    fi

    # Append alias
    printf '\n%s\n%s\n' "$MARKER" "$ALIAS_LINE" >> "$RC_FILE"

    echo "Added plugin alias to $RC_FILE:"
    echo "  $ALIAS_LINE"
    echo ""
    echo "Run 'source $RC_FILE' or open a new terminal, then start claude."
    echo "Updates from git pull take effect on next claude restart — no reinstall needed."
else
    echo "Could not detect shell config file."
    echo ""
    echo "Add this alias to your shell config manually:"
    echo "  $ALIAS_LINE"
    echo ""
    echo "Or launch directly:"
    echo "  claude --plugin-dir $PLUGIN_DIR"
fi
