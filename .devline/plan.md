# Implementation Plan: Multi-Phase Pipeline Orchestration

**Branch:** refactor/pipeline-improvement
**Created:** 2026-03-28
**Status:** active

## Architecture Overview

The multi-phase feature adds a layer of orchestration between the brainstorm and implementation stages. When the brainstormer detects a large-scope change, it outputs a `## Phases` section in brainstorm.md. The devline orchestrator then enters a sequential loop: for each phase, it launches a planner (scoped to that phase, with prior phase plans as context), runs the standard implement-review-merge cycle against the resulting plan file (`plan-phase-N.md`), and advances to the next phase. Documentation and deep review run once after all phases complete. The entire feature is backward compatible -- when no `## Phases` section exists, the pipeline operates exactly as today with a single `plan.md`.

Three files carry the bulk of the changes: the brainstorm skill (phase detection heuristic + output format), the devline orchestrator skill (multi-phase loop + state tracking + cleanup), and the planner agent (phase-scoped planning + context chain). Supporting files (plan format reference, plan skill, implement skill) receive minor updates to accommodate phase-specific plan file naming.

## Design Decisions

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Phase detection location | Brainstormer | Keeps the pipeline simple -- no new agent, brainstormer already evaluates scope | Separate phase-splitter agent (rejected: adds agent complexity for little value) |
| Plan file naming | `plan-phase-N.md` in `.devline/` | Predictable naming, easy glob pattern for cleanup, planner can read all prior plans by incrementing N | Per-phase subdirectories (rejected: over-engineered for sequential phases) |
| State tracking | Single `state.md` with `Phase:` field, reset task table per phase | Minimal schema change, recovery protocol can reconstruct phase from plan files on disk | One state.md per phase (rejected: complicates recovery -- need to find which state file is current) |
| Phase approval | Per-phase plan approval, no inter-phase approval gate | User already approves each plan; adding a "continue to next phase?" gate adds friction without value since the user can stop at any plan approval | Inter-phase confirmation step (rejected: redundant with plan approval) |
| Single branch | All phases on one feature branch | Matches brainstorm spec, avoids merge complexity, single PR at end | Per-phase branches (explicitly out of scope) |

## Dependency Graph

Wave 1: Task 1, Task 2
Wave 2: Task 3 (← 1, 2)
Wave 3: Task 4 (← 3)

## Tasks

### Task 1: Add phase detection and output format to brainstorm skill
**Agent:** implementer
**Model:** sonnet
**UI:** no
**Files owned:** `skills/brainstorm/SKILL.md`

**Context:**

The brainstormer currently outputs a flat brainstorm.md with no concept of phases. For the multi-phase pipeline to work, the brainstormer must evaluate whether the requested feature is large enough to benefit from splitting into sequential phases, and if so, include a `## Phases` section in its output. This is the entry point for the entire feature -- without it, the orchestrator never enters multi-phase mode.

**Spec:**

Add two things to the brainstorm skill:

1. **Phase detection heuristic** -- a new section in the brainstorm skill's process (between step 2 "Clarify" and step 3 "Write"), instructing the brainstormer to evaluate scope against these triggers:
   - The feature touches 3+ distinct systems/modules or architectural layers
   - A single plan would likely exceed 8-10 tasks
   - Changes cross multiple architectural boundaries (e.g., database schema + API + frontend)
   - The depth of changes spans surface-level config through core logic

   When the heuristic triggers, the brainstormer should split the work into 2-4 sequential phases, ordered so each phase builds on the previous one. Each phase should be a coherent unit of work (not arbitrary splits).

   When the heuristic does NOT trigger, no `## Phases` section is written -- the brainstorm.md format is identical to today (backward compatible).

2. **Phases output format** -- add `## Phases` as an optional section in the brainstorm.md template (after `## Key Decisions`, before `## Open Questions for Planner`). Format:

   ```markdown
   ## Phases

   ### Phase 1: [Name]
   [1-3 sentences: what this phase accomplishes, which parts of the codebase it touches]

   ### Phase 2: [Name]
   [1-3 sentences: what this phase accomplishes, how it builds on Phase 1]
   ```

   Add a note in the template that `## Phases` is only included when the heuristic triggers.

