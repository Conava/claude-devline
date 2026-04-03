# Advanced TDD Techniques

## Integration Testing — The Default for I/O Code

Integration tests verify that your code works with real infrastructure. For persistence, API, and event-driven code, these are your primary tests — not an afterthought after unit tests.

### When Integration Tests Are the Right Choice

- **Repository/DAO code** — custom queries, joins, constraints, cascades, soft-delete filters. A mocked repository hides every database bug.
- **API endpoints** — full request→response through routing, serialization, validation, service layer, and persistence. Test the contract your consumers rely on.
- **Event listeners and schedulers** — publish an event, assert the side effects in the real database. Mock-based listener tests that `verify(repo).save(any())` prove nothing about what was saved.
- **Migrations** — schema changes against a real database to catch constraint violations and data loss.
- **Transaction boundaries** — rollback behavior, isolation levels, optimistic locking. These are invisible to mocked tests.

### Patterns by Stack

**Spring Boot (Kotlin/Java) — Persistence:**
```kotlin
// @DataJpaTest is lighter than @SpringBootTest — loads only JPA slice
@DataJpaTest
@Import(TestcontainersConfiguration::class)
class TaskRepositoryTest {
    @Autowired lateinit var taskRepo: TaskRepository
    @Autowired lateinit var entityManager: TestEntityManager

    @Test
    fun `findOverdueByOrg returns only tasks past deadline for given org`() {
        val org = createOrg()
        val overdueTask = createTask(org, deadline = Instant.now().minus(1, ChronoUnit.DAYS))
        val futureTask = createTask(org, deadline = Instant.now().plus(1, ChronoUnit.DAYS))
        val otherOrgTask = createTask(createOrg(), deadline = Instant.now().minus(1, ChronoUnit.DAYS))
        entityManager.flush()

        val result = taskRepo.findOverdueByOrg(org.id)

        assertThat(result).containsExactly(overdueTask)
        // Proves: query filters by org AND deadline. Mock would prove nothing.
    }
}
```

**Spring Boot — Controller integration:**
```kotlin
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Import(TestcontainersConfiguration::class)
class UserControllerIntegrationTest {
    @Autowired lateinit var restTemplate: TestRestTemplate

    @Test
    fun `POST creates user and persists to database`() {
        val response = restTemplate.postForEntity("/api/users",
            CreateUserRequest(name = "Alice", email = "alice@example.com"),
            UserResponse::class.java)

        assertThat(response.statusCode).isEqualTo(HttpStatus.CREATED)
        assertThat(response.body!!.name).isEqualTo("Alice")
        // The user is really in the database — no echo-mock needed
    }
}
```

**Node.js / Express / Fastify:**
```typescript
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
class UserAPITest(TestCase):
    def test_create_user_persists_to_database(self):
        response = self.client.post('/api/users/', {
            'name': 'Alice', 'email': 'alice@example.com'
        })
        self.assertEqual(response.status_code, 201)
        self.assertTrue(User.objects.filter(email='alice@example.com').exists())
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
- Each test suite gets a fresh container — no shared state
- Reuse containers across test classes for speed (`@Testcontainers` with `reuse = true` in Spring, `GenericContainer.withReuse(true)` elsewhere)

### Integration Test Organization

Keep integration tests separate from unit tests so they can be run independently:
- **JUnit/Spring:** `src/test/java/.../integration/` or `@Tag("integration")`
- **pytest:** `tests/integration/` or `@pytest.mark.integration`
- **Jest:** `__tests__/integration/` or `*.integration.test.ts`
- **Go:** `go test -short` skips integration tests marked with `testing.Short()`

## End-to-End (E2E) Testing

E2E tests verify complete user journeys through the real system. They are the most expensive to write and maintain — use them for critical paths only.

### Feature-Level E2E Tests

In the devline pipeline, E2E tests are defined at the **feature level**, not per-task. The planner designs them as a dedicated final-wave task that runs after all implementation is merged. This ensures:

- They test the fully integrated feature, not isolated components
- They exercise pre-existing code paths that the feature builds on
- They catch integration bugs between new and old code
- They serve as regression tests going forward

### Designing Good E2E Tests

Each E2E test should represent a **complete user journey** — from the user's entry point through all layers to the observable outcome:

1. **Start from the user's perspective.** What does the user do? (API call, UI action, CLI command)
2. **Traverse the full stack.** Real HTTP, real service layer, real database, real events.
3. **Assert on user-visible outcomes.** Response body, database state, side effects (emails sent, events published, files created).
4. **Include pre-existing paths.** A feature that adds "risk classification" should test the full journey: create AI system → classify → verify propagation → check audit trail. The "create AI system" part is pre-existing code — the E2E test exercises it naturally.

### E2E Patterns by Platform

**API — Full lifecycle:**
```typescript
test('full order lifecycle', async () => {
  const product = await api.post('/products', { name: 'Widget', price: 9.99 });
  const order = await api.post('/orders', { productId: product.body.id, qty: 2 });
  expect(order.status).toBe(201);

  await api.post(`/orders/${order.body.id}/pay`, { method: 'test' });
  const paid = await api.get(`/orders/${order.body.id}`);
  expect(paid.body.status).toBe('paid');
  expect(paid.body.total).toBe(19.98);
});
```

**Web — Playwright:**
```typescript
test('user can sign up and reach dashboard', async ({ page }) => {
  await page.goto('/signup');
  await page.getByLabel('Email').fill('alice@example.com');
  await page.getByLabel('Password').fill('SecurePass123!');
  await page.getByRole('button', { name: 'Create Account' }).click();
  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByText('Welcome, alice')).toBeVisible();
});
```

**Spring Boot — Full journey with Testcontainers:**
```kotlin
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Import(TestcontainersConfiguration::class)
class RiskClassificationE2ETest {
    @Autowired lateinit var restTemplate: TestRestTemplate

