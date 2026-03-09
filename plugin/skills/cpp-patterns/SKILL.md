---
name: cpp-patterns
description: "C++ development conventions, patterns, testing, and best practices. Auto-loaded when working with .c/.cpp/.h files."
disable-model-invocation: false
user-invocable: false
---

# C++ Patterns

Domain knowledge for modern C++ (17/20/23) development. Follow these conventions when implementing C++ code.

## RAII and Resource Management

- Bind resource lifetime to object lifetime — never leak resources
- Use `std::unique_ptr` for exclusive ownership, `std::shared_ptr` only when sharing is required
- Use `std::make_unique` and `std::make_shared` — never naked `new`/`delete`
- Raw pointers (`T*`) are non-owning observers only
- Prefer scoped objects on the stack; avoid unnecessary heap allocation
- Use `std::exchange` in move constructors to leave moved-from objects in a valid state

## Rule of Zero / Rule of Five

- **Rule of Zero**: If all members are value types or smart pointers, define no special members — let the compiler generate them
- **Rule of Five**: If you manage a resource directly, define destructor, copy constructor, copy assignment, move constructor, and move assignment
- Never define only some of the five — either all or none

```cpp
// Rule of Zero — preferred: all members handle themselves
struct Config { std::string name; std::vector<int> values; };

// Rule of Five — only when managing raw resources
class Buffer {
public:
    explicit Buffer(std::size_t size);
    ~Buffer() = default;
    Buffer(const Buffer&);              Buffer& operator=(const Buffer&);
    Buffer(Buffer&&) noexcept = default; Buffer& operator=(Buffer&&) noexcept = default;
private:
    std::unique_ptr<char[]> data_;
    std::size_t size_;
};
```

## Modern C++ Features

- **Concepts (C++20)**: Constrain templates — prefer standard concepts (`std::integral`, `std::ranges::range`)
- **constexpr**: Use for compile-time computation; prefer over macros and magic constants
- **Structured bindings**: `auto [key, value] = map_entry;`
- **Ranges (C++20)**: Use `std::ranges::sort`, `std::views::filter` over raw iterator pairs
- **`std::optional`**: For values that may not exist — never use sentinel values
- **`std::string_view`**: For non-owning string parameters — prefer over `const std::string&`
- **`enum class`**: Always scoped enums — plain `enum` leaks names into enclosing scope
- **`using`** over `typedef` for type aliases

```cpp
// Concepts
template<std::integral T>
T gcd(T a, T b) { while (b) { a = std::exchange(b, a % b); } return a; }

// Ranges + structured bindings
for (const auto& [name, score] : scores | std::views::filter([](auto& p) { return p.second > 90; })) {
    fmt::print("{}: {}\n", name, score);
}
```

## Error Handling

- Use exceptions for errors that cannot be handled locally — throw by value, catch by `const&`
- Define custom exception types inheriting from `std::runtime_error` or `std::exception`
- Mark functions `noexcept` when they must not throw (destructors, move operations, swap)
- Use `std::expected` (C++23) or `std::optional` for expected failure paths
- Never throw built-in types (`int`, string literals) or catch by value (slicing risk)
- Never use empty catch blocks — handle or propagate

```cpp
class AppError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

void process(const std::string& path) {
    if (!valid(path)) throw AppError("invalid path: " + path);
}
```

## Concurrency

- Use `std::jthread` (C++20) over `std::thread` — automatic join on destruction
- Use `std::scoped_lock` for multiple mutexes (deadlock-free), `std::lock_guard` for single
- Always name lock guards — unnamed guards destroy immediately
- Use `std::condition_variable` with a predicate — never wait without a condition
- Prefer `std::atomic` for simple shared counters/flags
- Never use `volatile` for synchronization — it is for hardware I/O only
- Avoid lock-free programming unless you have deep expertise and profiling data

```cpp
class ThreadSafeQueue {
    std::mutex mutex_;
    std::condition_variable cv_;
    std::queue<int> queue_;
public:
    void push(int v) {
        std::lock_guard lock(mutex_);  // RAII lock, always named
        queue_.push(v);
        cv_.notify_one();
    }
    int pop() {
        std::unique_lock lock(mutex_);
        cv_.wait(lock, [this] { return !queue_.empty(); });  // predicate guard
        int v = queue_.front(); queue_.pop(); return v;
    }
};
```

## Testing with GoogleTest

- Use `TEST()` for standalone tests, `TEST_F()` with fixtures for shared setup
- `EXPECT_*` for non-fatal checks (continue test), `ASSERT_*` for fatal preconditions (stop test)
- Use GoogleMock (`MOCK_METHOD`) for interaction testing — prefer fakes for stateful behavior
- Follow TDD: RED (failing test) -> GREEN (minimal fix) -> REFACTOR

```cpp
// Fixture with shared setup
class CacheTest : public ::testing::Test {
protected:
    void SetUp() override { cache = std::make_unique<Cache>(100); }
    std::unique_ptr<Cache> cache;
};
TEST_F(CacheTest, ReturnsStoredValue) {
    cache->put("key", "val");
    EXPECT_EQ(cache->get("key"), "val");
}

// GoogleMock for interaction testing
class MockSender : public Sender {
public:
    MOCK_METHOD(void, Send, (const std::string& msg), (override));
};
TEST(ServiceTest, NotifiesOnPublish) {
    MockSender sender;
    EXPECT_CALL(sender, Send("hello")).Times(1);
    Service(sender).Publish("hello");
}
```

## Sanitizers

- **ASan** (`-fsanitize=address`): Detects buffer overflows, use-after-free, leaks
- **UBSan** (`-fsanitize=undefined`): Detects signed overflow, null dereference, alignment
- **TSan** (`-fsanitize=thread`): Detects data races in multithreaded code
- Always run sanitizers in CI — combine with `-fno-omit-frame-pointer` for readable stacks
- ASan and TSan cannot run simultaneously — use separate CI jobs

## Anti-Patterns

- Naked `new`/`delete` — use smart pointers or RAII wrappers
- `malloc()`/`free()` in C++ code — use containers and smart pointers
- `void*` for type erasure — use templates, `std::variant`, or `std::any`
- C-style casts `(int)x` — use `static_cast`, `dynamic_cast`, `const_cast`
- `using namespace std;` in headers at global scope
- Uninitialized variables — always initialize at declaration
- `0` or `NULL` as pointer — use `nullptr`
- `std::endl` — use `'\n'` (endl forces a flush)
- Magic numbers — use `constexpr` named constants
- Mixing signed and unsigned arithmetic without explicit conversion
- `volatile` for thread synchronization
- Detaching threads — lifetime management becomes impossible