**Integration points:**
- The `## Phases` heading is the exact string the devline orchestrator will search for to detect multi-phase mode. The heading must be exactly `## Phases` (H2).
- Each phase subsection must use `### Phase N: [Name]` format (H3 with the number).

**Test Cases:**
1. [manual] Brainstorm skill includes phase detection heuristic section in its process flow
2. [manual] Brainstorm template shows `## Phases` as optional section with correct format
3. [manual] Backward compatibility preserved -- template clearly states phases section is omitted for small scope

**Acceptance Criteria:**
- [ ] Phase detection heuristic is documented in the brainstorm skill's process, between clarification and writing
- [ ] `## Phases` section format is defined in the brainstorm.md template with correct heading levels
- [ ] The template explicitly marks `## Phases` as conditional/optional
- [ ] No changes to the rest of the brainstorm format or process

---

### Task 2: Update planner agent and plan format for phase-scoped planning
**Agent:** implementer
**Model:** sonnet
**UI:** no
**Files owned:** `agents/planner.md`, `agents/references/plan-format.md`

**Context:**

The planner currently reads a single brainstorm.md and produces a single plan.md. In multi-phase mode, the planner must be aware that it is planning for one specific phase of a larger feature. It needs to read prior phase plan files for context (what was already planned and implemented), scope its plan to only the current phase's work, and write to a phase-specific plan file. The planner's instructions must handle this without breaking single-phase (non-phase) planning.

**Spec:**

**`agents/planner.md` changes:**

Add a new subsection to "1. Deep Codebase Analysis" (after the existing mandatory reads) covering multi-phase context:

- When the planner receives a `phase` parameter (passed by the orchestrator), it is planning for that specific phase only
- Read all prior phase plan files (`plan-phase-1.md` through `plan-phase-{N-1}.md`) to understand what was already planned and implemented
- Scope the plan to only the current phase's work as described in the brainstorm's `## Phases` section
- The codebase already contains all prior phases' merged code -- use it as ground truth, not the prior plans' specs
- Do not re-plan or modify work from prior phases

Add a note to "7. Write Plan to Disk" that when operating in phase mode, the output file is `.devline/plan-phase-N.md` (where N is provided by the orchestrator), not `.devline/plan.md`.

**`agents/references/plan-format.md` changes:**

Add a `**Phase:**` header to the plan file format, after `**Status:**`:
```
**Phase:** [N of M — or "single" for non-phased plans]
```

This is informational -- it helps the orchestrator and recovery protocol identify which phase a plan belongs to.

**Edge cases:**
- Phase 1 planner has no prior plans to read -- this is the normal case, equivalent to today's single-plan mode except the scope is limited to Phase 1
- The planner must not assume prior phase code is exactly as the prior plan specified -- it may have been modified during review cycles

**Test Cases:**
1. [manual] Planner agent includes multi-phase context section in its analysis process
2. [manual] Plan format reference includes `**Phase:**` header field
3. [manual] Planner instructions are backward compatible -- single-phase planning is unchanged when no phase parameter is given

**Acceptance Criteria:**
- [ ] Planner's mandatory reads section covers prior phase plan files when in phase mode
- [ ] Planner scopes its plan to the current phase only
- [ ] Output file path is `plan-phase-N.md` when in phase mode, `plan.md` otherwise
- [ ] Plan format includes `**Phase:**` metadata header
- [ ] Single-phase planning path is completely unchanged

---

### Task 3: Add multi-phase orchestration loop to devline orchestrator
**Agent:** implementer
**Model:** opus
**UI:** no
**Files owned:** `skills/devline/SKILL.md`

**Context:**

This is the core of the feature. The devline orchestrator currently runs a linear pipeline: brainstorm, plan, implement, docs, deep review, done. For multi-phase support, the orchestrator needs to detect when brainstorm.md contains a `## Phases` section and, if so, loop through each phase sequentially -- running a full plan-implement-review-merge cycle for each phase before proceeding to the next. Documentation and deep review run once at the end across all phases. The orchestrator must also update state tracking, progress display, cleanup, and recovery to handle multi-phase state.

This task depends on Task 1 (brainstorm format) and Task 2 (planner format) because it references the exact heading format (`## Phases`) from Task 1 and passes the phase parameter/plan file path from Task 2.

**Spec:**

**Stage 2 modification -- multi-phase detection and loop:**

After Stage 1 (brainstorm approval), before launching the planner, add phase detection:

