# Distributed systems checklist

Selected when several deployable services talk to each other: broker clients, service-to-service calls, Kubernetes or compose manifests. Single-service concerns (timeouts, retries inside one process, logging) are in reliability.md and backend.md; this file covers what breaks between services. Every group ends with a recipe that injects the fault it describes.

## Calls between services

- **Propagate one deadline across every hop.** A callee that works past its caller's deadline wastes capacity on an answer nobody reads. Check: the inbound deadline or timeout header is read and the remaining budget is passed on (gRPC deadlines, a request header, `context.WithDeadline`); no hop starts a fresh full timeout.
- **Retry at one layer only.** Five layers with three tries each multiply load 243 times during an outage. Check: grep client wrappers, service mesh config and application code for stacked retry settings; exactly one owns retries.
- **Cap backoff, add jitter and keep a retry budget.** Synchronized retries turn a blip into a storm; a budget (for example retries limited to a fraction of recent requests) bounds the amplification. Check: the retry policy shows a max delay, jitter and a budget, and retries only on retriable errors (timeouts, 503, connection reset), never on 4xx.
- **Isolate each dependency with its own bulkhead.** One slow dependency drains the shared thread or connection pool and takes unrelated endpoints down with it. Check: per-dependency pool, semaphore or concurrency limit; a test slows one dependency and the others keep their latency.
- **Test circuit breakers in both modes.** A breaker that never opens, or never closes again, is worse than none. Check: a test drives failures until it opens, asserts the fast failure and the fallback, then restores the dependency and asserts half-open probing closes it.
- **Keep readiness independent of optional dependencies.** A readiness check that calls downstream services makes one outage cascade into every replica being pulled from rotation. Check: stop an optional dependency; the service stays ready and degrades only the feature that needs it. Liveness never calls anything remote.
- **Shed load early and bound every queue.** Accepting work you cannot finish raises latency for everyone. Check: queues have a size limit and a defined overflow behavior (reject with 429 or 503 plus `Retry-After`); a load test above capacity shows rejections, not growing latency.
- **Recipe, latency and partition.** Put toxiproxy between two services, add 2 s of latency and a `timeout` toxic, and assert the caller returns within its own deadline with a degraded answer and no thread or connection leak. Kubernetes: a chaos-mesh `NetworkChaos` experiment (delay or partition) between two namespaces.

## Messaging

- **Assume at-least-once delivery and make consumers idempotent.** Brokers redeliver after timeouts, rebalances and restarts; exactly-once end to end does not exist. Check: each handler records a message id or business key with its effect in one transaction, or its effect is naturally repeatable (upsert, set-to-value).
- **Use a transactional outbox, not a dual write.** Writing the database and publishing to the broker as two steps loses or invents events when the process dies between them. Check: the state change and the event row commit in one transaction; a separate relay publishes and marks rows sent; grep for `publish(`/`send(` calls inside a service method that also writes.
- **Rely on ordering only where the broker guarantees it.** Ordering holds per partition or per queue, and breaks on retries, parallel consumers and redelivery. Check: the ordering key is the partition key; handlers tolerate an older event arriving late (version or sequence check) or the design does not need order.
- **Park poison messages instead of looping on them.** One malformed message blocks a partition or burns CPU forever. Check: bounded redelivery, then a dead-letter queue with the error and original headers; an alert on DLQ depth; a replay path exists.
- **Apply backpressure.** An unbounded consumer buffer turns a slow downstream into an out-of-memory crash. Check: prefetch or max in-flight is set; consumers pause when the downstream is slow; lag is a metric.
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
- Backpressure: produce faster than the consumer can handle for 30 s and read peak memory (`procbudget.py` in performance.md, or `ps -o rss= -p $PID`); it must plateau.
- Compose-based multi-service run: `docker compose up -d --wait`, drive requests, `docker compose logs --no-color | grep -Ei 'error|warn|exception'` fails the check except for allowlisted lines with reasons, `docker compose down -v` in a `trap`.

## Sources

- Fallacies of distributed computing (Deutsch and others), widely published; ideas only, paraphrased.
- AWS Builders' Library: timeouts, retries and backoff with jitter; making retries safe with idempotent APIs; using load shedding to avoid overload. AWS copyright, paraphrased.
- Microsoft Azure Architecture Center cloud design patterns (Retry, Circuit Breaker, Bulkhead, Health Endpoint Monitoring, Queue-Based Load Leveling, Compensating Transaction, Throttling). CC-BY-4.0, adapted.
- mercari/production-readiness-checklist. MIT, adapted (service levels and readiness items).
- kgoralski/microservice-production-readiness-checklist. Apache-2.0, adapted (probes, termination, limits).
- Shopify/toxiproxy. MIT, adapted (fault recipes).
- chaos-mesh/chaos-mesh. Apache-2.0, adapted (experiment kinds).
- Pact documentation and pact-foundation/pact-specification. MIT, adapted (contract flow).
- open-telemetry/semantic-conventions. Apache-2.0, adapted (attribute names, context propagation).
- Google SRE book and workbook (SLOs, error budgets, cascading failures). CC-BY-NC-ND-4.0, paraphrased.
- Jepsen analyses (jepsen.io). No licence for the text, paraphrased (consistency claims under partitions).
- donnemartin/system-design-primer. CC-BY-4.0, adapted (consistency and backpressure patterns).
- resilience4j/resilience4j. Apache-2.0, adapted (bulkhead and breaker semantics).
