---
name: pipeline
description: "Use when the user asks to 'build a feature', 'add functionality', 'refactor code', 'create a new module', 'implement changes', 'develop', or any development task that benefits from a structured workflow. Default skill for development work unless the user explicitly asks for a single stage."
argument-hint: "[task description]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Bash, Grep, Glob
---

# Pipeline Orchestration

This document defines the orchestration flow for multi-stage development pipelines. When `/build` is invoked or a development task is detected, the main chat (Sonnet) acts as orchestrator: spawning agents, relaying questions between agents and the user, and tracking pipeline progress in context.

---

## Size Gating

Before entering the pipeline, evaluate whether the task is trivially small. A task is trivially small when it affects a single file with an obvious, well-scoped change (e.g., rename a variable, fix a typo, add a single config field). For trivially small tasks, skip Stages 0 through 2 and enter directly at Stage 3 with a synthetic single-task execution graph. Apply all subsequent stages normally.

For everything else, begin at Stage 0.

---

## Stage 0: Branch Safety

Run `git rev-parse --abbrev-ref HEAD` to determine the current branch.

- **Protected branch detected** (matched against `git.protected_branches` in the plugin config): Create a new feature branch using the prefix defined in `git.feature_branch_prefix` (default `feature/`). Derive the branch name from a slug of the task description. Check out the new branch before proceeding.
- **Wrong branch detected** (not protected, but not obviously related to the current task): Ask the user whether to continue on this branch or create a new one. Do not proceed until the user confirms.
- **Feature branch detected** (not protected, name matches the feature prefix or user confirms it is correct): Continue immediately.

---

## Stage 1: Brainstorm

Read `workflow.human_checkpoints` from the plugin config.

### Interactive Mode (when `"brainstorm"` is listed in `human_checkpoints`)

1. Generate a run ID (UUID v4).
2. Spawn a brainstorm agent. Pass it the user's task description and any referenced files.
3. The brainstorm agent returns 1 to 3 clarifying questions. Relay these questions to the user verbatim. Do not paraphrase or summarize.
4. Re-spawn the brainstorm agent with the Q&A history in context. The agent reads prior Q&A and either returns more questions or a finalized design document.
5. Repeat steps 3-4 until the agent returns a design document instead of questions.
6. Save the design document to `docs/plans/<run-id>-design.md`.

### Autonomous Mode (when `"brainstorm"` is NOT in `human_checkpoints`)

Spawn the brainstorm agent once in autonomous mode. Pass `autonomous: true` in the agent context. The agent produces a design document without asking questions, drawing on the codebase context, referenced files, and task description. Save the design document to `docs/plans/<run-id>-design.md`.

---

## Stage 2: Plan

Read `workflow.human_checkpoints` from the plugin config.

### Interactive Mode (when `"plan"` is listed in `human_checkpoints`)

1. Spawn a planner agent. Pass the design document path and the full codebase context.
2. The planner returns a draft execution graph or follow-up questions. If questions: relay to the user, pass answers back in context, re-spawn.
3. Repeat until the planner returns a finalized execution graph.

### Autonomous Mode (when `"plan"` is NOT in `human_checkpoints`)

Spawn the planner agent once. Pass `autonomous: true`. The planner produces the execution graph without interaction.

The execution graph is a JSON structure containing:
- `tasks`: an array of task objects, each with `id`, `description`, `touches` (list of file paths the task will modify), `depends_on` (list of task IDs), and `parallel_group` (integer).
- `order`: a topological ordering of task IDs respecting dependencies.

Save the execution graph to `docs/plans/<run-id>-plan.json`.

---

## Stage 3: Implement + Review

Read the execution graph from `docs/plans/<run-id>-plan.json`.

### Task Scheduling

Track completed task IDs and currently-running task file paths in context. A task is eligible to run when:
1. All task IDs in its `depends_on` list are in the completed set.
2. None of the file paths in its `touches` list overlap with any currently-running task's `touches` list.

Spawn eligible tasks in parallel up to the concurrency limit defined in `workflow.max_parallel_tasks` (default 4).

### Domain Skill Resolution

**Before spawning any implementer**, resolve domain skills for each task:

1. Read `${CLAUDE_PLUGIN_ROOT}/config/skill-mappings.yaml`.
2. For each file in the task's `touches` list, match its extension against `file_patterns` (e.g., `*.java` → `[java-coding-standards, jdtls-lsp]`) and its directory path against `directory_patterns`.
3. Also scan `relevant_context` files for framework markers listed in `framework_markers`.
4. Deduplicate. For each matched skill name, construct the full path: `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/SKILL.md`.
5. Pass this resolved list as `domain_skills` to the implementer. **Never spawn an implementer without resolving skills first.**

### Per-Task Execution

For each task:

1. **Implement**: Spawn an implementer agent with `isolation: "worktree"`. Pass the task object, the resolved `domain_skills` paths, the design document path, and any prior reviewer feedback (on retry). The implementer works in an isolated git worktree and returns an implementation summary and the worktree path.

2. **Review**: When the implementer returns, run `git diff <feature-branch>...<task-branch>` to get the diff. Spawn a **reviewer agent** (this is a per-task correctness check — it is **not** Stage 5 deep review). Pass the diff, implementation summary, task object, and design document. The reviewer returns a verdict: `PASS` or `FAIL` with specific feedback.

3. **On PASS**: Merge the worktree into the feature branch. The implementer runs with `isolation: "worktree"` — Claude Code creates the worktree and a task branch named `<feature-branch>/<task-id>`. After the agent completes, the worktree path is returned in the agent result. Run:
   ```
   git checkout <feature-branch>
   git merge --no-ff <feature-branch>/<task-id> -m "<type>(<task-id>): <task-description>"
   git worktree remove <worktree-path> --force
   git branch -d <feature-branch>/<task-id>
   ```
   Use `fix:` type for bug tasks, `feat:` for new features, `refactor:` for refactoring. Add the task ID to the completed set.

4. **On FAIL (attempt 1 — normal retry)**: Re-spawn the implementer agent with the reviewer's feedback appended to the task context.

5. **On FAIL (attempt 2 or 3 — systematic debugging)**: Spawn the **debugger agent** (opus) instead of re-spawning the implementer. Pass the task context, reviewer feedback history, prior implementation attempt evidence, and changed files. The debugger follows a four-phase methodology (Root Cause Investigation → Pattern Analysis → Hypothesis Testing → Implementation) and returns the fix along with a root cause analysis and regression test. On attempt 3, pass cumulative evidence from attempt 2 so the debugger builds on prior investigation rather than starting from scratch.

6. **On FAIL (attempt 4)**: Stop all currently running parallel agents. Spawn the planner agent with a `"debug_plan"` context containing the failing task details, reviewer feedback history, debugger root cause analyses from attempts 2-3, and the current state of the codebase. The planner produces a revised sub-plan for the failing task. Execute a new implement+review cycle using the revised plan. If the revised plan also fails after one full cycle, pause the entire pipeline and escalate to the user with a detailed summary of what failed and why.


---

## Stage 4: Docs Update

**This stage is mandatory. Do not skip it, even if the changes seem small.**

Spawn a docs-updater agent. Pass the list of all completed tasks, their implementation summaries, the design document, and any existing documentation files that reference modified code.

The docs-updater produces updated or new documentation reflecting the changes made during implementation.

Spawn a docs-reviewer agent. Pass the docs-updater's output and the implementation context. The reviewer returns `PASS` or `FAIL` with feedback.

- **PASS**: Commit the documentation changes.
- **FAIL**: Re-spawn the docs-updater with the reviewer's feedback. Repeat the review cycle. After 3 failed attempts, escalate to the user.

---

## Stage 5: Deep Review

**This is distinct from the per-task reviewer used in Stage 3.** Stage 3 uses the `reviewer` agent to check correctness of individual tasks. Stage 5 uses Opus-class specialist agents (security-reviewer, code-quality-reviewer, test-coverage-reviewer) to audit the entire diff holistically. Do not substitute Stage 3 per-task review for Stage 5.

Read `review.deep_review_mode` from the plugin config (default `"auto"`).

### Review Mode Selection

- **`full`**: Always spawn all 3 Opus review agents (security, code-quality, test-coverage). Use when quality cannot be compromised.
- **`targeted`**: Analyze the diff to determine which reviewers are relevant. Spawn only those. Rules:
  - Security reviewer: if changes touch auth, API endpoints, user input handling, crypto, network, or env/config files.
  - Code quality reviewer: if changes add or modify more than 50 lines of logic (excludes tests, docs, config).
  - Test coverage reviewer: if changes add or modify source code (not just tests or docs).
