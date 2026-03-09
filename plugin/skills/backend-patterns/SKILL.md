---
name: backend-patterns
description: "Node.js backend architecture — service layers, middleware, error handling, caching, auth, and background jobs. Auto-loaded when working with Express, Fastify, or Node.js API routes."
disable-model-invocation: false
user-invocable: false
---

# Backend Architecture Patterns

Domain knowledge for Node.js/Express/Fastify backend services. Follow these conventions when implementing server-side features.

## Project Structure

```
src/
├── routes/          # Route definitions (thin — validate, delegate, respond)
├── services/        # Business logic (orchestrates repositories, applies rules)
├── repositories/    # Data access (queries, transactions, ORM calls)
├── middleware/       # Request pipeline (auth, logging, rate limiting, error handling)
├── jobs/            # Background job definitions and processors
├── utils/           # Pure utility functions
└── types/           # Shared TypeScript interfaces and DTOs
```

- Routes call services, services call repositories — never skip layers
- Each layer has a single concern: routes handle HTTP, services handle logic, repos handle data
- DTOs define the contract between layers — do not pass raw request objects into services

## Repository Pattern

- Define repository interfaces with CRUD + query methods: `findAll`, `findById`, `create`, `update`, `delete`
- Implementations are database-specific — swap Postgres for Mongo without changing services
- Keep queries in repositories — services should not contain SQL or ORM-specific code
- Return domain objects, not raw database rows — map in the repository
- Use parameterized queries exclusively — never interpolate user input

## Service Layer

- Services contain all business rules — validation, authorization checks, orchestration
- Inject repositories via constructor for testability: `constructor(private userRepo: UserRepository)`
- Services are stateless — no instance variables that change between requests
- One public method per business operation — keep methods focused and testable
- Throw domain-specific errors (`NotFoundError`, `ConflictError`) — let error middleware translate to HTTP

## Middleware Pipeline

- Order matters: logging -> rate limiting -> auth -> validation -> handler -> error handling
- Keep middleware single-purpose — one concern per function
- Auth middleware extracts and validates token, attaches user to request context
- Validation middleware parses and validates request body/params with Zod schemas before handler runs
- Error-handling middleware is always last — catches thrown errors and formats HTTP responses

## Centralized Error Handling

- Define a base `AppError` class with `statusCode`, `message`, `isOperational` properties
- Subclass for specific cases: `NotFoundError(404)`, `ValidationError(422)`, `ConflictError(409)`
- Error middleware maps `AppError` subclasses to HTTP responses with structured JSON
- Log unexpected errors (non-operational) with full stack traces to monitoring
- Never expose stack traces or internal details in production error responses
- Validate all input at the boundary — return `422` with field-level error details

## Caching

- **Cache-aside**: check cache first, on miss fetch from DB and populate cache, set TTL
- **Redis** for distributed caching — use `SETEX` with appropriate TTL per data type
- Cache keys should be deterministic and namespaced: `users:{id}`, `markets:list:{filters_hash}`
- Invalidate cache on writes — delete the key, do not try to update cached values
- Set TTLs based on data volatility: 30s for real-time, 5m for semi-static, 1h+ for reference data
- Never cache user-specific data in shared caches without scoping keys to the user

## Authentication

- Use Bearer tokens (JWT or opaque) via `Authorization` header
- Validate on every request: check expiration, signature, issuer, audience
- Store refresh tokens server-side (database or Redis) — never in localStorage
- Short-lived access tokens (15m), long-lived refresh tokens (7d) with rotation
- Hash passwords with bcrypt (cost factor 12+) — never store plaintext

## Role-Based Access Control

- Define permissions as granular actions: `users:read`, `users:write`, `admin:manage`
- Map roles to permission sets — roles are just named collections of permissions
- Check permissions in middleware or service layer, never in repositories
- Use a `requirePermission('resource:action')` middleware for route-level guards
- Return `401` for missing/invalid auth, `403` for insufficient permissions

## Background Jobs

- Use a job queue (BullMQ, Agenda) for work that does not need to complete in the request cycle
- Jobs must be idempotent — safe to retry on failure without side effects
- Set max retries with exponential backoff: attempts 1-3 with delays 1s, 4s, 16s
- Log job start, completion, and failure with job ID for traceability
- Separate job definition (what to do) from job scheduling (when to do it)
- Dead-letter failed jobs after max retries — alert and investigate, do not silently drop

## Structured Logging

- Log as JSON — structured logs are searchable and parseable by log aggregators
- Include context on every log: `requestId`, `userId`, `method`, `path`, `duration`
- Generate `requestId` in middleware, propagate through the request lifecycle
- Log levels: `error` (failures), `warn` (degraded), `info` (operations), `debug` (development)
- Log at service boundaries: incoming request, outgoing response, external API calls
- Never log sensitive data: passwords, tokens, PII, credit card numbers

## Retry with Exponential Backoff

- Retry only on transient failures (network errors, 5xx, timeouts) — never on 4xx
- Backoff formula: `delay = baseDelay * 2^attempt` with jitter to prevent thundering herd
- Set a maximum retry count (3-5) and maximum delay cap (30s)
- Circuit breaker for external services: open after N consecutive failures, half-open after cooldown
- Log each retry attempt with attempt number and delay for debugging

## Database Practices

- Use connection pooling — configure min/max connections based on expected concurrency
- Prevent N+1 queries: batch-fetch related records with `WHERE id IN (...)` or use JOINs
- Select only needed columns — avoid `SELECT *` in production code
- Use transactions for operations that must be atomic across multiple tables
- Add database indexes for columns used in WHERE, JOIN, and ORDER BY clauses
- Use migrations for schema changes — never modify production schemas manually

## Health Checks and Graceful Shutdown

- Expose `/health` endpoint that checks database connectivity, Redis, and external dependencies
- Return `200` with dependency status details for monitoring and load balancers
- Handle `SIGTERM`: stop accepting new requests, finish in-flight requests, close connections, exit
- Set a shutdown timeout (30s) — force-exit if graceful shutdown exceeds it
- Drain job queues on shutdown — finish current job, do not pick up new ones
