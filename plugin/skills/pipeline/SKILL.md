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
| "Let me explore the codebase first" | No. Enter Stage 1 (brainstorm skill). It explores with the user. |
| "I need to understand the current state" | No. That is Stage 1 (brainstorm) or Stage 2 (plan). |
| "The task is too vague to brainstorm" | No. Vagueness is exactly what brainstorm resolves. |
| "Let me check the branch first" | Yes — Stage 0 only. Then immediately enter Stage 1. |
| "I'll invoke the merge-prep / plan / brainstorm skill" | No. **Never invoke other skills.** All stage logic is defined in this document. Use the Agent tool to spawn the relevant agent directly. |
| "Let me summarise what the brainstorm/plan agent said" | No. Relay its full output verbatim. The user needs the complete text to choose an approach. |
| "The reviewer found issues, I'll handle them in chat" | No. Spawn the implementer in fix mode. Then spawn the reviewer again. |
| "I'll fix this while waiting for other reviewers" | No. Wait for ALL reviewers to complete. Then spawn the implementer with all findings. Never use Edit/Write yourself. |
| "This is a simple fix, I'll do it directly" | No. ALL code changes go through agents. The orchestrator never edits files. |
| "The agent hit a permission wall, I'll implement it myself" | No. A permission failure means a configuration problem — investigate and fix it. Never fall back to editing files directly. |
| "The agent failed, it was just a trivial change" | No. Triviality is irrelevant. All code changes go through agents. Escalate to user if agents cannot run. |
| "I'll skip the domain agent, the planner already covered this" | No. Domain agents provide a deeper, domain-specific pass the planner cannot replicate. If the agent is listed, run it. |
| "I'll run domain agents in parallel to save time" | No. Domain agents run sequentially — each builds on the previous agent's refinements. |

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

Run this conversational design exploration directly in main chat — no agent spawn.

### Process

1. **Explore context.** Read README, CLAUDE.md, architecture docs, and relevant source files. Stop when you can ask informed questions.

2. **Clarify one question at a time.** Prefer multiple choice when options are knowable. Focus on purpose, constraints, and success criteria.

3. **Propose 2-3 approaches.** Lead with your recommendation. For each: one-sentence summary, pros/cons, relative effort. YAGNI ruthlessly — call out over-engineering.

4. **Get explicit approval on the approach.** Present a short summary of the chosen direction — a few bullet points covering what's being built and why. Ask: "Does this direction look right before I hand it to the planner?" Wait for confirmation.

   Keep this summary in-chat only. Do **not** write a design document — that is the planner's job. The planner receives the confirmed approach as context and produces the full plan.

---

## Stage 2: Plan

Skip for bug mode — use the debugger agent in Stage 3 instead.

Read `workflow.human_checkpoints` from config.

**Interactive mode** (`plan` in `human_checkpoints`):
1. Spawn the **planner agent**. Pass the task description and the confirmed approach from Stage 1 (Q&A summary and approved direction, inlined as context). Do not pass a design document — brainstorm does not produce one.
2. Relay the agent's **full output** to the user verbatim — proposed task breakdown, groupings, dependency decisions, and questions. Do not summarise or filter.
3. If the planner asked questions, collect answers and re-spawn with the full Q&A history.
4. When the planner produces a draft plan, **read the plan file** and present its full contents to the user. Do not summarise — show the entire document. Then ask: **"Does this plan look good, or do you want changes?"** Do not proceed until the user explicitly approves.
5. If the user requests changes, re-spawn the planner with the feedback appended. Repeat until approved.

**Autonomous mode**:
1. Spawn the **planner agent** once with `autonomous: true`. It produces the plan in one pass.

The planner writes a comprehensive markdown plan document containing:
- A `<!-- SCHEDULING -->` table (parsed by the orchestrator for task scheduling)
- Detailed `## Task T<N>` sections (self-contained context for each implementer)

Save to `docs/plans/YYYY-MM-DD-<slug>-plan.md`. Do not commit it — it is a temporary pipeline artifact.

---

## Stage 2.5: Domain Agent Refinement

Skip if the plan's `## Domain Agents Needed` section is empty or absent.

Domain agents are second-pass experts. Each reads the entire plan, takes ownership of its domain, challenges decisions, and refines task descriptions with specificity. They run **sequentially** — one completes before the next begins, because later agents can build on earlier ones' additions.

Available domain agents:

