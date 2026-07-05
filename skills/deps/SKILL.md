---
name: deps
description: "Update dependencies across one or many repositories. Default mode patches CVEs/security advisories: give CVE IDs (or a vulnerable package) and it researches affected/fixed versions, then launches dependency agents to update, verify, and commit. With --migrate it runs major-version migrations: give a package + target version (or an 'X to Y' library swap, or nothing for an EOL audit) and it researches the migration guide and tooling, gets your approval, then launches dependency agents (opus) to run codemods and refactor breaking changes. Use whenever the user mentions CVEs, security vulnerabilities in dependencies, patching/updating packages for security, OR migrating/upgrading a dependency across a major version, moving from one library to another, end-of-life/EOL, deprecations, or breaking-change upgrades."
argument-hint: "CVE-2024-XXXXX ... [--repos r1 r2]   |   --migrate <package> [from vX] to <vY> [--repos r1 r2]"
user-invocable: true
disable-model-invocation: false
---

# Deps — Dependency Patching & Migration

Launcher skill for dependency work across one or many repositories. It handles research and orchestration, then delegates the actual work to **dependency** agents. Two modes:

- **patch** (default) — targeted version bumps for CVEs / security advisories.
- **migrate** (`--migrate`) — major-version migrations with breaking changes, codemods, and code refactoring. Launches the dependency agent with **model opus** and its **migration block enabled**.

## Step 1: Parse Input & Mode

`--migrate` present → **migrate mode**; otherwise **patch mode**.

- **Patch:** CVE IDs matching `CVE-\d{4}-\d{4,}` (case-insensitive), or a named vulnerable package + advisory reference.
  ```
  CVE-2024-38816 CVE-2024-22243
  CVE-2024-38816 --repos my-api billing-service
  ```
- **Migrate:** package/library name (source, plus target if it's a library swap), current version (or "detect from repo"), target version. Input is flexible: `spring-boot to 3.2`, `aws-sdk-java from v1 to v2`, `moment to date-fns`, `python 3.8 to 3.12`, `angular 14 to 17`. `--migrate` with **no package** → EOL/deprecation audit (Step 3).
- **`--repos r1 r2`** (both modes): filter to those repos; otherwise auto-detect in Step 2.

## Step 2: Detect Repositories (both modes)

1. **Single repo:** current directory has `.git/` → work in it directly.
2. **Multi-repo folder:** subdirectories that are git repos → work in all, or only those in `--repos`.

For multi-repo with no `--repos` filter and more than 10 repos, list them and confirm with the user first.

## Step 3: Research

### Patch mode
For each CVE, use **WebSearch** (in parallel) to gather: package name + ecosystem; affected version range(s); fixed version(s); severity (CVSS); whether the fix crosses a major-version boundary. Good sources: NVD (`nvd.nist.gov`), GitHub Advisory Database. Present a summary table before proceeding:

```
| CVE            | Package       | Ecosystem | Affected  | Fix    | Severity | Major? |
|----------------|---------------|-----------|-----------|--------|----------|--------|
| CVE-2024-38816 | spring-webmvc | Maven     | < 6.1.13  | 6.1.13 | High     | No     |
```

If any CVE requires a **major version bump**, flag it and ask how to proceed — do not dispatch major-bump CVEs without approval.

### Migrate mode
The most important step — don't rush it. Use **WebSearch** + **WebFetch** to find: the official migration guide (primary source of truth); the changelog / breaking-changes list; migration **tooling** (codemod, OpenRewrite recipe, Rector rule, official CLI); community gotchas. Read the guide fully with WebFetch and extract actionable steps and a migration checklist. Check ecosystem tooling: Java/Kotlin → OpenRewrite; PHP → Rector; JS/TS → codemods/jscodeshift; Python → pyupgrade/django-upgrade; Go → `go fix`; Rust → `cargo fix`; Ruby → RuboCop; .NET → try-convert. (No package specified → scan manifests for EOL/deprecated/approaching-EOL deps, verify via WebSearch, and let the user pick.)

Present a migration plan and **wait for approval** before launching any agents:

```
## Migration: [package] v[old] → v[new]
### Breaking Changes
1. [e.g. javax.* → jakarta.*]
### Migration Tooling
- [tool]: [what it automates] — runs first; manual steps remaining: [...]
### Runtime Requirements
- Requires [e.g. Java 17+] — [met / not met per repo]
### Affected Repositories
| Repository | Current | Affected | Notes |
### Risk Assessment
- Low / Medium / High risk repos
### Verification: build + test always on (mandatory for migrations)
```

## Step 4: Read Settings (patch mode)

Check `.claude/devline.local.md` in each repo. Map CVE settings to the generic ones (prefixed wins): `cve_verify_build` → `dep_verify_build` (default `true`), `cve_verify_tests` → `dep_verify_tests` (default `true`). Git workflow is not configurable. For **migrate mode**, build + test verification is always on and cannot be disabled.

## Step 5: Launch dependency agents

**Git workflow** — follow the canonical **Git Workflow** section of the **kb-dependency-management** skill (default-branch detection, branch strategy, staging, committing, pushing). It is not re-embedded here; specify only these per-mode deltas to each agent:

| | Branch | Commit message | Push |
|-|--------|----------------|------|
| Patch | `fix/cve-[first-CVE-ID]` (lowercase) | `chore(deps): [comma-separated CVE IDs]` | **No** — launcher delivers |
| Migrate | `chore/migrate-[package]-v[old]-to-v[new]` | `chore(deps): migrate [package] from v[old] to v[new]` | **No** — launcher delivers |

Launch one **dependency** agent per repository (parallel/background for multi-repo; wait for all to finish). Each agent receives its repository path, that repo's settings, the git-workflow deltas above, and:

- **Patch:** the CVE research table as update targets. Migration block **off**.
- **Migrate:** model **opus**, migration block **on**, plus the migration guide URL(s)/summary, the migration tool + command (or "none — manual"), and the migration checklist from research.

## Step 6: Present Summary and Delivery Options (both modes)

Compile a summary table (columns adapt to mode):

```
Patch:   | Repository | CVEs Patched | CVEs Skipped | Branch | Issues |
Migrate: | Repository | Status | Tool Used | Manual Changes | Tests | Branch |
```

Report any repos with issues (test failures, verification/compilation errors — for migrations include what was done vs what remains and a recommendation) before presenting options. Then, for each repository with successful changes, ask how to deliver:

```
How would you like to deliver these changes?

1. **Create a PR** — push the branch and open a pull request (requires remote access)
2. **Squash merge locally** — squash-merge the branch into the default branch locally (no remote interaction)
3. **Exit** — leave the branch as-is and print the changes so you can handle it manually
```

**Option 1 — PR:** `git push -u origin [branch]`; `gh pr create` with title `chore(deps): [patch: CVE IDs | migrate package vX→vY]` and body = the research table / migration summary (breaking changes addressed, tool used, verification results); report the PR URL.

**Option 2 — Squash merge:** checkout default branch; `git merge --squash [branch]`; commit with the same message; `git branch -d [branch]`; report "Squash-merged into [default-branch]. Ready to push when you are."

**Option 3 — Exit:** print branch name, files changed (`git diff --stat [default]..[branch]`), and the commit(s); report "Branch [name] is ready. Push, merge, or cherry-pick manually."

In multi-repo mode, apply the same option to all repos unless the user requests per-repo handling.
