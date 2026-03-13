---
name: debug
description: This skill should be used when the user asks to "debug this", "fix this bug", "find the root cause", "investigate an error", "troubleshoot", "why is this failing", "trace the issue", or mentions errors, exceptions, stack traces, or unexpected behavior that needs investigation. Launches the debugger agent for systematic root cause analysis.
argument-hint: "<bug description, error message, or failing test>"
user-invocable: true
disable-model-invocation: false
---

# Debug — Systematic Bug Investigation

Launch the **debugger** agent to investigate and fix a bug using systematic root cause analysis.

## Determine Scope
1. If the user provides an error message, stack trace, or failing test — pass it directly
2. If the user describes unexpected behavior — pass the description
3. If no specifics given, the debugger will reproduce the issue first

## After Debug
Present the debugger's findings:
- Root cause identified and fixed
- Or: root cause identified, fix needs user decision

If the fix touches multiple files or is complex, suggest running `/devline:review` on the changes.
