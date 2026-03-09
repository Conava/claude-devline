---
name: error-detective
description: "Error pattern analysis for production systems. Log parsing, stack trace correlation, error timeline analysis, and monitoring query generation. Use for post-incident analysis or investigating error patterns across services."
argument-hint: "[error message, log file, or service name]"
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# Error Detective

Systematic error pattern analysis for when you need to understand WHY errors are happening, not just fix individual occurrences.

## When to Use

- Production errors that appear intermittently
- Error rate spikes after deployments
- Correlated failures across multiple services
- Post-incident analysis ("what happened and why")
- Log analysis to find patterns humans miss

## Process

### 1. Collect Error Data

Gather all available information:

- **Application logs**: Error messages, stack traces, request IDs
- **Infrastructure logs**: Container restarts, OOM kills, connection resets
- **Metrics**: Error rate over time, latency changes, resource utilization
- **Recent changes**: Deployments within 24-48 hours, config changes, dependency updates

### 2. Parse and Classify

#### Stack Trace Analysis (by language)

| Language | Key Frame | Common Patterns |
|----------|-----------|-----------------|
| Python | Last frame before site-packages | `AttributeError` on None, missing key, import error |
| JavaScript | First application frame (skip node_modules) | `TypeError: Cannot read properties of undefined`, unhandled rejection |
| Java | First frame in application package | `NullPointerException`, `ClassCastException`, `OutOfMemoryError` |
| Go | First frame in main module | nil pointer dereference, deadline exceeded, connection refused |

#### Error Classification

- **Transient**: Network timeouts, connection resets, rate limits → need retry/circuit breaker
- **Configuration**: Missing env vars, wrong URLs, permission denied → need config fix
- **Logic**: Wrong output, assertion failure, constraint violation → need code fix
- **Resource**: OOM, disk full, connection pool exhausted → need scaling or leak fix
- **Dependency**: External service down, API changed, certificate expired → need resilience

### 3. Correlate Across Dimensions

Build a timeline and look for correlations:

- **Time**: When did errors start? What was deployed then?
- **Users**: Affecting all users or specific segments?
- **Geography**: Region-specific (DNS, CDN, latency)?
- **Request path**: Specific endpoints or all traffic?
- **Load**: Errors increase with traffic (capacity) or constant (logic bug)?

### 4. Pattern Detection

Common error patterns:

| Pattern | Signature | Root Cause |
|---------|-----------|------------|
| **Cascading failure** | Service A errors → Service B errors → Service C errors | Missing circuit breaker, no bulkhead |
| **Thundering herd** | Error spike at exactly the same time | Cache expiration storm, synchronized retries |
| **Gradual degradation** | Error rate slowly increases over hours/days | Memory leak, connection leak, log file filling disk |
| **Deploy-correlated** | Errors start exactly at deployment time | Code bug, missing config, incompatible schema |
| **Time-based** | Errors at same time daily/weekly | Cron job conflict, certificate rotation, backup impact |
| **Load-dependent** | Errors only under high traffic | Connection pool exhaustion, timeout too short, no backpressure |

### 5. Generate Monitoring Queries

After identifying the pattern, create queries to detect recurrence:

```
# Example: Error rate spike detection
# Elasticsearch/Kibana
level:ERROR AND service:payment-service | stats count() by @timestamp(5m)

# SQL (application database logging)
SELECT date_trunc('minute', created_at) AS minute, count(*)
FROM error_logs
WHERE service = 'payment-service' AND level = 'ERROR'
GROUP BY 1 ORDER BY 1 DESC;

# Prometheus/Grafana
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
```

## Output

Provide:

- **Error timeline**: When errors started, key events, current state
- **Pattern classification**: Which pattern(s) match the evidence
- **Root cause hypothesis**: Most likely cause with supporting evidence
- **Monitoring queries**: Queries to detect recurrence
- **Remediation**: Immediate fix + structural improvement to prevent recurrence
- **Blast radius**: What was affected (users, data, revenue)
