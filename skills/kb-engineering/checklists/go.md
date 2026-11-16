# Go checklist

Selected when the project has a `go.mod`; services and CLIs also read `backend.md`. Written against Go 1.24 to 1.27; items that need a newer release name it, and the module's `go` directive decides what you may use. Generic timeout, retry and error rules live in `reliability.md`, test method in `testing.md`, measurement method in `performance.md`; this file holds what is specific to Go.

## Context and cancellation

- **Pass `context.Context` as the first parameter, named `ctx`, to every call that blocks; never store it in a struct and never pass nil.** A stored or missing context cannot be cancelled by the caller. Check: `grep -rn 'context.Background()\|context.TODO()' --include='*.go' .` shows only `main`, tests and top-level jobs; no struct field has type `context.Context`; staticcheck SA1012 (nil context) is clean.
- **Call every cancel function on every path.** A cancel that is never called leaks the child context until the parent ends. Check: `defer cancel()` directly after each `WithCancel`, `WithTimeout` or `WithDeadline`; `go vet` (analyzer `lostcancel`) is clean.
- **Make outbound work inherit the caller's context.** A query or request built without it keeps running after the client has gone. Check: `http.NewRequestWithContext`, `QueryContext`, `ExecContext` and the like instead of the context-free variants; golangci-lint `noctx` and `contextcheck` on the changed packages where the project runs golangci-lint.
- **Detach work that must outlive the request with `context.WithoutCancel` (Go 1.21), and give it its own deadline.** `context.Background()` drops trace ids and values, while the request context cancels the write halfway. Check: detached work uses `WithoutCancel(ctx)` wrapped in `WithTimeout`, and the goroutine running it has an owner (next section).
- **Record why a context ended.** `ctx.Err()` only says "canceled" or "deadline exceeded". Check: where cancellation has several causes, `WithCancelCause` (Go 1.20) or `WithTimeoutCause` (Go 1.21) sets one, and error logs print `context.Cause(ctx)`.
- **Keep context values to request-scoped data that crosses API boundaries.** Optional parameters hidden in a context are invisible at the call site. Check: value keys use an unexported key type; no configuration or dependencies travel in `ctx`.

## Goroutines and channels

- **Give every goroutine an owner, a stop signal and a way to wait for it.** Fire-and-forget goroutines leak and outlive shutdown (Code Review Comments, uber-go guide). Check: no goroutines started in `init()`; long-lived workers stop through a `Close` or `Shutdown` method that waits; `goleak.VerifyTestMain(m)` in packages that start goroutines (`VerifyNone` cannot be used with `t.Parallel`).
- **Fan out with `errgroup` or `WaitGroup.Go`, and bound the fan-out.** Hand-rolled `Add` and `Done` race with `Wait`, and an unbounded loop of `go` statements is an unbounded queue. Check: `errgroup.WithContext` (the derived context is cancelled on the first error) with `SetLimit(n)`, or `sync.WaitGroup.Go` (Go 1.25); `Add` happens before the `go` statement, never inside it (`go vet` analyzer `waitgroup` (1.25 and 1.26, renamed `waitgroupgo` in 1.27), staticcheck SA2000).
- **Make every send and receive able to give up.** The classic leak: the receiver returns early on an error and the workers block forever sending on an unbuffered channel. Check: sends and receives that can outlive their peer sit in a `select` with `<-ctx.Done()`, or the channel is buffered to the number of senders; on Go 1.27 the `goroutineleak` profile (GOEXPERIMENT `goroutineleakprofile` on 1.26) reports goroutines blocked on unreachable channels and locks (Verify it).
- **Know the channel rules that panic or hang.** Sending on or closing a closed channel panics, closing a nil channel panics, a nil channel blocks forever, and a closed channel yields zero values at once. Check: only the single sender closes, exactly once (or under `sync.Once`); receivers use `v, ok := <-ch` or `range`; a nil channel in a `select` is a deliberate way to disable a case, with a comment.
- **Keep channel buffers at one or none unless the size is justified.** A large buffer hides back-pressure and delays the deadlock to production load (uber-go guide). Check: every buffer above 1 has a comment saying what bounds it.
- **Do not expect `select` to prefer a case.** When several cases are ready, one is chosen pseudo-randomly, so a ready `ctx.Done()` can lose to a ready work channel many times in a row. Check: loops that must stop promptly test `ctx.Err()` before taking more work; tests do not rely on case order.
- **Contain panics per goroutine.** A panic that reaches the top of any goroutine kills the whole program, and `recover` only works in a deferred call in that same goroutine. Check: goroutines that run plugin or callback code recover at their top and report the panic as an error; the rest let it crash under a supervisor (`reliability.md`).

## Shared memory and sync

