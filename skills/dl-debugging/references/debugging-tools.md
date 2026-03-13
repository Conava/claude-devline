# Debugging Tools by Language

Use context7 MCP to look up current documentation for any tool mentioned here.

## JavaScript / TypeScript

### Built-in
- `console.log()`, `console.table()`, `console.trace()`
- `debugger` statement (triggers breakpoint in DevTools)
- Chrome DevTools: breakpoints, call stack, scope inspection
- Node.js: `node --inspect` + Chrome DevTools

### Libraries
- `debug` package: namespaced debug logging
- `why-is-node-running`: find what's keeping Node alive
- `clinic.js`: performance profiling (flame graphs, event loop)

### Common Errors
- `TypeError: Cannot read properties of undefined` — trace the variable back to its source
- `ReferenceError: X is not defined` — check scope, imports, spelling
- `Unhandled promise rejection` — missing `.catch()` or `try/catch` in async
- `ECONNREFUSED` — target service not running or wrong port

## Python

### Built-in
- `print()` for quick inspection
- `breakpoint()` (Python 3.7+) or `import pdb; pdb.set_trace()`
- `traceback.print_exc()` for exception details
- `python -m pdb script.py` for command-line debugging

### Libraries
- `ipdb`: Enhanced pdb with IPython features
- `rich.traceback`: Beautiful tracebacks
- `py-spy`: Sampling profiler (no code changes needed)
- `memory_profiler`: Track memory usage

### Common Errors
- `AttributeError: 'NoneType'` — something returned None unexpectedly
- `ImportError` — check module path, virtual environment, `__init__.py`
- `KeyError` — dict key doesn't exist, use `.get()` with default
- `IndentationError` — mixed tabs and spaces

## Go

### Built-in
- `fmt.Printf()` with `%+v` for struct details
- `log.Printf()` for timestamped output
- `runtime/pprof` for CPU/memory profiling
- `runtime.Stack()` for goroutine dumps

### Tools
- `dlv` (Delve): Go debugger with breakpoints and goroutine inspection
- `go test -race`: Detect race conditions
- `go vet`: Static analysis
- `pprof` web UI: `go tool pprof -http=:8080 profile.pb.gz`

### Common Errors
- `nil pointer dereference` — check all pointer returns before use
- `deadlock` — goroutines waiting on each other; check channel/mutex usage
- `data race` — shared state without synchronization; use `-race` flag

## Java / Kotlin

### Built-in
- IDE debugger (IntelliJ, Eclipse): breakpoints, watches, evaluate expression
- `System.out.println()` / `println()` (Kotlin)
- JVM flags: `-verbose:gc`, `-Xlog:gc*`
- Thread dumps: `jstack <pid>`

### Tools
- VisualVM: Memory, CPU, thread monitoring
- JProfiler: Commercial profiler
- Arthas: Runtime diagnostic tool
- async-profiler: Low-overhead profiler

### Common Errors
- `NullPointerException` — use `Optional`, null checks, or Kotlin null safety
- `ClassNotFoundException` — classpath issue, check dependencies
- `OutOfMemoryError` — heap dump analysis with MAT or VisualVM
- `ConcurrentModificationException` — iterating while modifying collection

## Rust

### Built-in
- `dbg!()` macro: prints expression and value with file:line
- `println!("{:?}", value)` for Debug trait output
- `RUST_BACKTRACE=1` for stack traces on panic
- `RUST_LOG=debug` with `env_logger` for log levels

### Tools
- `rust-gdb` / `rust-lldb`: Debuggers with Rust-aware pretty printing
- `cargo flamegraph`: CPU profiling flame graphs
- `cargo clippy`: Linting and common mistake detection
- `miri`: Detect undefined behavior

### Common Errors
- Borrow checker errors — restructure ownership or use `Rc`/`Arc`
- `unwrap()` panic — handle `Option`/`Result` properly
- Lifetime errors — annotate or restructure references

## General Techniques

### Binary Search (Git Bisect)
```bash
git bisect start
git bisect bad          # current commit is broken
git bisect good v1.0    # this version worked
# Git checks out middle commit, you test, mark good/bad
git bisect reset        # done
```

### Rubber Duck Debugging
Explain the problem step-by-step out loud. The act of articulating often reveals the issue.

### Printf Debugging (Structured)
Instead of random print statements:
1. Print at function entry with inputs
2. Print at decision points with conditions
3. Print at function exit with outputs
4. Remove all prints after fixing
