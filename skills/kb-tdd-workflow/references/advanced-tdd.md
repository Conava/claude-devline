# Advanced TDD Techniques

## Integration Testing

Integration tests verify that components work together correctly. Use them for:
- Database interactions (real database, not mocks)
- API endpoints (HTTP request/response cycle)
- Message queues and event systems
- Third-party service integrations (use sandboxed environments)
- Multi-module interactions where mocking would hide real bugs

### Strategy
- Keep integration tests separate from unit tests (different directories or markers)
- Use test databases/containers that can be reset between tests
- Test the happy path and critical error paths
- Run integration tests in CI, but allow skipping locally for speed
- Each test should set up and tear down its own state — never rely on test execution order

### Patterns by Stack

**Node.js / Express / Fastify:**
```typescript
// Use supertest for HTTP integration tests
import request from 'supertest';
import { app } from '../src/app';
import { db } from '../src/db';

beforeEach(async () => { await db.migrate.latest(); await db.seed.run(); });
afterEach(async () => { await db.migrate.rollback(); });

test('POST /users creates user and returns 201', async () => {
  const res = await request(app)
    .post('/users')
    .send({ name: 'Alice', email: 'alice@example.com' });
  expect(res.status).toBe(201);

  const user = await db('users').where({ email: 'alice@example.com' }).first();
  expect(user).toBeDefined();
});
```

**Python / Django / FastAPI:**
```python
# Django: use TestCase with real database
class UserAPITest(TestCase):
    def test_create_user_persists_to_database(self):
        response = self.client.post('/api/users/', {
            'name': 'Alice', 'email': 'alice@example.com'
        })
        self.assertEqual(response.status_code, 201)
        self.assertTrue(User.objects.filter(email='alice@example.com').exists())

# FastAPI: use TestClient
from fastapi.testclient import TestClient
def test_create_user(client: TestClient, db_session):
    response = client.post('/users', json={'name': 'Alice', 'email': 'alice@example.com'})
    assert response.status_code == 201
    assert db_session.query(User).filter_by(email='alice@example.com').one()
```

**Go:**
```go
func TestCreateUserIntegration(t *testing.T) {
    if testing.Short() { t.Skip("skipping integration test") }
    db := setupTestDB(t)
    defer db.Close()

    srv := httptest.NewServer(NewRouter(db))
    defer srv.Close()

    resp, err := http.Post(srv.URL+"/users", "application/json",
        strings.NewReader(`{"name":"Alice","email":"alice@example.com"}`))
    require.NoError(t, err)
    require.Equal(t, 201, resp.StatusCode)
}
```

### Test Containers

For databases and external services, prefer test containers over mocks:
- Docker-based test containers spin up real services for integration tests
- Libraries: `testcontainers` (Java, Go, Node, Python, Rust, .NET)
- Provides real behavior without requiring a persistent test environment
- Each test suite gets a fresh container — no shared state issues

## End-to-End (E2E) Testing

E2E tests verify the full user journey through the real system. They are the most expensive tests to write and maintain — use them sparingly for critical paths.

### When to Write E2E Tests
- User-facing workflows with multiple steps (signup → verify → first use)
- Flows that cross service boundaries
- Critical business paths (checkout, payment, data export)
- When acceptance criteria describe user-visible behavior

### When NOT to Write E2E Tests
- Testing individual validation rules (unit test)
- Testing API response shapes (integration test)
- Testing error handling for every edge case (unit test)
- Verifying internal state or implementation details

### E2E Patterns by Platform

**Web — Playwright (recommended):**
```typescript
import { test, expect } from '@playwright/test';

test('user can sign up and reach dashboard', async ({ page }) => {
  await page.goto('/signup');
  await page.getByLabel('Email').fill('alice@example.com');
  await page.getByLabel('Password').fill('SecurePass123!');
  await page.getByRole('button', { name: 'Create Account' }).click();

  // Verify redirect to dashboard
  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByText('Welcome, alice')).toBeVisible();
});
```

**Web — Cypress:**
```typescript
describe('Checkout flow', () => {
  it('completes purchase with valid payment', () => {
    cy.visit('/products');
    cy.contains('Add to Cart').first().click();
    cy.get('[data-testid="cart-icon"]').click();
    cy.contains('Checkout').click();
    cy.get('#card-number').type('4242424242424242');
    cy.contains('Pay').click();
    cy.url().should('include', '/order-confirmation');
  });
});
```

