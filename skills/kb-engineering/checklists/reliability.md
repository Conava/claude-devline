# Reliability checklist

Selected for new or changed I/O, processes, persistence, error paths or logging: anything that can hang, crash, lose data or fail silently.

Item format: rule, why, then `Check:` for the concrete step. Cite the item when a review finding comes from here.

## Timeouts and bounds on all I/O

- **Give every network, exec and IPC call a timeout.** A call without one turns a slow dependency into a hung process and then a full thread pool. Check: grep each client construction and call site for a timeout; the "Verify it" section lists libraries whose default is infinite.
- **Derive timeouts from the downstream's measured latency and the caller's remaining deadline.** Rule and check: `distributed.md`, "Pick timeouts from the dependency's measured latency" and "Propagate one deadline across every hop"; they apply to a single service's outbound calls too.
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
- **Degrade, do not fail, when an optional dependency is slow, and never invent the missing value.** A decoration from a weather or recommendation upstream should drop out, not break the page; a made-up number or a silent 0 is worse than a gap. Check: a fake upstream with a delay longer than the timeout still yields a valid, marked-degraded response within the budget; the fallback renders an explicit "no data" state; a cache keeps the last good value and backs off after a failed refresh instead of overwriting it.

## Changing shared code

- **When call sites move onto a shared helper, compare old and new behavior per call site.** Consolidation reviews pass on the helper and miss what each caller lost: a dropped save, a changed default, a stricter check, a different startup order. Check: list every caller of each changed shared function (`git grep -n 'name('` or the IDE's call hierarchy); for each, write down flags, persistence, defaults and error handling before and after (`git diff <base> -- <file>`); a new parameter defaults to the old behavior.
- **A change to shared data reaches consumers you cannot grep.** Templates, user config, plugins, other engines and reflection read the same key or construct without naming your function. Check: grep every reader of the value and every path that reads the same construct (config key, CSS variable, event name, column); a guard added at one reader is added at all of them or moved into the construct; prefer a new key when only a narrower audience should change.
- **Stricter validation or new defaults must not break a flow that worked.** A new required field or limit can disable a quick path that never showed that field. Check: walk every entry point that reaches the new check (quick prompt, full editor, import, API) with the old minimum input; limits apply only to the variant they belong to.
- **A decision about fetched data uses the same predicate as the fetch.** Two copies of "is this enabled" or "does the user own this" drift. Check: the fetch and the decision call one shared predicate, or ask the owning layer instead of re-deriving the answer (path text cannot answer ownership through symlinks).
- **A field that is set but never read is a missing gate or dead code.** Compilers rarely warn about unused struct fields or interface members, so a value meant to mark "unknown" can silently read as 0. Check: grep each new field, prop and parameter for a production read; use it or delete it.
- **Do not trigger a side effect twice.** An explicit save, reload or regenerate after a setter whose change hook already does it duplicates the work or the write. Check: before calling it explicitly, read the setter, observer or spec for an existing trigger.
- **A helper that only formats a message must never change which error is raised.** If it calls real logic and that throws, an unrelated defect replaces the intended error. Check: diagnostic and preview helpers catch everything their callees throw and fall back to generic wording; a test makes the callee throw.

## Maintainability

- **Reuse existing helpers and check APIs against the installed version.** Rule and check: `agent-process.md`, "Reuse what exists before writing something new" and "Check every API against the installed or released version".
- **Look docs up for unfamiliar or version-sensitive APIs, not for everything.** Retrieval helps rare and recently changed APIs and adds noise for ones used everywhere in the codebase (CloudAPIBench 2024). Check: calls into an API new to the codebase, recently upgraded or pinned to an old version were read from its docs or source (the dependency's sources jar, `node_modules/<pkg>`, `go doc`), not recalled.
- **Check each external tool's real flags, exit codes and output, per supported version.** Some tools exit 1 for "updates available", a dismissed privilege prompt exits 126 (a cancel, not a failure), and an option missing on an older distro's build fails the whole call. Check: read the man page or `--help` of the oldest version the targets ship, or detect support once and fall back; match states exactly, not by substring; an unknown backend gets a no-op, never another backend's value.

## Errors

- **Fail closed.** When a check cannot be completed (auth service down, parse failed, config missing), deny and report, never allow by default. Check: grep catch blocks around authorization, validation and feature flags for a permissive fallback.
- **Never swallow an error.** An empty catch, `_ = err` or a logged-and-continued failure leaves the system in a state nobody knows. Check: grep for empty `catch`, `except: pass`, discarded error returns; each remaining one has a reason on the line.
- **Handle the quiet paths too.** A clean EOF, a peer hang-up, an empty reply or a zero-length read are failures to handle, not successes. Check: tests close the connection mid-message and send an empty body; a call that reports "no error" on its failure path (a scanner stopping at a clean EOF, a context that was never cancelled) gets an explicit fallback before its error is wrapped, so nothing wrapped can be nil.
- **Report success only for work that finished.** A detached exec reports no failure, and a reply sent before async work ends cannot know the outcome. Check: success messages come from a real exit code or completion event; early replies say the work started, not that it succeeded.
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
- **Get detached children off the launcher's pipes.** A child that outlives its launcher but still holds its stdout or stderr keeps the reader blocked or dies on a closed pipe. Check: detached processes redirect stdin, stdout and stderr (to `/dev/null` or a log file) and start in their own session (`setsid`, `start_new_session=True`).
- **Know the process facts that surprise.** A stopped process ignores SIGTERM until it is resumed; `/proc/<pid>/comm` truncates names to 15 characters; under a session manager, many apps share the session's systemd unit, so acting on "the process's unit" can end the whole session. Check: send SIGCONT before SIGTERM to a stopped process; match long names on `/proc/<pid>/cmdline` or `exe`; before stopping a unit, confirm the process is its `MainPID` (`systemctl show -p MainPID <unit>`).
- **Log why the process is stopping.** A silent exit costs hours. Check: signal, fatal error and exit code are logged before exit.

## State and persistence

- **Write files atomically.** Write a temp file in the same directory, fsync where loss matters, then rename; a crash mid-write otherwise leaves a truncated file. Check: grep for direct writes to config, state and data files; kill the process during a write and re-read.
- **Migrate changed formats.** Old files on a user's disk outlive the code that wrote them. Check: a test loads a fixture from the previous version; unknown versions fail with a readable error instead of being overwritten.
- **Keep unknown fields on read-modify-write.** Dropping fields written by a newer version or another tool destroys data. Check: round-trip a document with an extra field and compare.
- **Make derived state independent of refresh order.** If the result depends on which fetch finished first, it will be wrong sometimes. Check: a test delivers replies in both orders.
- **Clear pending and busy flags in `finally`.** A flag set before an async call and cleared only on success locks the UI or worker forever after one failure. Check: force the call to fail; the flag is cleared; a pending flag never outlives the user's action, or it fires later on an unrelated event.
- **Drop stale async replies.** A reply to an old request must not overwrite newer state, and a cached result of an external flow (a login URL, a one-time code) belongs to the request that produced it. Check: tag requests with a generation or id and ignore mismatches; test with a slow first reply and a fast second; clear such caches when a new request starts or the account changes; per-open state resets on open, not on close.
- **Do not let runtime state overwrite saved settings.** Writing the current in-memory value back on exit stores a temporary override as the user's choice. Check: separate user settings from session state; a test runs with an override and confirms the settings file is unchanged.
- **Keep data-deleting settings out of imports and profiles.** Replaying stored settings replays their change hooks, so a retention or history toggle in a profile can erase data the user never chose to erase. Check: list the keys whose change deletes data; import, export and profile application skip them; a test applies a profile and counts the rows.
- **Changing how a value is stored must leave already-saved values alone.** A new storage flag or owner can make the platform drop the old value (a keyring entry marked "not saved" gets deleted). Check: before writing a new flag or moving ownership, read what the platform does with existing data under it; an upgrade test starts from a store written by the previous version.
- **Transactions or compensations for multi-step writes.** A crash between two writes leaves them inconsistent. Check: kill between steps; recovery restores a consistent state.

## Hostile input

- **Type-check before storing.** Imported files, server replies, tags and user data lie about their shape, and bad values surface far from where they entered. Check: a validation step at each boundary; it checks the kind before the content (a check that only inspects strings lets an array through, and JavaScript joins a one-element array back into the same string); feed the wrong type and a missing field.
- **Handle the edge values in every new function that takes outside input.** Missing null, empty and range checks are the most common robustness gap in generated code (Tambon et al. 2024). Check: a table or property test feeds empty, null, zero, negative, maximum and malformed values to each new public function.
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
- Shared-helper regressions: `git diff --stat <base>...HEAD`, then for each changed shared function `git grep -n '<name>('` and read every caller against `git show <base>:<file>`.
- Duplicates and deprecations in the change: `npx jscpd --min-lines 6 <changed dirs>`; PMD CPD `pmd cpd --minimum-tokens 80 --dir src`; the compiler or linter with deprecation warnings as errors on the changed files.

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
- Scientific findings on LLM-written code, facts only: Jain et al., CloudAPIBench (2024); Tambon et al., "Bugs in Large Language Models Generated Code" (2024).
- Lessons from real agent mistakes in the maintainer's own projects (shared-helper regressions, unreadable consumers, process facts): original text under the project licence.
