---
name: postgres-patterns
description: "PostgreSQL schema design, indexing, query optimization, and security conventions. Auto-loaded when working with SQL files or database migrations."
disable-model-invocation: false
user-invocable: false
---

# PostgreSQL Patterns

Domain knowledge for PostgreSQL development. Follow these conventions when writing schemas, queries, and migrations.

## Data Types

- IDs: `bigint` (or `bigserial`) -- avoid `int` (range limits) and random UUIDs (index fragmentation)
- Strings: `text` -- avoid `varchar(255)`, postgres `text` has no performance penalty
- Timestamps: `timestamptz` always -- never bare `timestamp` (loses timezone context)
- Money: `numeric(10,2)` -- never `float` or `double precision` (rounding errors)
- Flags: `boolean` -- not `varchar` or `int`
- JSON: `jsonb` -- never `json` (no indexing, slower operators)

## Index Types and Selection

| Query Pattern | Index Type | When to Use |
|--------------|------------|-------------|
| Equality/range (`=`, `>`, `<`, `BETWEEN`) | B-tree (default) | Most queries |
| JSONB containment (`@>`), full-text (`@@`) | GIN | JSONB columns, tsvector |
| Geometric/range overlap | GiST | PostGIS, range types |
| Large sequential tables (time-series) | BRIN | Append-only, physically ordered data |

### Index Conventions

- Composite indexes: equality columns first, then range columns
- Covering indexes: `CREATE INDEX idx ON t (col) INCLUDE (col2, col3)` to avoid table lookups
- Partial indexes: `WHERE deleted_at IS NULL` to reduce index size
- Always index foreign keys -- use the unindexed FK detection query below
- Drop unused indexes -- they slow writes with no read benefit

## Query Optimization

- Always check with `EXPLAIN (ANALYZE, BUFFERS)` before and after optimization
- Use cursor pagination (`WHERE id > $last_id ORDER BY id LIMIT 20`) instead of `OFFSET` (O(1) vs O(n))
- Use `EXISTS` instead of `COUNT(*)` when checking for row existence
- Prefer `SELECT` with explicit columns over `SELECT *`
- Use `FOR UPDATE SKIP LOCKED` for queue-style processing

## Useful Patterns

**UPSERT:** `INSERT ... ON CONFLICT (cols) DO UPDATE SET col = EXCLUDED.col`

**CTEs for readability:**
```sql
WITH active_users AS (
  SELECT id FROM users WHERE deleted_at IS NULL
)
SELECT * FROM orders WHERE user_id IN (SELECT id FROM active_users);
```

**Window functions:** `ROW_NUMBER()`, `RANK()`, `LAG()`, `LEAD()` for analytics without subqueries

**Queue processing:**
```sql
UPDATE jobs SET status = 'processing'
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending'
  ORDER BY created_at LIMIT 1
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

## Row Level Security (RLS)

- Enable RLS on tables with tenant/user data: `ALTER TABLE t ENABLE ROW LEVEL SECURITY`
- Wrap `auth.uid()` in a subselect for performance: `USING ((SELECT auth.uid()) = user_id)`
- Force RLS for table owners: `ALTER TABLE t FORCE ROW LEVEL SECURITY`
- Always test policies with `SET ROLE` to verify access boundaries

## Migration Safety

- Never rename columns directly -- add new, backfill, migrate reads, drop old
- Never drop columns in the same deploy as code changes -- decouple schema and code deploys
- Add indexes `CONCURRENTLY` to avoid table locks: `CREATE INDEX CONCURRENTLY`
- Add columns as `NULL` first, backfill, then add `NOT NULL` constraint
- Always make migrations reversible
- Test migrations against production-sized data before deploying
- Set `statement_timeout` and `lock_timeout` in migration scripts

## Anti-Pattern Detection Queries

```sql
-- Find unindexed foreign keys
SELECT conrelid::regclass, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );

-- Find slow queries (requires pg_stat_statements)
SELECT query, mean_exec_time, calls
FROM pg_stat_statements WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;

-- Check table bloat
SELECT relname, n_dead_tup, last_vacuum
FROM pg_stat_user_tables WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

## Configuration Essentials

- Set `idle_in_transaction_session_timeout = '30s'` to kill abandoned transactions
- Set `statement_timeout = '30s'` as a safety net
- Enable `pg_stat_statements` for query monitoring
- Revoke public schema access: `REVOKE ALL ON SCHEMA public FROM public`
- Use connection pooling (PgBouncer, Supavisor) for high-concurrency apps

## Common Anti-Patterns to Avoid

- Using `OFFSET` for pagination on large tables
- Missing indexes on foreign keys
- Using `timestamp` instead of `timestamptz`
- Storing money as `float`
- Running long-lived transactions (locks, bloat)
- Adding `NOT NULL` constraints without backfilling first
- Dropping columns in the same deploy as code changes
