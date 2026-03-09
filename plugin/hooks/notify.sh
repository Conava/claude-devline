#!/usr/bin/env bash
# notify.sh — Notification hook
# Handles permission_prompt and idle_prompt notifications.
set -euo pipefail

INPUT="$(cat)"

NOTIFICATION_TYPE="$(printf '%s' "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('notification_type', data.get('matcher', 'unknown')))
" 2>/dev/null || echo "unknown")"

case "$NOTIFICATION_TYPE" in
  permission_prompt)
    # No action needed — permission prompt is handled by Claude Code
    ;;
  idle_prompt)
    # No action needed — just acknowledge
    ;;
esac

exit 0
