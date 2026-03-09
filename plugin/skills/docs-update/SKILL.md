---
name: docs-update
description: "Use when the user asks to 'update docs', 'update documentation', 'sync readme', 'update CLAUDE.md', or 'refresh docs' to reflect recent code changes."
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, Bash
---

# Standalone Docs Update Stage

Run the documentation update stage independently to bring project documentation in sync with recent code changes. Includes an automatic review pass with a retry loop.

## Procedure

1. **Determine the base branch.** Auto-detect the remote default branch (`origin/main` or `origin/master`). If the user provided a specific base branch or commit range as an argument, use that instead. Compute the diff between the base and current HEAD to identify what changed.

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
