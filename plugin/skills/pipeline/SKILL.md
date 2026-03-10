---
name: pipeline
description: "Use when the user asks to 'build a feature', 'add functionality', 'refactor code', 'create a new module', 'implement changes', 'develop', or any development task that benefits from a structured workflow. Default skill for development work unless the user explicitly asks for a single stage."
argument-hint: "[task description]"
disable-model-invocation: false
user-invocable: true
---

# Pipeline Orchestration

The main chat acts as orchestrator: spawning agents directly, relaying questions to the user, and tracking progress in context. All orchestration logic is defined here — do not delegate to other skills.

## Orchestrator Discipline

**Do not explore, read files, or gather context yourself before entering Stage 0.** The pipeline stages exist precisely to do that work through the right agents. Rationalising "I need context first" means you are about to skip a stage — don't.

| Thought | Correct action |
|---------|---------------|
| "Let me explore the codebase first" | No. Pass the task to the brainstorm agent. It explores. |
| "I need to understand the current state" | No. That is Stage 1 (brainstorm) or Stage 2 (plan). |
| "The task is too vague to brainstorm" | No. Vagueness is exactly what brainstorm resolves. |
| "Let me check the branch first" | Yes — Stage 0 only. Then immediately enter Stage 1. |
| "I'll invoke the merge-prep / plan / brainstorm skill" | No. **Never invoke other skills.** All stage logic is defined in this document. Use the Agent tool to spawn the relevant agent directly. |
| "Let me summarise what the brainstorm/plan agent said" | No. Relay its full output verbatim. The user needs the complete text to choose an approach. |
| "The reviewer found issues, I'll handle them in chat" | No. Spawn the implementer in fix mode. Then spawn the reviewer again. |

Enter Stage 0 now.

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
2. Relay the agent's **full output** to the user verbatim — approaches, trade-offs, recommendations, and questions. Do not summarise, filter, or condense. The user must see the complete output to make informed choices.
3. Collect the user's answers and any approach selection.
4. Re-spawn the brainstorm agent with the full Q&A history. Repeat until the agent produces a design document.

**Autonomous mode**:
1. Spawn the **brainstorm agent** with `autonomous: true`. It produces a design document in one pass.

Save the design document to `docs/plans/YYYY-MM-DD-<slug>-design.md`. Commit: `git add docs/plans/...-design.md && git commit -m "docs: add design document for <task>"`.

---

## Stage 2: Plan

Skip for bug mode — use the debugger agent in Stage 3 instead.

Read `workflow.human_checkpoints` from config.

**Interactive mode** (`plan` in `human_checkpoints`):
1. Spawn the **planner agent**. Pass the design document path (or task description if no design doc exists).
2. Relay the agent's **full output** to the user verbatim — proposed task breakdown, groupings, dependency decisions, and questions. Do not summarise or filter.
3. Collect answers and re-spawn with the full Q&A history until the planner produces a finalized execution graph.

**Autonomous mode**:
1. Spawn the **planner agent** once with `autonomous: true`. It produces the execution graph in one pass.

The execution graph is a JSON structure with:
- `tasks`: array of `{ id, description, touches, depends_on, parallel_group }`
- `order`: topological ordering of task IDs

Save to `docs/plans/YYYY-MM-DD-<slug>-plan.json`. Commit: `git add docs/plans/...-plan.json && git commit -m "docs: add implementation plan for <task>"`.

---

## Stage 3: Implement + Review

Read the plan file once. Extract the scheduling fields into a compact in-context table — do not retain the full plan content:

| id | name (≤5 words) | group | touches | depends_on |
|----|-----------------|-------|---------|------------|
| T01 | board init | 1 | [src/board.ts] | [] |
| … | … | … | … | … |

Pass the plan file **path** (not its content) to agents that need the full task detail. For bug mode, create a single synthetic task row.

### Task Scheduling

Track status in the same table — update the `status` column as tasks progress:

| id | name | group | touches | depends_on | status |
|----|------|-------|---------|------------|--------|
| T01 | board init | 1 | [src/board.ts] | [] | ✅ merged |
| T02 | move validation | 2 | [src/moves.ts] | [T01] | ⏳ running |
| T03 | game state | 3 | [src/state.ts] | [T01] | 🔒 waiting |

This single table is all the orchestrator needs for scheduling, overlap detection, and progress display. Use it to render the status table shown to the user after each task completes.

A task is eligible when:
1. All `depends_on` IDs are `✅ merged`.
2. Its `touches` files don't overlap with any `⏳ running` task's touches.

Spawn eligible tasks in parallel up to `workflow.max_parallel_tasks` (default 4).

### Gitignore Check

Before creating any worktree, ensure `.claude/worktrees/` is gitignored so worktree directories never appear as untracked files:

```bash
grep -qx '.claude/worktrees/' .gitignore 2>/dev/null || echo '.claude/worktrees/' >> .gitignore
```

If `.gitignore` was modified, commit it: `git add .gitignore && git commit -m "chore: ignore worktree directories"`.

### Review Document

Before spawning the first implementer, create the feature's review document:
`docs/plans/YYYY-MM-DD-<slug>-review.md`

The orchestrator owns this file — agents do not write to it directly. Initialize it with:
```markdown
# Review — <slug>
Generated: YYYY-MM-DD

## Per-Task Reviews

## Stage 5: Deep Review
```

Pass this path to every reviewer spawn. Append all findings here as the pipeline progresses. This is the single source of truth that docs-updater reads at the end.

### Per-Task Execution

For each task:

1. **Create worktree from local HEAD** — no remote fetch, no SSH required:
   ```
   git worktree add .claude/worktrees/agent-<id> -b worktree-agent-<id> HEAD
   ```
   Generate the ID with: `printf '%x%x' $RANDOM $RANDOM`. Note the absolute worktree path.

2. **Spawn implementer**: Pass the task object, absolute worktree path, design document path, review document path, and any retry feedback. The implementer works entirely within the worktree — reads, writes, tests, self-reviews, and commits there.

3. **Spawn reviewer**: Spawn the **reviewer agent**. Pass: the implementer's status report, the plan file path, the task ID, the review document path, the feature branch name, the worktree branch name (`worktree-agent-<id>`), and the absolute worktree path. **Do not compute the git diff yourself** — the reviewer runs `git diff <feature-branch>...worktree-agent-<id>` from the worktree path. After the reviewer returns, **append its findings to the review document** under `### <task-id>: <task description>`, each marked `[OPEN]` or `[DEFERRED]`.

4. **On PASS**: Merge and clean up:
   ```
   git merge --no-ff worktree-agent-<id> -m "<type>(<task-id>): <description>"
   git worktree remove .claude/worktrees/agent-<id> --force
   git branch -D worktree-agent-<id>
   ```
   Use `fix:` for bugs, `feat:` for features, `refactor:` for refactoring. Add task to completed set.
   In the review document, mark any in-scope findings for this task that triggered a retry as `[RESOLVED — fixed in retry N]`. For out-of-scope findings:
   - If the code **compiles and tests pass** → mark `[DEFERRED]` in the review document.
   - If the code **does not compile or tests fail because of it** → escalate immediately to the **planner agent** with the finding. Do not defer. Do not proceed.

5. **On FAIL (attempt 1 — normal retry)**: Re-spawn the implementer with all in-scope reviewer findings appended to the task context.

6. **On FAIL (attempt 2–3 — systematic debugging)**: Spawn the **debugger agent** instead of the implementer. Pass the task context, reviewer feedback history, and prior attempt evidence. On attempt 3, pass cumulative evidence from attempt 2.

7. **On FAIL (attempt 4)**: Stop all parallel agents. Spawn the **planner agent** in `debug_plan` mode with full failure evidence. Execute a new implement+review cycle on the revised plan. If still failing, pause and escalate to the user.

