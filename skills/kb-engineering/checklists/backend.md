# Backend checklist

Selected for services and CLIs in Go, Rust, Python and Node (`go.mod`, a Cargo binary, a Python server or CLI, a Node server). JVM projects also read java.md. Timeouts, retries and logging detail lives in reliability.md; this file covers what is specific to services and command-line programs.

## API

- **Validate every input at the boundary, by type, range, length and format.** Handlers that trust their callers store garbage and crash later. Check: a table test sends missing, wrong-typed, oversized, negative and control-character values to each endpoint and expects a 4xx with the error envelope.
- **Paginate every list endpoint, with a hard maximum page size and a stable sort.** Unbounded lists exhaust memory, and unstable order duplicates or skips rows between pages. Check: the query has `LIMIT` and a unique tiebreaker in `ORDER BY`; a request with `limit=1000000` is clamped or rejected; prefer keyset (cursor) pagination for large tables.
- **Require an idempotency key on side-effecting POSTs that clients retry.** Retries after a timeout otherwise double-charge or double-create. Check: send the same key twice and assert one effect and the same response; the same key with different params is an error.
- **Return one error envelope with a stable code, a safe message and a request id; never stack traces, SQL or paths.** Internals help attackers and clients cannot parse prose. Check: force a 500 and a validation error and compare bodies; grep handlers for `err.Error()` or `str(e)` written into responses.
- **Use correct status codes and keep success shapes consistent.** Clients branch on them. Check: 201 with `Location` on create, 404 versus 403 chosen deliberately, 409 for conflicts, 429 with `Retry-After` for rate limits.
- **Change APIs additively.** Removing or retyping a field breaks deployed clients. Check: a contract or snapshot test of the old response still passes; new fields are optional; breaking changes get a new version.
- **Rate-limit by caller on expensive and unauthenticated endpoints.** One client should not starve the rest. Check: a burst test gets 429s after the limit and recovers after the window.
- **Cap request body size and set server read and write timeouts.** Slow or huge requests pin connections. Check: oversized body returns 413; a slowloris-style stalled client is cut off within the timeout.

## Data

- **Run migrations against the real database engine, from an empty database and from the previous release's schema.** SQLite-for-tests hides dialect differences and lock behavior. Check: Testcontainers or a throwaway database applies every migration in order and the app boots and passes a smoke test on the result.
- **Use expand and contract for schema changes.** Old and new app versions run side by side during a deploy. Check: add nullable or defaulted columns first, backfill in batches, switch reads and writes, drop in a later release; no migration both renames and drops in one step.
- **Keep each migration short and non-blocking.** A full-table rewrite or index build under a lock stalls production. Check: no `ALTER` that rewrites a large table inside a transaction without review; concurrent index creation where the engine supports it.
- **Wrap multi-statement changes in a transaction and choose the isolation level on purpose.** Read-modify-write races lose updates at the default level. Check: concurrent test hits the same row from two connections; use `SELECT ... FOR UPDATE`, a version column or a unique constraint, and expect one winner.
- **Back constraints in the database, not only in code.** Application checks race and are bypassed by other writers. Check: unique, foreign key and not-null constraints exist for every invariant the code assumes.
- **Add indexes from `EXPLAIN`, not by guessing.** Wrong indexes cost writes and may not be used. Check: `EXPLAIN (ANALYZE, BUFFERS)` (Postgres) or `EXPLAIN ANALYZE` (MySQL 8) on the new query with realistic row counts shows an index scan.
- **Eliminate N+1 queries.** One query per row turns a page into hundreds of round trips. Check: count queries per request in a test (query log or driver hook) and assert it does not grow with the number of rows.
- **Size the connection pool from the database's limit, not from request concurrency.** Large pools slow the database and `instances x max` can exceed its connection cap. Check: pool max times instance count stays under `max_connections` with headroom; a pool-exhaustion test shows requests fail fast with a timeout, not hang.
- **Never log or return raw query parameters containing secrets, and always use bound parameters.** String-built SQL is injection. Check: grep for string formatting or concatenation inside query calls.

## Config and lifecycle

