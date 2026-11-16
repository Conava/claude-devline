# Distributed systems checklist

Selected when several deployable services talk to each other: broker clients, service-to-service calls, Kubernetes or compose manifests. Single-service concerns (timeouts, retries inside one process, logging) are in reliability.md and backend.md; this file covers what breaks between services. Every group ends with a recipe that injects the fault it describes.

## Calls between services

- **Propagate one deadline across every hop, and cancellation with it.** A callee that works past its caller's deadline wastes capacity on an answer nobody reads. Check: the inbound deadline or timeout header is read and the remaining budget, minus a margin of a few hundred milliseconds for transit and post-processing, is passed on (gRPC deadlines, a request header, `context.WithDeadline`); each stage checks the remaining time before starting work; a cancelled request cancels its fan-out (including hedged copies); no hop starts a fresh full timeout.
- **Pick timeouts from the dependency's measured latency.** A guess is either too short (false timeouts) or so long that threads pile up. Check: choose an acceptable false-timeout rate (for example 0.1%) and set the timeout near that percentile (p99.9) of the dependency's latency, with padding when p99.9 is close to p50; connect and request timeouts are set separately; connections and TLS are established at startup, before the instance takes traffic.
- **Fail fast instead of holding a thread until the deadline.** When a small share of requests hang on a long deadline, they hold most of the workers and the success rate collapses (bimodal latency). Check: a test blackholes one dependency for 5% of requests and the caller's success rate and p99 for the other 95% stay within budget; dashboards show latency distributions, not averages; deadlines are not orders of magnitude above mean latency.
- **Retry at one layer only: the one directly above the layer that rejected.** Five layers with three tries each multiply load 243 times during an outage. A layer that gives up returns an "overloaded, do not retry" error or a degraded answer upward instead of letting the next layer retry too. Check: grep client wrappers, service mesh config (Istio `retries`, Envoy `retry_policy`) and application code for stacked retry settings; exactly one owns retries, and overload errors carry a no-retry marker.
- **Cap backoff, add jitter and keep a retry budget.** Synchronized retries turn a blip into a storm; a budget bounds the amplification. Starting values from published practice: at most 3 attempts per request, and retries only while they are under about 10% of a client's recent requests (or a token bucket that refills at a fixed rate). Check: the retry policy shows attempts, a max delay, jitter and a budget; it retries only retriable errors (timeouts, 503, connection reset), never 4xx, and only idempotent calls or calls carrying an idempotency key; retry rate is a metric with an alert.
- **Pass the idempotency key downstream.** An idempotent entry point that calls a non-idempotent service still double-charges on retry. Check: the request id or idempotency key is forwarded to every side-effecting downstream call, and a duplicate-request test asserts one effect at each tier.
- **Throttle on the client when the server is rejecting.** Rejecting still costs the server work. Check: clients track requests versus accepted over a sliding window (two minutes is a published value) and reject locally once requests exceed about twice the accepts; or the client library's adaptive retry mode is on.
- **Isolate each dependency with its own bulkhead.** One slow dependency drains the shared thread or connection pool and takes unrelated endpoints down with it. Check: per-dependency pool, semaphore or concurrency limit; a test slows one dependency and the others keep their latency.
- **Test circuit breakers in both modes.** A breaker that never opens, or never closes again, is worse than none. Check: a test drives failures until it opens, asserts the fast failure and the fallback, then restores the dependency and asserts half-open probing closes it.
- **Keep readiness independent of optional dependencies.** A readiness check that calls downstream services makes one outage cascade into every replica being pulled from rotation. Check: stop an optional dependency; the service stays ready and degrades only the feature that needs it. Liveness never calls anything remote.
- **Shed load early and bound every queue.** Accepting work you cannot finish raises latency for everyone, and an oversized queue spills out of memory. Check: in-flight requests have a limit past which the server returns 503 with `Retry-After`; queues have a size limit (a published starting point is no more than half the worker pool) and a defined overflow behavior; requests carry a criticality so batch traffic is shed before user traffic; a load test above capacity shows rejections, not growing latency.
- **Avoid fallback paths you never exercise.** A fallback that only runs during outages has latent bugs, and can widen the outage it was meant to absorb. Check: prefer making the primary path more available, letting the caller retry, or pushing data to where it is needed ahead of time; if a fallback stays, it serves a share of production traffic all the time (turning it into failover) and has a test.
- **Test failover and know what it loses.** Active-passive failover drops writes that were not replicated yet, and an untested standby is often not ready. Check: the design states the replication mode and the write-loss window; a scheduled drill or test kills the primary and measures recovery time and lost writes.
- **Load-test each service past its breaking point.** Knowing only that it handles today's load says nothing about how it fails. Check: a ramp (`k6` or the project's load tool) goes beyond the point of failure, with both gradual and sudden steps; the service sheds load rather than crashing, recovers by itself when load drops, and blackholing a non-critical dependency leaves critical paths within budget.
- **Ramp traffic back slowly after a crash loop or cold start.** Full traffic on cold caches or freshly restarted replicas restarts the cascade. Check: the rollout or load balancer has slow start (warm-up) configured; a restart test under load shows latency settling without a second wave of failures.
- **Recipe, latency and partition.** Put toxiproxy between two services, add 2 s of latency and a `timeout` toxic, and assert the caller returns within its own deadline with a degraded answer and no thread or connection leak. Kubernetes: a chaos-mesh `NetworkChaos` experiment (delay or partition) between two namespaces.

