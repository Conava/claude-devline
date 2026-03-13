---
name: dl-dependency-migration
description: Domain logic for complex dependency migrations — injected into the dependency-migrator agent. Provides methodology for researching migration guides, using ecosystem migration tools, refactoring code for breaking API changes, handling package renames, and verifying correctness. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Dependency Migration

Methodology for executing complex dependency migrations that involve breaking changes, API differences, package renames, behavioral changes, and code refactoring. This is not a version bump — it is a deliberate, researched transition from one major version or library to another.

## Migration Philosophy

A migration is only done when verification passes. Unlike simple patches where build/test verification can be disabled, migrations always require:

1. The code compiles successfully
2. The full test suite passes
3. If no test suite exists, manual smoke-testing instructions are provided to the user

This is non-negotiable. Migrations touch application logic, not just manifest files. Shipping a half-migrated codebase is worse than not migrating at all.

## Phase 1: Research the Migration Path

Before touching any code, build a complete picture of what the migration involves. This research phase is critical — skipping it leads to incomplete migrations and subtle runtime bugs.

### Find the official migration guide

Use **WebSearch** and **WebFetch** to find:

1. **Official migration guide** from the library/framework maintainers (this is the primary source of truth)
2. **Changelog / release notes** for the target version — especially breaking changes
3. **Community migration guides** (blog posts, GitHub discussions) for real-world gotchas
4. **GitHub issues** tagged with the migration — reveals common pitfalls

Good search queries:
- `"package-name" migration guide v1 to v2`
- `"package-name" breaking changes version X`
- `"package-name" upgrade guide`
- `site:github.com "package-name" migration`

When you find a migration guide, **WebFetch** the full page and extract the actionable steps. Don't just skim search results — read the actual guide. Pay attention to:

- **Removed APIs** — what was deleted and what replaces it
- **Renamed APIs** — methods/classes that changed names
- **Changed behavior** — same API but different semantics (these are the dangerous ones)
- **New required configuration** — things that were optional and are now mandatory
- **Dependency changes** — packages that were split, merged, or renamed
- **Minimum runtime requirements** — e.g., requires Java 17+, Node 18+, Python 3.9+

### Check for migration tooling

Many ecosystems have automated migration tools. Check if one exists before doing manual work:

| Ecosystem | Tool | What it does | How to run |
|---|---|---|---|
| Java/Kotlin | **OpenRewrite** | AST-based automated refactoring with recipes for framework migrations | `mvn org.openrewrite.maven:rewrite-maven-plugin:run -Drewrite.activeRecipes=<recipe>` |
| Java (AWS SDK) | **AWS SDK Migration Tool** | Automated V1→V2 migration using OpenRewrite recipes | `mvn org.openrewrite.maven:rewrite-maven-plugin:run -Drewrite.activeRecipes=software.amazon.awssdk.v2migration.AwsSdkJavaV1ToV2` |
| Java (Spring) | **OpenRewrite Spring recipes** | Spring Boot 2→3, Spring Framework 5→6, Spring Security migrations | `mvn org.openrewrite.maven:rewrite-maven-plugin:run -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0` |
| PHP | **Rector** | Automated PHP version upgrades and framework migrations | `vendor/bin/rector process src --set php80` or custom rules |
| JavaScript/TS | **jscodeshift** | AST-based codemods for JS/TS transformations | `npx jscodeshift -t <transform> <path>` |
| JavaScript/TS | **Framework codemods** | Next.js, React, Angular, etc. ship their own codemods | e.g., `npx @next/codemod@latest <transform> <path>` |
| Python | **pyupgrade** | Modernize Python syntax to newer versions | `pyupgrade --py3-plus *.py` |
| Python | **django-upgrade** | Automated Django version upgrades | `django-upgrade --target-version 4.2 **/*.py` |
| Go | **go fix** | Applies targeted fixes for Go API changes | `go fix ./...` |
| Rust | **cargo fix** | Applies compiler-suggested fixes for edition migrations | `cargo fix --edition` |
| Ruby | **Rubocop** | With migration cops for Rails upgrades | `rubocop -a --only Rails/` |
| .NET | **dotnet-migration-tool** | .NET framework to .NET Core/5+ migration | `dotnet try-convert` |

When a migration tool exists:
1. Run it first — it handles the mechanical, repetitive changes
2. Review what it changed
3. Handle the remaining manual migration steps it couldn't automate
4. Verify everything compiles and tests pass after the tool run, before doing manual work