- **Treat every data race as memory corruption, not as a benign glitch.** Races on interfaces, slices, maps and strings can tear their (pointer, length) or (pointer, type) pairs and corrupt arbitrary memory (Go memory model). Check: `go test -race` over unit and integration tests; the detector only sees races on paths that ran and costs 5-10x memory and 2-20x time, so also run a realistic workload with a `-race` build when concurrency changed.
- **Never synchronise through a plain variable.** Double-checked locking and busy-waiting on a `bool` are not guaranteed to see the other goroutine's writes, and the loop may never end. Check: one-time setup uses `sync.Once`, `sync.OnceValue` or `sync.OnceValues` (Go 1.21); flags and counters use typed atomics such as `atomic.Bool` and `atomic.Int64`, not raw `sync/atomic` functions on plain fields.
- **Never copy a `Mutex`, `RWMutex`, `WaitGroup`, `Cond`, `Once` or `sync.Map` after first use.** The copy has its own lock state and protects nothing. Check: `go vet` (analyzer `copylocks`) is clean; types holding a mutex use pointer receivers; mutexes are named fields, not embedded (uber-go guide).
- **Never take an `RLock` while already holding one on the same `RWMutex`.** A waiting writer blocks new readers, so recursive read locking deadlocks under write load. Check: helpers called with the read lock held do not lock again; a test runs readers alongside a writer.
- **Use `sync.Map` only for write-once, read-many caches or disjoint key sets.** For anything else a plain map with a mutex is faster and clearer. Check: each new `sync.Map` names which of the two cases applies.
- **Know whether loop variables are per iteration.** Only modules whose `go.mod` says `go 1.22` or later get a fresh variable per iteration; older ones share one, which also makes `t.Parallel` subtests silently test only the last case. Check: read the `go` directive before reasoning about closures in loops; `go vet` (analyzer `loopclosure`) is clean on older modules.

## Errors and nil

- **Never discard an error with `_`.** A dropped error turns a failure into wrong data later. Check: golangci-lint `errcheck` or a grep for `_ = ` and `_, _ =` on calls that return `error` in the diff; each remaining discard has a comment.
- **Wrap with `%w` to expose a cause and `%v` to hide it; match with `errors.Is` and `errors.As`.** Wrapping makes the inner error part of your API, and `==` or a type assertion misses wrapped errors. Check: no `err == ErrX` or `err.(*T)` on errors that may be wrapped (golangci-lint `errorlint`); `errors.AsType` where the module is on Go 1.26; on Go 1.27 `go vet` also flags wrapping a `*E` whose `E` implements `error`. Handle each error once (`reliability.md`).
- **Return a literal `nil` for "no error", never a typed nil pointer.** An `error` holding a nil `*MyError` has a type and compares non-nil, so callers see a failure that did not happen (Go FAQ). Check: functions returning `error` end in `return nil`, not a nil-valued concrete variable; staticcheck SA4023; a test asserts `err == nil` on the success path.
- **Check the error before touching any other result.** From Go 1.25 the compiler no longer delays nil checks, so code that used a result before checking `err` now panics. Check: no use of a returned value between the call and its `if err != nil`.
- **Use the comma-ok form for every type assertion on outside data.** A failed single-value assertion panics. Check: grep `\.([A-Za-z*]` assertions in the diff for a missing `, ok`.
- **Exit and panic only in `main`.** `os.Exit` and `log.Fatal` in a library skip deferred cleanup and cannot be tested (uber-go guide). Check: grep `os.Exit\|log.Fatal\|panic(` outside `main` packages and test helpers.

## HTTP clients and servers

