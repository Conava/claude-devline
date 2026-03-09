---
name: pipeline
description: "Use when the user asks to 'build a feature', 'add functionality', 'refactor code', 'create a new module', 'implement changes', 'develop', or any development task that benefits from a structured workflow. Default skill for development work unless the user explicitly asks for a single stage."
argument-hint: "[task description]"
disable-model-invocation: false
user-invocable: true
---

# Pipeline Orchestration

The main chat acts as orchestrator: spawning agents directly, relaying questions to the user, and tracking progress in context. All orchestration logic is defined here — do not delegate to other skills.

---

## Pre-Pipeline Options

Before entering the pipeline, determine the execution path:

- **Skip brainstorm**: If the task already has a clear spec, acceptance criteria, or design doc — or the user says "skip brainstorm" — skip Stage 1 and go directly to Stage 2.
- **Bug mode**: If the task is a specific bug with reproduction steps (not a new feature), skip Stages 1–2. In Stage 3, use the systematic-debugging path (debugger agent) for the failing component instead of the normal implement flow.

---

## Size Gating

A task is trivially small when it affects a single file with an obvious, well-scoped change (e.g., rename a variable, fix a typo, add a single config field). For trivially small tasks, skip Stages 0–2 and enter directly at Stage 3 with a synthetic single-task plan. Apply all subsequent stages normally.

---

## Stage 0: Branch Safety

Run `git rev-parse --abbrev-ref HEAD`.

- **Protected branch** (matches `git.protected_branches` in config): Create a feature branch using `git.feature_branch_prefix` + task slug. Check it out before proceeding.
- **Wrong branch** (not protected, not obviously related to the task): Ask the user whether to continue or create a new branch. Do not proceed until confirmed.
- **Feature branch**: Continue immediately.

---

## Stage 1: Brainstorm (optional)

Skip if: brainstorm is not needed (see Pre-Pipeline Options above).

Read `workflow.human_checkpoints` from config.

**Interactive mode** (`brainstorm` in `human_checkpoints`):
1. Spawn the **brainstorm agent**. Pass the task description and any referenced files.
2. Relay the agent's questions to the user verbatim. Collect answers.
3. Re-spawn the brainstorm agent with the full Q&A history. Repeat until the agent produces a design document.

**Autonomous mode**:
1. Spawn the **brainstorm agent** with `autonomous: true`. It produces a design document in one pass.

Save the design document to `docs/plans/YYYY-MM-DD-<slug>-design.md`. Commit: `git add docs/plans/...-design.md && git commit -m "docs: add design document for <task>"`.

---

## Stage 2: Plan

Skip for bug mode — use the debugger agent in Stage 3 instead.

Read `workflow.human_checkpoints` from config.

**Interactive mode** (`plan` in `human_checkpoints`):
1. Spawn the **planner agent**. Pass the design document path (or task description if no design doc exists).
2. Relay questions and re-spawn with answers until the planner produces a finalized execution graph.

**Autonomous mode**:
1. Spawn the **planner agent** once with `autonomous: true`. It produces the execution graph in one pass.

The execution graph is a JSON structure with:
- `tasks`: array of `{ id, description, touches, depends_on, parallel_group }`
- `order`: topological ordering of task IDs

Save to `docs/plans/YYYY-MM-DD-<slug>-plan.json`. Commit: `git add docs/plans/...-plan.json && git commit -m "docs: add implementation plan for <task>"`.

---

## Stage 3: Implement + Review

Read the execution graph from the plan file. For bug mode, create a single synthetic task from the bug description.

### Task Scheduling

Track completed task IDs and in-progress file paths in context. A task is eligible when:
1. All `depends_on` IDs are in the completed set.
2. Its `touches` files don't overlap with any in-progress task's `touches`.

Spawn eligible tasks in parallel up to `workflow.max_parallel_tasks` (default 4).

### Domain Skill Resolution

Before spawning any implementer, resolve domain skills for the task:
1. Read `${CLAUDE_PLUGIN_ROOT}/config/skill-mappings.yaml`.
2. For each file in `touches`, match its extension against `file_patterns` and directory against `directory_patterns`.
3. Deduplicate. Construct full paths: `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/SKILL.md`.

### Per-Task Execution

For each task:

1. **Create worktree from local HEAD** — no remote fetch, no SSH required:
   ```
   git worktree add .claude/worktrees/agent-<id> -b worktree-agent-<id> HEAD
   ```
   Use a random 8-character hex ID (e.g. `python3 -c "import secrets; print(secrets.token_hex(4))"`). Note the absolute worktree path.

2. **Spawn implementer**: Pass the task object, absolute worktree path, resolved domain skill paths, design document path, and any retry feedback. The implementer works entirely within the worktree — reads, writes, tests, self-reviews, and commits there.

3. **Spawn reviewer**: Run `git diff <feature-branch>...worktree-agent-<id>` to get the diff. Spawn the **reviewer agent**. Pass: diff, implementation summary, task object, design document, and the absolute worktree path. The reviewer reads files and runs tests from the worktree path.