## Messaging

- **Assume at-least-once delivery and make consumers idempotent.** Brokers redeliver after timeouts, rebalances and restarts, and producers resend after lost acks. Broker "exactly-once" features cover only what the broker controls (its own writes and offsets), never your side effects in other systems. Check: each handler records its deduplication key with its effect in one transaction (an inbox table), or its effect is naturally repeatable (upsert keyed on a business id, set-to-value, event carries the resulting state).
- **Choose a stable deduplication key and let the database arbitrate.** Keys the broker regenerates on redelivery, correlation ids shared by several messages and receive timestamps all defeat deduplication, and check-then-insert races between competing consumers. Check: the key is a producer-assigned message id or business idempotency key; a unique constraint (or an atomic set-if-absent) rejects the second insert; when several subscribers share one store the key includes the consumer name; the same key with a different payload goes to the dead-letter queue with an alert, not silently dropped.
- **Keep dedup records longer than any redelivery.** Expiring them early reopens the duplicate window. Check: retention exceeds max delivery attempts times the lock or visibility timeout and the message TTL, and covers replays from the dead-letter queue; broker-side duplicate detection is treated as volume reduction, not as the consumer's idempotency.
- **Record an in-progress state for side effects that cannot join the transaction.** A third-party call between "seen" and "done" can be half finished when the consumer dies. Check: the consumer writes the key as in-progress, makes the external call with an idempotency key, then marks it completed; a redelivery that finds a stale in-progress record reconciles it or routes it to a person before acking.
- **Use a transactional outbox, not a dual write.** Writing the database and publishing to the broker as two steps loses or invents events when the process dies between them. Check: the state change and the event row commit in one transaction; a separate relay (polling or change data capture) publishes with the outbox row id as message id and marks rows sent; per-aggregate order is kept (partition or session key = aggregate id); sent rows are cleaned up after a retention period of days; grep for `publish(`/`send(` calls inside a service method that also writes. Prefer the framework's built-in outbox where one exists.
- **Rely on ordering only where the broker guarantees it.** Ordering holds per partition or per queue, and breaks on retries, parallel consumers and redelivery. Check: the ordering key is the partition key; handlers tolerate an older event arriving late (version or sequence check) or the design does not need order.
- **Park poison messages instead of looping on them.** One malformed message blocks a partition or burns CPU forever. Check: bounded redelivery, then a dead-letter queue with the error and original headers; an alert on DLQ depth; a replay path exists.
- **Apply backpressure.** An unbounded consumer buffer turns a slow downstream into an out-of-memory crash. Check: prefetch or max in-flight is set; consumers pause when the downstream is slow; lag is a metric.
- **Alert on the age of the oldest message, not only queue depth.** Depth hides a stuck partition; age shows how late work is. Check: an age-of-oldest-message metric (first attempts separate from retries) with an alert; long-running handlers extend their visibility timeout or lease with a heartbeat so the broker does not hand the message to a second worker.
- **Keep one tenant's backlog from delaying everyone.** A shared FIFO queue makes every tenant wait behind the noisiest one. Check: per-tenant rate limits with a burst allowance, a separate queue for the few heaviest workloads, or shuffle sharding over a fixed pool of queues; a test floods one tenant and measures another tenant's latency. Messages a newer full sync will supersede may carry a TTL and be dropped.
- **Recipe, duplicate delivery.** Publish the same message twice (and once more after restarting the consumer mid-processing) and assert one effect: one row, one charge, one email.
- **Recipe, kill mid-transaction.** Kill the service between the database commit and the broker publish (a hook or a `SIGKILL` at a marked point) and assert the relay still publishes the event exactly once in effect after restart.