1. Read approved brainstorm.md and check for `## Phases` heading
2. If no `## Phases` section: proceed exactly as today (single plan.md, single implement cycle) -- this is the backward-compatible path
3. If `## Phases` section exists: count the phases (by counting `### Phase N:` headings), then enter the multi-phase loop:

**Multi-phase loop (for each phase N from 1 to total_phases):**

a. **Plan phase N:** Launch planner in foreground, passing:
   - The full brainstorm.md
   - The current phase number and total phases
   - Paths to all prior phase plan files (`.devline/plan-phase-1.md` through `.devline/plan-phase-{N-1}.md`)
   - Instruction to write output to `.devline/plan-phase-N.md`

   Handle the interactive NEEDS_INPUT loop identically to today's Stage 2.

b. **Approve phase N plan:** Same approval gate as today's Stage 2 (`auto_approve_plan` config respected).

c. **Implement phase N:** Run Stage 3 (implement) using `.devline/plan-phase-N.md` as the plan file instead of `.devline/plan.md`. All existing Stage 3 behavior (wave barriers, reviews, fix cycles, deferred findings batch fix) applies identically -- the only difference is which plan file is read. Stage 3.5 (deferred findings batch fix) runs at the end of each phase, not just at the end of all phases.

d. **Advance:** After all waves of phase N are complete (including deferred findings batch fix), proceed to phase N+1.

**Progress tracking updates:**

When in multi-phase mode, the initial task list should include phase-level grouping. Before each phase's implement cycle, create tasks for that phase's plan. The task creation pattern for multi-phase:

