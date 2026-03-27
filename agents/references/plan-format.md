# Plan File Format — `.devline/plan.md`

```markdown
# Implementation Plan: [Feature Name]

**Branch:** [current git branch name]
**Created:** [ISO 8601 date]
**Status:** active

## Architecture Overview
[High-level design: components, data flow, key abstractions. Component diagram if helpful.]

## Design Decisions
| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| ... | ... | ... | ... |

## Tasks

### Task 1: [Name]
**Wave:** [1 / 2 / 3 / ...]
**Agent:** [implementer / devops / debugger]
**Model:** [sonnet (default) / opus — use opus for tasks requiring complex architectural reasoning, large refactors, or tricky logic]
**UI:** [yes / no]
**Files owned:** [exact list of files this task creates/modifies]
**Depends on:** [none / Task N, Task M]

**Context:**

[Why this task exists. What problem it solves, what requirement it fulfills, what was wrong or missing before. The implementer needs to understand the motivation to make good judgment calls during implementation. Include references to specs, articles, regulations, or prior decisions where relevant.]

**Spec:**

[What this task produces and the constraints it must satisfy. Focus on the **what** and the **boundaries** — not step-by-step implementation instructions. The implementer is a capable engineer; give them the goal, the interface contracts, and the edge cases, then let them figure out the implementation.]

- **Interface contracts:** signatures, types, return types for public APIs this task creates or modifies
- **Behavior:** what the code must do, described in terms of inputs → outputs, not implementation steps
- **Edge cases and errors:** what can go wrong and how each case should be handled
- **Integration points:** what existing code this connects to — method calls, event names, expected listeners. The reviewer verifies these.
- **Constraints:** platform limitations, framework quirks, performance requirements, conventions to follow (reference existing patterns in the codebase)

For UI tasks, additionally specify:
- Component hierarchy and props
- State management (what state, where it lives, how it updates)
- Design system tokens to use (from `.devline/design-system.md`)

**Test Cases:**
1. [unit] [Test name] — [exact input → expected output/behavior]
2. [unit] [Test name] — [exact input → expected output/behavior]
3. [integration] [Test name] — [setup → action → expected result]

**Acceptance Criteria:**
- [ ] [Criterion — verifiable, not vague]

### Task 2: [Name]
...

## Feature-Goal Tests
[Tests proving the feature works end-to-end, assigned to the last task in the dependency chain or a dedicated integration test task.]

### 1. [Test name]
**Type:** [integration / e2e]
**Trigger:** [What initiates the behavior]
**Expected result:** [The observable output]
**Verification:** [How the test asserts this]
**Assigned to:** Task N

## Dependency Graph
Wave 1: [Task 1], [Task 2], [Task 3]
Wave 2: [Task 4] (← 1, 2)
Wave 3: [Task 5] (← 3, 4)
```
