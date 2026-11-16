# Java and JVM checklist

Selected when the project builds with Maven or Gradle (`pom.xml`, `build.gradle`, `build.gradle.kts`); read it together with `backend.md`. Targets JDK 21 and 25 LTS with Spring Boot 3.x and 4.x; version-sensitive items name the version they apply to.

## Concurrency

- **Know which JDK you are on before reasoning about virtual-thread pinning.** The rules changed in JDK 24. Check: read the toolchain or `release` setting in the build file, and apply the matching item below.
- **On JDK 21-23, don't block inside `synchronized` on a virtual thread.** Blocking I/O or `Object.wait()` inside a monitor pins the carrier thread, and enough pinned carriers stall the whole scheduler. Check: blocking calls inside `synchronized` on request paths use `ReentrantLock` instead; `-Djdk.tracePinnedThreads=full` or JFR `jdk.VirtualThreadPinned` shows no long pins under load.
- **From JDK 24 (JEP 491), stop rewriting `synchronized` for virtual threads, but know what still pins.** Monitors no longer pin; native frames still do. Check: look for pinning where a native method or FFM call calls back into blocking Java, where a class loads during symbol resolution, inside class initializers that block, and while waiting for another thread to initialize a class. Code already migrated to `ReentrantLock` can stay.
- **Diagnose pinning with JFR, not the old system property.** `-Djdk.tracePinnedThreads` was removed in JDK 24 and setting it does nothing. Check: record and print `jdk.VirtualThreadPinned` events (Verify it); from JDK 24 the event also names the reason and the carrier.
- **Never pool virtual threads; bound the scarce resource instead.** Virtual threads are cheap to create, and a fixed pool of them just reinvents a platform pool. Check: tasks run on `Executors.newVirtualThreadPerTaskExecutor()` or a virtual `Thread.Builder`; limits come from a `Semaphore` around the database, upstream or file handle being protected.
- **Audit `ThreadLocal` caches when moving to virtual threads.** One cache per thread becomes one per task, so memory grows and reuse vanishes. Check: grep touched code and libraries for `ThreadLocal` used as a cache; on JDK 25 pass request context with `ScopedValue` (final in JEP 506) rather than inheritable thread locals.
- **Remember that connection pools still cap concurrency.** Ten thousand virtual threads queue on a 10-connection pool. Check: the pool size comes from the database (Data and clients), and timeouts on acquiring a connection are short enough to fail fast.
- **Close every `ExecutorService` you create.** Unclosed executors leak threads and block JVM exit or redeploys. Check: try-with-resources (`ExecutorService` is `AutoCloseable` from JDK 19) or `shutdown()` plus `awaitTermination()` in a lifecycle hook; container-managed executors (Spring `TaskExecutor`) instead of ad-hoc ones in beans.
- **Handle every `CompletableFuture` failure path.** An exception in an unjoined future vanishes silently. Check: each chain ends in `join()`, `handle`, `exceptionally` or `whenComplete` that logs or propagates; `orTimeout` or `completeOnTimeout` on anything waiting for I/O; blocking stages get an explicit executor, not the common `ForkJoinPool`.
- **Never swallow `InterruptedException`.** Swallowing it breaks cancellation and shutdown. Check: catch blocks either rethrow or call `Thread.currentThread().interrupt()` before returning.
- **Test lock-free and `volatile` code with jcstress.** Ordinary tests cannot show Java Memory Model reorderings. Check: new atomics, double-checked locking or hand-rolled lock-free structures come with a jcstress test, or are replaced by `java.util.concurrent` classes; any agent-written concurrent code gets jcstress or a stress loop, since models fail Java concurrency tasks with deadlocks and races (CONCUR, ISSTA 2026).
- **Keep preview APIs out of production code unless the project opts in.** Structured concurrency is still a preview in JDK 25 (JEP 505) and changes between releases. Check: no `--enable-preview` added without the owner agreeing.

## Kotlin

