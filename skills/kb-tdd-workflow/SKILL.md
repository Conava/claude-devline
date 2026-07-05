---
name: kb-tdd-workflow
description: Domain logic for TDD methodology — injected into agents that implement code using test-driven development. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# TDD Workflow

Test-driven development produces better-designed, more maintainable code by writing tests before implementation. The critical skill is choosing the right test level — not defaulting to unit tests with mocks.

## Core Philosophy: Right Level, Real Dependencies

1. **Default to the highest useful level.** If a test can run against real infrastructure in under 5 seconds, it should. Don't mock what you can test for real.
2. **Mock only at boundaries you don't own.** External APIs, email providers, payment gateways, third-party webhooks — mock these. Your own database, your own repositories, your own event bus, your own HTTP handlers — use the real thing.
3. **Test behavior, not mechanics.** `verify(repo).save(any())` proves a method was called, not that the right thing was persisted. Assert on outcomes: query the database, check the HTTP response, verify the event payload. If you can only assert that a mock was invoked, you're testing wiring, not behavior.
4. **Parameterize repetitive patterns.** If N endpoints x M roles all need the same auth check, write one parameterized test iterating all combinations. If 20 DTOs all validate `@NotBlank` on their name field, test the validation framework once, not 20 times.
5. **Don't test the framework.** The framework is already tested by its maintainers.

## Test Level Selection

Choose the test level based on **what the code does**, not on convention or habit.

### When to write integration tests (real DB, real HTTP, real infra)

- **Persistence code** — any repository, DAO, or data access layer. Custom `@Query` methods, complex joins, constraint validation, cascades. These are the most bug-prone code in any project and the most dangerous to mock. Use Testcontainers, `@DataJpaTest`, in-memory databases, or test containers.
- **API endpoints** — controller/handler tests that verify request→response through the real routing, serialization, validation, and service layers. Use `@WebMvcTest`/`@SpringBootTest`, supertest, `httptest`, TestClient, etc.
- **Event-driven flows** — listeners, propagation engines, schedulers. Test that publishing an event produces the right side effects in the real database.
- **Migrations** — schema changes tested against a real database to catch column mismatches, constraint violations, data loss.
- **Multi-component interactions** — anywhere two or more of your own components collaborate and mocking one would hide real bugs (transaction boundaries, error propagation, ordering).

### When to write unit tests (isolated, fast, no I/O)

- **Pure business logic** — calculation engines, state machines, validation rules, parsers, formatters. These have clear inputs→outputs with no I/O.
- **Domain model behavior** — methods on entities/value objects that compute something.
- **Algorithm-heavy code** — sorting, filtering, transformation, scoring.
- **Error path logic** — retry strategies, circuit breakers, fallback chains (logic only, not the actual I/O).

### When to write E2E tests

- **Complete user journeys** — multi-step flows from entry point to observable outcome (signup→verify→first use, create→classify→propagate).
- **Cross-boundary flows** — requests that traverse multiple services or modules.
- **Critical business paths** — the paths where a bug means revenue loss, compliance violation, or data corruption.

E2E tests are defined at the **feature level** by the planner (see Feature-Goal Tests in the plan), not per-task. Include a dedicated final-wave E2E task ONLY for features with a genuine multi-step cross-boundary journey; skip it for single-component changes, pure-logic changes, and bugfixes (per-task integration tests already cover that surface). When present, it runs after all implementation is merged.

## What NOT to Test

These produce noise without catching bugs. Delete them if they exist; don't write new ones.

- **Framework behavior** — `@NotBlank` rejects blank strings, `@Valid` triggers validation, Spring Security enforces `@PreAuthorize`. The framework is tested by its own test suite. Only test YOUR validation logic (custom validators, conditional rules, business constraints).
- **Language features** — data class defaults, null safety, enum values, constructor parameters. If Kotlin/Java/TS guarantees it, don't test it.
- **Delegation methods** — one-liner passthrough methods that just call another method. Testing `helper.doThing()` calls `service.doThing()` verifies nothing useful.
- **Trivial getters/setters** — unless they contain logic.
- **Mock echo patterns** — `whenever(repo.save(any())).thenAnswer { it.arguments[0] }` followed by `verify(repo).save(any())`. You've tested that Mockito works, not that your code works. If you need to test persistence, hit a real database.

### Auth/RBAC testing: consolidate, don't duplicate

If every controller has 5-10 tests like "returns 403 for VIEWER role", you have N_endpoints * M_roles nearly identical tests. Replace with:

1. **One parameterized security test** that iterates all secured endpoints x roles and asserts the expected status code. This covers the RBAC matrix comprehensively.
2. **A few handwritten tests** per controller for non-obvious auth behavior (custom permission logic, resource-level authorization, org isolation).

## Core Cycle: Red-Green-Refactor

1. **Red** — Write a failing test that defines expected behavior
2. **Green** — Write the code to make the test pass
3. **Refactor** — Improve code structure while keeping tests green

Never skip steps. Never write implementation before a failing test exists.

**For planners:** Define test cases in the plan with their level: `[unit]`, `[integration]`, `[e2e]` (per-test-case tagging is cheap — keep it). Use the selection heuristics above — don't default to `[unit]`. NEW repository methods, controller endpoints, event listeners, and schedulers should be `[integration]` by default. But when modifying existing, already-integration-tested persistence/endpoint code **without changing its schema or contract**, a targeted unit test of the changed logic is sufficient — rely on the existing integration suite.

**For implementers:** Implement tests one at a time through the cycle. Each test drives the next increment of design.

## Implementation Strategy

Use **Obvious Implementation** by default — write the real implementation when the solution is clear. Fall back to **Fake It** (hardcoded values, then generalize) when the problem is genuinely uncertain or you keep hitting unexpected failures.

## Test-First Process

### Step 1: Analyze Requirements

Break the feature into discrete, testable behaviors. Each behavior becomes one test case. Order from simplest to most complex — degenerate/base cases first, then complexity.

### Step 2: Write ONE Failing Test

Start with the simplest behavior. Write a single test that:
- Has a clear, descriptive name stating expected behavior
- Arranges minimal preconditions
- Acts on the unit under test
- Asserts one specific outcome

Run the test. Confirm it fails for the right reason (not a syntax error or import issue).

**Do NOT write the next test yet.** Each test drives the next design decision.

### Step 3: Make It Pass

Write the code to make the test pass. Never write more production code than current tests require.

### Step 4: Refactor

With the test green, improve: remove duplication, extract methods, improve naming, simplify logic. Run tests after every change.

### Step 5: Repeat

Back to Step 2. Cycle: one test → pass → refactor → next test.

## Test Quality Standards

Tests must be fast, isolated, deterministic, self-validating, and descriptively named. Follow Arrange-Act-Assert (AAA).

### What to Test

Cover: happy paths, edge cases (empty, null, boundary), error cases, state transitions. Test through public APIs — not private internals.

### Parameterization

When you see the same test structure repeated with different inputs, use parameterized tests instead of copy-pasting:

- **JUnit 5:** `@ParameterizedTest` with `@MethodSource` or `@CsvSource`
- **pytest:** `@pytest.mark.parametrize`
- **Jest/Vitest:** `test.each`
- **Go:** table-driven tests
- **Rust:** macro-generated test cases or `rstest`

Rule of thumb: if you're about to write a third test with the same structure but different data, parameterize.

## Framework Detection

Check the project for existing test infrastructure before creating tests:

1. Look for test configuration files (`jest.config`, `vitest.config`, `pytest.ini`, `build.gradle`, `pom.xml`, `go.mod`, `Cargo.toml`, etc.)
2. Look for existing test directories (`__tests__`, `test/`, `tests/`, `spec/`, `src/test/`)
3. Look for test runner scripts in `package.json`, `Makefile`, etc.
4. Look for E2E test setup (`playwright.config`, `cypress.config`, `e2e/`, `tests/e2e/`)
5. Match existing patterns — naming conventions, directory structure, assertion style

If `.claude/devline.local.md` exists, check for `test_framework` override.

## Parallel Task Testing

In parallel pipelines: only test files in your task, mock other tasks' dependencies, ensure tests run independently. Cross-task integration tests belong in a dedicated task.

## Running Tests

Always run the full test suite after implementation. Report: passed/failed/skipped counts, failure details, coverage changes if available.

**Zero tolerance for failures.** The feature branch starts green. Every test failure is signal — either your code is wrong, your change is incomplete, or the test needs updating to reflect intentionally changed behavior. Never dismiss failures as "pre-existing" or "unrelated."

## Additional Resources

### Reference Files

- **`references/framework-patterns.md`** — Language-specific TDD patterns (JS/TS, Python, Go, Java, Rust, etc.)
- **`references/advanced-tdd.md`** — Integration testing patterns, E2E strategies, mocking boundaries, anti-patterns