- **Load and validate all configuration at startup, and fail fast with a message naming the bad key.** A missing variable found at the first request fails in production at 3 am. Check: start the binary with a required variable unset and with a malformed value; it exits non-zero within seconds, naming the key, without printing secret values.
- **Take configuration from the environment, not from code or committed files (12-factor).** The same build must run in every environment. Check: no environment-specific constants or credentials in the repo; defaults are safe for production.
- **Write logs to stdout or stderr as an event stream, structured, one line per event (12-factor).** The platform handles routing and rotation. Check: the service writes no log files of its own unless asked, and output parses as JSON lines.
- **Expose separate liveness and readiness endpoints.** Liveness restarts a stuck process; readiness removes it from rotation. Putting a database check in liveness restarts every instance during a database outage. Check: liveness is cheap and dependency-free; readiness reflects only dependencies the service cannot work without; optional dependencies degrade a feature, not readiness.
- **Handle SIGTERM: stop accepting, finish in-flight work within a deadline, flush, then exit 0.** Orchestrators send SIGTERM and kill after a grace period. Check: start a slow request, send SIGTERM, assert the request completes, new connections are refused and the process exits within the deadline.
- **Start fast.** Slow startup breaks autoscaling and rolling restarts (12-factor disposability). Check: time from exec to ready is measured and recorded in the evidence.
- **Make background jobs idempotent and resumable.** Jobs run twice after crashes and deploys. Check: run a job, kill the process halfway, restart; the result equals one clean run with no duplicates.
- **Bind to a configurable address and port, and let the OS choose a free port in tests.** Fixed ports collide with the user's own services and parallel runs. Check: tests bind port 0 and read the port back; the sandbox run writes it to a file.

## CLIs

- **Use meaningful exit codes: 0 success, 1 failure, 2 usage error, and document others.** Scripts and CI branch on them. Check: run with bad flags, missing files and a forced failure and assert each code.
- **Write results to stdout and diagnostics to stderr.** Pipes break when logs mix into data. Check: `prog > out.txt` leaves only data in the file; `prog 2>/dev/null` still yields the result.
- **Provide `--help` that lists every flag, default and exit code.** Agents and humans read it before running unknown tools. Check: `prog --help` exits 0 and mentions every flag the parser defines.
- **Never prompt when stdin is not a terminal.** A hidden prompt hangs CI and agent runs forever. Check: run with `< /dev/null`; it either uses flags and defaults or exits 2 with a message; confirmations have a `--yes` flag.
- **Bound output and honor `NO_COLOR` and non-TTY output.** Megabytes of output flood terminals and agent contexts, and escape codes corrupt files. Check: large input produces a summary plus a flag for full output; output piped to a file has no escape codes.
- **Make destructive commands support `--dry-run` and refuse paths derived from unvalidated input.** Wrong deletes are unrecoverable. Check: dry run prints the plan and changes nothing; tests run under a temp directory.

## Go

- **Pass `context.Context` as the first parameter through every call that blocks, and derive timeouts from it.** Contexts carry cancellation and deadlines across layers. Check: `grep -rn 'context.Background()' --include='*.go' .` shows only `main`, tests and top-level jobs.
- **Set timeouts on `http.Server` (at least `ReadHeaderTimeout`) and on every `http.Client`.** `http.Client{}` has no timeout and `http.Server{}` has none. Check: grep for `http.Get(`, `http.DefaultClient` and `&http.Server{` without the fields.
- **Give every goroutine an owner and an exit path.** Fire-and-forget goroutines leak and hide panics (uber-go guide). Check: `go.uber.org/goleak` `VerifyTestMain` in packages that start goroutines; use `errgroup` or `sync.WaitGroup` to wait on shutdown.
- **Wrap errors once with context using `%w`, and handle them once.** Logging and returning the same error duplicates noise; bare returns lose the operation. Check: no `log` call immediately followed by `return err` for the same error; callers use `errors.Is` and `errors.As`.
- **Run tests with `-race` and `-shuffle=on`, and use `-count=1` to bypass the test cache.** Data races and order dependence are bugs that pass quietly. Check: `go test -race -shuffle=on -count=1 ./...` is green; the printed seed is kept in the evidence.
- **Exit and panic only in `main`.** Library code that calls `os.Exit` or `log.Fatal` skips deferred cleanup and cannot be tested. Check: grep `os.Exit|log.Fatal|panic(` outside `main` packages.