- **`copy()` on a data class is shallow.** The copy shares mutable lists and maps with the original, so changing one changes both. Check: data classes hold read-only types (`List`, `Map`) or immutable collections; a test mutates the copy and asserts the original is unchanged.
- **Inside `apply {}` and `with {}`, the receiver's members shadow the enclosing class's.** `entity.apply { status = status }` assigns the entity's property to itself, not the service's value. Check: assign explicitly (`entity.status = newStatus`) when names match; the IDE's self-assignment warning is clean on changed files.

## JVM in containers

- **Size the heap from the container limit.** The default heap is 25% of the limit, wasting most of the container, while a hard-coded `-Xmx` drifts from the limit. Check: `-XX:MaxRAMPercentage` around 70-75, leaving room for metaspace, thread stacks, direct buffers and the code cache; verify the effective `MaxHeapSize` inside the container (Verify it).
- **Dump the heap on OOM to a writable path.** Without a dump, an OOM leaves nothing to analyse. Check: `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=<mounted writable dir>`; the dir survives the container restart.
- **Exit on OOM when a supervisor restarts the process.** A JVM limping on after `OutOfMemoryError` serves errors with partly broken state. Check: `-XX:+ExitOnOutOfMemoryError` under Kubernetes, systemd or a process manager.
- **Run JFR continuously in production-like runs.** The recording from before an incident is the useful one, and JFR costs about 1%. Check: `-XX:StartFlightRecording=maxage=6h,maxsize=500m,dumponexit=true,filename=<writable dir>/app.jfr`.
- **Choose the GC deliberately and give the JVM at least two CPUs.** With fewer than 2 CPUs or under about 1.8 GB, the JVM silently picks Serial GC. Check: `-XX:+UseG1GC` (the general default) set explicitly for small containers; ZGC for latency-sensitive services, where JDK 21 needs `-XX:+ZGenerational`, JDK 23 makes generational the default and JDK 24 removes the non-generational mode.
- **Look at native memory when RSS exceeds the heap.** Threads, direct buffers, JNI and metaspace live outside `-Xmx` and are what get containers OOM-killed. Check: `-XX:NativeMemoryTracking=summary` and `jcmd <pid> VM.native_memory summary`.

## Transactions and JPA

- **Turn off open-in-view.** The default keeps a session and connection open through view rendering and lets serializers trigger lazy loads. Check: `spring.jpa.open-in-view=false` and no `LazyInitializationException` in the real-app run's log.
- **Don't rely on `@Transactional` across self-invocation.** Calls through `this` bypass the proxy, so no transaction starts; private methods are never proxied. Check: grep calls from inside a class to its own `@Transactional` methods; move the method to another bean or use `TransactionTemplate`.
- **Know that checked exceptions commit by default.** Spring rolls back only on unchecked exceptions and errors. Check: `rollbackFor` is set where a checked exception must undo work, and an integration test throws it and asserts the row is absent.
- **Prevent N+1 queries explicitly.** JPA defaults `@ManyToOne` and `@OneToOne` to eager and lazy collections load per row. Check: associations are `fetch = LAZY`; list endpoints use fetch joins, `@EntityGraph` or batch fetching; a test counts queries (Hibernate statistics or a datasource proxy) for a list of N items.
- **Dispatch async work after the commit, not inside the transaction.** An `@Async` call or a message sent inside a transaction can run before the commit, so the worker's `findById` finds nothing; class-level `@Transactional` puts every public method in this position. Check: dispatch after `save()` uses `@TransactionalEventListener(phase = AFTER_COMMIT)` or `TransactionSynchronizationManager.registerSynchronization(... afterCommit ...)`; an integration test with a real database asserts the worker sees the row.
- **A try-catch around a `REQUIRED` transactional callee does not protect the caller.** The callee's runtime exception marks the shared transaction rollback-only, and the outer commit then throws `UnexpectedRollbackException` despite the catch. Check: fire-and-forget side effects that may fail run in `REQUIRES_NEW` (in another bean, because of self-invocation); a test makes the side effect throw and asserts the main write is kept.
- **Expect constraint violations at flush, not at `save()`.** With pre-assigned ids Spring Data calls `merge` and the INSERT waits for the flush, so a catch around `save()` never fires; a mocked repository that throws synchronously hides this. Check: use `saveAndFlush` where the violation must be caught there, or remove the false-safety catch; the test runs against the real database engine.
- **Set timestamps at persist time and check inherited mappings.** A field initializer like `Instant.now()` records when the object was built, not when it was stored, and a copied base entity can map columns the table lacks. Check: `@PrePersist`/`@PreUpdate` or `@CreationTimestamp`/`@UpdateTimestamp`; `spring.jpa.hibernate.ddl-auto=validate` in an integration test against the migrated schema.

