# TDD Framework Patterns

Language and framework-specific TDD patterns. Use the find-docs skill (`npx -y ctx7`) to look up current API documentation for any framework mentioned here.

## JavaScript / TypeScript

### Jest / Vitest
```typescript
describe('UserService', () => {
  it('should create a user with valid input', () => {
    const user = createUser({ name: 'Alice', email: 'alice@example.com' });
    expect(user.id).toBeDefined();
    expect(user.name).toBe('Alice');
  });

  it('should throw on invalid email', () => {
    expect(() => createUser({ name: 'Alice', email: 'invalid' }))
      .toThrow('Invalid email');
  });
});
```

**Conventions:**
- Test files: `*.test.ts` or `*.spec.ts`
- Collocate with source or in `__tests__/` directory
- Use `describe` for grouping, `it` for individual cases
- Mock external dependencies with `vi.mock()` (Vitest) or `jest.mock()`

### React Testing Library
```typescript
import { render, screen, fireEvent } from '@testing-library/react';

test('submits form with valid data', async () => {
  render(<LoginForm onSubmit={mockSubmit} />);

  await userEvent.type(screen.getByLabelText('Email'), 'user@example.com');
  await userEvent.click(screen.getByRole('button', { name: 'Submit' }));

  expect(mockSubmit).toHaveBeenCalledWith({ email: 'user@example.com' });
});
```

**Key principle:** Test behavior, not implementation. Query by role, label, or text — not by CSS class or test ID.

## Python

### pytest
```python
def test_create_user_with_valid_input():
    user = create_user(name="Alice", email="alice@example.com")
    assert user.id is not None
    assert user.name == "Alice"

def test_create_user_raises_on_invalid_email():
    with pytest.raises(ValueError, match="Invalid email"):
        create_user(name="Alice", email="invalid")
```

**Conventions:**
- Test files: `test_*.py` or `*_test.py`
- Test functions: `test_*`
- Use `conftest.py` for shared fixtures
- Use `@pytest.fixture` for test setup
- Use `@pytest.mark.parametrize` for data-driven tests

### Django
```python
from django.test import TestCase

class UserAPITest(TestCase):
    def test_create_user_endpoint(self):
        response = self.client.post('/api/users/', {
            'name': 'Alice', 'email': 'alice@example.com'
        })
        self.assertEqual(response.status_code, 201)
```

## Go

```go
func TestCreateUser(t *testing.T) {
    user, err := CreateUser("Alice", "alice@example.com")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "Alice" {
        t.Errorf("got name %q, want %q", user.Name, "Alice")
    }
}

func TestCreateUser_InvalidEmail(t *testing.T) {
    _, err := CreateUser("Alice", "invalid")
    if err == nil {
        t.Fatal("expected error for invalid email")
    }
}
```

**Conventions:**
- Test files: `*_test.go` in same package
- Table-driven tests for multiple cases
- Use `t.Helper()` for test utility functions
- Use `testify` for assertion helpers if the project uses it

## Java / Kotlin

### JUnit 5
```java
@Test
void shouldCreateUserWithValidInput() {
    User user = userService.create("Alice", "alice@example.com");
    assertNotNull(user.getId());
    assertEquals("Alice", user.getName());
}

@Test
void shouldThrowOnInvalidEmail() {
    assertThrows(IllegalArgumentException.class, () ->
        userService.create("Alice", "invalid")
    );
}
```

**Conventions:**
- Test classes: `*Test.java` in `src/test/java/`
- Use `@BeforeEach` for setup
- Use `@ParameterizedTest` for data-driven tests
- Use Mockito for mocking: `@Mock`, `when().thenReturn()`

## Rust

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_user_with_valid_input() {
        let user = create_user("Alice", "alice@example.com").unwrap();
        assert_eq!(user.name, "Alice");
    }

    #[test]
    #[should_panic(expected = "Invalid email")]
    fn create_user_invalid_email() {
        create_user("Alice", "invalid").unwrap();
    }
}
```

**Conventions:**
- Tests in `#[cfg(test)]` module within the source file
- Integration tests in `tests/` directory
- Use `assert_eq!`, `assert_ne!`, `assert!`

## Dart / Flutter

```dart
test('creates user with valid input', () {
  final user = createUser(name: 'Alice', email: 'alice@example.com');
  expect(user.id, isNotNull);
  expect(user.name, equals('Alice'));
});

testWidgets('submits login form', (tester) async {
  await tester.pumpWidget(LoginForm());
  await tester.enterText(find.byType(TextField), 'user@example.com');
  await tester.tap(find.text('Submit'));
  await tester.pump();
  expect(find.text('Welcome'), findsOneWidget);
});
```
