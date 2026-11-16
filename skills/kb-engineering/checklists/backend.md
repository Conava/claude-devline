# Backend checklist

Selected for services and command-line programs in any language. Read it together with the language checklist (Language specifics). Timeouts, retries and logging detail lives in reliability.md; this file covers what is specific to services and command-line programs.

## API

- **Validate every input at the boundary, by type, range, length and format.** Handlers that trust their callers store garbage and crash later. Check: a table test sends missing, wrong-typed, oversized, negative and control-character values to each endpoint and expects a 4xx with the error envelope.
- **Add negative security tests at every new trust boundary.** Rule and check: `security.md` Threat model first, "Write a malicious-input test for every new trust-boundary handler". For endpoints add: authorization is deny-by-default, enforced server-side in shared middleware and checked per object, not per type.
- **Paginate every list endpoint, with a hard maximum page size and a stable sort.** Unbounded lists exhaust memory, and unstable order duplicates or skips rows between pages. Check: the query has `LIMIT` and a unique tiebreaker in `ORDER BY`; a request with `limit=1000000` is clamped to the maximum and a negative size is rejected with 400; an empty next-page token is the only end-of-list signal; prefer keyset (cursor) pagination for large tables.
- **Make page tokens opaque and never an authorization.** A readable or base64-only token gets parsed and forged by clients. Check: tokens are encrypted or signed; authorization runs on every page; a token reused with different filters returns 400; a test edits a token and expects 400.
- **Require an idempotency key on side-effecting POSTs that clients retry.** Retries after a timeout otherwise double-charge or double-create. Check: send the same key twice and assert one effect and the same response (replayed from the stored result, since the client probably never got the first); the same key with different params is an error; the key's retention window is documented.
- **Return one error envelope with a stable code, a safe message and a request id; never stack traces, SQL or paths.** Internals help attackers and clients cannot parse prose. Check: force a 500 and a validation error and compare bodies; grep handlers for `err.Error()` or `str(e)` written into responses.
- **Use correct status codes and keep success shapes consistent.** Clients branch on them. Check: 201 with `Location` on create, permission checked before existence (403 without access, 404 only for a caller who could see it, or 404 for both when existence itself is secret), 409 for conflicts, 429 with `Retry-After` for rate limits; error bodies carry a stable machine-readable reason code that never changes meaning.
- **Change APIs additively.** Removing or retyping a field breaks deployed clients. Check: a contract or snapshot test of the old response still passes; new fields are optional; breaking changes get a new version.
- **Give an omitted or empty parameter the same meaning in every sibling endpoint.** When one module treats `null` as "all" and another as "none", callers have to know which. Check: a table test calls each sibling endpoint with the parameter omitted, empty and present, and the results follow one documented rule.
- **Give a new function the same exposure as its siblings.** If every other module has a REST route, a CLI command and docs, a new one with only a route is a gap users trip on. Check: list the entry points (routes, CLI subcommands, RPC methods, docs pages) of two sibling modules and the new one, and match them or note why not.
- **Change both halves of an internal protocol together and version it.** A daemon and its client (UI, CLI, plugin) that share a socket or IPC protocol break when one side ships alone. Check: the diff touches both sides or adds a compatibility check; the protocol version is bumped, checked at connect time with a clear error, and moved past the base branch's version after a merge; the protocol doc changes in the same commit.
- **Read what a library call really does on its empty and error paths before relying on it.** HTTP clients that throw on 4xx before you see the status, single-row queries that throw on zero rows, and "not blank" validators that also reject null on PATCH fields all surprise. Check: for each library call on a non-happy path (zero rows, 4xx, null, timeout), confirm the behavior in its docs or source for the installed version and add a test for that path.
- **Rate-limit by caller on expensive and unauthenticated endpoints.** One client should not starve the rest. Check: a burst test gets 429s after the limit and recovers after the window.
- **Cap request body size and set server read and write timeouts.** Slow or huge requests pin connections. Check: oversized body returns 413 (Go: `http.MaxBytesReader`); a slowloris-style stalled client is cut off within the timeout.

## Data