**API — Full stack HTTP:**
```typescript
// Start a real server, hit real endpoints, verify real database state
test('full order lifecycle', async () => {
  const product = await createTestProduct();
  const order = await api.post('/orders', { productId: product.id, quantity: 2 });
  expect(order.status).toBe(201);

  const fetched = await api.get(`/orders/${order.body.id}`);
  expect(fetched.body.status).toBe('pending');

  await api.post(`/orders/${order.body.id}/pay`, { method: 'test' });
  const paid = await api.get(`/orders/${order.body.id}`);
  expect(paid.body.status).toBe('paid');
});
```

**CLI:**
```typescript
import { execSync } from 'child_process';

test('init command creates project structure', () => {
  const output = execSync('my-cli init --name test-project', { cwd: tmpDir });
  expect(output.toString()).toContain('Project created');
  expect(fs.existsSync(path.join(tmpDir, 'test-project', 'package.json'))).toBe(true);
});
```

**Mobile — Flutter:**
```dart
testWidgets('user can log in and see profile', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(Key('email_field')), 'alice@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  expect(find.text('Welcome, Alice'), findsOneWidget);
});
```

### E2E Best Practices
- **Minimal setup, maximum coverage:** Each E2E test should cover a complete user journey, not a single interaction
- **Use realistic test data:** Create data through the app's own APIs/UI, not by inserting directly into the database
- **Handle async gracefully:** Wait for elements/states, don't use arbitrary sleeps
- **Clean up after yourself:** Each test should be independent — create and destroy its own data
- **Run in CI:** E2E tests should run in CI on every PR. Mark flaky tests and fix them — don't just retry.
- **Keep the count low:** 5-15 E2E tests covering critical journeys is better than 100 brittle ones

## Mocking Strategies

### When to Mock
- External services (APIs, databases, message queues) in unit tests
- Slow operations (file I/O, network) in unit tests
- Non-deterministic operations (time, random, UUIDs)

### When NOT to Mock
- The unit under test itself
- Simple value objects or data structures
- When the real thing is fast and deterministic
- In integration tests (use the real thing)

### Mock Patterns
- **Stub:** Returns predefined values
- **Spy:** Records calls for later assertion
- **Fake:** Simplified working implementation (in-memory database)
- **Mock:** Verifies specific interactions occurred

### Anti-patterns
- Mocking everything (tests become tautological)
- Testing mock behavior instead of production behavior
- Brittle mocks that break when implementation changes
- Complex mock setup that's harder to read than the code

## TDD with Legacy Code

### Characterization Tests
When working with untested legacy code:
1. Write tests that capture current behavior (even if buggy)
2. Use the tests as a safety net for refactoring
3. Refactor to make the code testable
4. Then fix bugs with proper TDD

### Seam Technique
Find "seams" — points where you can alter behavior without changing code:
- Constructor injection (pass dependencies)
- Method extraction (override in test subclass)
- Interface extraction (swap implementations)

## Property-Based Testing

Instead of specific examples, define properties that should always hold:
- "For any valid email, user creation succeeds"
- "Sorting any list produces a list of the same length"
- "Encoding then decoding returns the original"

Useful for finding edge cases you wouldn't think to test manually.

## Test Organization

### Arrange-Act-Assert (AAA)
```
// Arrange: set up test data and preconditions
// Act: execute the behavior under test
// Assert: verify the outcome
```

### Given-When-Then (BDD style)
```
// Given: initial context
// When: action occurs
// Then: expected outcome
```

### Test Naming
- Describe the scenario and expected outcome
- `shouldReturnEmptyListWhenNoUsersExist`
- `test_login_fails_with_expired_token`
- `creates user with valid input`

### Directory Structure
```
tests/
├── unit/           # Fast, isolated, mocked dependencies
├── integration/    # Real database, real HTTP, real services
└── e2e/            # Full user journeys, real environment
```

Or collocated:
```
src/
├── users/
│   ├── user.service.ts
│   ├── user.service.test.ts        # Unit tests
│   └── user.service.integration.ts # Integration tests
tests/
└── e2e/
    └── user-journey.test.ts        # E2E tests
```

Match the existing project convention. If no convention exists, prefer the separated `tests/` structure.
