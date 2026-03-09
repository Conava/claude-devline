---
name: perf-review
description: "Performance analysis and optimization skill. Measurement-first approach with profiling, load testing, caching strategy, and observability patterns."
argument-hint: "[component or area to analyze]"
user-invocable: true
---

# Performance Review

Measurement-first approach: **profile before optimizing**. Gut feelings about performance are wrong 80% of the time.

## Process

### 1. Establish Baseline

Before changing anything, measure current state:

- **Response times**: P50, P95, P99 latencies for critical paths
- **Throughput**: Requests/second, transactions/second under normal load
- **Resource usage**: CPU, memory, I/O, network, connection counts
- **User-facing metrics**: Core Web Vitals (LCP, FID, CLS) for frontend

Use the project's existing monitoring tools. If none exist, add temporary instrumentation.

### 2. Identify Bottlenecks (Pareto Analysis)

Focus on the 20% of code causing 80% of performance issues:

- **CPU profiling**: Generate flame graphs to find hot functions
  - Node.js: `node --prof` or `clinic flame`
  - Python: `py-spy`, `cProfile`, `scalene`
  - Go: `pprof`
  - Rust: `cargo flamegraph`
  - JVM: `async-profiler`, `JFR`
- **Memory profiling**: Heap snapshots to find leaks and large allocations
- **I/O profiling**: Database query logs (slow query log), network traces
- **Frontend**: Chrome DevTools Performance tab, Lighthouse

### 3. Prioritize by Impact

Rank optimizations by: `user_impact × frequency × implementation_effort`

| Priority | Example |
|----------|---------|
| High | N+1 queries on the most-visited page |
| Medium | Uncompressed API responses on moderately-used endpoint |
| Low | Micro-optimizing a rarely-called background job |

### 4. Common Optimization Patterns

#### Database
- **N+1 queries**: Batch fetches, joins, `prefetch_related`/`select_related`
- **Missing indexes**: `EXPLAIN ANALYZE` on slow queries
- **Connection pooling**: PgBouncer, HikariCP — don't open connections per request
- **Query caching**: Materialized views for expensive aggregations

#### Application
- **Caching**: Memoize pure computations, cache external API responses
- **Async processing**: Move non-critical work to background queues (email, notifications, analytics)
- **Connection reuse**: HTTP keep-alive, database connection pools
- **Batch operations**: Batch inserts/updates instead of one-at-a-time
- **Lazy loading**: Defer expensive initialization until first use

#### Frontend
- **Bundle size**: Code splitting, tree shaking, dynamic imports
- **Image optimization**: WebP/AVIF, responsive `srcset`, lazy loading below fold
- **Render performance**: Virtualize long lists, debounce expensive event handlers, `useMemo`/`useCallback` for expensive computations
- **Network**: HTTP/2, compression (gzip/brotli), preload critical resources

#### Infrastructure
- **CDN**: Static assets, cacheable API responses
- **Auto-scaling**: Scale on actual metrics (CPU, queue depth), not schedules
- **Connection limits**: Set appropriate pool sizes, timeouts, retry budgets

### 5. Load Testing

Before deploying optimizations, validate under load:

- **Tools**: k6, Locust, JMeter, Artillery
- **Scenarios**: Realistic user patterns (not just hammering one endpoint)
- **Baseline comparison**: Compare before/after with same test scenarios
- **Soak testing**: Run for extended periods to catch memory leaks and resource exhaustion

### 6. Verify and Monitor

After optimization:
- Compare P50/P95/P99 against baseline
- Set performance budgets and alerts
- Monitor for regressions in CI/CD

## Anti-Patterns

- Optimizing without profiling first
- Premature caching (adds complexity, invalidation bugs)
- Micro-optimizing code that runs once per request when the database query takes 100x longer
- Adding indexes without checking write impact
- Choosing "faster" technology without measuring the actual bottleneck