### Worktree Cleanup Failure

If `git worktree remove` fails due to untracked or modified files: run `git worktree prune` to remove stale references, then `git branch -D worktree-agent-<id>` to remove the branch. Do not use `rm -rf` or `git clean`.

---

## Stage 4: Deep Review

**Distinct from Stage 3 per-task review.** This audits the entire diff holistically.

Pass the base branch name and HEAD to each reviewer — **do not compute the full diff yourself**. Each reviewer runs `git diff <base-branch>...HEAD` itself.

All findings from Stage 5 are appended to the review document under `## Stage 5: Deep Review`, each marked `[OPEN]` or `[DEFERRED]`. After each reviewer returns, append its findings before spawning the next.

### Step 1: Holistic Compliance (always)

**Spawn the reviewer agent (Sonnet)** with the base branch name, the plan file path, the design document path, and the review document path. Its job is to answer:
- Was the plan followed? Are all tasks accounted for in the diff?
- Were issues from Stage 3 per-task reviews actually resolved, or do they still appear in the final diff?
- Does the overall feature behave as designed end-to-end?

This is the only reviewer checking "did we build the right thing" — the specialist reviewers below check "did we build it correctly."

### Step 2: Specialist Reviews

**Always spawn**: **code-quality reviewer** (Opus).
**Spawn if code changes exist** (not just docs/config): **test-coverage reviewer** (Opus).
**Spawn only if security-relevant** (changes touch auth, API endpoints, user input handling, crypto, network, or env/config files): **security reviewer** (Opus).

For trivially small changes (single file, <30 lines, no new API): replace Steps 1 and 2 with a single **reviewer agent** (Sonnet) covering all areas in one pass:

> "Review this diff as a combined holistic + security + quality + coverage check. First verify the plan was followed and all prior review findings are resolved. Then scan for injection risks, hardcoded secrets, OWASP Top 10 patterns, naming clarity, DRY violations, dead code, error handling, behavioral test coverage, and silent failures. Report findings with severity (critical/important) and confidence ≥ 0.8."

Each reviewer returns findings with `severity` (critical/important) and `confidence` (0.0–1.0). Discard findings below `review.confidence_threshold` (default 0.8).

### Escalation

- **Critical finding**: Spawn the **implementer in fix mode** with all critical findings (plus any actionable important findings). After the fix agent returns, **spawn the reviewer agent again** with the same scope (full diff, base branch, review document path) to verify the fixes. If reviewer passes → mark fixed findings `[RESOLVED]` in the review document and continue. If reviewer fails again → escalate to planner (architectural) or pause for user (business logic).
- **Important finding (first occurrence)**: Include in the fix mode batch **only if directly actionable within the current scope**. Mark as `[DEFERRED]` for findings that require external infrastructure, architectural changes outside scope, or would substantially expand the work.
- **Important finding (second occurrence for same issue)**: Escalate to planner or user.
- **Minor findings**: Log in the review document as `[DEFERRED]` and continue to Stage 5.

**Code simplifier**: Do not auto-invoke. If Stage 4 surfaces significant simplification opportunities (dead code clusters, over-engineered abstractions, excessive duplication), note them in the review document as `[DEFERRED]` recommendations. The user can invoke `/simplify` as a follow-up after merge.

---

## Stage 5: Docs Update

**Mandatory. Do not skip. Runs after deep review so the review document is complete.**

Spawn the **docs-updater agent**. Pass the list of completed tasks, the design document path, the review document path, and paths to existing documentation files that reference modified code. The docs-updater reads the review document directly and records only `[OPEN]` and `[DEFERRED]` findings — it ignores `[RESOLVED]` ones.

Spawn the **docs-reviewer agent**. Pass the docs-updater output and implementation context.

- **PASS**: Commit documentation changes.
- **FAIL**: Re-spawn docs-updater with reviewer feedback. Retry up to 3 times, then escalate to user.

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
