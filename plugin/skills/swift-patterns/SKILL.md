---
name: swift-patterns
description: "Swift/SwiftUI development conventions, concurrency, DI, and testing patterns for iOS/macOS. Loaded manually via /skills-load swift."
disable-model-invocation: false
user-invocable: false
---

# Swift Patterns

Domain knowledge for Swift and SwiftUI development on Apple platforms. Follow these conventions when implementing Swift code.

## SwiftUI State Management

Choose the simplest property wrapper that fits:

| Wrapper | Use Case |
|---------|----------|
| `@State` | View-local value types (toggles, form fields, sheet flags) |
| `@Binding` | Two-way reference to parent's `@State` |
| `@Observable` class + `@State` | Owned model with multiple properties |
| `@Observable` class (no wrapper) | Read-only reference passed from parent |
| `@Bindable` | Two-way binding to an `@Observable` property |
| `@Environment` | Shared dependencies injected via `.environment()` |

Use `@Observable` (not `ObservableObject`) -- it tracks property-level changes so only views reading changed properties re-render.

## View Composition

- Extract subviews into small focused structs -- only the subview reading changed state re-renders
- Use `ViewModifier` for reusable styling, extend `View` with convenience methods
- Use `#Preview` macro with mock data for fast iteration
- Use `LazyVStack`/`LazyHStack` for large collections -- creates views only when visible
- Use stable `Identifiable` IDs in `ForEach` -- never array indices
- Never do I/O or heavy computation in `body` -- use `.task {}` for async work

```swift
@Observable
final class ItemListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private let repository: any ItemRepository

    init(repository: any ItemRepository = DefaultItemRepository()) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await repository.fetchAll()) ?? []
    }
}

struct ItemListView: View {
    @State private var viewModel = ItemListViewModel()

    var body: some View {
        List(viewModel.items) { ItemRow(item: $0) }
            .overlay { if viewModel.isLoading { ProgressView() } }
            .task { await viewModel.load() }
    }
}
```

## Navigation

Use `NavigationStack` with `NavigationPath` and typed `Hashable` destination enums for programmatic routing. Wrap in an `@Observable` Router class injected via `.environment()`.

## Swift Concurrency

- **async/await**: Prefer structured concurrency — use `async let` for parallel independent work, `TaskGroup` for dynamic parallelism
- **Actors**: Use actors for shared mutable state — compiler-enforced serialized access, no manual locks
- **MainActor**: Annotate UI-related classes with `@MainActor`; use `.task {}` in views
- **Swift 6.2**: Async functions stay on the calling actor by default — concurrency is opt-in with `@concurrent`
- **Sendable**: All types crossing actor boundaries must be `Sendable`
- **Isolated conformances (6.2)**: MainActor types can conform to non-isolated protocols with `@MainActor Exportable`

```swift
// Actor-based repository — thread-safe by design
public actor LocalRepository<T: Codable & Identifiable> where T.ID == String {
    private var cache: [String: T] = [:]
    public func save(_ item: T) throws { cache[item.id] = item; try persistToFile() }
    public func find(by id: String) -> T? { cache[id] }
}

// @concurrent for CPU-intensive background work (Swift 6.2)
@concurrent
static func extractSubject(from data: Data) async -> Sticker { /* ... */ }
```

## Protocol-Based Dependency Injection

Define small, focused protocols for external boundaries (file system, network, APIs). Inject via default parameters — production uses real implementations, tests inject mocks:

```swift
public protocol FileAccessorProviding: Sendable {
    func read(from url: URL) throws -> Data
    func write(_ data: Data, to url: URL) throws
}

public actor SyncManager {
    private let fileAccessor: FileAccessorProviding

    public init(fileAccessor: FileAccessorProviding = DefaultFileAccessor()) {
        self.fileAccessor = fileAccessor
    }

    public func sync() async throws {
        let data = try fileAccessor.read(from: syncURL)
        // Process...
    }
}
```

## Error Handling

- Use `Result<T, E>` for errors that callers should handle explicitly
- Use typed throws (Swift 6+): `func load() throws(LoadError)` for precise error types
- Use `do`/`catch` with pattern matching for recovery
- Use `guard` for early exits — keeps the happy path unindented
- Use `defer` for cleanup that must run regardless of exit path

## Testing

### Swift Testing (preferred for new code)

```swift
import Testing

@Test("Sync manager handles missing container")
func testMissingContainer() async {
    let manager = SyncManager(fileSystem: MockFileSystem(containerURL: nil))
    await #expect(throws: SyncError.containerNotAvailable) {
        try await manager.sync()
    }
}
```

### XCTest (existing codebases)

- Use `XCTestCase` subclasses with `setUp()`/`tearDown()`
- `XCTAssertEqual`, `XCTAssertThrowsError` for assertions
- Test async code with `async` test methods

### Mock Design

- Mock only external boundaries — never internal types
- Design mocks with configurable error properties for testing failure paths
- Use `@unchecked Sendable` on mock classes when needed for actor-boundary crossing
- Prefer fakes (in-memory implementations) over strict mock verification for stateful behavior

```swift
final class MockFileAccessor: FileAccessorProviding, @unchecked Sendable {
    var files: [URL: Data] = [:]
    var readError: Error?

    func read(from url: URL) throws -> Data {
        if let error = readError { throw error }
        guard let data = files[url] else { throw CocoaError(.fileReadNoSuchFile) }
        return data
    }

    func write(_ data: Data, to url: URL) throws { files[url] = data }
}
```

## Anti-Patterns

- `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` in new code — use `@Observable`
- `AnyView` type erasure — use `@ViewBuilder` or `Group` for conditional views
- Putting async work in `body` or `init` — use `.task {}`
- `DispatchQueue` for synchronization in new code — use actors
- `nonisolated` to suppress compiler errors without understanding isolation
- `@concurrent` on every async function — most do not need background execution
- `#if DEBUG` conditionals instead of proper dependency injection
- God protocols with many methods — keep protocols focused on one concern
- Fighting the concurrency compiler — if it reports a data race, the code has a real issue
- Force-unwrapping optionals in production code — use `guard let` or `if let`