## Spring Boot

- **Make graceful shutdown finish inside the orchestrator's grace period.** It is on by default since Boot 3.4 (`server.shutdown=graceful` on older versions), and the per-phase timeout defaults to 30 s, which equals Kubernetes' default termination grace. Check: `spring.lifecycle.timeout-per-shutdown-phase` is set below the grace period (for example 20 s with 30 s), and a test or manual run shows in-flight requests complete on SIGTERM.
- **Split liveness and readiness.** A liveness probe that checks the database restarts every pod when the database blips. Check: `management.endpoint.health.probes.enabled=true` (automatic on Kubernetes); liveness holds no external dependencies; readiness includes what this instance needs, for example `management.endpoint.health.group.readiness.include=readinessState,db`.
- **Use constructor injection.** Field injection hides dependencies and makes beans untestable without the container. Check: no `@Autowired` fields in new code; final fields set by the constructor; an optional dependency is a nullable constructor parameter or an `ObjectProvider`, never an `@Autowired(required = false)` field, which stays null in plain unit tests and silently skips its branch.
- **Validate configuration at startup; binding failures are silent.** A typo in config should fail the boot, not the first request at 3 a.m., but `@Value` cannot bind YAML lists, a misspelled key leaves the default, and properties removed in a major upgrade are accepted and ignored. Check: lists and groups use `@ConfigurationProperties` classes (records welcome) with `@Validated` and Jakarta constraints such as `@NotBlank` on critical fields; a test boots with a missing value and expects failure; during a major upgrade, add `spring-boot-properties-migrator` (runtime scope) temporarily and read its report of renamed and removed keys.
- **Map routing errors before the catch-all handler.** A `@ExceptionHandler(Exception.class)` also catches `NoHandlerFoundException`, `NoResourceFoundException` and `HttpRequestMethodNotSupportedException`, so a wrong path or method returns 500. Check: the advice extends `ResponseEntityExceptionHandler` or maps `ErrorResponse` types first; a test hits an unknown path and a wrong method and expects 404 and 405.
- **Keep mutable state out of singleton beans.** Controllers, services and entity listeners are shared by every request, so a field holding per-request data is a race. Check: no mutable instance fields in singletons; per-entity caches use a concurrent map keyed on a stable id (not identity hash).
- **Return errors without internals.** Stack traces and exception messages leak structure and data. Check: a `@RestControllerAdvice` returns `ProblemDetail` (RFC 9457); `server.error.include-stacktrace` and `include-message` stay at their default `never`; a test asserts an error body contains no class names.
- **Wire tracing and metrics through Micrometer.** Spring's instrumentation emits observations, and trace ids in logs connect a request across services. Check: Boot 4 uses `spring-boot-starter-opentelemetry` (OTLP export, `management.opentelemetry.*` properties); Boot 3.x uses `micrometer-tracing-bridge-otel` plus an exporter; log lines show trace and span ids.
- **Treat `spring.threads.virtual.enabled=true` (Boot 3.2+, JDK 21+) as a concurrency change.** Request handling, `@Async` and scheduling move to virtual threads at once. Check: apply the Concurrency items, especially pinning on JDK 21-23 and pool limits; set `spring.main.keep-alive=true` when only virtual threads keep the JVM alive.
- **Use `@MockitoBean`, not `@MockBean`.** `@MockBean` was deprecated in Boot 3.4 and removed in 4.0. Check: new tests use `@MockitoBean` and `@MockitoSpyBean`.
- **Quarkus and Micronaut differ.** Quarkus enables graceful shutdown only when `quarkus.shutdown.timeout` is set and moves endpoints to virtual threads per method with `@RunOnVirtualThread`; Micronaut runs controllers on the Netty event loop, so blocking code needs `@ExecuteOn(TaskExecutors.BLOCKING)`. Check: the equivalent setting exists for each Spring item above.

