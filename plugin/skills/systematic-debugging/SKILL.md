---
name: systematic-debugging
description: "Use when encountering any bug, test failure, or unexpected behavior — before proposing fixes. Also use as a standalone entry point for bug-fixing tasks without the full pipeline."
argument-hint: "[bug description or error message]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Bash, Grep, Glob
---

# Systematic Debugging

Standalone entry point for bug-fixing tasks that don't need brainstorm or plan. The actual debugging methodology (four-phase root cause analysis) lives in the debugger agent.

## Procedure

1. **Branch safety.** If on a protected branch, create a fix branch: `fix/<descriptive-slug>`.

2. **Spawn the debugger agent.** Pass the bug description, error messages, reproduction steps, and any relevant files the user mentioned. The debugger agent performs systematic root cause analysis and implements the fix.

3. **Spawn the verifier agent.** After the debugger returns, verify that tests and build pass.

4. **Report results.** Summarize the root cause, fix applied, and test outcome. Offer to create a PR.
