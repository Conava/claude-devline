---
name: review
description: Perform an in-depth code review of recent changes. Checks correctness, security, performance, and code quality.
argument-hint: "[files or description of changes to review]"
user-invocable: true
disable-model-invocation: true
---

# Review — In-Depth Code Review

Launch the **reviewer** agent to perform a thorough code review.

## Determine Scope
1. If the user specifies files or a description, review those
2. If no scope is given, review uncommitted changes (`git diff` and `git diff --staged`)
3. If no uncommitted changes, review the most recent commit

## Review Process
The reviewer agent will check:
- **Correctness** — logic errors, edge cases, error handling
- **Security** — injection, credentials, auth, input validation
- **Performance** — N+1 queries, memory leaks, blocking calls
- **Quality** — naming, conventions, dead code, test quality

## After Review
- **PASS**: Code is ready — present results to the user
- **FAIL**: The reviewer returns issues with file:line references and fix suggestions. Launch an **implementer** agent with the issue list, then re-run the **reviewer** on the fixed code. Repeat up to 2 cycles. If still failing, escalate to the **debugger** agent.