## Data and clients

- **Keep the connection pool small and sized from the database.** Large pools add contention, not throughput. Check: HikariCP `maximumPoolSize` starts near `cores * 2 + effective spindles` of the database host; `instances * maximumPoolSize` stays under the database's connection limit with headroom; `maxLifetime` sits below any proxy or database idle cut-off.
- **Turn on leak detection outside production.** A connection held across a slow call drains the pool silently. Check: `spring.datasource.hikari.leak-detection-threshold` (milliseconds) set in test and staging profiles; the real-app run's log shows no leak warnings.
- **Test migrations against the real database engine.** H2 accepts SQL that PostgreSQL or MySQL rejects, and the reverse. Check: Flyway or Liquibase migrations run in an integration test against a Testcontainers instance of the production engine; destructive changes follow expand-contract.
- **Put a timeout on every JDBC and HTTP call.** Several Java defaults wait forever. Check, per client:
  - JDBC: no query timeout by default; set `@Transactional(timeout = ...)`, `spring.transaction.default-timeout` or `jakarta.persistence.query.timeout`, plus the driver's socket timeout (PostgreSQL `socketTimeout` defaults to 0, infinite).
  - JDK `HttpClient`: no connect or request timeout unless set with `HttpClient.Builder.connectTimeout` and `HttpRequest.Builder.timeout`.
  - `HttpURLConnection`: connect and read timeouts default to 0, infinite.
  - Spring clients: Boot 3.4-3.5 `spring.http.client.connect-timeout` and `read-timeout` for `RestClient` and `RestTemplate`, plus `spring.http.reactiveclient.*` for `WebClient` from 3.5; Boot 4 `spring.http.clients.connect-timeout` and `read-timeout` for all three; clients built by hand bypass these.
- **Retry in one layer only.** Retries stacked in client, library and caller multiply load. Check: resilience4j, Spring Retry or Spring Framework 7's `@Retryable` and `@ConcurrencyLimit` (enabled by `@EnableResilientMethods`) appear at one layer per call path; backoff and budgets follow `reliability.md`.

## Security

- **Never use Java native deserialization on untrusted data.** `ObjectInputStream.readObject` on attacker bytes is remote code execution through gadget chains. Check: grep `ObjectInputStream` and `readObject`; unavoidable cases install an allowlisting `ObjectInputFilter` (JDK 9+, filter factories JDK 17+); Jackson never enables default typing or class-name type ids on untrusted input.
- **Create XML parsers XXE-safe.** JDK parser factories resolve external entities and DTDs by default. Check: `DocumentBuilderFactory` and `SAXParserFactory` set `http://apache.org/xml/features/disallow-doctype-decl` to true; `XMLInputFactory` sets `SUPPORT_DTD` to false; `TransformerFactory` and `SchemaFactory` set `ACCESS_EXTERNAL_DTD` and `ACCESS_EXTERNAL_SCHEMA` to empty.
- **Keep Spring Security's defaults unless there is a reason.** Defaults deny unauthenticated access and keep CSRF protection for browser sessions. Check: `anyRequest().authenticated()` or stricter closes the rule chain; CSRF is disabled only for stateless token APIs, with a comment saying so; a parameterized test asserts 401 and 403 for each endpoint and role, sending a valid body, because method security runs after binding and validation and an invalid body returns 400 and passes the test for the wrong reason.
- **Expose only `health` and `info` over the web.** `heapdump`, `env`, `configprops`, `threaddump` and `loggers` leak secrets or allow changes. Check: `management.endpoints.web.exposure.include=health,info` unless more is secured; actuator on a separate `management.server.port` that is not publicly routed.

## Verification tools

