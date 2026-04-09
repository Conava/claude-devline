# Plan File Format — `.devline/plan.md`

```markdown
# Implementation Plan: [Feature Name]

**Branch:** [current git branch name]
**Created:** [ISO 8601 date]
**Status:** active
**Phase:** [N of M — or "single" for non-phased plans]

## Architecture Overview
[High-level design: components, data flow, key abstractions. Component diagram if helpful.]

## Design Decisions
| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| ... | ... | ... | ... |

## Dependency Graph

This is the SINGLE SOURCE OF TRUTH for task ordering. Everything about which tasks run when, what depends on what, and which tasks can parallelize is defined here and ONLY here.

Wave 1: [Task 1], [Task 2], [Task 3]
Wave 2: [Task 4] (← 1, 2), [Task 5] (← 3)
Wave 3: [Task 6] (← 4, 5)

Rules enforced by the orchestrator:
- All tasks in a wave run in parallel in isolated worktrees
- A wave starts ONLY after every task in the previous wave is done (implemented + reviewed + merged)
- The `←` notation lists which earlier tasks this task depends on (must be from a prior wave)
- Tasks within the same wave have ZERO dependencies on each other — no shared files, no type references, no logical ordering

## Tasks

### Task 1: [Name]
**Agent:** [implementer / devops / debugger]
**Model:** [sonnet (default) / opus — use opus for tasks requiring complex architectural reasoning, large refactors, or tricky logic]
**UI:** [yes / no]
**Files owned:** [exact list of files this task creates/modifies]

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

## Feature E2E Task

The final wave MUST include a dedicated E2E test task. This task writes no implementation code — only end-to-end tests that verify the feature works as a whole, including interactions with pre-existing code.

### Task N: Feature E2E Tests
**Agent:** implementer
**Model:** sonnet
**UI:** no
**Files owned:** [E2E test files only]

**Context:**

End-to-end verification of the complete feature. These tests exercise the full stack — from user entry point through all layers to observable outcomes — and naturally cover pre-existing code paths that the feature builds on.

**Spec:**

[Describe the E2E test infrastructure to use (Testcontainers, Playwright, supertest, etc.) and any test utilities to leverage from the existing test suite.]

**Test Cases:**
1. [e2e] [User journey name] — [entry point] → [steps through the system] → [observable outcome]. Pre-existing paths exercised: [list which existing code this journey touches]
2. [e2e] [User journey name] — ...
3. [e2e] [Critical error path] — [trigger] → [expected error handling across the stack]

**Acceptance Criteria:**
- [ ] All E2E tests pass against real infrastructure (no mocks except external services)
- [ ] Each test creates and cleans up its own data
- [ ] Pre-existing code paths are exercised (not just new code)

```