| Agent | Domain |
|-------|--------|
| `design-agent` | UI/UX, React, CSS, visual design, accessibility, theme-factory, Next.js |
| `java-agent` | Java, Spring Boot layering, JPA entities, Spring Security, backend patterns |
| `python-agent` | Python, Django, FastAPI/Flask, Celery, pytest, DRF |
| `rust-agent` | Rust, Actix-web/Axum, ownership design, async concurrency |
| `cpp-agent` | C/C++, RAII, CMake, GoogleTest, service architecture |
| `database-agent` | Schema design, migrations, indexing, query optimization, PostgreSQL |
| `api-agent` | REST contract, URL design, status codes, error format, versioning, pagination |
| `deployment-agent` | CI/CD, Docker, Kubernetes, Terraform, health checks, observability |

### Per-Agent Loop

For each agent listed in `## Domain Agents Needed` (in order, skipping any already marked `[x]`):

#### 1. Spawn the domain agent

Pass the plan file path. Example prompt:

> "Read the full plan at `docs/plans/YYYY-MM-DD-<slug>-plan.md`. Apply your domain expertise, challenge all decisions in your domain, add or refine tasks as needed, take ownership of all [domain] decisions. When done, update the plan and mark yourself complete."

Wait for the agent to complete (these run **in the foreground**, not background — the next agent depends on the result).

#### 2. Handle Q&A

If the agent outputs a `DOMAIN_AGENT_QUESTIONS:` block, relay each question to the user verbatim. Collect answers, then **re-spawn the agent** with the questions and answers appended to the prompt. Repeat until the agent outputs `DOMAIN_AGENT_COMPLETE`.

#### 3. Confirm completion

When the agent outputs `DOMAIN_AGENT_COMPLETE: <agent-name>`, mark it done and move to the next.

### Final Planner Validation Pass

After all domain agents complete, **re-spawn the planner agent** in validation mode. Pass the plan file path and:

> "The plan has been refined by domain agents. Validate the updated plan: verify task ordering, parallel group correctness, file ownership conflicts, and that all domain agent additions are internally consistent. Apply Step 8 (Critical Self-Challenge) to the full updated plan. Do not add new features — only fix planning defects introduced during domain agent refinement."

In **interactive mode** (`plan` in `human_checkpoints`): read the plan file and present its full contents to the user. Do not summarise. Then ask: **"The plan has been refined by domain experts. Does this final plan look good?"** Wait for approval.

In **autonomous mode**: accept the planner's validation result directly.

The plan is now final. Proceed to Stage 3.

---

## Stage 3: Implement + Review

Read the plan file once. Extract the `<!-- SCHEDULING -->` table into an in-context tracking table:

| id | name | group | touches | depends_on | status |
|----|------|-------|---------|------------|--------|
| T01 | board init | 1 | src/board.ts | — | 🔒 waiting |
| … | … | … | … | … | … |

Pass the plan file **path** (not its content) to each implementer. The plan's `## Task T<N>` sections contain all the detail the implementer needs. For bug mode, create a single synthetic task row.

### Task Scheduling

Track status in the same table — update the `status` column as tasks progress:

| id | name | group | touches | depends_on | status |
|----|------|-------|---------|------------|--------|
| T01 | board init | 1 | [src/board.ts] | [] | ✅ merged |
| T02 | move validation | 2 | [src/moves.ts] | [T01] | ⏳ running |
| T03 | game state | 3 | [src/state.ts] | [T01] | 🔒 waiting |

A task is eligible when:
1. All `depends_on` IDs are `✅ merged`.
2. Its `touches` files don't overlap with any `⏳ running` task's touches.

Spawn eligible tasks in parallel up to `workflow.max_parallel_tasks` (default 4).

### Review Document

Before spawning the first implementer, create the feature's review document:
`docs/plans/YYYY-MM-DD-<slug>-review.md`

The orchestrator owns this file — agents do not write to it directly. Initialize it with:
```markdown
# Review — <slug>
Generated: YYYY-MM-DD

## Batch Reviews

## Stage 4: Deep Review
```

### Per-Group Execution

Process one parallel group at a time:

#### 1. Spawn implementers

For each eligible task in the group, spawn the **implementer agent** using `run_in_background: true` (which has `isolation: worktree` in frontmatter — Claude Code auto-creates and auto-merges worktrees). Pass only the **plan file path** and **task ID** (e.g. `T03`). Do not pass inline task descriptions, design summaries, or any other context — the plan file is the implementer's sole source of truth and adding extra context risks conflicting with it. Spawn all eligible tasks simultaneously up to `max_parallel_tasks`.

The implementer works in its isolated worktree, runs its self-check gate, commits, and finishes. On finish, changes are **auto-merged** to the feature branch by Claude Code — the root session does not handle this.

