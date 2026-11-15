# Reliability checklist

Selected for new or changed I/O, processes, persistence, error paths or logging: anything that can hang, crash, lose data or fail silently.

Item format: rule, why, then `Check:` for the concrete step. Cite the item when a review finding comes from here.

## Timeouts and bounds on all I/O

- **Give every network, exec and IPC call a timeout.** A call without one turns a slow dependency into a hung process and then a full thread pool. Check: grep each client construction and call site for a timeout; the "Verify it" section lists libraries whose default is infinite.
- **Derive timeouts from the downstream's latency percentiles and the caller's remaining deadline.** A fixed 30 s inside a 5 s request wastes work nobody waits for. Check: the timeout is below the caller's deadline and above the dependency's observed p99 or p99.9.
- **Set connect and read (or overall) timeouts separately.** A connect timeout alone does not stop a server that accepts and then goes silent. Check: both are set, or an overall deadline wraps the call.
- **Bound every read and every captured output.** An unbounded body, stdout capture or log line is a memory leak waiting for a large or hostile peer. Check: reads use a size limit; child-process output is capped or streamed to a file.
- **Never do I/O while holding a lock.** One slow call then blocks every other waiter and can deadlock the shutdown path. Check: read the critical sections; copy the data out, release, then call.
- **Pass argv arrays, not `sh -c` strings built from data.** Quoting bugs become injection and hangs; the shell also hides the real exit status. Check: grep for `sh -c`, `shell=True`, `os.system`, `Runtime.exec(String)`.
- **Clamp server-supplied sizes, counts and delays.** A peer that says "retry after 10 years" or "length 4 GB" must not be believed. Check: every `Retry-After`, `Content-Length`, page-size or sleep value read from a reply passes through a min/max.
- **Kill the child on timeout, then wait for it.** A timed-out call that leaves its process running leaks it. Check: the timeout path terminates the process group and reaps it.

## Retries and overload

- **Retry in one layer only.** Five layers with three tries each multiply the load on a struggling dependency 243 times. Check: trace the call path; exactly one component retries and the others fail fast.
- **Cap the backoff and add jitter to every delay.** Uncapped exponential waits stall forever; unjittered ones make every client return at the same instant. Check: the delay has a maximum and a random component; the same applies to periodic timers and cache expiry.
- **Bound retries with a budget.** A per-process token bucket or a ratio of retries to first attempts stops retries from amplifying an outage. Check: a hard attempt limit plus a budget exist; neither is "unlimited".
- **Retry only retriable errors.** Retrying a 400, an auth failure or a validation error repeats a guaranteed failure. Check: the retry predicate names timeouts, connection resets, 429 and 503; everything else fails at once.
- **Retry only idempotent operations, or send an idempotency key.** A retried payment or insert without a key does the side effect twice. Check: side-effecting calls carry a client-generated request token; the server stores the result atomically with the effect and rejects the same token with different parameters.
- **Bound every queue and buffer.** An unbounded queue turns overload into out-of-memory and latency that grows without limit. Check: each queue, channel and executor has a capacity and a defined behavior when full (reject, drop oldest, block the producer with a timeout).
- **Shed load early and cheaply.** Rejecting at the edge costs less than failing after doing the work. Check: the overload path returns a fast 429 or 503 before touching the database; try it by running with a tiny limit.
- **Isolate dependencies with bulkheads.** One slow upstream must not drain the threads or connections every other feature needs. Check: separate pools or semaphores per dependency; a test with one dependency stalled shows the others still answer.
- **Rate-limit inbound work that can be abused.** Expensive endpoints and background triggers need a ceiling per caller. Check: the limiter exists and a test exceeds it.
- **Test a circuit breaker in both modes.** A breaker has open, half-open and closed states, and agents usually test only the first failure. Check: tests cover opening after failures, fast-fail while open, the half-open probe, and recovery.
- **Degrade, do not fail, when an optional dependency is slow.** A decoration from a weather or recommendation upstream should drop out, not break the page. Check: a fake upstream with a delay longer than the timeout still yields a valid, marked-degraded response within the budget.

