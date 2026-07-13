# Debugging Reference

On-demand pattern recognition and tooling for the debugger. The core scientific process (Reproduce → Evidence → Hypothesize → Test → Fix → Verify) lives in the agent; this is the supplementary catalog. Use find-docs (`npx ctx7@latest`) for current docs on any tool here.

## Common Bug Patterns (symptoms → causes → investigation)

**Null / undefined** (`NullPointerException`, `TypeError: Cannot read properties of undefined`, `AttributeError: 'NoneType'`): uninitialized var used before assignment; error path returns null/undefined; optional field accessed without check; Promise not awaited; array index out of bounds. → Find the exact null variable, trace back to where it should be assigned, check every code path (is there one that skips assignment?), check for async timing gaps.

**Off-by-one** (index out of bounds, missing first/last, loop runs ±1): `<` vs `<=`; 0- vs 1-indexed; fence-post (N items → N-1 separators); exclusive slice end. → Check index 0, length-1, length; trace the loop for 0, 1, 2 elements; confirm inclusive vs exclusive end.

**Race conditions** (intermittent, works in debugger, different result each run): shared mutable state without synchronization; check-then-act without atomicity; ordering assumed without guarantees; stale closures. → Identify shared mutable state, check synchronization (mutex/lock/atomic/channel), log with timestamps + thread/goroutine IDs, use race detectors (`go test -race`, TSan).

**Memory leaks** (growing memory, OOM, slowdown over time): listeners added never removed; cache without eviction; closures holding large objects; unclosed connections/handles/streams; circular references. → Profile over time, take heap snapshots at intervals, diff them for growing objects.

**Deadlocks** (hang, no CPU, logs stop): mutual lock waits; channel send/receive with no counterpart; DB transaction lock contention. → Thread/goroutine dump, find blocked threads and what they wait on, check lock ordering consistency, check unbuffered channels with no receiver.

**Serialization** (wrong types after parse, missing fields, date/encoding errors): JSON number precision loss (large ints in JS); timezone (UTC vs local); encoding mismatch (UTF-8 vs Latin-1); missing fields → null; field-name case sensitivity. → Log raw serialized data before parse, compare expected vs actual types, verify both sides agree on names/types.

**Connection / timeout** (`ECONNREFUSED`, timeouts, intermittent 5xx): service not running; wrong host/port; pool exhausted; firewall/DNS/TLS. → Verify target reachable, check config, monitor pool metrics, look for connection leaks, test with curl/telnet.

**Integration issues:** check API contracts (caller sends what callee expects); verify serialization; check timeouts/retries/error handling.

**State management:** mutation where it shouldn't happen; stale closures/cached values/shallow copies; invalid state transitions.

## Debugging Tools by Language

**JS/TS:** `console.log/table/trace`, `debugger`, Chrome DevTools, `node --inspect`; `debug` package, `why-is-node-running`, `clinic.js`. Errors: `Cannot read properties of undefined` (trace to source), `X is not defined` (scope/import/spelling), unhandled rejection (missing `.catch`/`try`), `ECONNREFUSED` (service down/wrong port).

**Python:** `breakpoint()` / `pdb`, `traceback.print_exc()`, `python -m pdb`; `ipdb`, `rich.traceback`, `py-spy` (sampling profiler, no code changes), `memory_profiler`. Errors: `AttributeError: 'NoneType'` (unexpected None), `ImportError` (path/venv/`__init__.py`), `KeyError` (use `.get()`), `IndentationError` (tabs vs spaces).

**Go:** `fmt.Printf("%+v")`, `runtime/pprof`, `runtime.Stack()`; `dlv` (Delve), `go test -race`, `go vet`, `go tool pprof -http=:8080`. Errors: nil pointer deref (check pointer returns), deadlock (channel/mutex), data race (`-race`).

**Java/Kotlin:** IDE debugger, `jstack <pid>` thread dumps, `-verbose:gc`; VisualVM, JProfiler, Arthas, async-profiler. Errors: NPE (Optional/null safety), `ClassNotFoundException` (classpath), `OutOfMemoryError` (heap dump + MAT/VisualVM), `ConcurrentModificationException` (mutating while iterating).

**Rust:** `dbg!()`, `println!("{:?}")`, `RUST_BACKTRACE=1`, `RUST_LOG=debug`; `rust-gdb`/`rust-lldb`, `cargo flamegraph`, `cargo clippy`, `miri`. Errors: borrow checker (restructure ownership or `Rc`/`Arc`), `unwrap()` panic (handle `Option`/`Result`), lifetime errors.

## General Techniques

**Git bisect** — binary-search the breaking commit:
```bash
git bisect start
git bisect bad            # current is broken
git bisect good v1.0      # this worked
# test each checkout, mark good/bad
git bisect reset
```

**Rubber duck** — explain the problem step-by-step out loud; articulating often reveals it.

**Structured printf** — print at function entry (inputs), decision points (conditions), and exit (outputs); remove all after fixing.