Wait for all background implementers in the group to complete. Mark completed tasks `✅ merged` in the status table.

#### 2. Batch review

After all tasks in the group have merged, spawn the **reviewer agent** using `run_in_background: true`. Pass:
- The plan file path and the list of task IDs in this group
- The review document path
- The base branch name (feature branch before this group started — use a tag or commit hash saved before step 1)

The reviewer runs `git diff <pre-group-commit>...HEAD` to see the combined diff of all tasks in the group. It reviews against the plan requirements for all tasks in the batch.

Wait for the reviewer to complete. Then **append findings to the review document** under `### Group <N>: <task list>`, each marked `[OPEN]` or `[DEFERRED]`.

#### 3. On PASS

Continue to the next group.

#### 4. On FAIL (attempt 1 — targeted retry)

For each task with in-scope findings:
- Re-spawn the **implementer** using `run_in_background: true` with the plan file path, task ID, and the reviewer findings for that specific task appended. Reviewer findings are the only additional context — do not add summaries or re-descriptions of the task.
- After all retries complete and auto-merge, re-run the batch reviewer on the same scope.

#### 5. On FAIL (attempt 2 — systematic debugging)

For tasks still failing: spawn the **debugger agent** using `run_in_background: true` instead of the implementer. Pass the task context, reviewer feedback history, and prior attempt evidence.

After debugger fixes auto-merge, re-run the batch reviewer.

#### 6. On FAIL (attempt 3)

Stop. Spawn the **planner agent** in `debug_plan` mode with full failure evidence. Execute a new implement+review cycle on the revised plan. If still failing, pause and escalate to the user.

---

## Stage 4: Deep Review

**Distinct from Stage 3 per-task review.** This audits the entire diff holistically.

**Every reviewer computes its own diff.** Include the base branch name in each reviewer's spawn prompt (e.g., "Base branch: main"). Each reviewer runs `git diff <base-branch>...HEAD` itself. Do not compute or pass the diff inline — the reviewers have Bash access and must run git diff themselves.

All findings from Stage 4 are appended to the review document under `## Stage 4: Deep Review`, each marked `[OPEN]` or `[DEFERRED]`.

### Determine Review Intensity

Read `review.deep_review_mode` from config (default: `"auto"`).

| Mode | Behavior |
|------|----------|
| `full` | Always run Steps 1 + 2 (all specialists) |
| `targeted` | Step 1 always; Step 2 spawns only relevant specialists based on diff content |
| `light` | Single reviewer (Sonnet) covering all areas in one pass |
| `auto` | Choose based on diff scope — see below |

**Auto mode** (default): Compute the diff stats (`git diff --stat <base-branch>...HEAD`).

- **Trivially small** (single file, <30 lines changed, no new API): use `light` mode.
- **Small-medium** (<10 files, <300 lines): use `targeted` mode.
- **Large** (10+ files or 300+ lines): use `full` mode.

### Light Mode

Replace Steps 1 and 2 with a single **reviewer agent** (Sonnet) using `run_in_background: true`:

> "Review this diff as a combined holistic + security + quality + coverage check. First verify the plan was followed and all prior review findings are resolved. Then scan for injection risks, hardcoded secrets, OWASP Top 10 patterns, naming clarity, DRY violations, dead code, error handling, behavioral test coverage, and silent failures. Report findings with severity (critical/important) and confidence ≥ 0.8."

### Step 1: Holistic Compliance (full + targeted modes)

**Spawn the reviewer agent (Sonnet)** using `run_in_background: true` with the base branch name, the plan file path, and the review document path. Its job is to answer:
- Was the plan followed? Are all tasks accounted for in the diff?
- Were issues from Stage 3 per-task reviews actually resolved, or do they still appear in the final diff?
- Does the overall feature behave as designed end-to-end?

This is the only reviewer checking "did we build the right thing" — the specialist reviewers below check "did we build it correctly."

### Step 2: Specialist Reviews (full + targeted modes)

**Spawn specialists in parallel** using `run_in_background: true`. Collect results after all complete.

In **full** mode, spawn all applicable specialists. In **targeted** mode, apply the conditions below:

- **Code-quality reviewer** (Sonnet): Always spawn.
- **Test-coverage reviewer** (Sonnet): Spawn if code changes exist (not just docs/config).
- **Security reviewer** (Opus): Spawn only if security-relevant (changes touch auth, API endpoints, user input handling, crypto, network, or env/config files).

Each reviewer returns findings with `severity` (critical/important) and `confidence` (0.0–1.0). Discard findings below `review.confidence_threshold` (default 0.8).