4. **On PASS**: Merge and clean up:
   ```
   git merge --no-ff worktree-agent-<id> -m "<type>(<task-id>): <description>"
   git worktree remove .claude/worktrees/agent-<id> --force
   git branch -D worktree-agent-<id>
   ```
   Use `fix:` for bugs, `feat:` for features, `refactor:` for refactoring. Add task to completed set.

5. **On FAIL (attempt 1 — normal retry)**: Re-spawn the implementer with reviewer feedback appended to the task context.

6. **On FAIL (attempt 2–3 — systematic debugging)**: Spawn the **debugger agent** instead of the implementer. Pass the task context, reviewer feedback history, and prior attempt evidence. On attempt 3, pass cumulative evidence from attempt 2.

7. **On FAIL (attempt 4)**: Stop all parallel agents. Spawn the **planner agent** in `debug_plan` mode with full failure evidence. Execute a new implement+review cycle on the revised plan. If still failing, pause and escalate to the user.

### Worktree Cleanup Failure

If `git worktree remove` fails due to untracked or modified files: run `git worktree prune` to remove stale references, then `git branch -D worktree-agent-<id>` to remove the branch. Do not use `rm -rf` or `git clean`.

---

## Stage 4: Docs Update

**Mandatory. Do not skip.**

Spawn the **docs-updater agent**. Pass the list of completed tasks, their implementation summaries, the design document, and paths to existing documentation files that reference modified code.

Spawn the **docs-reviewer agent**. Pass the docs-updater output and implementation context.

- **PASS**: Commit documentation changes.
- **FAIL**: Re-spawn docs-updater with reviewer feedback. Retry up to 3 times, then escalate to user.

---

## Stage 5: Deep Review

**Distinct from Stage 3 per-task review.** This audits the entire diff holistically.

Compute the full diff: `git diff <base-branch>...HEAD`.

**Always spawn**: **code-quality reviewer** (Opus).
**Spawn if code changes exist** (not just docs/config): **test-coverage reviewer** (Opus).
**Spawn only if security-relevant** (changes touch auth, API endpoints, user input handling, crypto, network, or env/config files): **security reviewer** (Opus).

For trivially small changes (single file, <30 lines, no new API): spawn a single **reviewer agent** (Sonnet) instead, with a combined prompt covering all three areas.

Each reviewer returns findings with `severity` (critical/important/minor) and `confidence` (0.0–1.0). Discard findings below `review.confidence_threshold` (default 0.8).

### Escalation

- **Critical finding**: Escalate immediately. If architectural → spawn planner. If business logic → pause for user. Do not proceed until resolved.
- **Important finding (first occurrence)**: Loop back to Stage 3 **only if the fix is directly actionable within the current scope**. Do NOT loop back for findings that require external runtime infrastructure (e.g. UI test frameworks), significant architectural changes outside task scope, or would substantially expand the work. Log those as deferred findings and continue.
- **Important finding (second occurrence for same issue)**: Escalate to planner or user.
- **Minor findings**: Log and continue to Stage 6.

---

## Stage 6: Verification

**Do not run test commands directly.** Spawn the **verifier agent**.

Pass the execution graph, all implementation summaries, design document, and current branch state. The verifier uses `workflow.verification_commands` from config or auto-detects: Maven/Gradle → `mvn test` / `./gradlew test`; Node → `npm test`; Python → `pytest`; Rust → `cargo test`; Go → `go test ./...`.

- **PASS**: Continue to Stage 7.
- **FAIL (build/type errors)**: Spawn **build-fixer agent** with the failure output. Re-run verification. If still failing, fall through to test/lint path.
- **FAIL (test/lint)**: Loop back to Stage 3 for failing components. Second failure → escalate to planner. Third failure → pause for user.

---

## Stage 7: Merge Prep

1. **Generate merge commit message**: Follow `git.merge_commit_template` from config. Summarize all changes, tasks completed, and review outcomes. Default: conventional commit format with a detailed body.

2. **Generate PR title**: Under 72 characters, prefixed with branch type (`feat:`, `fix:`, `refactor:`).

3. **Present for approval**: Show the user both. Wait for explicit confirmation before proceeding.

4. **Clean up plan artifacts**:
   - If plan files are git-tracked: `git rm docs/plans/<design-doc> docs/plans/<plan-json> && git commit -m "chore: remove pipeline plan artifacts"`
   - If plan files are untracked (were never committed): delete the files without a commit.

5. **Report**: `"Pipeline complete. Ready for PR."` with task count, review iterations, findings addressed, and agent spawns.

---

## Error Handling

- **Agent spawn failure**: Retry once. If still failing, pause for user intervention.
- **Git merge conflict**: Log with full context. Attempt automatic resolution for trivial conflicts (both sides added different items to a list). Non-trivial conflicts → pause for user.
- **Config missing or malformed**: Use defaults for all values. Log a warning that defaults are in use.
