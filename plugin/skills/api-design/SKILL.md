---
name: api-design
description: "REST API and web service design conventions. Auto-loaded when working with API endpoints, Express/FastAPI/Spring controllers, or OpenAPI specs."
disable-model-invocation: false
user-invocable: false
---

# API Design Patterns

Domain knowledge for RESTful API and web service design. Follow these conventions when implementing APIs.

## URL Design

- Use plural nouns for resource collections: `/users`, `/orders`, `/products`
- Nest sub-resources: `/users/{id}/orders`
- Maximum 2 levels of nesting — deeper relationships use query params or links
- Use kebab-case for multi-word paths: `/order-items`
- No verbs in URLs — HTTP methods convey the action
- Use query parameters for filtering, sorting, pagination: `/users?role=admin&sort=name&page=2`

## HTTP Methods

- `GET` — Read (idempotent, cacheable, no body)
- `POST` — Create new resource or trigger action
- `PUT` — Full replacement of a resource (idempotent)
- `PATCH` — Partial update (provide only changed fields)
- `DELETE` — Remove resource (idempotent)

## Status Codes

- `200 OK` — Successful GET, PUT, PATCH, or DELETE
- `201 Created` — Successful POST that creates a resource (include Location header)
- `204 No Content` — Successful DELETE with no response body
- `400 Bad Request` — Malformed request syntax or invalid parameters
- `401 Unauthorized` — Missing or invalid authentication
- `403 Forbidden` — Authenticated but insufficient permissions
- `404 Not Found` — Resource does not exist
- `409 Conflict` — State conflict (duplicate, version mismatch)
- `422 Unprocessable Entity` — Valid syntax but semantic errors (validation failures)
- `429 Too Many Requests` — Rate limit exceeded (include Retry-After header)
- `500 Internal Server Error` — Unexpected server failure

## Request/Response Design

- Use JSON for request and response bodies
- Consistent envelope for collections: `{ "data": [...], "pagination": { "page": 1, "total": 42 } }`
- Include `id` and relevant timestamps (`created_at`, `updated_at`) in responses
- Use ISO 8601 for dates: `2024-01-15T09:30:00Z`
- Use camelCase for JSON field names (or match project convention)

## Error Responses

Structured error format:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description",
    "details": [
      { "field": "email", "message": "Must be a valid email address" }
    ]
  }
}
```

- Machine-readable error codes (UPPER_SNAKE_CASE)
- Human-readable messages
- Field-level details for validation errors
- Never expose stack traces or internal details in production

## Authentication and Authorization

- Use Bearer tokens (JWT or opaque) via `Authorization` header
- Validate tokens on every request — check expiration, signature, issuer
- Use scopes or roles for authorization granularity
- Return `401` for missing/invalid auth, `403` for insufficient permissions
- Rate limit authentication endpoints aggressively

## Pagination

- Offset-based: `?page=2&per_page=20` — simple, allows jumping to pages
- Cursor-based: `?cursor=abc123&limit=20` — better for real-time data, no skipping
- Always include pagination metadata in response
- Set reasonable defaults and maximums for page size

## Versioning

- URL prefix: `/v1/users` (most explicit)
- Or header-based: `Accept: application/vnd.api+json;version=1`
- Never break existing clients — additive changes are safe, removing fields is breaking
- Deprecation: add `Sunset` header and `Deprecated` flag in docs before removal

## Security

- Validate all input — reject unknown fields, check types and ranges
- Use parameterized queries — never concatenate user input into queries
- Set security headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security`
- CORS: restrict origins to known clients, never `*` for authenticated endpoints
- Rate limiting on all endpoints, stricter on auth/sensitive endpoints