## Rust

- **Keep blocking calls off the async runtime.** A blocking call on a tokio worker stalls every task on it. Check: file I/O, heavy CPU and synchronous clients go through `tokio::task::spawn_blocking` or an async equivalent; `tokio-console` shows no task with long polls.
- **Set timeouts explicitly.** `reqwest` clients have no total timeout by default and futures wait forever. Check: `Client::builder().timeout(..)` and `tokio::time::timeout` around external awaits.
- **Do not hold a `std::sync::Mutex` guard across an `.await`.** It deadlocks or blocks the worker. Check: clippy's `await_holding_lock` is on (it is in the default `suspicious` group); use `tokio::sync::Mutex` only when a guard must cross an await.
- **Return `Result` and avoid `unwrap` and `expect` on external input.** Panics in a task abort the request or the process. Check: grep `unwrap()` and `expect(` outside tests; `cargo clippy -- -D warnings` passes, with `clippy::pedantic` where the project has adopted it.
- **Fuzz parsers and test concurrency primitives with permutation tools.** Hostile input and interleavings are where unsafe and lock-free code fails. Check: `cargo fuzz run <target>` for a few minutes on touched parsers; `RUSTFLAGS="--cfg loom" cargo test` for loom models; AddressSanitizer or ThreadSanitizer via `cargo +nightly` with `-Zsanitizer` where `unsafe` changed.

## Python

- **Pass an explicit timeout to every `requests` call.** `requests` has no default timeout, so a stalled server hangs the worker forever. `httpx` defaults to 5 seconds, which is often too short or hides intent. Check: grep for `requests.(get|post|put|delete|request)(` and `Session` calls without `timeout=`; set a `(connect, read)` tuple.
- **Never leave asyncio tasks unreferenced or un-awaited.** The loop keeps only weak references, so tasks may be garbage collected mid-run, and exceptions vanish. Check: store tasks or use `asyncio.TaskGroup` (3.11+); wrap external awaits in `asyncio.timeout()` (3.11+) or `asyncio.wait_for`; run tests with `PYTHONASYNCIODEBUG=1` or `-X dev`.
- **Do not call blocking code inside `async def`.** One `time.sleep` or sync DB call stalls every request. Check: use `asyncio.to_thread` or async drivers; asyncio debug mode logs slow callbacks.
- **Randomize test order only where the project has `pytest-randomly` or `pytest-xdist`; do not add them uninvited.** Adding plugins changes the project's toolchain. Check: if present, run `pytest -p randomly` and note the printed seed; if absent, mention it as a suggestion.
- **Type configuration and validate it at startup.** Untyped `os.environ[...]` scattered through code fails late. Check: one settings class (pydantic-settings, dataclass or similar) parsed at boot; `mypy` or `pyright` passes if the project uses it.
- **Use `subprocess` with a list and `shell=False`, and always pass `timeout=`.** Shell strings are injection and untimed children hang. Check: grep `shell=True` and `subprocess.run(` without `timeout`.

## Node

- **Let unhandled rejections crash the process, and run under a supervisor.** Since Node 15 the default is to throw on an unhandled rejection, and continuing in unknown state corrupts data. Check: no `process.on('unhandledRejection', () => {})` swallowing handler; a process manager, container restart policy or systemd restarts with backoff.
- **Pass `AbortSignal.timeout(ms)` to `fetch` and other cancellable calls.** `fetch` has no overall timeout; undici's header and body timeouts are 300 seconds. Check: grep `fetch(` calls without `signal`; HTTP servers set `server.requestTimeout` and `headersTimeout`.
- **Do not block the event loop.** Sync file APIs, large JSON parsing and CPU loops stall every request. Check: measure lag with `perf_hooks.monitorEventLoopDelay()` under load and keep p99 within budget; move CPU work to `worker_threads`.
- **Close the server and drain on SIGTERM.** Without `server.close()` and in-flight tracking, deploys drop requests. Check: handler for `SIGTERM` stops accepting, awaits in-flight work and exits within the deadline.
- **Distinguish operational errors from programmer errors.** Retry or report the first; crash on the second. Check: error classes or flags separate them; the central handler does not hide `TypeError` and `ReferenceError`.

## Verify it

