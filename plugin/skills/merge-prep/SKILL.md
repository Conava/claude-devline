---
name: merge-prep
description: "Use when the user asks to 'prepare for merge', 'merge prep', 'clean up plan artifacts', 'generate merge commit', 'prepare PR', or when the pipeline reaches stage 7."
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Bash, Grep, Glob
---

# Merge Preparation

Prepare the current feature branch for merge or PR creation.

## Process

1. Read all files in `docs/plans/` to understand the full scope of work done during this feature
2. Load git configuration from merged plugin config:
   - `git.merge_commit_format`
   - `git.merge_commit_template`
   - `git.pr_title_format`
   - `git.pr_title_template`
   - `git.max_pr_title_length`
3. Generate a merge commit message following the configured template that summarizes all work
4. Generate a PR title following the configured template (respect max length)
5. Present both for user approval
6. After approval:
   - Delete all files in `docs/plans/`
   - Commit the cleanup with `chore: remove plan artifacts`
7. Report: "Ready for PR. Suggested title: \<title\>"

## Guidelines

- The merge commit should give a high-level overview, not list every file changed
- The PR title should be concise and follow the team's format
- Plan artifacts are useful during PR review but must not reach the target branch
