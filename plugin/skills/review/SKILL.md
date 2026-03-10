---
name: review
description: "Use when the user asks to 'review this code', 'deep review', 'check for security issues', 'review my changes', or 'audit this branch'."
argument-hint: "[branch, scope, or file path]"
user-invocable: true
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Standalone Review Stage

Run a deep, multi-perspective code review on the current branch without entering a fix loop. This stage only reports findings — it does not modify code.

## Procedure

1. **Determine the base branch.** Auto-detect whether the remote default branch is `origin/main` or `origin/master` by checking `git remote show origin` or falling back to the repository's HEAD reference. If the user provided a specific base branch as an argument, use that instead.

2. **Load configuration.** Read `review.confidence_threshold` from the merged plugin config (default: `0.8`, scale 0.0–1.0). Also read `review.deep_review_mode` (default: `"auto"`) to determine review intensity.

3. **Compute the diff.** Generate the diff between the base branch and the current HEAD. Collect the list of changed files, added lines, and removed lines. This diff is the shared input for all review agents.

4. **Determine which agents to spawn.** Always spawn code quality. Apply these conditions for the others:

   - **Security reviewer**: spawn only if the diff touches security-relevant files — auth/session/token logic, API endpoint handlers, user input processing, crypto/hashing, network/HTTP clients, environment variables, or config files.
   - **Test coverage reviewer**: spawn only if the diff contains non-trivial code changes (not just docs, config, or comment updates). Check whether any `.test.`, `_test.`, or `spec.` file changes are present alongside source changes.

   Spawn eligible agents concurrently, each receiving the full diff and changed file list:
   - **Code quality reviewer** — checks for code smells, complexity hotspots, naming inconsistencies, dead code, and adherence to project conventions. Always spawned.
   - **Security reviewer** — scans for vulnerability patterns, hardcoded secrets, injection risks, unsafe deserialization, and permission issues. Conditional (see above).
   - **Test coverage reviewer** — evaluates whether changed code paths have corresponding tests, identifies missing edge-case coverage, and flags untested error handling. Conditional (see above).

5. **Aggregate findings.** Collect results from all three agents. Filter out any findings below the configured `confidence_threshold`. De-duplicate overlapping findings across agents.

6. **Report results grouped by severity.** Present the final report organized into severity tiers:
   - **Critical** — issues that must be addressed before merge (security vulnerabilities, data loss risks, broken functionality).
   - **Important** — issues that should be addressed but are not blocking (quality concerns, missing tests, style violations).
   Include file paths, line numbers, and a brief explanation for each finding. Do not attempt to fix any issues or loop back to implementation — this stage is report-only.
   If the review identifies significant simplification opportunities, suggest using the code-simplifier agent as a follow-up action.