## Errors

- **Fail closed.** When a check cannot be completed (auth service down, parse failed, config missing), deny and report, never allow by default. Check: grep catch blocks around authorization, validation and feature flags for a permissive fallback.
- **Never swallow an error.** An empty catch, `_ = err` or a logged-and-continued failure leaves the system in a state nobody knows. Check: grep for empty `catch`, `except: pass`, discarded error returns; each remaining one has a reason on the line.
- **Handle the quiet paths too.** A clean EOF, a peer hang-up, an empty reply or a zero-length read are failures to handle, not successes. Check: tests close the connection mid-message and send an empty body.
- **Give users a readable error and keep internals in the log.** Stack traces, SQL and paths in a response help attackers and confuse users. Check: trigger a failure and read the response body; the log has the cause, the response has a generic message and a correlation id.
- **Release resources on every path.** Files, sockets, locks, transactions and temp directories leak on the error branch. Check: each acquire has a matching `finally`, `defer`, `with` or try-with-resources; run the failure path in a loop and watch open file descriptors.
- **Separate operational errors from programmer errors.** Bad input and a dead peer are expected and handled; a violated invariant means the state is unknown. Check: invariants raise or panic; expected failures return typed errors.
- **Crash on unknown state instead of limping on.** A process that continues after corruption writes more corruption. Check: uncaught exception and unhandled promise rejection handlers log and exit non-zero under a supervisor (Node 15+ already exits on unhandled rejections by default).
- **Wrap errors once with context.** Wrapping at every layer buries the cause; not wrapping loses where it happened. Check: one wrap that names the operation and the input identity; the original error is kept as the cause.
- **Propagate cancellation.** Work that continues after its caller gave up wastes capacity. Check: Go `context.Context` reaches every blocking call; async tasks and futures are cancelled with their request.
- **Keep fault handling code reachable by a test.** Recovery paths that never ran in a test usually fail on first use (OWASP 2025 A10, Mishandling of Exceptional Conditions). Check: each error branch you added has a test that drives it.

## Process lifecycle

- **Run long-lived processes under a supervisor with bounded restarts and backoff.** An instantly restarting crash loop burns CPU and hides the cause. Check: systemd `Restart=` with `RestartSec`/`StartLimit*`, a Kubernetes backoff, or the project's own watchdog with a cap.
- **Restore state after a restart.** A crash that forgets the user's position, queue or session is a data loss from their view. Check: kill the process with SIGKILL mid-work and start it again; the state is back.
- **Shut down gracefully within a deadline.** Stop accepting work, finish or checkpoint in-flight work, close resources, then exit; force-exit when the deadline passes. Check: send SIGTERM under load and time the exit; in-flight requests complete or fail cleanly.
- **Start fast.** Slow starts stall rollouts and recovery. Check: measure start to ready and compare with a recorded baseline.
- **Never let an optional subsystem block startup.** If the cache, telemetry exporter or secondary device is down, the app starts and that feature degrades alone. Check: start with each optional dependency absent; the core still works and the log says what is degraded.
- **Split readiness from liveness.** Liveness means "restart me", readiness means "send me traffic"; a failing optional dependency must not fail liveness. Check: the two endpoints are separate and the liveness probe checks no external system.
- **Make background jobs idempotent and resumable.** A job that was killed halfway will be rerun. Check: kill the worker mid-job, restart, and confirm exactly one effect.
- **Log why the process is stopping.** A silent exit costs hours. Check: signal, fatal error and exit code are logged before exit.

## State and persistence

