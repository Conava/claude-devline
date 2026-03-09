---
name: golang-patterns
description: "Go development conventions, patterns, and best practices. Auto-loaded when working with .go files."
disable-model-invocation: false
user-invocable: false
---

# Go Patterns

Domain knowledge for Go development. Follow these conventions when implementing Go code.

## Project Structure

- Follow standard Go project layout
- `cmd/` for main applications, `internal/` for private packages, `pkg/` for public library code
- One package per directory, package name matches directory name
- `_test.go` suffix for test files in the same package

## Code Style

- Follow `gofmt` formatting unconditionally
- Use `golint` and `go vet` conventions
- Exported names: `PascalCase`. Unexported: `camelCase`
- Acronyms all caps: `HTTPServer`, `XMLParser`, `userID`
- Interface names: single-method interfaces use method name + `er` suffix (`Reader`, `Writer`, `Closer`)

## Error Handling

- Return errors as the last return value: `func Foo() (Result, error)`
- Check errors immediately — never ignore with `_`
- Wrap errors with context: `fmt.Errorf("failed to process order %d: %w", id, err)`
- Use `errors.Is()` and `errors.As()` for error checking, not string comparison
- Define sentinel errors as package-level vars: `var ErrNotFound = errors.New("not found")`
- Use custom error types for errors needing additional context

## Concurrency

- Use goroutines for concurrent work, channels for communication
- Prefer `sync.WaitGroup` for fork-join parallelism
- Use `context.Context` for cancellation and timeouts — pass as first parameter
- Never start goroutines without a way to stop them (use context or done channels)
- Use `sync.Mutex` for simple shared state, channels for coordination
- Use `errgroup.Group` for concurrent tasks that can fail

## Interfaces

- Define interfaces at the consumer, not the implementer
- Keep interfaces small — prefer 1-2 methods
- Accept interfaces, return structs
- Use `io.Reader`, `io.Writer` and standard library interfaces where possible
- Don't export interfaces that have only one implementation

## Testing

### Table-Driven Tests

The standard Go testing pattern. Use subtests with `t.Run()` for isolation and readable output.

```go
func TestParseConfig(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *Config
        wantErr bool
    }{
        {
            name:  "valid config",
            input: `{"host": "localhost", "port": 8080}`,
            want:  &Config{Host: "localhost", Port: 8080},
        },
        {
            name:    "invalid JSON",
            input:   `{invalid}`,
            wantErr: true,
        },
        {
            name:    "empty input",
            input:   "",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseConfig(tt.input)
            if tt.wantErr {
                if err == nil {
                    t.Error("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %+v; want %+v", got, tt.want)
            }
        })
    }
}
```

### Test Helpers

- Call `t.Helper()` in helper functions for accurate line reporting
- Use `t.Cleanup()` for resource teardown
- Use `t.TempDir()` for temporary files (auto-cleaned)
- Use `testify/assert` or `testify/require` only if project already uses them

### Golden File Testing

Store expected output in `testdata/` and compare against it. Update with `-update` flag.

```go
var update = flag.Bool("update", false, "update golden files")

func TestRender(t *testing.T) {
    got := Render(input)
    golden := filepath.Join("testdata", "expected.golden")

    if *update {
        os.WriteFile(golden, got, 0644)
    }

    want, _ := os.ReadFile(golden)
    if !bytes.Equal(got, want) {
        t.Errorf("output mismatch:\ngot:\n%s\nwant:\n%s", got, want)
    }
}
```

### Benchmarking

Use `testing.B` with `b.ReportAllocs()` for memory tracking and `b.Run()` for sub-benchmarks.

```go
func BenchmarkProcess(b *testing.B) {
    data := generateTestData(1000)
    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        Process(data)
    }
}

// Run: go test -bench=BenchmarkProcess -benchmem
// Output: BenchmarkProcess-8   10000   105234 ns/op   4096 B/op   10 allocs/op
```

### Fuzzing (Go 1.18+)

Use `FuzzXxx` functions with a seed corpus for property-based testing of input validation.

```go
func FuzzParseJSON(f *testing.F) {
    // Seed corpus
    f.Add(`{"name": "test"}`)
    f.Add(`[]`)
    f.Add(`""`)

    f.Fuzz(func(t *testing.T, input string) {
        var result map[string]interface{}
        err := json.Unmarshal([]byte(input), &result)
        if err != nil {
            return // Invalid input is expected
        }
        // If parsing succeeded, re-encoding should work
        _, err = json.Marshal(result)
        if err != nil {
            t.Errorf("Marshal failed after successful Unmarshal: %v", err)
        }
    })
}

// Run: go test -fuzz=FuzzParseJSON -fuzztime=30s
```

### HTTP Handler Testing

Use `httptest` for testing HTTP handlers without starting a real server.

```go
func TestAPIHandler(t *testing.T) {
    tests := []struct {
        name       string
        method     string
        path       string
        body       string
        wantStatus int
    }{
        {"get user", http.MethodGet, "/users/123", "", http.StatusOK},
        {"not found", http.MethodGet, "/users/999", "", http.StatusNotFound},
        {"create user", http.MethodPost, "/users", `{"name":"Bob"}`, http.StatusCreated},
    }

    handler := NewAPIHandler()
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            var body io.Reader
            if tt.body != "" {
                body = strings.NewReader(tt.body)
            }
            req := httptest.NewRequest(tt.method, tt.path, body)
            req.Header.Set("Content-Type", "application/json")
            w := httptest.NewRecorder()

            handler.ServeHTTP(w, req)

            if w.Code != tt.wantStatus {
                t.Errorf("got status %d; want %d", w.Code, tt.wantStatus)
            }
        })
    }
}
```

### Coverage Targets

| Code Type | Target |
|-----------|--------|
| Critical business logic | 100% |
| Public APIs | 90%+ |
| General code | 80%+ |
| Generated code | Exclude |

```bash
go test -cover -coverprofile=coverage.out ./...
go tool cover -func=coverage.out       # Per-function coverage
go tool cover -html=coverage.out       # Visual HTML report
go test -race -coverprofile=coverage.out ./...  # With race detection
```

## Common Anti-Patterns to Avoid

- Returning `interface{}` / `any` — use generics (1.18+) or concrete types
- Panicking in library code — return errors instead
- Goroutine leaks — always ensure goroutines can exit
- Using `init()` for complex logic — prefer explicit initialization
- Overusing channels when a mutex would be simpler
- Package-level global state — prefer dependency injection
