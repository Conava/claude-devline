# Plan File Format — `.devline/plan.md`

```markdown
# Implementation Plan: [Feature Name]

**Branch:** [current git branch name]
**Created:** [ISO 8601 date, e.g. 2026-03-13]
**Status:** active

## Architecture Overview
[High-level design, component diagram if helpful]

## Design Decisions
| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| ... | ... | ... | ... |

## Tasks

### Task 1: [Name]
**Agent:** [implementer / devops — use devops for build, CI/CD, Docker, infra, tooling work]
**UI:** [yes / no — set to yes if this task creates or modifies UI files. Include design system references in the task description.]
**Files owned:** [list of files this task creates/modifies]
**Depends on:** [none / Task N, Task M]

**Test Cases:**
1. [unit] [Test name] — [what it verifies]
2. [integration] [Test name] — [what it verifies across components]

**Implementation Steps:**
[Describe WHAT to achieve and WHY, not HOW to code it. The implementer is an engineer —
give behavioral contracts, not code dictation.]
1. [Behavioral step — what this achieves]
2. [Behavioral step — what this achieves]

**Integration Contracts:**
[How this code connects to the rest of the system. Be specific — the reviewer verifies each line-by-line:]
- [Exact notification/event: "`GameManager` must call `notifyObservers(GameEvent.CODE_CONSUMED)` after removing a code"]
- [Exact lifecycle hook: "`NewPanel` must register with `LifecycleManager.register()` in constructor and call `dispose()` in `onClose()`"]
- [Exact state propagation: "When `config.theme` changes, `ThemeService.applyTheme()` must trigger CSS variable updates"]
- [Exact sync requirement: "`SessionStore.remove()` must use atomic `ConcurrentHashMap.remove(key)` that returns the value"]

**Platform Constraints:**
[APIs, CSS properties, or framework features to use carefully. Leave empty if none.]
- [e.g., "JavaFX CSS uses `derive()` or hex — no `rgba()`"]
- [e.g., "Target browsers include Safari 14 — use `Array.at()` polyfill or alternative"]

**Acceptance Criteria:**
- [ ] [Criterion from feature spec this task addresses]

**Review Checklist:**
[High-risk verification points for the reviewer]
- [ ] [e.g., "Observer notification fires after state change, not before"]
- [ ] [e.g., "New endpoint has auth middleware — check route registration"]

### Task 2: [Name]
...

## Feature-Goal Tests
[Tests proving the feature works as a whole, not just individual pieces]

### 1. [Test name] — [which goal/acceptance criterion this proves]
**Type:** [integration / e2e / UI]
**Trigger:** [What initiates the behavior]
**Expected result:** [The observable output]
**Verification method:** [How the test asserts this]
**Assigned to:** Task N

## Dependency Graph
[Task 1] ──┐
            ├──→ [Task 4] ──→ [Task 5]
[Task 2] ──┘
[Task 3] ──────────────────→ [Task 5]

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| ... | ... | ... |

## Integration Testing
[Cross-task integration tests verifying interactions with real dependencies.
If integration tests span multiple tasks, define a dedicated integration test task.]

## E2E Testing
[Critical user journeys to verify end-to-end. 5-15 tests covering highest-value paths.]
```