Sandboxed real run of the built binary (a starting point; adapt names and flags):

```bash
set -u
work=$(mktemp -d); export HOME="$work/home" XDG_STATE_HOME="$work/state" XDG_CONFIG_HOME="$work/config"; mkdir -p "$HOME" "$XDG_STATE_HOME" "$XDG_CONFIG_HOME"
./bin/myservice --listen 127.0.0.1:0 --port-file "$work/port" >"$work/out.log" 2>&1 &
pid=$!; trap 'kill "$pid" 2>/dev/null; sleep 1; kill -9 "$pid" 2>/dev/null; echo "logs in $work"' EXIT
for i in $(seq 1 50); do [ -s "$work/port" ] && break; sleep 0.2; done
port=$(cat "$work/port")
for i in $(seq 1 50); do curl -fsS "http://127.0.0.1:$port/readyz" >/dev/null && break; sleep 0.2; done
curl -fsS "http://127.0.0.1:$port/notes" && curl -sS -o /dev/null -w '%{http_code}\n' -X POST -d 'not json' "http://127.0.0.1:$port/notes"
! grep -Ei 'error|warn|panic|traceback' "$work/out.log"
```

If the service cannot write its port, bind a port found with `python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1])'` just before start.

- **Fault injection:** put toxiproxy between the service and its dependency (`toxiproxy-server &`, `toxiproxy-cli create -l 127.0.0.1:26379 -u 127.0.0.1:6379 dep`, `toxiproxy-cli toxic add -t latency -a latency=3000 dep`, then `toxiproxy-cli toxic add -t timeout -a timeout=0 dep`), re-run the requests and assert degraded responses within the timeout, not hangs. Remove toxics and confirm recovery.
- **Latency percentiles:** use an installed load tool, for example `oha -z 20s -c 32 http://127.0.0.1:$port/notes`, `hey -z 20s -c 32 URL`, `wrk -t2 -c32 -d20s --latency URL` or `k6 run script.js`; run alone, record load average and read p50, p95 and p99 against the project's budget.
- **Migrations:** apply them to a throwaway database, for example `docker run --rm -d -e POSTGRES_PASSWORD=x -p 54329:5432 postgres:16` (stop it by container id afterwards) or Testcontainers in the test suite, then boot the app against it.
- **Shutdown:** start a slow request in the background, `kill -TERM "$pid"`, assert the request finishes and `wait "$pid"` returns 0 within the deadline.
- **Go:** `go vet ./... && go test -race -shuffle=on -count=1 ./... && go build ./...`.
- **Rust:** `cargo clippy --all-targets -- -D warnings && cargo test && cargo build --release`.
- **Python:** `python3 -X dev -m pytest -x -q` plus the project's type checker; grep `timeout=` as above.
- **Node:** `npx tsc --noEmit && npm test && npm run build`, then run the built output as above.

## Sources

- heroku/12factor (MIT, adapted): config, logs, disposability, dev and prod parity.
- uber-go/guide (Apache-2.0, adapted): error handling, goroutine lifetimes, exit in main only.
- uber-go/goleak (MIT, adapted): goroutine leak detection in tests.
- addyosmani/agent-skills `performance-optimization` (MIT, adapted): backend symptoms such as N+1, pool exhaustion and unbounded fetches.
- MicrosoftDocs/architecture-center cloud design patterns (CC-BY-4.0, adapted): health endpoint monitoring, throttling, retry.
- Shopify/toxiproxy (MIT, adapted): fault injection between a service and its dependency.
- tokio-rs/loom and tokio-console (MIT, adapted), rust-fuzz/cargo-fuzz (Apache-2.0, adapted): Rust concurrency and fuzz checks.
- goldbergyoni/nodebestpractices (CC-BY-SA, paraphrased): operational versus programmer errors, crash on unknown state, process manager.
- AWS Builders' Library on timeouts, retries and idempotent APIs (AWS copyright, paraphrased): idempotency keys, timeouts.
- OWASP Cheat Sheet Series (CC-BY-SA-4.0, paraphrased): input validation and error handling.
- Official docs for Go, Rust, tokio, Python, httpx, requests, asyncio and Node.js (vendor docs, paraphrased, facts only): default timeouts, unhandled rejection behavior, `AbortSignal.timeout`.
