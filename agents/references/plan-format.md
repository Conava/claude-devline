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
**Agent:** [implementer / devops]
**UI:** [yes / no]
**Files owned:** [exact list of files this task creates/modifies]
**Depends on:** [none / Task N, Task M]

**Spec:**

[The precise specification of what this task produces. This is the core of the plan — it must be detailed enough that the implementer makes zero design decisions.]

For each function/class/endpoint/component this task creates or modifies, specify:
- **Signature:** name, parameters with types, return type
- **Behavior:** what it does, step by step
- **Inputs:** valid ranges, formats, constraints
- **Outputs:** exact shape of return values, response bodies, emitted events
- **Errors:** what can go wrong and exactly how to handle each case (throw, return error, log, retry)
- **Integration points:** exact method calls, event names, and expected listeners that connect this code to the rest of the system. The reviewer verifies these line-by-line.
- **Constraints:** platform limitations, framework quirks, performance requirements

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
[Task 1] ──┐
            ├──→ [Task 4] ──→ [Task 5]
[Task 2] ──┘
[Task 3] ──────────────────→ [Task 5]
```
