---
name: kb-tdd-workflow
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

Use **Obvious Implementation** by default — write the real implementation when the solution is clear. Fall back to **Fake It** (hardcoded values, then generalize) when the problem is genuinely uncertain or you keep hitting unexpected failures. The test-first discipline and incremental verification remain non-negotiable regardless of strategy.

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

With the test green, improve: remove duplication, extract methods, improve naming, simplify logic. Run tests after every change. If a test breaks, undo.

### Step 5: Repeat

Go back to Step 2. Cycle: one test → pass → refactor → next test. Never all tests at once.

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

**When to write integration tests:** Database interactions, API endpoints, event-driven flows, multi-module interactions, anywhere mocking would hide real bugs.

### End-to-End (E2E) Tests
Test from the user's perspective — full stack, real environment. Cover critical user journeys only (not edge cases). Accept they're slower — write fewer, focused on high-value paths.

**When to write E2E tests:** Multi-step user workflows, cross-service flows, critical business paths, acceptance criteria with user-visible behavior.

### The Testing Pyramid

Many unit tests, fewer integration, fewest E2E. Planners: specify test level per case. Implementers: write integration/E2E tests after unit-level is green.

## Framework Detection

Check the project for existing test infrastructure before creating tests:

1. Look for test configuration files (`jest.config`, `vitest.config`, `pytest.ini`, `build.gradle`, `pom.xml`, `go.mod`, `Cargo.toml`, etc.)
2. Look for existing test directories (`__tests__`, `test/`, `tests/`, `spec/`, `src/test/`)
3. Look for test runner scripts in `package.json`, `Makefile`, etc.
4. Look for E2E test setup (`playwright.config`, `cypress.config`, `e2e/`, `tests/e2e/`)
5. Match the existing patterns — naming conventions, directory structure, assertion style

If a `.claude/devline.local.md` file exists, check for `test_framework` override.

## Test Quality Standards

Tests must be fast, isolated, deterministic, self-validating, and descriptively named. Follow Arrange-Act-Assert (AAA).

### What to Test

Cover happy paths, edge cases (empty, null, boundary), error cases, and state transitions. Test through public APIs — not private internals or trivial accessors. Push permutation coverage to unit tests; reserve E2E for critical user journeys.

## Parallel Task Testing

In parallel pipelines: only test files in your task, mock other tasks' dependencies, ensure tests run independently. Cross-task integration tests belong in a dedicated task.

## Running Tests

Always run the full test suite after implementation. Report: passed/failed/skipped counts, failure details, coverage changes if available.

## Additional Resources

### Reference Files

For framework-specific patterns and advanced TDD techniques:

- **`references/framework-patterns.md`** — Language-specific TDD patterns (JS/TS, Python, Go, Java, Rust, etc.)
- **`references/advanced-tdd.md`** — Integration testing, E2E testing, mocking strategies, TDD with legacy code