- **Check each new JDK or library call against the Javadoc of the version in use.** Models misuse Java APIs often: unclosed streams, unhandled checked exceptions, unchecked preconditions and null or empty returns (RobustAPI, AAAI 2024). Check: `-Xlint:all -Werror` (or `options.compilerArgs` in Gradle) shows no new deprecation or rawtypes warnings in changed classes; every `Closeable` is in try-with-resources; Error Prone and SpotBugs run on the changed classes.
- **After a major framework upgrade, prove annotations still take effect.** Moved or renamed annotations (Boot 4 split test auto-configuration into new modules and packages) may still resolve through an old artifact and then do nothing. Check: each test slice has a test that would fail without its configuration (for example, an injected `MockMvc` is non-null and answers); the build has no old and new framework artifacts side by side (`./gradlew dependencies` or `mvn dependency:tree`).
- **Run integration tests against real infrastructure with Testcontainers.** Mocks of your own database hide the bugs that matter. Check: Boot 3.1+ wires containers with `@ServiceConnection` instead of hand-written properties; containers are static per class for speed; Testcontainers 2.x module artifacts are named `testcontainers-<module>`.
- **Inject latency and failure with the Testcontainers toxiproxy module.** Timeouts and degraded paths only prove themselves against a slow dependency. Check: one test per external dependency adds a latency toxic past the client timeout and asserts the degraded response (outline in Verify it).
- **Turn bug classes into ArchUnit rules.** A rule checks every class, including the ones written next month. Check: layering, forbidden APIs (`ObjectInputStream`, field injection, `System.exit`) and naming rules live in an ArchUnit test.
- **Run Error Prone with NullAway.** They catch bug patterns and null dereferences at compile time. Check: Error Prone needs JDK 21+ to run (it can still compile for older `--release`); NullAway covers the project's packages; Spring Framework 7 and Boot 4 publish JSpecify nullness annotations NullAway understands.
- **Run PIT on touched packages.** It shows whether the tests would notice the change breaking. Check: `targetClasses` limited to the touched package; surviving mutants in changed lines are killed or explained.
- **Read the real cause when a Gradle test run fails with every test green.** A forked test JVM that dies of OOM can make Gradle fail with a `NoSuchFileException` on its own result files. Check: read the first error in `build/reports/tests` and the daemon log; give test JVMs headroom (`maxHeapSize`) and fork per class (`forkEvery = 1`) when contexts accumulate.
- **Randomize JUnit order.** Hidden order dependence is common in Spring context tests. Check: random method and class orderers configured (commands in `testing.md`), seed recorded.
- **Profile with async-profiler or JFR; use JMH only for micro-benchmarks.** Timing loops in JUnit measure warm-up, JIT and GC noise. Check: hot-path claims come with a JFR or async-profiler profile; micro-optimizations come with a JMH benchmark.

## Verify it

Build, tests and checks: `./gradlew --no-daemon check` or `mvn -B verify`.

Effective heap and GC inside a memory-limited container:
`docker run --rm --memory=512m --cpus=1 eclipse-temurin:25-jre java -XX:MaxRAMPercentage=75 -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | Use(G1|Serial|Z)GC '`

JFR on a process you started (PID from `$!`):
- `jcmd "$pid" JFR.start name=verify settings=profile`
- `jcmd "$pid" JFR.dump name=verify filename="$run/verify.jfr"`
- `jfr print --events jdk.VirtualThreadPinned "$run/verify.jfr"` (no output means no pins over the threshold)
- `jfr summary "$run/verify.jfr"` and, on JDK 21+, `jfr view hot-methods "$run/verify.jfr"`
- Native memory (needs `-XX:NativeMemoryTracking=summary` at start): `jcmd "$pid" VM.native_memory summary`

PIT:
- Gradle: plugin `id("info.solidsoft.pitest")`, then `pitest { junit5PluginVersion.set("1.0.0"); targetClasses.set(setOf("com.example.notes.*")) }` and `./gradlew --no-daemon pitest` (report in `build/reports/pitest`)
- Maven: add `org.pitest:pitest-junit5-plugin` as a dependency of `pitest-maven`, then `mvn -B test-compile org.pitest:pitest-maven:mutationCoverage -DtargetClasses='com.example.notes.*'`

