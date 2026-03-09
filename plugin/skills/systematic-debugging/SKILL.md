---
name: systematic-debugging
description: "Use when encountering any bug, test failure, or unexpected behavior — before proposing fixes. Also use as a standalone entry point for bug-fixing tasks without the full pipeline."
argument-hint: "[bug description or error message]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Agent, Read, Write, Edit, Bash, Grep, Glob
---

# Systematic Debugging

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

### Automatic (pipeline integration)

This skill is invoked automatically by the pipeline when a task fails its first normal retry in Stage 3. The pipeline spawns the **debugger agent** (opus) instead of re-spawning the implementer. The flow is:

1. Implementer completes task → Reviewer returns FAIL
2. **Normal retry**: Re-spawn implementer with reviewer feedback
3. If still FAIL → **Systematic debugging attempt 1**: Spawn the **debugger agent** with the task context, reviewer feedback history, and the implementer's prior work. The debugger follows the four phases below.
4. If still FAIL → **Systematic debugging attempt 2**: Spawn the debugger again with cumulative evidence from attempt 1. It must build on prior investigation, not restart from scratch.
5. If still FAIL → **Escalate**: Stop parallel agents, spawn planner with `debug_plan` context including all debugging evidence.

### Standalone (bug fixing without the pipeline)

When the user asks to fix a specific bug, diagnose an issue, or investigate unexpected behavior — and does NOT need the full brainstorm→plan→implement pipeline — use this skill directly:

1. **Skip brainstorm and plan.** The bug IS the spec. The fix IS the plan.
2. **Branch safety**: If on a protected branch, create a fix branch (e.g., `fix/descriptive-slug`).
3. **Spawn the debugger agent** with the bug description, error messages, and any reproduction steps the user provided.
4. **Spawn the verifier agent** after the debugger returns to confirm tests/build pass.
5. **Report results** and offer merge/PR options.

This replaces brainstorm+planner for bug-fixing tasks because a bug doesn't need a design — it needs diagnosis. The debugger agent uses opus for deeper reasoning about complex root causes.

### Bug-fix planning (planner integration)

When the planner receives a task that is a bug fix (not a new feature), it should:

1. **Small bugs** (single component, clear reproduction): Create a single task with `test_approach: tdd` that references this skill. The implementer loads the systematic-debugging skill and follows the four phases within one task.
2. **Medium bugs** (cross-component, intermittent): Create a 2-3 task debug plan:
   - Task 1: Root cause investigation (uses debugger agent)
   - Task 2: Fix implementation with regression test (uses implementer)
   - Task 3: Verification (uses verifier)
3. **Large bugs** (architectural, systemic): The planner should flag this as needing brainstorm first — the bug may indicate a design problem that needs redesign before fixing.

## The Four Phases

Complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings — they often contain the exact solution
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably? What are the exact steps?
   - If not reproducible → gather more data, don't guess

3. **Check Recent Changes**
   - `git diff`, recent commits, new dependencies, config changes
   - Environmental differences between working and broken state

4. **Gather Evidence in Multi-Component Systems**

   When the system has multiple components (CI → build → signing, API → service → database):

   ```
   For EACH component boundary:
     - Log what data enters the component
     - Log what data exits the component
     - Verify environment/config propagation
     - Check state at each layer

   Run once to gather evidence showing WHERE it breaks
   THEN analyze evidence to identify the failing component
   THEN investigate that specific component
   ```

5. **Trace Data Flow**
   - Where does the bad value originate?
   - What called this function with the bad value?
   - Keep tracing backward until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

1. **Find Working Examples** — Locate similar working code in the same codebase
2. **Compare Against References** — If implementing a pattern, read the reference implementation COMPLETELY
3. **Identify Differences** — List every difference between working and broken, however small
4. **Understand Dependencies** — What components, settings, config, and assumptions are involved?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** — "I think X is the root cause because Y" — be specific
2. **Test Minimally** — Smallest possible change, one variable at a time
3. **Verify Before Continuing**
   - Worked → Phase 4
   - Didn't work → Form NEW hypothesis, don't add more fixes on top
4. **When You Don't Know** — Say so. Don't pretend. Research more or ask for help.

### Phase 4: Implementation

1. **Create Failing Test Case** — Simplest possible reproduction. Automated test if possible. MUST exist before fixing.
2. **Implement Single Fix** — Address the root cause. ONE change at a time. No "while I'm here" improvements.
3. **Verify Fix** — Test passes? No other tests broken? Issue actually resolved?
4. **If Fix Doesn't Work**
   - Count: How many fixes have you tried?
   - If < 3: Return to Phase 1, re-analyze with new information
   - If >= 3: STOP — question the architecture (see below)
   - DON'T attempt fix #4 without architectural discussion

5. **If 3+ Fixes Failed: Question Architecture**

   Pattern indicating architectural problem:
   - Each fix reveals new shared state / coupling / problems in different places
   - Fixes require "massive refactoring" to implement
   - Each fix creates new symptoms elsewhere

   **STOP and question fundamentals.** Is this pattern sound? Are we sticking with it through inertia? Discuss with the user before attempting more fixes.

## Red Flags — STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)
- Each fix reveals new problems in different places

**ALL of these mean: STOP. Return to Phase 1.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question the pattern. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## Supporting Techniques

### Defense in Depth

After finding and fixing the root cause, validate at EVERY layer to prevent recurrence:

- **Entry point**: Validate inputs at the system boundary
- **Business logic**: Assert invariants where data is used
- **Environment guards**: Verify external dependencies are available
- **Debug instrumentation**: Add logging that would have caught this bug earlier

### Condition-Based Waiting (for flaky tests)

Replace arbitrary timeouts with condition polling:

```typescript
// BAD: arbitrary timeout
await new Promise(resolve => setTimeout(resolve, 2000));

// GOOD: wait for actual condition
async function waitFor(condition: () => boolean, timeout = 5000, interval = 50) {
  const start = Date.now();
  while (!condition()) {
    if (Date.now() - start > timeout) throw new Error('Timed out');
    await new Promise(r => setTimeout(r, interval));
  }
}
```

### Root Cause Tracing

Trace bugs backward through the call stack to find the original trigger:

1. Start at the error — what value is wrong?
2. Where did that value come from? Read the caller.
3. What called THAT with the wrong input? Read its caller.
4. Continue until you find the first place the data went wrong.
5. Fix at the source, not where it crashes.

Use `git bisect` for regressions — find the exact commit that introduced the bug.
