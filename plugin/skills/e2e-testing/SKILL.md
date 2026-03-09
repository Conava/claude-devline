---
name: e2e-testing
description: "Playwright E2E testing patterns — Page Object Model, selectors, waiting strategies, and CI integration. Auto-loaded when working with Playwright tests or E2E test infrastructure."
disable-model-invocation: false
user-invocable: false
---

# E2E Testing Patterns

Domain knowledge for Playwright-based end-to-end testing. Follow these conventions when writing or maintaining E2E tests.

## Project Structure

```
tests/
├── e2e/
│   ├── auth/            # Authentication flows
│   ├── features/        # Feature-specific tests
│   └── smoke/           # Critical path smoke tests
├── pages/               # Page Object Model classes
├── fixtures/            # Custom test fixtures and data factories
└── playwright.config.ts
```

- Group test files by feature area, not by page
- Keep smoke tests separate — they run on every deploy
- One spec file per user flow, not per page

## Page Object Model

- Every page or major component gets a POM class — encapsulate selectors and actions
- Constructor takes `Page`, assigns all locators as readonly properties
- Methods represent user actions (`login`, `search`, `addToCart`), not DOM operations
- POM methods handle their own waiting — callers should not add extra waits
- Never expose raw selectors outside POMs — all interaction goes through methods
- Name POM files to match the feature: `LoginPage.ts`, `DashboardPage.ts`, `CheckoutPage.ts`

## Selector Strategy

- **Preferred**: `data-testid` attributes — stable, decoupled from styling and structure
- **Acceptable**: ARIA roles and labels (`getByRole('button', { name: 'Submit' })`) for accessibility testing
- **Avoid**: CSS classes, tag names, XPath, text content (fragile, locale-dependent)
- Use `page.getByTestId('name')` shorthand when `data-testid` attributes exist
- Scope selectors to parent locators to avoid ambiguity: `dialog.getByTestId('confirm-btn')`

## Waiting and Assertions

- Never use `page.waitForTimeout()` — always wait for a specific condition
- Wait for network: `page.waitForResponse(resp => resp.url().includes('/api/data'))`
- Wait for elements: `locator.waitFor({ state: 'visible' })` before interaction
- Wait for navigation: `page.waitForURL('**/dashboard')`
- Use Playwright's auto-waiting locators (`.click()`, `.fill()`) — they retry automatically
- Assert with `expect(locator)` — built-in retrying assertions: `toBeVisible()`, `toHaveText()`, `toHaveCount()`

## Test Structure

- Use `test.describe` to group related scenarios — share `beforeEach` setup
- Each test should be independent — no ordering dependencies between tests
- Set up test data via API calls or fixtures, not through the UI (except when testing the UI flow itself)
- Clean up test data in `afterEach` or use isolated test accounts
- Tag tests for selective runs: `test('feature @smoke', ...)` or `test.describe.configure({ tag: '@slow' })`

## Configuration

- Set `fullyParallel: true` for speed, `workers: 1` in CI if tests share state
- Set `retries: 2` in CI, `retries: 0` locally — retries mask flakiness during development
- Configure `trace: 'on-first-retry'` — captures trace only when a test fails then passes on retry
- Set `screenshot: 'only-on-failure'` and `video: 'retain-on-failure'` — minimal artifact noise
- Define `actionTimeout: 10000` and `navigationTimeout: 30000` as sensible defaults
- Use `webServer` config to auto-start the dev server before tests

## Multi-Browser Testing

- Test against Chromium, Firefox, and WebKit using `projects` config
- Add mobile viewports: `devices['Pixel 5']`, `devices['iPhone 13']`
- Run full browser matrix in CI nightly, Chromium-only on PRs for speed
- Use `test.skip` with browser conditions for known browser-specific issues

## Flakiness Prevention

| Cause | Fix |
|-------|-----|
| Race condition | Use auto-waiting locators, never raw `page.click()` |
| Network timing | Wait for specific API responses, not arbitrary timeouts |
| Animation interference | Wait for `'visible'` state, use `page.waitForLoadState('networkidle')` |
| Shared test data | Isolate test data per test, use unique identifiers |
| Viewport-dependent | Set explicit viewport in test or config |
| Time-dependent | Mock `Date.now()` or use relative time assertions |

- Reproduce flaky tests: `npx playwright test --repeat-each=10`
- Quarantine flaky tests with `test.fixme(true, 'Flaky — tracking in #123')`
- Never skip flaky tests silently — always link to a tracking issue

## Artifact Capture

- Screenshots: `page.screenshot({ path: 'artifacts/step-name.png', fullPage: true })`
- Element screenshots: `locator.screenshot({ path: 'artifacts/component.png' })`
- Traces: configured via `trace: 'on-first-retry'` — view with `npx playwright show-trace trace.zip`
- Videos: configured via `video: 'retain-on-failure'` — auto-attached to test results
- Upload all artifacts in CI with `actions/upload-artifact@v4`, set `if: always()`

## CI Integration

- Install browsers: `npx playwright install --with-deps`
- Run with explicit `BASE_URL` env var pointing to staging or preview deployment
- Shard large suites: `npx playwright test --shard=1/4` across parallel CI jobs
- Upload HTML report as artifact for every run — set `retention-days: 30`
- Fail the pipeline on any test failure — do not allow flaky tests to pass silently
- Run smoke tests on deploy, full suite on schedule or PR

## Test Data Management

- Use API fixtures to create and tear down test data — faster than UI setup
- Generate unique identifiers per test run to avoid collisions: `test-${Date.now()}`
- Use Playwright fixtures (`test.extend`) for reusable authenticated contexts
- Store auth state with `storageState` to avoid logging in for every test
- Never depend on production data — tests must work against a clean environment
