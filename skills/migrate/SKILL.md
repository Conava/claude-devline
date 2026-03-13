---
name: migrate
description: "Migrate dependencies to new major versions — handles breaking changes, API refactoring, package renames, and behavioral differences. Researches migration guides and tooling, then launches dependency-migrator agents. Use this skill when the user wants to upgrade a dependency across a major version, migrate from one library to another (e.g., Moment.js to date-fns), prepare for EOL by upgrading early, or handle any dependency transition that involves more than just changing a version number. Triggers on phrases like 'migrate', 'upgrade to v2', 'move from X to Y', 'end of life', 'EOL', 'deprecated', 'major version upgrade', 'breaking changes'."
argument-hint: "<package> [from vX] to <vY> [--repos repo1 repo2]"
user-invocable: true
disable-model-invocation: false
---

# Migrate

Orchestrates complex dependency migrations across one or many repositories. This is a launcher skill — it handles research, planning, and user approval, then delegates the actual migration to **dependency-migrator** agents (Opus).

Unlike the CVE patcher which does targeted version bumps, migrations involve breaking changes, code refactoring, API replacements, and sometimes entirely different libraries. The migrate skill ensures thorough research happens before any code is touched.

## Step 1: Parse Input

The input is flexible — users describe migrations in many ways:

```
spring-boot to 3.2                         # Upgrade to specific version
aws-sdk-java from v1 to v2                 # Full version transition
moment to date-fns                         # Library replacement
lodash 3.x to 4.x --repos api billing     # Scoped to specific repos
python 3.8 to 3.12                         # Runtime/language upgrade
angular 14 to 17                           # Framework multi-version jump
                                           # No args = scan for EOL/deprecated deps
```

