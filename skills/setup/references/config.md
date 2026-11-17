# devline configuration

Every devline setting is optional. A skill resolves each key on its own, from the first layer that sets it:

1. **The request.** Whatever the user says in the current request ("build three", "skip the plan gate", "branch it as fix/…").
2. **Repo:** `.claude/devline.md` in the repository root, committed. Project rules: git policy, testing approach, design system, `design_mode`.
3. **User:** `${CLAUDE_CONFIG_DIR:-~/.claude}/devline/config.md`. Personal preferences across repos: models, voice, what AI may and may not do.
4. **Plugin default:** the owner skill's `## Defaults` section.

Layers merge key by key: a repo file that sets only `branch_format` still takes every other key from the user file or the defaults. Missing files are fine; read them fresh each time, nothing is cached.

## Format

```markdown
---
branch_format: "{kind}/{title}"
protected_branches: [main, release]
test_depth: focused
---

Squash-merge every PR. Open a PR for every change, never push to main.
```

- Frontmatter: flat `key: value` lines, one key per line, no nesting. Lists use `[a, b]` or `- item` lines; a pipe-separated string (`"main|release"`) means the same. Lines starting with `#` are comments. Hooks may parse this, so keep it that flat.
- Below the frontmatter, optional free prose for rules no key can say. A skill that owns the topic follows it (the git skill follows git policy written here). When the repo and user prose disagree, the repo wins.
- Unknown keys are ignored.

## Legacy files

Before 0.5, settings lived in `devline.local.md`. If a layer's file is missing but its legacy file exists, read the legacy file as that layer:

| Layer | File | Legacy file |
|---|---|---|
| Repo | `.claude/devline.md` | `.claude/devline.local.md` |
| User | `${CLAUDE_CONFIG_DIR:-~/.claude}/devline/config.md` | `${CLAUDE_CONFIG_DIR:-~/.claude}/devline.local.md` |

The first time in a session you read a legacy file, tell the user once: "Read settings from `<legacy>`; move them to `<new>` (`/devline:setup` offers to do it)." The new file wins when both exist.

## Keys

"Layer" is where a key usually belongs; any key works in either file.

| Key | Default | Owner | Layer |
|---|---|---|---|
| `auto_approve_brainstorm` | `false` | devline | user |
| `auto_approve_plan` | `false` | devline | user |
| `fast_lane` | `auto` (`auto`, `always`, `off`) | devline | user |
| `stage_menu` | `ask` (`ask`, `auto`) | devline | user |
| `protected_branches` | `[main, master, develop, release, production, staging]` | git | repo |
| `branch_format` | `"{kind}/{title}"` | git | repo |
| `branch_kinds` | `[feat, fix, refactor, docs, chore, test, ci]` | git | repo |
| `test_depth` | `auto` (`auto`, `deep`, `focused`) | kb-tdd-workflow | repo |
| `test_framework` | auto-detect | kb-tdd-workflow | repo |
| `doc_format` | auto-detect | agents/references/documentation.md | repo |
| `cloud_provider` | auto-detect | agents/references/cloud-infra.md | repo |
| `dep_branch_strategy` | `main` (`main`, `branch`) | kb-dependency-management | repo |
| `dep_auto_commit` | `true` | kb-dependency-management | repo |
| `dep_auto_push` | `true` | kb-dependency-management | repo |
| `dep_verify_build` | `true` | kb-dependency-management | repo |
| `dep_verify_tests` | `true` | kb-dependency-management | repo |
| `cve_verify_build` | value of `dep_verify_build` | deps | repo |
| `cve_verify_tests` | value of `dep_verify_tests` | deps | repo |
| `design_model` | `opus` | design | user |
| `sketch_model` | `sonnet` | design | user |
| `mockup_model` | `sonnet` | design | user |
| `design_sketches` | `10` | design | user |
| `design_pick` | `ask` (`ask`, `auto`) | design | user |
| `design_mode` | `auto` (`auto`, `m3e-strict`, `default`) | design | repo |

Owner is the skill whose `## Defaults` section defines the key (`skills/<owner>/SKILL.md`), or the file that reads it. What each value does is described there.