- **Write files atomically.** Write a temp file in the same directory, fsync where loss matters, then rename; a crash mid-write otherwise leaves a truncated file. Check: grep for direct writes to config, state and data files; kill the process during a write and re-read.
- **Migrate changed formats.** Old files on a user's disk outlive the code that wrote them. Check: a test loads a fixture from the previous version; unknown versions fail with a readable error instead of being overwritten.
- **Keep unknown fields on read-modify-write.** Dropping fields written by a newer version or another tool destroys data. Check: round-trip a document with an extra field and compare.
- **Make derived state independent of refresh order.** If the result depends on which fetch finished first, it will be wrong sometimes. Check: a test delivers replies in both orders.
- **Clear pending and busy flags in `finally`.** A flag set before an async call and cleared only on success locks the UI or worker forever after one failure. Check: force the call to fail; the flag is cleared.
- **Drop stale async replies.** A reply to an old request must not overwrite newer state. Check: tag requests with a generation or id and ignore mismatches; test with a slow first reply and a fast second.
- **Do not let runtime state overwrite saved settings.** Writing the current in-memory value back on exit stores a temporary override as the user's choice. Check: separate user settings from session state; a test runs with an override and confirms the settings file is unchanged.
- **Transactions or compensations for multi-step writes.** A crash between two writes leaves them inconsistent. Check: kill between steps; recovery restores a consistent state.

## Hostile input

- **Type-check before storing.** Imported files, server replies, tags and user data lie about their shape, and bad values surface far from where they entered. Check: a validation step at each boundary; feed the wrong type and a missing field.
- **Cap sizes and counts.** A 2 GB string or a million-element list is a denial of service. Check: limits on bodies, fields, nesting depth, array lengths and decompressed size.
- **Reject control characters and invalid encodings where they do not belong.** They break logs, file names and terminals, and enable injection. Check: names and identifiers that reach logs, paths or commands reject NUL and newlines.
- **Never let input reach a shell.** See the argv rule above; security.md covers the exploit side. Check: no path from external data into a shell string.
- **Fuzz parsers and protocol handlers.** Hand-written examples miss the malformed ones. Check: a property-based or fuzz test per parser (see testing.md).

## Logging and observability

- **Use structured logs with levels that have defined meanings.** Error means an invariant broke or an operation failed without recovery; warn means degraded but handled; info marks lifecycle and business events; debug is off by default. Check: logs are key-value or JSON; a failure the code recovers from is not logged at error.
- **Log one event per condition, not one per tick.** A retry loop or poll that logs every iteration drowns the signal and fills the disk. Check: log on state change (first failure, recovery) with a count, or rate-limit.
- **Bound or rotate every log, including those of long-running processes.** An append-only file or in-memory buffer grows until it hurts. Check: rotation or a size cap is configured; run the process for a while and check the file size; UI and in-app log views have a line limit.
- **Keep secrets out of logs.** Tokens, passwords, cookies, authorization headers and URLs with tokens or signed query strings must not appear. Check: grep the logs of a test run for the test credentials; redact URLs before logging.
- **Make errors name the operation, the input identity and the cause.** "Failed" tells nobody what to do. Check: each error line says what was attempted, on which id or path, and the underlying error.
- **Carry a correlation id across the request and every hop.** Without one, one user's failure cannot be followed through the logs. Check: the id is created at the edge, in every log line of the request, and forwarded to downstream calls.
- **Use standard attribute names.** OpenTelemetry semantic conventions (`http.request.method`, `http.response.status_code`, `db.system`, `exception.type`) let tools and people read logs from different services alike. Check: new fields reuse a convention name when one exists.
- **Pick metrics, logs or traces by the question.** Metrics answer "how much and how often", logs "what happened here", traces "where did the time go". Check: no per-user or per-id labels on metrics (high cardinality).
- **Test that the important log line appears.** Telemetry rots silently; the line that tells you about the outage is the one nobody tested. Check: a test captures logs and asserts the line and its fields for the main failure paths.
- **Scan the logs of every verification run.** Warnings tolerated once become permanent. Check: see testing.md for the scan and the allowlist rules.

## Verify it

Fault injection, in a sandbox and never against the user's real services.