When no tool exists, or after the tool has done what it can, proceed with manual migration.

### Build a migration checklist

Before starting code changes, compile a checklist from your research:

```
## Migration: [package] v[old] → v[new]

### Prerequisites
- [ ] Runtime version requirement met (e.g., Java 17+)
- [ ] No conflicting dependency version locks

### Automated steps
- [ ] Run [migration tool] if available
- [ ] Update version in dependency manifest

### Manual code changes
- [ ] Replace removed API X with new API Y
- [ ] Rename import from old.package to new.package
- [ ] Update configuration format from X to Y
- [ ] Handle behavioral change: [description]

### Verification
- [ ] Build passes
- [ ] All tests pass
- [ ] [Specific smoke test for migrated functionality]
```

Present this checklist to the user (via the launcher skill) before starting work.

## Phase 2: Execute the Migration

### Order of operations

1. **Update the dependency version** in the manifest file (follow dl-dependency-management for ecosystem-specific commands)
2. **Run migration tool** if one exists — this handles bulk mechanical changes
3. **Fix compilation errors** systematically:
   - Start with import/package changes (these cascade into the most errors)
   - Then fix API signature changes (renamed methods, changed parameters)
   - Then fix type changes (generics, return types)
   - Then fix configuration changes
4. **Fix behavioral changes** — these don't cause compilation errors but change runtime behavior. The migration guide research is essential here.
5. **Update tests** if test APIs changed (e.g., testing utilities that moved packages)
6. **Run the full test suite** — this catches behavioral regressions

### Handling package renames

When a library splits into multiple packages or changes its artifact name:

1. Identify all old package references: `grep -r "old.package.name" --include="*.java"` (or equivalent)
2. Update imports systematically — use find-and-replace when the mapping is 1:1
3. Update dependency manifest — remove old artifact, add new one(s)
4. If the library split into multiple packages, add only the ones actually used (check imports)

### Handling removed APIs with no direct replacement

Sometimes a feature is removed without a drop-in replacement. In these cases:

1. Document what was removed and why (from the migration guide)
2. Identify all usages in the codebase
3. Propose an alternative implementation to the user
4. If the alternative is straightforward, implement it
5. If it requires significant design decisions, flag it and ask

### Handling behavioral changes

These are the most dangerous migration issues because the code compiles fine but behaves differently:

1. List all behavioral changes from the migration guide
2. Search the codebase for usage of affected APIs
3. For each usage, determine if the behavioral change impacts it
4. Add or update tests to assert the expected behavior under the new version
5. Fix any code that relied on the old behavior

## Phase 3: Verification

Verification is mandatory and comprehensive:

1. **Build** — the project must compile cleanly with no warnings related to the migration
2. **Test suite** — all existing tests must pass. If a test fails:
   - Determine if the test is testing old behavior that legitimately changed → update the test
   - Or if it reveals a real regression → fix the code
3. **Search for remnants** — grep for old package names, old API patterns, deprecated markers that the migration should have resolved
4. **No partial migrations** — if some usages couldn't be migrated, document them clearly rather than leaving a mix of old and new patterns

If verification fails and the issues are beyond quick fixes, do not commit. Report what succeeded, what failed, and what needs human attention.

## Git Workflow

Read settings from `.claude/devline.local.md`:

| Setting | Default | Description |
|---|---|---|
| `migrate_branch_strategy` | `"branch"` | `"branch"` = create branch (default for migrations — safer). `"main"` = commit to default branch. |
| `migrate_auto_push` | `true` | Push after successful verification. |
| `migrate_auto_commit` | `true` | Commit after successful verification. |

Note: unlike simple patches, the default branch strategy for migrations is `"branch"` because migrations are larger and benefit from PR review.

Branch naming: `chore/migrate-[package]-v[old]-to-v[new]`

Commit message format: `chore(deps): migrate [package] from v[old] to v[new]`

Build and test verification cannot be disabled for migrations — these settings are intentionally absent.

## Error Handling

- **Migration tool fails**: Report the error, fall back to manual migration
- **Compilation fails after migration**: Investigate systematically — start with the most basic errors (imports) and work up
- **Tests fail**: Distinguish between tests that need updating (testing old behavior) vs genuine regressions
- **Partial migration**: If some code can't be migrated automatically, document what's left and why
- **Runtime requirement not met**: Report that the target version requires a newer runtime and ask the user how to proceed
