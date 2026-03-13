---
name: deep-review
description: Final comprehensive pull request review — the last gate before merge. Checks security, credentials, code quality, tech debt, conventions, and plan compliance.
argument-hint: "[branch name or description]"
user-invocable: true
disable-model-invocation: true
---

# PR — Final Merge-Readiness Review

Launch the **deep-review** agent for a comprehensive final review.

## Determine Scope
1. If a branch is specified, compare it against the base branch (main/master)
2. If no branch specified, review all changes on the current branch vs. base
3. Use `git diff main...HEAD` (or equivalent) to identify all changes

## Review Checklist
The deep-review will perform:
1. **Security Audit** — Vulnerability scan, OWASP Top 10 checks
2. **Credential Scan** — Hardcoded keys, tokens, passwords, private keys
3. **Code Quality** — Technical debt, duplication, error handling, resource leaks
4. **Convention Adherence** — Naming, structure, imports, test organization
5. **Plan Compliance** — Every acceptance criterion met (if plan exists)
6. **Test Verification** — Full suite passes, meaningful coverage
7. **Documentation Check** — Docs updated for new features

## Strictness
Check `.claude/devline.local.md` for review strictness settings:
- Default: block on all issues
- Configurable: `pr_review_strictness`, `pr_review_block_categories`, `pr_review_warn_categories`

## Verdict
- **APPROVED** — Code is merge-ready
- **CHANGES REQUIRED** — Issues must be fixed first (with specific fix suggestions)