- Slow or cut dependency with toxiproxy: `toxiproxy-cli create -l 127.0.0.1:18080 -u 127.0.0.1:8080 upstream`, then `toxiproxy-cli toxic add -t latency -a latency=3000 upstream` (slow), `-t timeout -a timeout=0` (accepts and stalls), `-t reset_peer` (reset), and `toxiproxy-cli toggle upstream` (cut). Point the app at the proxy, assert the timeout, the degraded reply and the log line.
- Dependency killed mid-run: start it yourself, record `$!`, `kill -KILL "$pid"` while requests are in flight; confirm errors are handled, the supervisor behavior is as designed and the app recovers when it returns.
- Malformed replies: give the fake upstream a control file the fake re-reads per request (`delay`, `fail`, `garbage`, `truncate`) and run each scenario.
- Full disk: mount a small tmpfs in a private mount namespace (`unshare -rm sh -c 'mount -t tmpfs -o size=1m tmpfs "$d" && ...'`), or `ulimit -f 1024` in a subshell for a file-size ceiling; confirm the write error is reported and no file is half written.
- Shutdown under load: run a load tool (`oha`, `hey`, `wrk`, `k6`) against the built binary, send `kill -TERM "$pid"`, then check the exit time against the deadline and that no request got a reset that the design promised to finish.
- Crash recovery: `kill -KILL "$pid"` during a write; restart and verify the state file parses and the position is restored.
- Log size and rotation: after a long run, `du -h "$LOGDIR"` and `ls -l`; confirm rotation by setting a tiny size limit and counting files.
- Missing timeouts, by grep over the changed files. Defaults that are infinite or unset, checked against current docs on 2026-11-15:
  - Java: `HttpURLConnection` connect and read timeouts default to 0 (infinite); `java.net.http.HttpClient` has no default connect timeout and `HttpRequest` has no default request timeout; Spring `RestTemplate` and `RestClient` take their limits from the request factory, so set connect and read timeouts on it explicitly; Apache HttpClient 5 has a response timeout that is unset by default.
  - Python: `requests` never times out unless `timeout=` is passed (its docs say so); `httpx` defaults to 5 s of network inactivity, so check for `timeout=None`; `urllib.request.urlopen` and `socket` use the global default (none).
  - Go: `http.DefaultClient` and a zero `http.Client{}` have no timeout; `http.Server` with no `ReadHeaderTimeout` is open to slow clients.
  - Node: `http.request` has no socket timeout by default; global `fetch` (undici) has a 300 s headers timeout and body timeout, which is still far too long for most calls; pass `AbortSignal.timeout(ms)`.
  - Grep starter: `grep -rnE 'HttpURLConnection|requests\.(get|post|put|delete|request)\(|http\.DefaultClient|http\.Get\(|fetch\(' src | grep -v timeout`, then read each hit.
- Shell use: `grep -rnE 'sh -c|shell=True|os\.system|child_process\.exec\(' src`.

## Sources

- AWS Builders' Library, "Timeouts, retries and backoff with jitter", "Making retries safe with idempotent APIs", "Using load shedding to avoid overload": AWS copyright, paraphrased.
- Microsoft Azure Architecture Center, Cloud design patterns (Retry, Circuit Breaker, Bulkhead, Health Endpoint Monitoring, Queue-Based Load Leveling, Throttling): CC-BY-4.0, adapted.
- addyosmani/agent-skills, observability-and-instrumentation and debugging-and-error-recovery: MIT, adapted.
- OWASP Top 10:2025 (A09, A10) and the Logging and Error Handling cheat sheets: CC-BY-SA-4.0, paraphrased.
- OpenTelemetry semantic conventions: Apache-2.0, adapted.
- The Twelve-Factor App (config, logs, disposability): MIT, adapted.
- goldbergyoni/nodebestpractices (operational vs programmer errors, crash on unknown state): CC-BY-SA, paraphrased.
- uber-go/guide (handle errors once, goroutine lifetimes): Apache-2.0, adapted.
- Shopify/toxiproxy: MIT, adapted.
- Python `requests` and `httpx` documentation, Java SE `java.net.http` documentation: vendor and project documentation, facts only.
- Google SRE book and workbook (overload, cascading failures): CC-BY-NC-ND-4.0, paraphrased.
- CoSAI project-codeguard logging rules: CC-BY-4.0, adapted.
