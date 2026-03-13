---
name: dl-tdd-workflow
description: Domain logic for TDD methodology — injected into agents that implement code using test-driven development. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# TDD Workflow

Guidance for test-driven development across all languages and frameworks. TDD produces better-designed, more maintainable code by writing tests before implementation.

## Core Cycle: Red-Green-Refactor

1. **Red** — Write a failing test that defines expected behavior
2. **Green** — Write the code to make the test pass
3. **Refactor** — Improve code structure while keeping tests green

Never skip steps. Never write implementation before a failing test exists.

**For planners:** Define all test cases upfront as part of the plan — the implementer needs them to know what to build. Include unit, integration, and E2E test cases as appropriate (see Test Granularity below).
**For implementers:** Do NOT write all tests at once. Implement them one at a time through the cycle. Each test drives the next increment of design — that's what makes TDD powerful.

## Implementation Strategy

Kent Beck defines three ways to make a failing test pass. Choose based on confidence, not ritual:

- **Obvious Implementation (default):** When the solution is clear, write the real implementation directly. There is no value in pretending not to know the answer.
- **Fake It:** Return a hardcoded value, then gradually generalize. Use this when the problem is genuinely complex, the requirements are ambiguous, or you keep hitting unexpected failures. Small steps help validate assumptions.
- **Triangulation:** Only generalize when two or more concrete test cases force it. Useful when the correct abstraction isn't obvious yet.

The key insight: hardcoded values and baby steps exist to build understanding incrementally. An agent that already knows the algorithm gains nothing from faking — but the test-first discipline and incremental verification remain non-negotiable.

**In practice:** Use Obvious Implementation by default. Fall back to Fake It when working on genuinely uncertain problems, unfamiliar codebases where small steps validate assumptions about existing behavior, or intricate interactions where incremental verification catches integration bugs early.

## Test-First Process

### Step 1: Analyze Requirements

Break the feature into discrete, testable behaviors. Each behavior becomes one test case. Order test cases from simplest to most complex — start with degenerate/base cases, then add complexity. This ordering (inspired by the Transformation Priority Premise) produces cleaner incremental development regardless of implementation strategy.

### Step 2: Write ONE Failing Test

Start with the simplest behavior. Write a single test (or a tightly related pair) that:
- Has a clear, descriptive name stating expected behavior
- Arranges minimal preconditions
- Acts on the unit under test
- Asserts one specific outcome

Run the test. Confirm it fails for the right reason (not a syntax error or import issue).

**Do NOT write the next test yet.** The whole point is that each test drives the next design decision.

### Step 3: Make It Pass

Write the code to make the test pass. Use the appropriate implementation strategy (see above). Never write more production code than what current tests require.

### Step 4: Refactor

With the test green, actively look for improvements:
- Remove duplication
- Extract methods/functions
- Improve naming
- Simplify logic
- Upgrade data structures (e.g., array scan → Set/Map for O(1) lookups)

"No changes needed" is rarely true — there is almost always something to improve, even if small. Run tests after every change. If a test breaks, undo the last change.

### Step 5: Repeat

Go back to Step 2 with the next test case. Each new test should force the implementation to become more general.

**The implementation cycle is: one test → make it pass → refactor → next test. Not: all tests → make them all pass → refactor.** (The planner defines what to test; the implementer decides the order and pace of the cycle.)

## Test Granularity

Different levels of testing serve different purposes. Apply the right level for each behavior:

### Unit Tests
Test individual functions, methods, or classes in isolation. These form the bulk of the test suite.
- Fast (milliseconds), isolated, deterministic
- Mock external dependencies (APIs, databases, file I/O)
- Test through public API, not private internals
- One behavior per test

### Integration Tests
Test that components work together correctly — the real interactions, not mocked ones.
- Use real databases (test containers or in-memory), real HTTP handlers, real message queues
- Keep separate from unit tests (different directory or test markers)
- Test the critical paths: happy path and key error paths
- Reset state between tests (transactions, container resets)
- Acceptable to be slower than unit tests, but keep them under a few seconds each