- **Run migrations against the real database engine, from an empty database and from the previous release's schema.** SQLite-for-tests hides dialect differences and lock behavior. Check: Testcontainers or a throwaway database applies every migration in order and the app boots and passes a smoke test on the result.
- **Use expand and contract for schema changes.** Old and new app versions run side by side during a deploy. Check: add nullable or defaulted columns first, backfill in batches, switch reads and writes, drop in a later release; no migration both renames and drops in one step.
- **Keep each migration short and non-blocking.** A full-table rewrite or index build under a lock stalls production. Check: no `ALTER` that rewrites a large table inside a transaction without review; concurrent index creation where the engine supports it. Postgres `CREATE INDEX CONCURRENTLY` cannot run in a transaction block and leaves an `INVALID` index on failure: the migration tool runs it outside a transaction and `SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;` returns no rows afterwards.
- **Run migrations and admin tasks as one-off processes from the same release and config (12-factor).** A script run from a laptop with other code or settings changes production in ways nobody can reproduce. Check: migrations and maintenance scripts live in the repo and run with the deployed image or build and its environment, not from a separate checkout.
- **Wrap multi-statement changes in a transaction and choose the isolation level on purpose.** Read-modify-write races lose updates at the default level. Check: concurrent test hits the same row from two connections; use `SELECT ... FOR UPDATE`, a version column or a unique constraint, and expect one winner.
- **Back constraints in the database, not only in code.** Application checks race and are bypassed by other writers. Check: unique, foreign key and not-null constraints exist for every invariant the code assumes.
- **Treat columns of a UNIQUE key as not updatable, and do not index them twice.** Updating a key column violates or quietly weakens the constraint. Postgres already creates a unique B-tree index for every UNIQUE and PRIMARY KEY constraint, but not for foreign-key referencing columns. Check: the ORM marks unique-key fields non-updatable; no `CREATE INDEX` duplicates a single-column UNIQUE (`\d table` lists indexes); referencing columns used in deletes or joins have their own index.
- **Hash or compare what you read back, not what you wrote.** Stores normalize values: Postgres timestamps keep microseconds, so nanosecond values come back truncated, and `jsonb` reorders keys and drops duplicates. A hash computed before insert then never matches on read. Check: truncate timestamps to the store's precision and canonicalize JSON before hashing, or hash the value read back; a round-trip test writes, reads and compares the hash.
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
- **Provide `--help` that lists every flag, default and exit code, and change it with the defaults.** Agents and humans read it before running unknown tools, and an example that relied on an old default silently returns nothing. Check: `prog --help` exits 0 and mentions every flag the parser defines; when a default changes, grep API doc annotations, CLI help, struct or docstring comments and README examples for the old value. Before "fixing" code to match docs, find out which side is deliberate.
- **Never prompt when stdin is not a terminal.** A hidden prompt hangs CI and agent runs forever. Check: run with `< /dev/null`; it either uses flags and defaults or exits 2 with a message; confirmations have a `--yes` flag.
- **Bound output and honor `NO_COLOR` and non-TTY output.** Megabytes of output flood terminals and agent contexts, and escape codes corrupt files. Check: large input produces a summary plus a flag for full output; output piped to a file has no escape codes.
- **Make destructive commands support `--dry-run` and refuse paths derived from unvalidated input.** Wrong deletes are unrecoverable. Check: dry run prints the plan and changes nothing; tests run under a temp directory.

## Language specifics

Language traps, toolchain gates and runtime defaults (timeouts, async pitfalls, test flags) live in the language checklists; read the one for the project's language together with this file.

- **Go:** `go.md`.
- **Rust:** `rust.md`.
- **Python:** `python.md`.
- **TypeScript and JavaScript (Node):** `typescript.md`.
- **Java and Kotlin:** `java.md`.

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
- **Language gates:** typecheck, lint, test and build commands per toolchain are in each language checklist's Verify it.

## Sources

- heroku/12factor (MIT, adapted): config, logs, disposability, dev and prod parity, backing services, admin processes.
- Google API Improvement Proposals AIP-155, AIP-158, AIP-193 (CC-BY-4.0, adapted): request ids and replayed responses, pagination limits and opaque tokens, permission before existence and stable error reasons.
- PostgreSQL documentation: constraints, CREATE INDEX, JSON types, date and time types (PostgreSQL licence, facts only).
- addyosmani/agent-skills `performance-optimization` (MIT, adapted): backend symptoms such as N+1, pool exhaustion and unbounded fetches.
- MicrosoftDocs/architecture-center cloud design patterns (CC-BY-4.0, adapted): health endpoint monitoring, throttling, retry.
- Shopify/toxiproxy (MIT, adapted): fault injection between a service and its dependency.
- AWS Builders' Library on timeouts, retries and idempotent APIs (AWS copyright, paraphrased): idempotency keys, timeouts.
- OWASP Cheat Sheet Series, including Authorization (CC-BY-SA-4.0, paraphrased): input validation, error handling, deny by default, object-level checks.
- Official Go `net/http` docs (vendor docs, paraphrased, facts only): `MaxBytesReader`.