- **`light`**: Spawn a single Sonnet-based reviewer that performs a combined check covering security, quality, and coverage at a surface level. Best for trivial or low-risk changes.
- **`auto`** (default): Choose the mode based on change scope:
  - Trivially small task (single file, <30 lines changed, no new public API) → `light`
  - Medium task (2-5 files, <200 lines, no security-sensitive changes) → `targeted`
  - Large task or any security-sensitive change → `full`

### Agent Spawning

Based on the selected mode:

1. **Security reviewer** (Opus): Analyze all changes for security vulnerabilities, injection risks, auth/authz gaps, secret exposure, and unsafe deserialization. Reference OWASP categories relevant to the stack.
2. **Code quality reviewer** (Opus): Check for architectural consistency, naming conventions, error handling, performance anti-patterns, dead code, and adherence to project style guides.
3. **Test coverage reviewer** (Opus): Verify that new and modified code has adequate test coverage. Flag untested branches, missing edge cases, and integration test gaps.

In `light` mode, spawn a single Sonnet agent with a combined prompt covering all three areas. It produces the same findings format but with a single agent.

Each reviewer returns findings as a list of issues, each with a `severity` (`critical`, `important`, `minor`) and a `confidence` score (0.0 to 1.0).

### Filtering and Escalation

Read `review.confidence_threshold` from the plugin config (default 0.8). All confidence values use a 0.0–1.0 scale. Discard findings with confidence below the threshold.

- **Critical finding detected**: Immediately escalate. If the finding is actionable by the planner (e.g., architectural issue), spawn the planner with the finding. If it requires human judgment (e.g., business logic concern), pause and present to the user. Do not proceed until resolved.
- **Important finding detected (first occurrence)**: Loop back to Stage 3 for the relevant task. Create a new implementation task targeting the finding. Execute a full implement+review cycle.
- **Important finding detected (second occurrence for the same issue)**: Escalate to the planner or human. Present the full history of the finding, including both implementation attempts.
- **Minor findings only**: Log them in context. Continue to Stage 6.

---

## Stage 6: Verification

**Do not run tests or build commands directly.** Always spawn the verifier agent. Running `mvn test`, `npm test`, or any equivalent directly does not satisfy this stage.

Spawn a verifier agent. Pass the full execution graph, all implementation summaries, the design document, and the current branch state. The verifier runs project-defined verification commands as specified in `workflow.verification_commands` in the config. If not configured, the verifier auto-detects: Maven/Gradle projects → `mvn test` or `./gradlew test`; Node.js → `npm test`; Python → `pytest`; Rust → `cargo test`; Go → `go test ./...`.

- **PASS**: Continue to Stage 7.
- **FAIL (build/type errors)**: Spawn a build-fixer agent with the failure output. The build-fixer applies minimal surgical fixes to get the build passing, then re-run verification. If the build-fixer cannot resolve the errors after one attempt, fall through to the general failure path below.
- **FAIL (test/lint failures)**: Loop back to Stage 3 for the failing components. If verification fails a second time after re-implementation, escalate to the planner. If it fails a third time, pause for human intervention.

---

## Stage 7: Merge Prep

Read all files in `docs/plans/` to reconstruct what was done across the pipeline.

1. **Generate merge commit message**: Follow the template in `git.merge_commit_template` from the config. Include a summary of all changes, tasks completed, and review outcomes. If no template is configured, use conventional commit format with a detailed body.

2. **Generate PR title**: Derive from the task description. Keep it under 72 characters. Include a prefix matching the branch type (e.g., `feat:`, `refactor:`, `fix:`).

3. **Present for approval**: Show the user the merge commit message and PR title. Wait for confirmation or edits. Do not proceed without explicit user approval.

4. **Clean up plan artifacts**: Remove all files in `docs/plans/` that were created during this run. Stage and commit the removal as a separate cleanup commit with message `chore: remove pipeline plan artifacts for <run-id>`.

5. **Report completion**: Output `"Pipeline complete. Ready for PR."` along with a summary: number of tasks completed, review iterations, findings addressed, and total agent spawns.

---

## Error Handling

- **Agent spawn failure**: Retry once. If the second spawn fails, log the error and pause for human intervention.
- **Git operation failure** (merge conflict, worktree error): Log the error with full context. Attempt automatic conflict resolution for trivial conflicts (e.g., both sides added different items to a list). For non-trivial conflicts, pause and present the conflict to the user.
- **Config missing or malformed**: Use defaults for all configurable values. Log a warning that defaults are in use.