    @Test
    fun `classify AI system and verify propagation creates tasks`() {
        // 1. Create org and AI system (exercises pre-existing code)
        val org = createOrg(modules = setOf("AI_GOVERNANCE"))
        val aiSystem = createAiSystem(org, name = "Chatbot")

        // 2. Submit classification answers (new feature code)
        val classification = restTemplate.postForEntity(
            "/api/orgs/${org.id}/ai-systems/${aiSystem.id}/classify",
            classificationAnswers, ClassificationResponse::class.java)
        assertThat(classification.body!!.riskLevel).isEqualTo("HIGH")

        // 3. Verify propagation created compliance tasks (cross-component)
        val tasks = restTemplate.getForEntity(
            "/api/orgs/${org.id}/tasks?source=classification",
            Array<TaskResponse>::class.java)
        assertThat(tasks.body).isNotEmpty
        assertThat(tasks.body!!.map { it.title }).contains("Human oversight plan")

        // 4. Verify audit trail (pre-existing audit system)
        val audit = restTemplate.getForEntity(
            "/api/orgs/${org.id}/audit?entity=${aiSystem.id}",
            Array<AuditResponse>::class.java)
        assertThat(audit.body!!.map { it.action }).contains("CLASSIFIED")
    }
}
```

### E2E Best Practices

- **Minimal count, maximum coverage.** 3-10 E2E tests per feature covering critical journeys is better than 50 fragile ones.
- **Use realistic test data.** Create data through the app's own APIs, not by inserting directly into the database.
- **Handle async gracefully.** Wait for elements/states, don't use arbitrary sleeps.
- **Clean up after yourself.** Each test is independent — creates and destroys its own data.
- **Run in CI.** E2E tests run on every PR. Fix flaky tests — don't retry them.

## Mocking — When and How

### The Only Valid Reasons to Mock

1. **External services you don't control** — third-party APIs, payment gateways, email providers, SMS services. You can't spin these up in a test container.
2. **Non-deterministic inputs** — current time, random values, UUIDs. Inject these as dependencies so tests can control them.
3. **Catastrophic side effects** — sending real emails, charging real credit cards, deleting production data.
4. **Cross-task dependencies in parallel pipelines** — when the real dependency doesn't exist yet because another agent is building it.

### What Should Never Be Mocked

- **Your own database/repositories** — use Testcontainers or in-memory databases. An echo-mock (`thenAnswer { it.arguments[0] }`) hides constraint violations, FK errors, query bugs, and transaction issues.
- **Your own services/components** — if you're testing a controller, let it call the real service. If the service is too slow, that's a performance problem to fix, not a reason to mock.
- **Your own event bus/message queue** — test that publishing an event produces real side effects.
- **Framework internals** — don't mock Spring's `ApplicationContext`, Express's `req/res`, or Django's `QuerySet`. Use the framework's test utilities.

### Anti-Patterns to Avoid

| Anti-Pattern | What It Looks Like | Why It's Bad |
|---|---|---|
| **Echo mock** | `when(repo.save(any())).thenAnswer { it.arguments[0] }` | Tests that "save returns what you gave it" — proves nothing about persistence |
| **Verify-only test** | `verify(service, times(3)).process(any())` | Proves a method was called N times, not that it did the right thing |
| **Delegation test** | Test that `helper.doX()` calls `service.doX()` | Tests a one-liner passthrough — zero business logic verified |
| **Framework test** | Test that `@NotBlank` rejects blank strings | Tests Spring's validation, not your code |
| **Language test** | Test that a data class defaults to null/empty | Tests Kotlin/Java language features |
| **Over-mocked integration** | `@SpringBootTest` with 6 `@MockBean` annotations | You're testing wiring between mocks, not real behavior |

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

Useful for finding edge cases you wouldn't think to test manually. Good for: parsers, serializers, mathematical operations, invariant-heavy code.

## Test Organization

### Arrange-Act-Assert (AAA)
```
// Arrange: set up test data and preconditions
// Act: execute the behavior under test
// Assert: verify the outcome
```

### Test Naming
- Describe the scenario and expected outcome
- `shouldReturnEmptyListWhenNoUsersExist`
- `test_login_fails_with_expired_token`
- `creates user with valid input`

### Directory Structure
```
tests/
├── unit/           # Fast, isolated, pure logic
├── integration/    # Real database, real HTTP, real services
└── e2e/            # Full user journeys, real environment
```

Match the existing project convention. If no convention exists, prefer the separated structure.