Error Prone and NullAway:
- Gradle: plugin `id("net.ltgt.errorprone")`; dependencies `errorprone("com.google.errorprone:error_prone_core:<version>")` and `errorprone("com.uber.nullaway:nullaway:<version>")`; in `tasks.withType<JavaCompile>().configureEach { options.errorprone { check("NullAway", CheckSeverity.ERROR); option("NullAway:AnnotatedPackages", "com.example") } }`
- Maven: in `maven-compiler-plugin`, `compilerArgs` `-XDcompilePolicy=simple`, `--should-stop=ifError=FLOW`, `-Xplugin:ErrorProne -Xep:NullAway:ERROR -XepOpt:NullAway:AnnotatedPackages=com.example` (one argument), and `error_prone_core` plus `nullaway` under `annotationProcessorPaths`; add the `--add-exports jdk.compiler/...` and `--add-opens` lines from the Error Prone installation guide to `.mvn/jvm.config`

ArchUnit rule (no web class talks to a repository directly):

```java
@AnalyzeClasses(packages = "com.example")
class LayeringTest {
    @ArchTest
    static final ArchRule webDoesNotUseRepositories =
        noClasses().that().resideInAPackage("..web..")
            .should().dependOnClassesThat().resideInAPackage("..repository..");
}
```

Testcontainers and toxiproxy latency test (outline; artifact `org.testcontainers:testcontainers-toxiproxy`, image `ghcr.io/shopify/toxiproxy`):

```java
// 1. Shared Network; start the dependency (database or fake upstream) with a network alias, e.g. "weather".
// 2. Start ToxiproxyContainer on the same network; create a proxy:
//      Proxy proxy = new ToxiproxyClient(tp.getHost(), tp.getControlPort())
//          .createProxy("weather", "0.0.0.0:8666", "weather:8080");
// 3. Point the app at tp.getHost() and tp.getMappedPort(8666) (e.g. via @DynamicPropertySource).
// 4. Happy path: call the endpoint, assert the enriched response.
// 5. proxy.toxics().latency("slow", ToxicDirection.DOWNSTREAM, timeoutMs + 500);
//    call again, assert the degraded response arrives within timeout + margin and a warning is logged once.
// 6. Remove the toxic (or proxy.disable() for a hard outage) and assert recovery.
```

## Sources

- JEP 444 and JEP 491, OpenJDK (Oracle copyright): paraphrased (pinning before and after JDK 24, remaining pinning cases, removal of `jdk.tracePinnedThreads`).
- JEP 474, JEP 490, JEP 505, JEP 506, OpenJDK (Oracle copyright): paraphrased (generational ZGC default and non-generational removal, structured concurrency preview status, scoped values final in JDK 25).
- Spring Boot reference documentation (Apache-2.0): adapted (graceful shutdown, health probes and groups, open-in-view, HTTP client timeout properties, virtual threads, OpenTelemetry starter, `@MockitoBean`).
- Spring Framework reference documentation (Apache-2.0): adapted (transaction rollback rules and proxy self-invocation, core resilience annotations).
- brettwooldridge/HikariCP wiki, "About Pool Sizing" (Apache-2.0): adapted (pool size formula, leak detection).
- testcontainers-java documentation (MIT): adapted (toxiproxy module, artifact and image names).
- TNG/ArchUnit (Apache-2.0): adapted (architecture rule example).
- google/error-prone installation guide and uber/NullAway (Apache-2.0 / MIT): adapted (JDK 21 requirement, compiler arguments, `jvm.config` exports).
- hcoles/pitest and szpak/gradle-pitest-plugin (Apache-2.0): adapted (Gradle and Maven mutation commands).
- affaan-m/ECC (everything-claude-code) `springboot-verification`, `jpa-patterns` (MIT): adapted (real database instead of H2, verification order).
- AWS Builders' Library, timeouts and retries (AWS copyright): paraphrased (one retrying layer).
- OWASP Deserialization and XXE Prevention cheat sheets (CC-BY-SA-4.0): paraphrased (deserialization filters, parser factory settings).
- Scientific findings on LLM-written code, facts only: Zhong and Wang, RobustAPI (AAAI 2024); CONCUR (ISSTA 2026).
- Lessons from real agent mistakes in a Kotlin and Spring Boot 4 project, kept where they hold for any Spring or JPA codebase: original text under the project licence.