## Consistency

- **Model multi-service workflows as sagas with compensations.** There is no distributed transaction to roll back; each step needs a defined undo or a forward-recovery path. Check: every step lists its compensating action; compensations are idempotent and retried; a half-finished saga is visible (state column, dashboard) and resumable.
- **Never order events by wall-clock time.** Clocks skew between hosts and jump on correction. Check: grep for timestamp comparisons used as ordering or conflict resolution; use sequence numbers, versions or logical clocks; a clock-skew experiment (chaos-mesh `TimeChaos`, or `faketime` in a test) changes no outcome.
- **State the read-your-writes expectation.** A write through one service followed by a read through a replica or projection can return the old value. Check: the design names which reads may be stale and for how long; the UI or API handles it (return the written state, poll, version token); a test reads through the lagging path right after a write.
- **Treat claims of consistency as claims to test.** Partitions cause lost writes and stale reads even in mature databases. Check: anything claiming linearizability or no lost updates has a test that writes under a partition and a crash and then checks the final state.
- **Recipe, compensation.** Fail step three of a saga (fake returns an error, or toxiproxy resets the connection) and assert steps one and two are compensated and the saga ends in a visible terminal state.

## Schema evolution

- **Make message and API changes backward and forward compatible.** Producers and consumers deploy at different times, and a rollback puts old code next to new data. Check: new fields optional with defaults; unknown fields ignored, not rejected; no field removed, renamed or retyped in place; enum consumers tolerate new values.
- **Change databases with expand and contract.** A column rename in one deploy breaks the version still running. Check: add the new shape, write both, backfill, switch reads, then drop in a later release; every step is safe with both versions live.
- **Pin boundaries with consumer-driven contract tests.** Integration environments catch drift late and flakily. Check: consumers publish expectations (Pact), providers verify them in CI before deploy (`can-i-deploy`); the contract covers error responses and not only the happy path.
- **Recipe, version skew.** Run the previous release's consumer against the new producer (and the new consumer against old messages kept as fixtures) and assert both work. Pact: consumer test writes the pact, provider verification replays it.

## Observability

- **Propagate trace context and a correlation id through every hop, including queues.** Without it an incident is a pile of unrelated logs. Check: W3C `traceparent` is forwarded on HTTP and written into message headers; consumers continue the trace; every log line carries the trace or request id.
- **Expose RED metrics per service and per dependency.** Rate, errors and duration answer "which service is hurt" in one glance. Check: request count, error count and a latency histogram per route; the same per outbound dependency; no unbounded label values such as user ids.
- **Define SLOs and alert on error-budget burn.** Alerting on causes (CPU) pages for non-problems and misses slow degradation. Check: each user-facing service has a latency and availability target and burn-rate alerts; the target is written next to the dashboard.
- **Use standard attribute names.** Shared names let one query span services and languages. Check: HTTP, database and messaging spans use OpenTelemetry semantic-convention names.
- **Log the deduplication key and count duplicates.** A rising duplicate rate is an early sign of a lock window that is too short, a misconfigured producer or sick consumers. Check: consumers log the dedup key with the trace id and export a duplicates-detected counter.
- **Recipe, verify the telemetry.** In the integration test, make one request through two services and assert the collector (an in-memory exporter) holds one trace with spans from both and a log line with the same trace id.

## Production readiness

Scale this by service level: critical (user-facing, data of record), standard, experimental. An experimental service may skip items if the skip is written down.

- **Name an owner and an on-call path.** An unowned service has no one to page. Check: an owner or team in the repo (CODEOWNERS, service catalog entry).
- **Keep a runbook for each alert.** An alert without a first action wastes the first ten minutes. Check: each alert links a runbook with symptoms, checks and mitigations.
- **Ship dashboards and alerts with the code.** Dashboards made by hand drift or vanish. Check: dashboards and alert rules live in the repo and deploy with the service.
- **Know how to roll back.** The previous version must run against the current data. Check: the rollback command is documented and was tried; migrations are expand-contract; a flag can disable the new path.
- **Set capacity and limits.** Missing limits let one service starve its neighbors. Check: CPU and memory requests and limits, replica count and autoscaling bounds, a pod disruption budget for critical services, a tested load figure.
- **Handle termination.** Kubernetes sends SIGTERM and then kills after the grace period. Check: the service stops accepting work, drains in-flight requests and messages within `terminationGracePeriodSeconds`, and a rolling restart under load drops no requests.
- **Document dependencies and their failure behavior.** Check: each upstream and downstream is listed with its timeout, what happens when it is down, and who owns it.