- "Phase N: Plan" (one per phase)
- "Phase N: Implement" (one per phase, contains sub-tasks from that phase's plan)
- "Documentation" (once, at end)
- "Deep Review" (once, at end)

**State tracking updates (`state.md` schema):**

Add to the `## Pipeline State` section:
```markdown
- **Phase:** N/M (or "single" for non-phased pipelines)
- **Phase name:** [name from brainstorm]
```

On phase transitions, update these fields. Reset the `## Task Progress` table for the new phase's tasks. Prior phase task progress is not preserved in state.md (it can be reconstructed from plan files and git history if needed).

**Recovery protocol updates:**

Add to the recovery protocol (after step 1, reading state.md):
- If state.md contains `Phase: N/M`, this is a multi-phase pipeline
- Check which plan-phase files exist on disk (`.devline/plan-phase-*.md`) to determine which phases are complete
- A phase is complete if its plan file exists AND all its tasks are merged (check git log for `task-N:` commits matching the plan's task list)
- Resume from the current phase -- if mid-implement, resume Stage 3; if between phases, start the next phase's planning

**Cleanup updates:**

Add to the exit cleanup artifact deletion list:
```bash
.devline/plan-phase-*.md
```

This globs all phase plan files. The existing `.devline/plan.md` cleanup remains for single-phase pipelines.

**Stale artifact check updates (Stage 0):**

When checking for stale artifacts, also check for `plan-phase-*.md` files alongside `plan.md`.

**Integration points:**
- Phase detection key: `## Phases` heading (H2) in brainstorm.md -- exact match from Task 1
- Phase plan file naming: `plan-phase-N.md` -- matches Task 2's planner output path
- `**Phase:**` header in plan files -- matches Task 2's format addition
- Stage 3 already parameterized to read "the plan" -- this task changes which file that refers to
- Stage 4 (docs) and Stage 5 (deep review) are unchanged -- they run once at the end, covering all phases

**Edge cases:**
- Single phase in `## Phases` section: treat as multi-phase (write `plan-phase-1.md`), even though it is functionally equivalent to single-plan mode. This avoids special-casing.
- User rejects a phase plan: same behavior as today -- planner iterates. User can also choose "Stop here" to halt the pipeline mid-feature.
- Phase N implementation fails (unrecoverable): user can stop the pipeline. Already-implemented phases are committed to the branch.

**Test Cases:**
1. [manual] No `## Phases` in brainstorm.md -- pipeline runs identically to current behavior
2. [manual] `## Phases` with 3 phases -- orchestrator loops through plan-implement for each
3. [manual] Phase plan files named correctly (`plan-phase-1.md`, etc.)
4. [manual] State.md includes phase tracking fields
5. [manual] Recovery protocol handles mid-phase resume
6. [manual] Cleanup deletes all `plan-phase-*.md` files

**Acceptance Criteria:**
- [ ] Orchestrator detects `## Phases` heading in brainstorm.md
- [ ] Multi-phase loop runs plan-approve-implement sequentially for each phase
- [ ] Each phase's planner receives all prior plan files as context
- [ ] Stage 3 uses the correct phase-specific plan file
- [ ] Stages 4 and 5 run once at the end, not per-phase
- [ ] Stage 3.5 (deferred findings) runs at the end of each phase
- [ ] State.md tracks current phase number
- [ ] Recovery protocol reconstructs multi-phase state
- [ ] Exit cleanup includes phase plan files
- [ ] Backward compatible -- no `## Phases` means unchanged behavior
- [ ] Progress tracking reflects phase structure

---

### Task 4: Update plan skill and implement skill for phase-aware invocation
**Agent:** implementer
**Model:** sonnet
**UI:** no
**Files owned:** `skills/plan/SKILL.md`, `skills/implement/SKILL.md`

**Context:**

The plan and implement skills are user-invocable entry points that can be used independently of the full devline pipeline (e.g., `/plan`, `/implement`). They need minor updates to handle phase-specific plan files so they work correctly when invoked during a multi-phase pipeline or when a user wants to manually run a phase's plan/implementation.

**Spec:**

**`skills/plan/SKILL.md` changes:**

Add a note that when the orchestrator passes phase context (phase number, prior plan file paths), the planner should be launched with that context. The plan skill's interactive loop (NEEDS_INPUT handling) is unchanged. Add a note that the output file will be `plan-phase-N.md` when in phase mode.

**`skills/implement/SKILL.md` changes:**

Update the "With a Plan" section to note that the plan file may be either `.devline/plan.md` (single-phase) or `.devline/plan-phase-N.md` (multi-phase). The implement skill should accept a plan file path parameter. All other behavior (wave execution, worktree isolation, review loop) is unchanged -- it operates on whichever plan file it is given.

Update the validation step ("Validate the plan first") to handle both `plan.md` and `plan-phase-N.md` file names.

**Edge cases:**
- User runs `/implement` without specifying a plan file: default to `.devline/plan.md` (existing behavior)
- User runs `/implement` with a phase plan file: use that file

**Test Cases:**
1. [manual] Plan skill documents phase context passing
2. [manual] Implement skill accepts phase-specific plan file path
3. [manual] Default behavior (no phase context) unchanged for both skills

**Acceptance Criteria:**
- [ ] Plan skill documents how phase context is passed to the planner
- [ ] Implement skill accepts and validates phase-specific plan file paths
- [ ] Default behavior preserved for non-phase invocations

## Feature-Goal Tests

### 1. Backward compatibility -- single-phase pipeline
**Type:** manual / integration
**Trigger:** User starts devline with a small-scope feature that produces no `## Phases` in brainstorm.md
**Expected result:** Pipeline runs identically to pre-feature behavior: single `plan.md`, single implement cycle, docs, deep review
**Verification:** No `plan-phase-*.md` files created, state.md has no `Phase:` field or shows `Phase: single`
**Assigned to:** Task 3

### 2. Multi-phase end-to-end flow
**Type:** manual / integration
**Trigger:** User starts devline with a large-scope feature; brainstormer outputs 3 phases
**Expected result:** Orchestrator runs 3 sequential plan-implement cycles, each producing `plan-phase-N.md`, then runs docs and deep review once
**Verification:** Three plan files exist, git log shows task commits from all three phases, docs and deep review run once at the end
**Assigned to:** Task 3

### 3. Phase context chain
**Type:** manual / integration
**Trigger:** Phase 2 planner is launched during a multi-phase pipeline
**Expected result:** Planner receives brainstorm.md + plan-phase-1.md as context, and can see Phase 1's merged code in the codebase
**Verification:** Phase 2's plan references or builds upon Phase 1's work without re-planning it
**Assigned to:** Task 3

## Documentation Updates

### 1. `agents/references/plan-format.md`
**Type:** format spec
**What to update:** Already handled by Task 2 -- `**Phase:**` header addition
**Driven by:** Task 2

None additional identified. This is an internal pipeline feature with no user-facing API or external documentation. The changes are self-documenting within the skill and agent definition files.