- **Give every client a timeout.** `http.Get`, `http.Post` and `http.Head` use `http.DefaultClient`, and a zero `Client.Timeout` means no timeout. Check: grep `http.Get(`, `http.Post(`, `http.DefaultClient` and `&http.Client{` without `Timeout`; one client and transport are built once and reused, not per request.
- **Close every response body, after checking the error.** An unclosed body leaks the connection; deferring `Close` before the error check dereferences a nil response. Check: `defer resp.Body.Close()` directly after `if err != nil`; `go vet` (analyzer `httpresponse`), staticcheck SA5001 and golangci-lint `bodyclose`; before Go 1.27 read the body to EOF so the connection can be reused.
- **Set server timeouts, at least `ReadHeaderTimeout`.** Zero means none; `ReadHeaderTimeout` and `IdleTimeout` fall back to `ReadTimeout`, and with that zero too there is no limit at all. Check: every `&http.Server{` sets `ReadHeaderTimeout`, `ReadTimeout` or per-handler deadlines, `WriteTimeout` and `IdleTimeout`; streaming or long endpoints extend their own deadline with `http.NewResponseController(w).SetWriteDeadline` (Go 1.20) instead of disabling the server-wide one.
- **Cap request bodies with `http.MaxBytesReader` and map the overflow to 413.** Reads past the limit return a `*http.MaxBytesError`; headers are capped by `MaxHeaderBytes` (default 1 MB). Check: a test posts limit+1 bytes and gets 413 via `errors.As(err, &maxErr)`.
- **Shut down with `Server.Shutdown` and wait for it.** `ListenAndServe` returns `http.ErrServerClosed` at once, and `Shutdown` neither closes nor waits for hijacked connections such as WebSockets. Check: `ErrServerClosed` is not logged as a failure; `main` blocks until `Shutdown` returns; WebSocket handlers are told through `RegisterOnShutdown` or their own context; the SIGTERM test in `backend.md` passes.
- **Keep `net/http/pprof` off public listeners.** Its blank import registers handlers on `http.DefaultServeMux`. Check: no `_ "net/http/pprof"` in a binary that serves `DefaultServeMux` publicly; profiles go on a separate localhost or internal port.
- **Build dial addresses with `net.JoinHostPort`.** `fmt.Sprintf("%s:%d", host, port)` breaks on IPv6 literals. Check: `go vet` (analyzer `hostport`, Go 1.25) is clean.
- **On Go 1.25, protect cookie-authenticated browser endpoints with `http.CrossOriginProtection`.** It rejects unsafe cross-origin requests using Fetch metadata, without tokens. Check: state-changing routes that rely on cookies are wrapped, or the project's CSRF scheme is named (`security.md` Sessions and cookies).

## Slices, defer and conversions

- **Copy slices and maps at API boundaries.** Slicing shares the backing array and `append` may or may not reallocate, so a caller that keeps its slice can change your state, and a result slice can change theirs (uber-go guide). Check: stored inputs and returned internals are copied (`slices.Clone`, `maps.Clone`) or capped with a full slice expression `s[lo:hi:hi]` so `append` must copy; a test mutates the input after the call and asserts internal state is unchanged.
- **Copy out small pieces of big buffers.** A small sub-slice keeps the whole underlying array alive. Check: data kept from a large read is copied into a new slice; a heap profile (`go tool pprof -base`) shows no growth after repeated calls.
- **Remember that `defer` runs at function return, not at the end of a loop body, and evaluates its arguments immediately.** Deferring `Close` in a loop holds every file open until the function ends. Check: staticcheck SA9001 and SA5003 are clean; loop bodies that open resources move into a helper function or close explicitly.
- **Range-check before converting integers.** Conversions truncate or sign-extend silently, and signed overflow wraps without a panic. Check: lengths and counts from outside input are compared against the target type's limits before `int32(...)`, `uint16(...)` and the like; a test feeds the maximum and a negative value.
- **Confine user-supplied paths with `os.Root` (Go 1.24).** It rejects paths that escape the directory, including through symlinks. Check: file access under an upload or workspace directory goes through `os.OpenRoot`; the zip-slip test in `security.md` passes.

## Modules, toolchain and vulnerabilities

- **Use only APIs your `go` directive allows, and none that are deprecated.** Models reach for deprecated or too-new calls (`agent-process.md`), and `WaitGroup.Go` (1.25), `b.Loop` (1.24) or `errors.AsType` (1.26) do not exist on older toolchains. Check: read the `go` line in `go.mod` first; `go vet` (analyzer `stdversion`, run by `go test` by default from 1.27) and staticcheck SA1019 are clean on changed packages.
- **Keep `go.mod` and `go.sum` tidy and verified.** Drift between code and module files breaks other people's builds. Check: `go mod tidy -diff` exits 0 (non-zero when changes are needed); `go mod verify` prints "all modules verified".
- **Scan with `govulncheck`.** It reports only vulnerabilities your code reaches through the call graph, so findings are real work. Check: `govulncheck ./...` exits 0, and `govulncheck -mode binary <bin>` on release artifacts; it cannot see calls made only through `reflect` and its findings cannot be silenced, so fix or upgrade rather than suppress.
- **Pin developer tools with `tool` directives (Go 1.24).** `go install ...@latest` in scripts gives each run a different linter. Check: `go get -tool <path>` and `go tool <name>` instead of a `tools.go` file or `@latest`.
- **Treat a new lint suppression like a loosened test.** `//nolint` and `//lint:ignore` lines added to get green hide the finding (`testing.md`, never loosen a test). Check: every suppression in the diff names the check and the reason, and the report lists them.

## Tests, fuzzing, benchmarks and profiling

