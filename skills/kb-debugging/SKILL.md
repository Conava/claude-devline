---
name: kb-debugging
description: Domain logic for systematic debugging — injected into the debugger agent. Provides scientific debugging methodology (reproduce, gather evidence, hypothesize, test, fix, verify). Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Debugging Methodology

Systematic approach to finding and fixing bugs using the scientific method. Every debugging session follows: Reproduce → Gather Evidence → Hypothesize → Test → Fix → Verify.

## The Scientific Debugging Process

### Step 1: Reproduce

Before anything else, reproduce the bug reliably:

1. Get the exact steps, inputs, or conditions that trigger the bug
2. Reproduce it locally — if not reproducible, gather more context
3. Identify the minimum reproduction case (smallest input/steps that trigger it)
4. Document the reproduction steps for later verification

If the bug is intermittent, look for:
- Race conditions (timing-dependent)
- State-dependent behavior (order of operations)
- Environment differences (config, data, versions)
- Resource limits (memory, connections, file handles)

### Step 2: Gather Evidence

Collect all available information before forming hypotheses:

- **Error messages and stack traces** — Read them carefully, they often point directly to the issue
- **Logs** — Check application logs, system logs, build logs around the time of the error
- **Git history** — When did this last work? What changed? Use `git log --oneline -20` for recent changes, `git diff` to see uncommitted changes, and `git bisect` to binary-search for the exact commit that introduced the bug. Git bisect is often the fastest path to root cause when the bug is a regression.
- **State inspection** — Current values of variables, database records, config
- **Environment** — Versions, dependencies, OS, runtime configuration

### Step 3: Hypothesize

Form specific, testable hypotheses about the root cause:

- "The null pointer is because X is not initialized when Y calls it"
- "The timeout happens because the connection pool is exhausted by Z"
- "The wrong output is because the sort is unstable and input order matters"

Rank hypotheses by:
1. How well they explain ALL symptoms
2. How likely they are given the evidence
3. How easy they are to test

### Step 4: Test Hypotheses

Test each hypothesis systematically, starting with the most likely:

1. Design a test that would confirm OR refute the hypothesis
2. Add targeted logging, assertions, or breakpoints
3. Run the reproduction case
4. Analyze results — does the evidence support or refute?
5. If refuted, move to next hypothesis. If confirmed, proceed to fix.

Never skip straight to fixing without confirming the hypothesis. A fix based on a wrong hypothesis creates new bugs.

### Step 5: Fix

Once the root cause is confirmed:

1. Write a test that fails with the bug and passes with the fix
2. Implement the minimal fix for the root cause
3. Run the failing test — confirm it passes
4. Run the full test suite — confirm nothing else broke
5. Remove any debugging code (extra logging, temporary assertions)

### Step 6: Verify

After the fix:

1. Re-run the original reproduction steps — confirm the bug is gone
2. Check related areas for similar bugs (same pattern elsewhere?)
3. Consider if the bug class can be prevented (linting rules, type constraints, validation)
4. Document what was learned if the root cause was non-obvious

## Common Bug Patterns

### Off-by-One Errors
- Check loop boundaries, array indices, fence-post conditions
- Look for `<` vs `<=`, `i` vs `i+1`

### Null/Undefined References
- Trace the variable back to its origin
- Check all paths — is there a code path where it's never assigned?
- Look for async gaps where state can change

### Race Conditions
- Look for shared mutable state accessed from multiple threads/goroutines/processes
- Check for missing locks, atomic operations, or synchronization
- Add ordering guarantees or make state immutable

### State Management
- Check if state is being mutated where it shouldn't be
- Look for stale closures, cached values, or shallow copies
- Verify state transitions are valid

### Integration Issues
- Check API contracts — is the caller sending what the callee expects?
- Verify serialization/deserialization (JSON types, date formats, encoding)
- Check network timeouts, retries, and error handling

## Debugging Tools

Use language-appropriate debugging tools:

- **Logging** — Add targeted, temporary log statements at key decision points
- **Debugger** — Set breakpoints at suspicious locations, inspect state
- **Git bisect** — Find the exact commit that introduced the bug
- **Profiler** — For performance bugs, identify bottlenecks
- **Network tools** — For API issues, inspect request/response payloads

Use the find-docs skill (`npx ctx7@latest`) for current documentation on debugging tools and error messages.

## Additional Resources

### Reference Files

For language-specific debugging techniques:

- **`references/debugging-tools.md`** — Language-specific debuggers, profilers, and diagnostic tools
- **`references/common-errors.md`** — Common error patterns by language and framework
