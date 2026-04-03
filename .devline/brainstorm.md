# Brainstorm: Multi-Phase Pipeline Orchestration

**Created:** 2026-03-28

## What We're Building
A mechanism for the devline pipeline to automatically split large-scope changes into multiple sequential phases, each with its own planner and plan. This distributes cognitive load across multiple planning passes so each planner produces thorough, well-analyzed plans rather than one planner struggling with an overwhelming scope.

## Architecture Impact
- **Frontend:** no
- **Backend:** no — this is a prompt/agent architecture change
- **Database:** no
- **Infrastructure:** no

## UI Impact
- **UI touched:** no
- **Platform:** CLI (Claude Code)

## Core Concept

**Current flow (single-plan):**
```
Brainstorm → Plan → Implement (waves) → Review → Merge
```

**New flow (multi-phase):**
```
Brainstorm (with phases) → [Phase 1: Plan → Implement → Review → Merge]
                         → [Phase 2: Plan (with Phase 1 context) → Implement → Review → Merge]
                         → [Phase N: Plan (with Phase 1..N-1 context) → ...]
                         → Deep Review → Done
```

Each phase runs a full pipeline cycle (plan → implement → review → merge) sequentially on the **same feature branch**. Phases always execute in order — no parallel phase execution.

## How It Works

### 1. Brainstormer Detects Scope & Outputs Phases

The brainstormer evaluates scope using a **size/impact heuristic**:
- How many systems/modules are touched?
- How deep are the changes (surface config vs. core logic)?
- How many architectural boundaries are crossed?
- Would a single plan exceed ~8-10 tasks?

When the heuristic triggers, brainstorm.md includes a `## Phases` section:

```markdown
## Phases

### Phase 1: [Name]
[What this phase accomplishes, which parts of the codebase it touches]

### Phase 2: [Name]
[What this phase accomplishes, builds on Phase 1 by...]

### Phase 3: [Name]
[...]
```

For small/medium scopes, no phases section — pipeline works exactly as today (backward compatible).

### 2. Devline Orchestrator Detects Phases

The orchestrator reads brainstorm.md after approval. If a `## Phases` section exists:
- Switch to multi-phase mode
- Loop through phases sequentially
- Each phase gets its own planner agent and plan file (`plan-phase-1.md`, `plan-phase-2.md`, etc.)

### 3. Sequential Phase Execution

For each phase:
1. **Plan:** Launch planner with brainstorm.md (full doc) + all prior plan files as context. Planner focuses on the current phase's scope but understands what came before.
2. **Approve:** User approves the phase plan (same approval gate as today).
3. **Implement:** Run the standard wave-based implementation pipeline for this phase's plan.
4. **Review:** Per-task reviews as normal.
5. **Merge:** All tasks for this phase merge to the feature branch.
6. **Proceed:** Move to next phase.

### 4. Context Chain

Each planner receives:
- The full brainstorm.md (including all phases)
- All prior phase plan files (plan-phase-1.md, plan-phase-2.md, ...)
- The current state of the codebase (which now includes all prior phases' merged code)

This means Phase 2's planner sees Phase 1's plan AND its actual implementation, enabling it to plan accurately against real code rather than assumptions.

### 5. Completion

After all phases complete:
- Documentation stage runs once (covering all phases)
- Deep review runs once (covering the full feature branch diff)
- Single feature branch, ready for PR

## Scope

### In Scope
- Size/impact heuristic in the brainstormer for phase detection
- Phase output format in brainstorm.md
- Multi-phase orchestration loop in the devline skill
- Per-phase plan file naming (plan-phase-N.md)
- Context passing between phase planners
- Per-phase user approval gates
- State tracking for multi-phase progress

### Out of Scope
- Parallel phase execution (explicitly excluded — too complex)
- Separate branches per phase (single branch for the whole operation)
- Automatic phase count determination by a separate agent (brainstormer handles it)
- Changes to the implementer, reviewer, or deep-review agents (they work per-plan as today)

## Key Decisions
- **Brainstormer owns phase splitting** — no separate phase-splitter agent
- **Always sequential** — phases never execute in parallel, avoiding merge complexity
- **Single branch** — all phases commit to one feature branch, one PR at the end
- **Motivation is planner throughput** — the goal is distributing planning load, not parallelizing execution
- **Backward compatible** — small scopes produce no phases section, pipeline unchanged

## Open Questions for Planner
- Exact heuristic thresholds for phase detection (task count? module count? both?)
- Whether the user should be able to override phase boundaries after brainstorm (e.g., merge two phases, split one further)
- How state.md tracks multi-phase progress (new fields? or one state.md per phase?)
- Whether to show a phase progress summary between phases
