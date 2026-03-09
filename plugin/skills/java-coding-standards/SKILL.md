---
name: java-coding-standards
description: "Java coding standards and conventions. Auto-loaded when working with .java files."
disable-model-invocation: false
user-invocable: false
---

# Java Coding Standards

Domain knowledge for Java development. Follow these conventions when implementing Java code.

## Naming Conventions

- Classes/Interfaces: `PascalCase` — `OrderService`, `PaymentProcessor`
- Methods/Variables: `camelCase` — `calculateTotal`, `orderCount`
- Constants: `UPPER_SNAKE_CASE` — `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT`
- Packages: all lowercase, reverse domain — `com.example.order.service`
- Generics: single uppercase letters — `T`, `E`, `K`, `V`

## Class Design

- Favor composition over inheritance
- Classes should be final by default — only open for extension when designed for it
- One public class per file
- Keep fields private, expose behavior through methods
- Use sealed classes/interfaces (17+) for restricted hierarchies
- Records (16+) for immutable data carriers: `record Point(int x, int y) {}`

## Method Design

- Methods should do one thing and do it well
- Maximum 3-4 parameters — use a parameter object for more
- Return `Optional<T>` instead of nullable return types
- Never return null collections — return empty collections
- Use `var` (10+) for local variables when type is obvious from context

## Exception Handling

- Use checked exceptions for recoverable conditions, unchecked for programming errors
- Create domain-specific exception hierarchies: `OrderNotFoundException extends RuntimeException`
- Never catch `Exception` or `Throwable` broadly — catch specific types
- Always include context in exception messages
- Use try-with-resources for all `AutoCloseable` resources
- Log exceptions at the boundary — don't log and rethrow

## Collections and Streams

- Use `List.of()`, `Map.of()`, `Set.of()` for immutable collections
- Prefer `List.copyOf()` over `Collections.unmodifiableList()`
- Use Streams for declarative data transformations, not imperative loops
- Don't overuse streams — complex logic is clearer as loops
- Use `Collectors.toUnmodifiableList()` for immutable stream results

## Null Safety

- Use `Optional<T>` for return types that may be absent
- Never use `Optional` as a field or parameter type
- Use `Objects.requireNonNull()` in constructors for early validation
- Consider `@Nullable` / `@NonNull` annotations for API boundaries
- Use `Optional.map().orElseThrow()` chains instead of null checks

## Testing

- JUnit 5 with `@Test`, `@DisplayName`, `@Nested` for test organization
- Use `@ParameterizedTest` for test variants
- AssertJ for fluent assertions: `assertThat(result).isEqualTo(expected)`
- Mockito for mocking: mock at boundaries, not internal collaborators
- Use `@ExtendWith(MockitoExtension.class)` over `@RunWith`
- Test naming: `methodName_scenario_expectedBehavior` or descriptive sentences

## Common Anti-Patterns to Avoid

- God classes with too many responsibilities
- Utility classes with only static methods — consider proper OO design
- Premature abstraction — don't create interfaces for single implementations
- Stringly-typed code — use enums and typed objects
- Ignoring generics warnings with `@SuppressWarnings("unchecked")`
- Deep inheritance hierarchies — prefer composition
