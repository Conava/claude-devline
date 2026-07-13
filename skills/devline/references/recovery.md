# State Persistence & Recovery

Loaded rarely — only when the pipeline must reconstruct its state (resume-after-crash, post-compaction, conversation resume). During normal Stage 3 operation the implementation protocol (`references/implementation-protocol.md`) already directs state-file writes; this file holds the full schemas and the recovery steps.

## State Persistence

Persist all mutable state to files — conversation context is disposable summaries only.

### `.devline/state.md` — single source of truth for pipeline state
Create when entering Stage 3. Update after every status change. Always end the file with `## END` as an integrity marker — if this line is missing when reading, the file was partially written; re-derive state from `plan.md` + `TaskList`.

```markdown
## Pipeline State
- **Stage:** implement
- **Phase:** N/M (or "single" for non-phased pipelines)
- **Phase name:** [name from brainstorm, e.g., "Core data model"]
- **Updated:** 2026-03-20T14:32:00
- **Active agents:** 3/10
- **Pipeline started:** 2026-03-20T14:00:00

## Task Progress
| # | Status | Review Attempts | Notes |
|---|--------|-----------------|-------|
| 1 | done | 1 (CLEAN) | |
| 2 | building | 0 | Launched 2026-03-20T14:28:00 |
| 3 | blocked | 0 | Waiting on 1 |

## Pending Fix Cycles
| Task | Fix File | Created |
|------|----------|---------|
| 5 | .devline/fix-task-5.md | 2026-03-20T14:35:00 |

## Deferred Findings
- **Total:** 5
- **File:** .devline/deferred-findings.md

## END
```

Key schema rules:
- **Active agents** counter tracks concurrency against the 10-agent limit
- **Launched** timestamps are absolute ISO 8601 — they survive compaction and enable health monitoring to compute elapsed time after recovery
- **Pending Fix Cycles** tracks orphaned fix-task files so recovery can resume them
- Task **Status** values: `blocked`, `queued`, `building`, `reviewing`, `fixing`, `done`, `failed`

### `.devline/deferred-findings.md` — deferrable findings collected across tasks
Append findings grouped by task. During batch fix, the implementer prefixes each fixed finding with `[FIXED]` so partial progress is trackable.

```markdown
## Deferred Findings

### Task 1: Auth module
1. [FIXED] **Code Quality** `src/auth.ts:42` — Rename `x` to `tokenExpiry`
2. **Code Quality** `src/auth.ts:78` — Extract duplicated validation

### Task 3: API routes
1. **Code Quality** `src/routes.ts:15` — Extract duplicated validation into helper
```

### Context discipline
1. After receiving agent output: extract verdict, update `.devline/state.md` (including active agent count), append deferred findings, output a brief summary to user.
2. Write review findings to `.devline/fix-task-{N}.md` for implementers to read. Record in state.md's Pending Fix Cycles table. Delete both entries after fix cycle completes.
3. **Proactive checkpointing:** After every 5 agent completions, ensure `.devline/state.md` fully reflects current state. This ensures recoverability even if compaction happens between agent completions.

### Recovery protocol
If unsure of pipeline state — after compaction, conversation resume, or starting a new conversation with an active pipeline:

1. **Read `.devline/state.md`** — check for `## END` integrity marker. If missing, the file is corrupt; fall back to steps 3-5 to reconstruct.
2. **If state.md contains `Phase: N/M`** (not "single"), this is a multi-phase pipeline:
   - Check which plan-phase files exist on disk (`.devline/plan-phase-*.md`) to determine which phases are complete
   - A phase is complete if its plan file exists AND all its tasks are merged (check git log for `task-N:` commits matching the plan's task list)
   - Resume from the current phase — if mid-implement, resume Stage 3 with the current phase's plan file; if between phases, start the next phase's planning
3. **Read `.devline/deferred-findings.md`** — restore collected findings.
4. **Read the active plan file** — `.devline/plan.md` for single-phase, or `.devline/plan-phase-N.md` (where N is the current phase from state.md) for multi-phase — restore task definitions, dependencies, acceptance criteria. Validate `**Branch:**` and `**Status:**` against current git state.
5. **Cross-check git log against state.md** — run `git log --oneline` and grep for `task-N:` commits. If a task has a commit in git but state.md shows `building` or `reviewing`, the crash happened after commit but before state update — mark that task as `done` in state.md. This prevents relaunching already-completed tasks.
6. **Check `TaskList`** — this is the ground truth for what agents are running (state.md agent IDs are conversation-scoped and may be stale after compaction).
7. **Check for orphaned `.devline/fix-task-*.md` files** — each represents an interrupted fix cycle. Resume by launching an implementer for each.
7. **Read `.devline/agent-log.md`** if it exists — the SubagentStop hook logs agent completions here. Cross-reference with state.md to identify agents that completed but weren't processed (e.g., due to compaction between completion and processing).
8. **Recompute active agent count** from TaskList and update state.md.
9. **Recompute elapsed times** from absolute timestamps in state.md's Task Progress table. Resume health monitoring escalation based on actual elapsed time.
10. Resume orchestration from the recovered state.
