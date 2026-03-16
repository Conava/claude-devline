---
name: kb-dependency-management
description: Domain logic for dependency management — injected into the dependency-patcher agent. Provides ecosystem detection, version update mechanics, build/test verification, and commit/push workflows across all major package managers. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Dependency Management

Shared methodology for updating dependencies across all supported package ecosystems. This skill is injected into the dependency-patcher agent and provides the mechanics of detecting, updating, verifying, and committing dependency changes — regardless of whether the trigger is a CVE, a routine version bump, or part of a larger migration.

## Ecosystem Detection

A repository can use multiple ecosystems (e.g., a monorepo with `package.json` and `pom.xml`). Scan for all of the following and track which are present:

| Marker files | Ecosystem | Lock files |
|---|---|---|
| `package.json` | npm/yarn/pnpm | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` |
| `pom.xml` | Maven | — |
| `build.gradle`, `build.gradle.kts` | Gradle | `gradle.lockfile` |
| `requirements.txt`, `pyproject.toml`, `Pipfile`, `setup.py`, `setup.cfg` | Python (pip/poetry/pipenv) | `requirements.txt`, `poetry.lock`, `Pipfile.lock` |
| `go.mod` | Go | `go.sum` |
| `Cargo.toml` | Rust | `Cargo.lock` |
| `composer.json` | PHP (Composer) | `composer.lock` |
| `Gemfile` | Ruby (Bundler) | `Gemfile.lock` |
| `*.csproj`, `*.fsproj`, `packages.config` | .NET (NuGet) | `packages.lock.json` |
| `build.sbt` | Scala (sbt) | — |
| `mix.exs` | Elixir (Mix) | `mix.lock` |
| `pubspec.yaml` | Dart/Flutter (pub) | `pubspec.lock` |
| `Package.swift` | Swift (SPM) | `Package.resolved` |

Detect the package manager variant too — if `yarn.lock` exists, use `yarn`; if `pnpm-lock.yaml`, use `pnpm`; otherwise default to `npm`.

## Checking if Affected

For each dependency to update:

1. Search the dependency manifest(s) for the package name
2. Extract the currently declared version (handle version ranges, properties, variables, and catalogs)
3. Compare against the affected/outdated version range
4. If the dependency is not present or the version is already at/above the target, skip it

For Maven/Gradle, check for version properties — the version might be declared as `<spring.version>6.1.2</spring.version>` and referenced elsewhere. Update the property, not each individual reference.

For Gradle version catalogs (`gradle/libs.versions.toml`), update the version in the catalog file.

## Updating Dependencies

Use native tooling when possible — it handles lock file updates automatically:

| Ecosystem | Update command | Notes |
|---|---|---|
| npm | `npm install package@version` | Updates package-lock.json |
| yarn | `yarn add package@version` | Updates yarn.lock |
| pnpm | `pnpm add package@version` | Updates pnpm-lock.yaml |
| Maven | Edit `pom.xml` directly | Update version tags or properties |
| Gradle | Edit `build.gradle(.kts)` or version catalog | Run `./gradlew dependencies --write-locks` if lockfile exists |
| pip | Edit `requirements.txt` or `pyproject.toml` | Run `pip install -r requirements.txt` or `pip install -e .` |
| poetry | `poetry add package@version` | Updates poetry.lock |
| Go | `go get package@version && go mod tidy` | Updates go.sum |
| Cargo | Edit `Cargo.toml`, then `cargo update -p package` | Updates Cargo.lock |
| Composer | `composer require package:version` | Updates composer.lock |
| Bundler | Edit `Gemfile`, then `bundle install` | Updates Gemfile.lock |
| NuGet | `dotnet add package Package --version X.Y.Z` | Updates lock if enabled |
| sbt | Edit `build.sbt` | Run `sbt update` |
| Mix | Edit `mix.exs`, then `mix deps.get` | Updates mix.lock |
| pub | Edit `pubspec.yaml`, then `dart pub get` / `flutter pub get` | Updates pubspec.lock |
| SPM | Edit `Package.swift`, then `swift package resolve` | Updates Package.resolved |

When a single package appears in multiple update requests, use the highest target version that satisfies all of them.

## Verification

Verification has two stages, both controlled by settings (see Settings section below):

### Build verification (`dep_verify_build`)

Run the ecosystem's build command to confirm the update doesn't break compilation:

| Ecosystem | Build command |
|---|---|
| npm/yarn/pnpm | `npm run build` (or `yarn build` / `pnpm build`) |
| Maven | `mvn compile -q` |
| Gradle | `./gradlew build -x test` |
| Python | `python -m py_compile` on changed files, or `pip install -e .` |
| Go | `go build ./...` |
| Cargo | `cargo build` |
| Composer | `composer install --dry-run` |
| Bundler | `bundle exec ruby -e "puts 'ok'"` |
| NuGet | `dotnet build` |

If no obvious build command exists, skip this step rather than guessing.

### Test verification (`dep_verify_tests`)

Run the test suite if one exists:

| Ecosystem | Test command |
|---|---|
| npm/yarn/pnpm | `npm test` (or `yarn test` / `pnpm test`) |
| Maven | `mvn test -q` |
| Gradle | `./gradlew test` |
| Python | `pytest` or `python -m unittest discover` |
| Go | `go test ./...` |
| Cargo | `cargo test` |
| Composer | `./vendor/bin/phpunit` |
| Bundler | `bundle exec rspec` or `bundle exec rake test` |
| NuGet | `dotnet test` |

Check for custom test commands in `package.json` scripts, `Makefile`, or CI config before falling back to defaults.

### Handling failures

- If the failure is a straightforward compatibility issue (import path changed, method renamed, type signature updated), fix it as part of the update
- If the failure is complex or touches significant application logic, do not commit — report the issue with details (error output, affected files) and let the user decide

## Settings

Read `.claude/devline.local.md` YAML frontmatter in each repo for these settings. All are optional — defaults shown:

| Setting | Default | Description |
|---------|---------|-------------|
| `dep_branch_strategy` | `"main"` | `"main"` = commit to default branch. `"branch"` = create a branch per update batch. |
| `dep_auto_push` | `true` | Push automatically after successful verification. |
| `dep_auto_commit` | `true` | Commit automatically after successful verification. |
| `dep_verify_build` | `true` | Run build verification before committing. |
| `dep_verify_tests` | `true` | Run test suite before committing. |

The launcher skill (cve-patcher, migrate, etc.) may map its own setting names to these — e.g., `cve_branch_strategy` maps to `dep_branch_strategy`. Check for both the prefixed and generic versions, with the prefixed version taking priority.

When `dep_auto_commit` is `false`, `dep_auto_push` is implicitly `false` too.

## Git Workflow

### Default branch detection

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

Fall back to `main`, then `master` if that command fails.

### Branch strategy

- **`"main"`** (default): ensure you're on the default branch, pull latest before starting
- **`"branch"`**: create a descriptive branch from the default branch. Branch naming depends on the launcher skill:
  - CVE: `fix/cve-XXXX-XXXXX` (first CVE ID)
  - Migration: `chore/migrate-package-vX-to-vY`
  - General update: `chore/deps-update-YYYY-MM-DD`

### Staging and committing

- Stage all changed files: dependency manifests, lock files, and any minor code fixes
- If `dep_auto_commit` is false: stop and report what was staged
- Commit message format depends on the launcher skill (passed to the agent via prompt)
- Always include `Co-Authored-By: Claude <noreply@anthropic.com>` in the commit
- If `dep_auto_push` is false: stop and report what was committed

### Pushing

- Never force-push
- If push fails because the branch is behind remote, pull with rebase and retry once
- If it fails again, report the error to the user

## Major Version Bumps

Never auto-update across major versions. When a required update crosses a major version boundary:

1. Flag it clearly in the report
2. Explain what changed (breaking changes if known)
3. Ask the user how to proceed
4. Only update if the user explicitly approves

This rule applies regardless of the trigger (CVE, migration, or routine update). Security severity does not override it — a major bump can introduce subtle breakage that's worse than the vulnerability in the short term.

## Error Handling

- If a dependency is not found in the manifest, skip it silently (it's just not used in this repo)
- If native tooling fails, fall back to direct file editing + manual lock file regeneration
- If verification fails, do not commit — report with full error output
- If git operations fail (push, pull), report the error and suggest the user check credentials/permissions