## Verify it

Pick what the project already uses; install nothing system-wide without asking.

- Duplicate delivery, Java: Testcontainers `KafkaContainer` or `RabbitMQContainer`; publish twice, await the consumer, assert `count(*) = 1` in the real database.
- Duplicate delivery, Go: `testcontainers-go` with a broker module; same shape. Python: `testcontainers` plus `pytest`.
- Toxiproxy latency and partition (server on `localhost:8474`):
  - `toxiproxy-cli create --listen 127.0.0.1:26379 --upstream 127.0.0.1:6379 cache`
  - `toxiproxy-cli toxic add --type latency --attribute latency=2000 cache`
  - `toxiproxy-cli toxic add --type timeout --attribute timeout=0 cache` (a partition: the connection hangs), remove with `toxiproxy-cli toxic remove --toxicName timeout_downstream cache`
  - Point the service under test at the proxy port; with Testcontainers use the `ToxiproxyContainer` module so the setup lives in the test.
- Pact: consumer test generates `pacts/*.json`; provider verification (`pact-provider-verifier`, or the JVM/Go/JS provider test) replays it; `pact-broker can-i-deploy --pacticipant Consumer --version "$GIT_SHA"` gates the deploy.
- Chaos on Kubernetes (staging only, never the user's live cluster; ask first): a `PodChaos` with `action: pod-kill`, a `NetworkChaos` with `action: delay` and `delay.latency: 2s`, and a `TimeChaos` for skew; apply with `kubectl apply -f`, watch SLO dashboards or the test's assertions, delete the experiment afterwards.
- Kill mid-transaction: start the service as a child, wait for a log marker at the commit-to-publish gap, `kill -9 $PID`, restart, assert the outbox row is published once and the consumer's effect is single.
- Load past breaking point: `k6 run --stage 2m:100,2m:400,1m:800,2m:0 script.js` (or `ramping-arrival-rate` in the script) against staging; read error rate, p99 and recovery after the last stage; in parallel, `toxiproxy-cli toxic add --type timeout --attribute timeout=0 optional-dep` to blackhole a non-critical dependency.
- Concurrent duplicates: start two consumer instances, publish one message twice at the same moment, and assert one row and one unique-constraint rejection in the logs.
- Backpressure: produce faster than the consumer can handle for 30 s and read peak memory (`procbudget.py` in performance.md, or `ps -o rss= -p $PID`); it must plateau.
- Compose-based multi-service run: `docker compose up -d --wait`, drive requests, `docker compose logs --no-color | grep -Ei 'error|warn|exception'` fails the check except for allowlisted lines with reasons, `docker compose down -v` in a `trap`.

## Sources

- Fallacies of distributed computing (Deutsch and others), widely published; ideas only, paraphrased.
- AWS Builders' Library: timeouts, retries and backoff with jitter; making retries safe with idempotent APIs; using load shedding to avoid overload; avoiding insurmountable queue backlogs; avoiding fallback in distributed systems. AWS copyright, paraphrased.
- Microsoft Azure Architecture Center cloud design patterns (Retry, Circuit Breaker, Bulkhead, Health Endpoint Monitoring, Queue-Based Load Leveling, Compensating Transaction, Throttling, Idempotent Consumer, Transactional Outbox guide). CC-BY-4.0, adapted.
- mercari/production-readiness-checklist. MIT, adapted (service levels and readiness items).
- kgoralski/microservice-production-readiness-checklist. Apache-2.0, adapted (probes, termination, limits).
- Shopify/toxiproxy. MIT, adapted (fault recipes).
- chaos-mesh/chaos-mesh. Apache-2.0, adapted (experiment kinds).
- Pact documentation and pact-foundation/pact-specification. MIT, adapted (contract flow).
- open-telemetry/semantic-conventions. Apache-2.0, adapted (attribute names, context propagation).
- Google SRE book and workbook (SLOs, error budgets; chapters "Addressing Cascading Failures" and "Handling Overload": deadline propagation, retry budgets, client-side throttling, criticality, testing to failure). CC-BY-NC-ND-4.0, paraphrased.
- Jepsen analyses (jepsen.io). No licence for the text, paraphrased (consistency claims under partitions).
- donnemartin/system-design-primer. CC-BY-4.0, adapted (consistency, failover and backpressure patterns).
- resilience4j/resilience4j. Apache-2.0, adapted (bulkhead and breaker semantics).
