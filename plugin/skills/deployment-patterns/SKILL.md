---
name: deployment-patterns
description: "Deployment strategies, CI/CD pipelines, health checks, environment config, and production readiness. Auto-loaded when working with CI/CD configs or Kubernetes manifests."
disable-model-invocation: false
user-invocable: false
---

# Deployment Patterns

Domain knowledge for deployment and CI/CD. Follow these conventions when setting up pipelines, configuring deployments, and preparing for production.

## Deployment Strategies

### Rolling (Default)

- Replace instances gradually -- old and new run simultaneously during rollout
- Requires backward-compatible changes (two versions serve traffic concurrently)
- Use for: standard deployments, most changes

### Blue-Green

- Two identical environments; switch traffic atomically after verification
- Instant rollback by switching back to previous environment
- Requires 2x infrastructure during deployment
- Use for: critical services, zero-tolerance for issues

### Canary

- Route small percentage (1-5%) of traffic to new version first
- Gradually increase if metrics look good (5% -> 25% -> 50% -> 100%)
- Requires traffic splitting infrastructure and monitoring
- Use for: high-traffic services, risky changes, database migrations

## CI/CD Pipeline Patterns

### Standard Pipeline Stages

```
PR opened:      lint -> typecheck -> unit tests -> integration tests -> preview deploy
Merged to main: lint -> typecheck -> tests -> build image -> deploy staging -> smoke tests -> deploy production
```

### Pipeline Conventions

- Pin all action/tool versions (e.g., `actions/checkout@v4`, not `@latest`)
- Cache dependency installs (npm, pip, go mod) between runs
- Run lint and typecheck before tests (fast failures first)
- Build Docker images with content-addressable tags (`$GITHUB_SHA`), not `:latest`
- Use GitHub Actions cache (`type=gha`) for Docker layer caching
- Require environment approval gates for production deploys
- Upload test coverage and build artifacts for traceability

## Health Checks

### Application Health Endpoints

- `/health` -- simple liveness check, returns `200 OK` with `{"status": "ok"}`
- `/health/detailed` -- internal monitoring, checks database, redis, external services
- Detailed endpoint returns `503` with `{"status": "degraded"}` if any dependency fails
- Include `version`, `uptime`, and per-check `latency_ms` in detailed response

### Kubernetes Probes

- **Liveness:** restart if unhealthy -- `httpGet /health`, `periodSeconds: 30`, `failureThreshold: 3`
- **Readiness:** remove from load balancer if not ready -- `periodSeconds: 10`, `failureThreshold: 2`
- **Startup:** allow slow starts -- `periodSeconds: 5`, `failureThreshold: 30` (150s max)
- Set `initialDelaySeconds` based on actual app startup time
- Liveness probes should NOT check external dependencies (risk of cascading restarts)

## Environment Configuration

### Twelve-Factor App Conventions

- All config via environment variables -- never hardcoded in source
- Validate all env vars at startup with a schema (zod, pydantic, etc.) -- fail fast
- Use `.env` files for local dev only (always gitignored)
- Use secrets manager (AWS SSM, Vault, Doppler) for production secrets
- Separate `NODE_ENV`/`RAILS_ENV` from `APP_ENV` -- framework mode vs deployment target

### Required Variables Pattern

- `DATABASE_URL` -- full connection string
- `PORT` -- server port (default 3000/8000)
- `LOG_LEVEL` -- debug/info/warn/error (default info)
- `APP_ENV` -- development/staging/production
- Secrets: inject at runtime, never bake into images

## Rollback Strategies

- **Kubernetes:** `kubectl rollout undo deployment/app` -- instant revert to previous ReplicaSet
- **Docker tags:** always keep previous image tagged and available
- **Platform-specific:** `vercel rollback`, `railway up --commit <sha>`
- **Database:** migrations must be backward-compatible so rollback doesn't require schema revert
- **Feature flags:** disable new features without deploying -- decouple deploy from release

### Rollback Prerequisites

- Previous image/artifact is tagged and available
- Database migrations are backward-compatible (no destructive DDL)
- Feature flags can disable new code paths without redeploy
- Monitoring alerts catch error rate spikes within minutes
- Rollback has been tested in staging before production release

## Production Readiness Checklist

### Application

- All tests pass (unit, integration, E2E)
- No hardcoded secrets in code or config
- Structured logging (JSON), no PII in logs
- Health check endpoint returns meaningful status
- Error handling covers edge cases, no unhandled promise rejections

### Infrastructure

- Docker image builds reproducibly (pinned versions)
- Environment variables documented and validated at startup
- Resource limits set (CPU, memory) in orchestrator
- Horizontal scaling configured (min/max instances)
- SSL/TLS on all endpoints

### Monitoring and Operations

- Application metrics exported (request rate, latency, error rate)
- Alerts on error rate exceeding threshold
- Structured log aggregation (searchable, retained)
- Uptime monitoring on health endpoint
- Rollback plan documented and tested
- Runbook for common failure scenarios

### Security

- Dependencies scanned for CVEs in CI
- CORS restricted to allowed origins only
- Rate limiting on public endpoints
- Authentication and authorization verified
- Security headers set (CSP, HSTS, X-Frame-Options)