Extract:
- **Package/library name** (source and optionally target if it's a library swap)
- **Current version** (or "detect from repo")
- **Target version**
- **Repos**: If `--repos` is present, filter to those. Otherwise auto-detect.

## Step 2: Detect Repositories

Same pattern as other dependency skills:

1. **Single repo**: Current directory has `.git/` → work in it directly
2. **Multi-repo folder**: Subdirectories with `.git/` → work in all or filtered by `--repos`

For multi-repo with no filter and more than 10 repos, confirm with the user.

## Step 3: Research the Migration

This is the most important step. Do not skip or rush it.

### 3a: Find the migration guide

Use **WebSearch** to find:

1. **Official migration guide** — the primary source of truth
2. **Changelog / breaking changes list** for the target version
3. **Migration tooling** — does a codemod, OpenRewrite recipe, Rector rule, or official CLI tool exist?
4. **Community guides** — blog posts and GitHub discussions for real-world gotchas

Research queries to try:
- `"[package]" migration guide v[old] to v[new]`
- `"[package]" breaking changes v[new]`
- `"[package]" upgrade tool codemod`
- `"[package]" v[new] migration issues site:github.com`

Use **WebFetch** on the most promising results to read the full migration guide. Extract actionable steps.

### 3b: Check for migration tools

Search for ecosystem-specific tooling:

| Ecosystem | Check for |
|---|---|
| Java/Kotlin (Maven/Gradle) | OpenRewrite recipes (`docs.openrewrite.org/recipes`), official migration tools |
| PHP (Composer) | Rector rules (`getrector.com`) |
| JavaScript/TypeScript (npm) | Official codemods (`npx @package/codemod`), jscodeshift transforms |
| Python (pip/poetry) | pyupgrade, django-upgrade, framework-specific tools |
| Go | `go fix`, official migration scripts |
| Rust | `cargo fix --edition`, clippy migration lints |
| Ruby (Bundler) | RuboCop cops, rails app:update |
| .NET (NuGet) | `dotnet try-convert`, .NET Upgrade Assistant |

### 3c: If no package specified — EOL/deprecation audit

When the user invokes without a specific package, scan for dependencies that are EOL, deprecated, or approaching end of support:

1. Scan dependency manifests for all declared packages
2. Check major framework/runtime versions against known support windows
3. Use WebSearch to verify EOL status for anything that looks potentially unsupported
4. Present findings and let the user choose what to migrate

## Step 4: Present Migration Plan

Present a detailed summary to the user and **wait for approval** before launching any agents:

```
## Migration: [package] v[old] → v[new]

### Breaking Changes
1. [Change description — e.g., "javax.* namespace renamed to jakarta.*"]
2. [Change description — e.g., "Spring Security: WebSecurityConfigurerAdapter removed"]
3. [Change description — e.g., "Default serialization changed from X to Y"]

### Migration Tooling
- [Tool name]: [what it automates] — will run first
- Manual steps remaining: [what the tool can't handle]

### Runtime Requirements
- Requires: [e.g., Java 17+, Node 18+] — [met/not met in target repos]

### Affected Repositories
| Repository | Current Version | Affected | Notes |
|---|---|---|---|
| my-api | 2.7.18 | Yes | Heavy usage of removed APIs |
| billing | 2.7.18 | Yes | Minimal usage, mostly auto-migratable |
| auth | 3.1.0 | No | Already on 3.x |

### Risk Assessment
- **Low risk**: [repos where migration is mostly automated]
- **Medium risk**: [repos with moderate manual work]
- **High risk**: [repos with heavy usage of removed/changed APIs]

### Settings
- Branch strategy: [branch/main] (default: branch)
- Auto-commit: [yes/no]
- Auto-push: [yes/no]
- Build verification: always on (mandatory for migrations)
- Test verification: always on (mandatory for migrations)
```

The user must approve before proceeding. If they want to exclude certain repos or defer high-risk ones, adjust accordingly.

## Step 5: Read Settings

Check `.claude/devline.local.md` for migration-specific settings:

| Setting | Default | Description |
|---|---|---|
| `migrate_branch_strategy` | `"branch"` | Default is `"branch"` for migrations (safer for large changes). |
| `migrate_auto_push` | `true` | Push after successful verification. |
| `migrate_auto_commit` | `true` | Commit after successful verification. |

Build and test verification are **always enabled** for migrations — there are no settings to disable them.

If migration-specific settings aren't present, fall back to `dep_*` settings, then to defaults (except `dep_branch_strategy` defaults to `"branch"` for migrations regardless).

## Step 6: Launch Dependency-Migrator Agents

### Single-repo mode

Launch one **dependency-migrator** agent with:

```
Migrate [package] from v[old] to v[new] in this repository.

Repository: [absolute path]

Migration guide: [URL or summary of key breaking changes]

Migration tool: [tool name and command, or "none — manual migration"]

Migration checklist:
[The compiled checklist from research]

Commit message: chore(deps): migrate [package] from v[old] to v[new]

Settings:
- Branch strategy: [branch/main]
- Branch name: chore/migrate-[package]-v[old]-to-v[new]
- Auto-commit: [true/false]
- Auto-push: [true/false]
```

### Multi-repo mode

Launch one **dependency-migrator** agent per repository in parallel (background). Each receives:

- The full migration research (guide, breaking changes, tool info)
- Its specific repository path and current version
- The migration checklist
- That repo's settings

Wait for all agents to complete.

## Step 7: Present Summary

```
| Repository       | Status    | Tool Used      | Manual Changes | Tests  | Branch                            |
|------------------|-----------|----------------|----------------|--------|-----------------------------------|
| my-api           | Migrated  | OpenRewrite    | 12 files       | 98/98  | chore/migrate-spring-boot-2-to-3  |
| billing-service  | Migrated  | OpenRewrite    | 3 files        | 45/45  | chore/migrate-spring-boot-2-to-3  |
| legacy-app       | Failed    | OpenRewrite    | —              | 12/30  | (not pushed)                      |
```

For failed repos, include:
- What went wrong (test failures, compilation errors)
- What was already done vs what remains
- Recommendation (manual fix needed, defer, etc.)

For succeeded repos on branch strategy, remind the user to review and merge the branches.
