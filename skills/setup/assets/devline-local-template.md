# devline.local.md Settings Template

Settings are presented in 4 batches during setup. For each batch, show all settings with defaults and ask if the user wants to change anything. Only non-default values are written to the final file.

---

## Batch 1 — Pipeline Flow

```
auto_approve_brainstorm: false    — Pause for approval after brainstorming
auto_approve_plan: false          — Pause for approval after planning
```

---

## Batch 2 — Branching & Commits

```
branch_format: "{kind}/{title}"  — Branch naming format ({kind}, {title} placeholders)
branch_kinds: "feat|fix|refactor|docs|chore|test|ci"  — Allowed branch kinds (pipe-separated)
protected_branches: "(main|master|develop|release|production|staging)"  — Protected branches (regex group)
merge_style: "squash"            — Merge style: squash, merge, or rebase
direct_edit_extensions: "(md|txt|json|yaml|yml|toml|ini|cfg|conf|lock|gitignore|gitattributes|editorconfig|prettierrc|eslintrc|stylelintrc)"  — Extensions editable on protected branches
commit_format: "kind(scope): details"  — Human-readable commit format
commit_format_regex: "^(feat|fix|refactor|docs|chore|test|ci|style|perf|build|revert)(\\([a-zA-Z0-9._-]+\\))?: .+"  — Commit validation regex
```

---

## Batch 3 — Framework Detection & Review

```
test_framework: auto-detect       — Override: "vitest", "jest", "pytest", etc.
frontend_framework: auto-detect   — Override: "react", "vue", "svelte", etc.
doc_format: auto-detect           — Override: "markdown", "asciidoc", etc.
cloud_provider: auto-detect       — Override: "aws", "gcp", "azure", etc.
```

---

## Batch 4 — Dependency Management

```
dep_branch_strategy: "main"       — "main" = commit directly, "branch" = branch per update
dep_auto_push: true               — Push after verification
dep_auto_commit: true             — Commit after verification
dep_verify_build: true            — Build check before commit
dep_verify_tests: true            — Test suite before commit

CVE patcher overrides (same defaults as dep_*):
  cve_branch_strategy, cve_auto_push, cve_auto_commit, cve_verify_build, cve_verify_tests

Migration overrides (branch_strategy defaults to "branch"):
  migrate_branch_strategy: "branch", migrate_auto_push: true, migrate_auto_commit: true
  Note: build/test verification always on for migrations
```

---

## Output Format

Only non-default settings are written. If nothing was changed, no file is created.

```markdown
---
# Devline Local Settings — only non-default values.
# Full reference: https://github.com/marlonlom/claude-devline#settings-reference
<non-default settings here>
---
```
