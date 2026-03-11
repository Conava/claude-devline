---
name: docs-update
description: "Use when the user asks to 'update docs', 'update documentation', 'sync readme', 'update CLAUDE.md', or 'refresh docs' to reflect recent code changes."
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, Bash
---

# Standalone Docs Update Stage

Run the documentation update stage independently to bring project documentation in sync with recent code changes. Includes an automatic review pass with a retry loop.

## Procedure

1. **Check branch and base ref.**

   Run `git rev-parse --abbrev-ref HEAD` to get the current branch.

   - **Feature branch, no argument**: diff against `origin/main` (or `origin/master`). This is the ideal case — the diff covers exactly the work on this branch.
   - **Feature branch, argument provided**: use the provided base branch or commit hash instead.
   - **Main/master branch, argument provided**: use the provided commit hash or range as the base. Proceed.
   - **Main/master branch, no argument**: warn the user before proceeding:

     > ⚠️ **You are on the default branch with no base ref specified.**
     >
     > The docs-updater works by diffing your current HEAD against a base. On `main` without a base, there is no meaningful diff — it will see zero changes and update nothing, or diff against an arbitrary point.
     >
     > **Options:**
     > - Run from a feature branch (recommended — the diff covers exactly your changes)
     > - Provide a specific commit hash or range: `/docs-update <commit-hash>` or `/docs-update HEAD~5..HEAD`
     > - Provide a tag: `/docs-update v1.2.0`
     >
     > Do you want to proceed anyway with a manually specified range, or cancel?

     Wait for the user's response. If they provide a range, use it. If they cancel, stop.

   Once the base ref is established, compute the diff: `git diff <base>...HEAD`.

2. **Load configuration.** Read `plugin/config/workflow.yaml` to retrieve documentation settings such as `docs.tracked_files` (list of doc files to consider, e.g., `README.md`, `CLAUDE.md`, `docs/**/*.md`), `docs.max_review_attempts` (default: 2), and `docs.style_guide` if one is configured.

3. **Spawn the docs-updater agent.** Launch the docs-updater agent in incremental update mode (Mode 1) with the base branch diff. The agent reads the `project_structure` config to locate all documentation files (README, CLAUDE.md, architecture doc, API spec, changelog, ADRs). It analyzes code changes, identifies documentation that is now stale or incomplete, and writes updated content. For CLAUDE.md files, the agent verifies that commands still work, referenced paths still exist, and descriptions match actual code.

4. **Spawn the docs-reviewer agent.** After the updater completes, launch the docs-reviewer agent. The reviewer checks that:
   - All significant code changes are reflected in documentation.
   - Updated docs are accurate and consistent with the actual code.
   - No formatting or structural issues were introduced.
   - Links and references remain valid.

5. **Handle reviewer feedback (retry loop).** If the docs-reviewer reports failures or issues:
   - Re-spawn the docs-updater agent with the reviewer's feedback appended as correction instructions.
   - Run the docs-reviewer again on the new output.
   - Repeat up to `docs.max_review_attempts` times (default: 2). If the reviewer still fails after all attempts, report the remaining issues and proceed.

6. **Report results.** Print a summary listing each documentation file that was updated, a brief description of what changed in each, and whether the review passed. If any reviewer issues remain unresolved, include them as warnings.
