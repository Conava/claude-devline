---
name: kb-blast-radius
description: Grep-based reverse dependency analysis plus reach classification — injected into the planner and reviewer agents and read by the devline orchestrator before Stage 1. Computes which files are affected by changes to a set of seed files and which kinds of risk (reach) a change has, which decides the stages a run gets. Not invoked directly.
user-invocable: false
disable-model-invocation: false
---

# Blast Radius Analysis

Lightweight, zero-dependency reverse dependency analysis using grep-based import tracing. Answers: "if I change file X, what else is affected?"

## When to Use

- **Planner:** Before task decomposition — identify coupled files so tasks have correct boundaries and file ownership.
- **Reviewer:** After implementation — verify the implementer considered all dependents of changed files.
- **Reviewer (scope: branch):** During the cross-task integration sweep — structurally validate that all dependents were covered across the full changeset.
- **Orchestrator:** before Stage 1, to compose the run (see devline references/stages.md)

## How It Works

1. Collects all source files in the repo (excluding node_modules, vendor, dist, build, target, .git)
2. Greps each file for import/require/use statements
3. Resolves relative imports to file paths
4. Builds a **reverse dependency map**: for each file, which files import it
5. BFS-expands from seed files through the reverse map (depth-limited)
6. Matches seed files and dependents to test files by naming convention

Supports: TypeScript, JavaScript, Python, Go, Rust, Java, Kotlin, Ruby, PHP, C/C++, Vue, Svelte.

## Reach

Reach is what a change can affect beyond the lines it touches. Each category pulls stages into the run (mapping in devline `references/stages.md`). A one-line change can have reach; a large change can have none.

### Before code exists

1. Guess seed files from the request: `git grep -l -i '<term>'` for the nouns it names (feature, endpoint, flag, table, component).
2. Run `--target` on them (`--depth 1` is enough here).
3. Check the request text, the seeds and their dependents against the signals below. Every category with a match applies; name the matching signal as the reason.

After implementation, the reviewer can repeat step 3 on `--changed` output.

### Categories

| Category | Signals in the request | Signals in seeds and dependents | Related reference |
|---|---|---|---|
| Security surface | auth, login, token, permission, password, secret, upload, input validation, shell out, URL fetch | paths or imports with `auth`, `session`, `crypto`, `acl`; request handlers that read input; `exec`/`subprocess`/`spawn`; file path handling; dependency manifest changes | kb-engineering `security.md` |
| Resource use | slow, memory, CPU, large files, batch, cache, startup, polling | loops over I/O, queries in loops, caches, workers, schedulers, long-running processes, new dependencies | kb-engineering `performance.md` |
| Public contract | API, endpoint, CLI flag, config key, file format, rename, deprecate | exported symbols with many dependents, route definitions, argument parsers, config loaders, serializers, OpenAPI/proto/schema files | kb-engineering `backend.md` (and the stack checklist) |
| Persisted data | schema, migration, column, table, stored format, backup | `migrations/`, ORM models, SQL files, on-disk formats, serialization of saved state | kb-engineering `reliability.md` |
| UI | page, screen, component, layout, theme, style, accessibility | component and style files, templates, design tokens, assets | kb-engineering `web.md` or `desktop.md`; the design skill's references; `kb-m3e` for Material 3 |
| Concurrency / shared state | parallel, async, race, lock, queue, retry, cache invalidation | threads, goroutines, async tasks, locks, global or module state, shared files, message brokers | kb-engineering `reliability.md`, `distributed.md` |
| Build / release / CI | build, deploy, release, CI, package, version, Docker | build and CI config (`.github/workflows/`, `Dockerfile`, `package.json` scripts, `Makefile`), lockfiles, version files | kb-engineering stack checklist `## Verify it` |

No match in any category means no reach: the preset's stages are enough.

## Running the Script

The script is at `${CLAUDE_SKILL_DIR}/scripts/blast-radius.sh`. Invoke it from the project's working directory.

### Pre-implementation (planner)

When you know which files will be modified, pass them as targets:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/blast-radius.sh \
  --target src/auth/token.ts src/auth/session.ts
```

### Post-implementation (reviewer)

Analyze actual changes against a base ref:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/blast-radius.sh \
  --changed main
```

Defaults to `HEAD~1` if no base ref given. Also picks up unstaged and untracked files if git diff is empty.

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--depth N` | 2 | BFS depth limit. 1 = direct importers only. 2 = importers of importers. |
| `--format md\|json` | md | Output format. Use `json` for programmatic consumption. |
| `--no-tests` | (off) | Skip test file association. |

## Interpreting Results

The output categorizes affected files:

- **Seed files** — the files being changed (input)
- **Direct dependents** — files that directly import a seed file. These are most likely to break or need updates.
- **Transitive dependents** — files that import a direct dependent. Lower risk but worth checking for cascading changes.
- **Associated tests** — test files matched by naming convention (`.test.ts`, `.spec.ts`, `_test.go`, `test_*.py`, etc.)

## Limitations

- **File-level, not function-level.** If file A imports one function from file B, the whole file shows as a dependent. This is a conservative over-approximation — better to flag too many files than too few.
- **Static imports only.** Dynamic imports (`import()` with variables), reflection, and metaprogramming are not captured.
- **No re-export tracing.** If file A re-exports from file B, dependents of A won't appear as dependents of B.
- **C# not supported.** Namespace-based imports don't map to file paths without project analysis.
- **Go is module-aware** but only works if `go.mod` exists at the root.

These gaps mean the script covers ~80-90% of real dependency edges. When the output says "no dependents found," it may be a leaf node or may use a pattern the script doesn't capture — agents should use judgment.

## For Planners

Use blast radius to inform task design:

1. Run `--target` on the files you intend to modify
2. If two seed files share many dependents, they likely belong in the same task
3. If a seed file has many direct dependents, consider whether dependents need API updates (breaking change) or are unaffected (internal refactor)
4. Include high-impact dependents in the task's "Files owned" list
5. Flag transitive dependents in the task's review checklist

## For Reviewers

Use blast radius to verify implementation completeness:

1. Run `--changed` against the base branch
2. Check: were all direct dependents either updated or confirmed unaffected?
3. If a direct dependent wasn't touched and isn't in the task's scope, flag it — the implementer may have missed a required update
4. Verify associated test files were run or updated

## For Reviewer (scope: branch)

Use blast radius for the cross-task integration sweep:

1. Run `--changed` against the base branch to see the full changeset's impact
2. Cross-reference with the plan's integration contracts
3. Any direct dependent that appears in the blast radius but wasn't touched by any task is a potential integration gap