- **Gate on `go test -race -shuffle=on -count=1 ./...`.** `-count=1` is the idiomatic way to bypass the test cache, and shuffling exposes order dependence. Check: green, with the printed shuffle seed in the evidence (`testing.md`); the default 10-minute `-timeout` is not raised to hide a hang.
- **Use the test's own context and goroutine.** `t.Context()` (Go 1.24) is cancelled when the test ends; `t.FailNow` and `t.Fatal` from another goroutine do not stop the test. Check: no `context.Background()` in new tests on Go 1.24+; staticcheck SA2002 is clean.
- **Test time and concurrency with `testing/synctest` (Go 1.25), not sleeps.** Inside `synctest.Test` the clock is fake and advances when every goroutine is blocked. Check: no `time.Sleep` used for synchronisation in new tests; on Go 1.27 `httptest.NewTestServer` gives HTTP tests an in-memory network inside the bubble.
- **Fuzz parsers and decoders with native fuzzing.** A `FuzzXxx(f *testing.F)` with `f.Add` seeds runs the seeds on every plain `go test`. Check: `go test -run '^$' -fuzz '^FuzzParse$' -fuzztime 60s ./pkg` (one target per run, best on amd64 or arm64); the target is fast, deterministic and stateless; failing inputs written to `testdata/fuzz/FuzzXxx/` are committed with the fix.
- **Back benchmark claims with `benchstat`.** Single runs are noise. Check: benchmarks use `for b.Loop()` (Go 1.24); old and new results come from at least 10 interleaved runs each, compared with `benchstat old.txt new.txt`; a `~` means no significant difference, and re-running until a difference appears is not allowed (`performance.md`).
- **Profile one thing at a time with pprof.** Profiles interfere with each other, and block and mutex profiles are off until `runtime.SetBlockProfileRate` or `runtime.SetMutexProfileFraction` turns them on. Check: hot-path claims come with a CPU or heap profile; `go tool trace` is used for scheduling and latency questions, not hot spots; in containers, note that Go 1.25 derives `GOMAXPROCS` from the cgroup CPU limit and a manual `GOMAXPROCS` turns that off.

## Verify it

```bash
go vet ./...
go test -race -shuffle=on -count=1 ./...
go tool staticcheck ./...        # or staticcheck ./... when installed outside go.mod
golangci-lint run --new-from-rev=origin/main   # only where the project has a golangci config
go mod tidy -diff && go mod verify
govulncheck ./...
```

- Stress the tests you touched: `go test -race -count=100 -run '^TestName$' ./pkg/...`.
- Fuzz: `go test -run '^$' -fuzz '^FuzzParse$' -fuzztime 60s ./pkg/parser`; replay a crash with `go test -run 'FuzzParse/<hash>' ./pkg/parser`.
- Benchmarks: `go test -run '^$' -bench . -count 10 ./pkg > old.txt`, apply the change, repeat into `new.txt`, then `benchstat old.txt new.txt`.
- Profiles: `go test -cpuprofile cpu.out -run '^$' -bench . ./pkg && go tool pprof -top cpu.out`; heap with `-memprofile mem.out`.
- Goroutine leaks in a running service (Go 1.27, pprof on an internal port): `curl -s "http://127.0.0.1:$pprof_port/debug/pprof/goroutineleak?debug=1"` after exercising the flow; any stack listed is a leak to explain.
- Prove the gate can fail: plant one data race or one unclosed body in a scratch copy and watch `-race` or `go vet` go red (`agent-process.md`).

## Sources

- go.dev documentation: Effective Go, The Go Memory Model, The Go Programming Language Specification, Go FAQ, Diagnostics, Go Fuzzing, Vulnerability Management, Data Race Detector, blog posts on Go 1.13 errors, slices and loop variables, release notes for Go 1.24, 1.25, 1.26 and 1.27 (text CC-BY-4.0, code BSD-3-Clause): adapted (memory model advice, channel and conversion rules, typed nil errors, defer semantics, fuzzing workflow, race detector cost, version-specific APIs).
- Go Code Review Comments, Go wiki (CC-BY-4.0): adapted (context placement, goroutine lifetimes, error handling).
- pkg.go.dev documentation for `context`, `net/http`, `sync`, `cmd/go`, `cmd/vet`, `golang.org/x/sync/errgroup`, `govulncheck` and `benchstat` (BSD-3-Clause): adapted (cancel rules, server timeouts and shutdown, sync copy rules, test flags, vet analyzers, scanner limits, benchstat method).
- uber-go/guide (Apache-2.0): adapted (copy at boundaries, channel size, goroutine ownership, exit in main, mutex fields, typed atomics).
- uber-go/goleak (MIT): adapted (`VerifyTestMain`, `t.Parallel` caveat).
- dominikh/go-tools, staticcheck check list (MIT): check IDs referenced (SA1012, SA1019, SA2000, SA2002, SA4023, SA5001, SA5003, SA9001).
- golangci/golangci-lint documentation (GPL-3.0): tool use only, linter names and `new-from-rev` option.
- Wang et al., "How and Why LLMs Use Deprecated APIs in Code Completion?", ICSE 2025 (paper, facts only): deprecated and version-mismatched API use.