### Escalation

**The orchestrator MUST NOT edit files or fix findings directly.** All fixes go through the implementer agent in fix mode. The orchestrator's job is to collect findings, decide disposition, and spawn the fix agent.

**Fix everything actionable. Do not defer findings that can be fixed now.**

Wait for **all** reviewers to complete before proceeding. Then spawn the **implementer in fix mode** using `run_in_background: true` with all findings above the confidence threshold — critical and important. The fix agent addresses them all in one pass: dead code removal, naming fixes, incorrect test assertions, missing edge case tests, DRY refactors, silent error handling. Wait for the fix agent to complete, then **spawn the reviewer agent again** using `run_in_background: true` with the same scope (full diff, base branch, review document path) to verify. If reviewer passes → mark findings `[RESOLVED]` in the review document and continue. If reviewer fails → one more retry, then escalate to user.

The only findings that get `[DEFERRED]` are those that **cannot** be fixed within the current scope:
- Requires changes to code outside the feature branch's touched files
- Requires external infrastructure not yet available (e.g., a CI pipeline, a third-party service)
- Represents an architectural decision that needs user input

Everything else gets fixed now. "We'll clean it up later" is not an acceptable disposition for actionable findings.

---

## Stage 5: Docs Update

**Mandatory. Do not skip. Runs after deep review so the review document is complete.**

Before spawning the docs-updater, check if `docs/architecture.md` (or the configured `architecture` path) exists. Pass `architecture_missing: true` in the agent prompt if it does not — the docs-updater will create a stub and note it in its output.

Spawn the **docs-updater agent** using `run_in_background: true`. Pass:
- The list of completed tasks
- The review document path
- Paths to existing Tier 1 and Tier 2 documentation files that reference modified code
- `architecture_missing: true/false`

The docs-updater:
1. Creates the architecture stub if missing (Step 0)
2. Updates Tier 1 and relevant Tier 2 docs, with active pruning (Mode 1)
3. Records `[OPEN]`/`[DEFERRED]` findings from the review document and closes any resolved prior findings (Mode 1b)

Wait for the docs-updater to complete. If it reported `architecture_stub_created: true`, notify the user: **"The architecture doc didn't exist — a stub was created at `docs/architecture.md`. Run `/docs-generate architecture` when ready to fill it in."**

Spawn the **docs-reviewer agent** using `run_in_background: true`. Pass the docs-updater output and implementation context. Wait for it to complete.

- **PASS**: Commit documentation changes.
- **FAIL**: Re-spawn docs-updater using `run_in_background: true` with reviewer feedback. Wait for completion. Retry up to 3 times, then escalate to user.

---

## Stage 6: Verification

**Do not run test commands directly.** Spawn the **verifier agent** using `run_in_background: true`.

Pass the execution graph, all implementation summaries, and current branch state. The verifier uses `workflow.verification_commands` from config or auto-detects: Maven/Gradle → `mvn test` / `./gradlew test`; Node → `npm test`; Python → `pytest`; Rust → `cargo test`; Go → `go test ./...`.

Wait for the verifier to complete, then:

- **PASS**: Continue to Stage 7.
- **FAIL (build/type errors)**: Spawn **build-fixer agent** using `run_in_background: true` with the failure output. Wait for it to complete, then re-spawn the verifier. If still failing, fall through to test/lint path.
- **FAIL (test/lint)**: Loop back to Stage 3 for failing components. Second failure → escalate to planner. Third failure → pause for user.

---

## Stage 7: Merge Prep

1. **Generate merge commit message**: Follow `git.merge_commit_template` from config. Summarize all changes, tasks completed, and review outcomes. Default: conventional commit format with a detailed body.

2. **Generate PR title**: Under 72 characters, prefixed with branch type (`feat:`, `fix:`, `refactor:`).

3. **Present for approval**: Show the user both. Wait for explicit confirmation before proceeding.

4. **Clean up plan artifacts**: Delete the plan doc and review doc: `rm -f docs/plans/<plan-md> docs/plans/<review-md>`. These are never committed, so no git operation needed.

5. **Report**: `"Pipeline complete. Ready for PR."` with task count, review iterations, findings addressed, and agent spawns.

---

## Error Handling

- **Agent spawn failure**: Retry once. If still failing, pause for user intervention.
- **Git merge conflict**: Log with full context. Attempt automatic resolution for trivial conflicts (both sides added different items to a list). Non-trivial conflicts → pause for user.
- **Config missing or malformed**: Use defaults for all values. Log a warning that defaults are in use.