**When to write integration tests:**
- Database interactions (queries, migrations, transactions)
- API endpoints (full request/response cycle)
- Message queues and event-driven flows
- Multi-service or multi-module interactions
- Anywhere mocking would hide a real integration bug

### End-to-End (E2E) Tests
Test the feature from the user's perspective — the full stack, real environment.
- Verify that the entire flow works as the user would experience it
- Cover the critical user journeys, not every edge case (that's what unit tests are for)
- For web: use browser automation (Playwright, Cypress). For APIs: real HTTP requests against a running server. For CLI: run the actual binary.
- Accept that E2E tests are slower and more brittle — write fewer of them, focused on high-value paths
- Include setup and teardown of test data/environment

**When to write E2E tests:**
- User-facing workflows with multiple steps (signup → verify email → first login)
- Flows that cross multiple services or systems
- Critical business paths where a regression would be severe
- When the plan's acceptance criteria describe user-visible behavior

### The Testing Pyramid

Follow the pyramid: many unit tests, fewer integration tests, fewest E2E tests. If you find yourself writing more E2E tests than unit tests, the design likely has coupling issues — push testing down to lower levels.

**For planners:** Specify the test level for each test case in the plan. Default to unit tests. Add integration tests for cross-component interactions and E2E tests for critical user journeys described in the acceptance criteria.

**For implementers:** Write unit tests during the TDD cycle. Write integration and E2E tests after the unit-level implementation is green and refactored — these verify the assembled pieces, not individual behaviors.

## Framework Detection

Check the project for existing test infrastructure before creating tests:

1. Look for test configuration files (`jest.config`, `vitest.config`, `pytest.ini`, `build.gradle`, `pom.xml`, `go.mod`, `Cargo.toml`, etc.)
2. Look for existing test directories (`__tests__`, `test/`, `tests/`, `spec/`, `src/test/`)
3. Look for test runner scripts in `package.json`, `Makefile`, etc.
4. Look for E2E test setup (`playwright.config`, `cypress.config`, `e2e/`, `tests/e2e/`)
5. Match the existing patterns — naming conventions, directory structure, assertion style

If a `.claude/devline.local.md` file exists, check for `test_framework` override.

## Test Quality Standards

### Good Tests Are:
- **Fast** — milliseconds for unit tests, seconds for integration, acceptable minutes for E2E
- **Isolated** — no test depends on another
- **Deterministic** — same result every run
- **Self-validating** — pass or fail, no manual inspection
- **Descriptive** — test name explains the behavior

### Test Structure

Follow Arrange-Act-Assert (AAA) or Given-When-Then:

```
Arrange: Set up preconditions and inputs
Act: Execute the behavior under test
Assert: Verify the expected outcome
```

### What to Test

- Happy path (expected inputs → expected outputs)
- Edge cases (empty, null, boundary values)
- Error cases (invalid inputs, failure modes)
- State transitions (before → action → after)
- Component interactions (integration level)
- Critical user journeys (E2E level)

### What Not to Test

- Third-party library internals
- Private implementation details (test through public API)
- Trivial getters/setters without logic
- Framework boilerplate
- Every permutation at the E2E level (push to unit tests instead)

## Parallel Work Package Testing

When working as part of a parallel implementation pipeline:

1. Only write tests for files in the assigned work package
2. Never modify test files outside the package scope
3. Use mocks/stubs for dependencies from other packages
4. Ensure tests can run independently without other packages
5. Integration tests that span multiple packages belong in a dedicated integration test package — the planner should define this as a separate work package that depends on the components it integrates

## Running Tests

Always run the full test suite after implementation, not just the new tests. Report results clearly:

- Number of tests passed/failed/skipped
- Failure messages and stack traces
- Coverage changes if available
- Integration and E2E test results separately if they have different run commands

## Additional Resources

### Reference Files

For framework-specific patterns and advanced TDD techniques:

- **`references/framework-patterns.md`** — Language-specific TDD patterns (JS/TS, Python, Go, Java, Rust, etc.)
- **`references/advanced-tdd.md`** — Integration testing, E2E testing, mocking strategies, TDD with legacy code
