---
name: database-design
description: "Database architecture, schema design, indexing strategy, migration safety, and query optimization patterns for relational and NoSQL databases."
user-invocable: false
---

# Database Design Patterns

## Technology Selection

| Need | Choice | Reasoning |
|------|--------|-----------|
| Strong consistency, complex queries | PostgreSQL | ACID, rich types, JSONB, full-text search |
| Document-oriented, flexible schema | MongoDB | Schema-on-read, horizontal scaling |
| High-throughput key-value | Redis | In-memory, sub-ms latency |
| Time-series data | TimescaleDB / InfluxDB | Compression, retention policies |
| Graph relationships | Neo4j / PostgreSQL recursive CTEs | Traversal queries |
| Full-text search | Elasticsearch / PostgreSQL tsvector | Relevance scoring, faceting |

## Schema Design Principles

### Normalization First
Design in 3NF minimum, then selectively denormalize for measured performance needs:
- **1NF**: Atomic values, no repeating groups
- **2NF**: No partial dependencies on composite keys
- **3NF**: No transitive dependencies

### Denormalization Decisions
Only denormalize when you have evidence (query profiling) that joins are the bottleneck:
- Materialized views for read-heavy aggregations
- Computed columns for frequently derived values
- Embedding for 1:1 relationships that are always fetched together

### Data Modeling Patterns
- **Temporal data**: Use `valid_from`/`valid_to` columns (SCD Type 2) for audit trails
- **Hierarchical data**: Closure table for deep hierarchies, materialized path for breadcrumbs, adjacency list for simple trees
- **Multi-tenancy**: Schema-per-tenant (isolation) vs shared-schema with `tenant_id` (simplicity)
- **Soft deletes**: `deleted_at` timestamp — add partial index `WHERE deleted_at IS NULL` for active records

## Indexing Strategy

### Rules
- Index every foreign key column
- Index columns in `WHERE`, `ORDER BY`, `JOIN ON` clauses
- Composite indexes: most selective column first, then order matters for range queries
- Covering indexes: include all `SELECT` columns to enable index-only scans
- Partial indexes: `CREATE INDEX ... WHERE status = 'active'` when filtering is common

### Anti-patterns
- Indexing low-cardinality columns alone (boolean, status with 3 values)
- Too many indexes on write-heavy tables (each insert/update maintains all indexes)
- Missing index maintenance (bloated indexes, outdated statistics)

## Migration Safety (Zero-Downtime)

### Safe Migration Pattern
1. **Add nullable column** (or with default) — backward compatible
2. **Deploy code** that writes to both old and new columns
3. **Backfill** old data in batches (not one giant UPDATE)
4. **Deploy code** that reads from new column
5. **Add NOT NULL constraint** (if needed) after backfill verified
6. **Drop old column** in a later release

### Dangerous Operations — Require Extra Care
- `ALTER TABLE ... ADD COLUMN ... NOT NULL` without default (locks table)
- `CREATE INDEX` without `CONCURRENTLY` (locks table)
- Renaming columns (breaks running code during deploy)
- Changing column types (requires table rewrite)

### Backfill Template
```sql
-- Batch backfill: process 1000 rows at a time
DO $$
DECLARE batch_size INT := 1000;
DECLARE rows_updated INT;
BEGIN
  LOOP
    UPDATE my_table
    SET new_column = compute_value(old_column)
    WHERE id IN (
      SELECT id FROM my_table
      WHERE new_column IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;
    COMMIT;
    PERFORM pg_sleep(0.1);  -- backpressure
  END LOOP;
END $$;
```

## Query Optimization

### Common Patterns
- **N+1**: Replace loop queries with `JOIN` or `IN (subquery)` or ORM `prefetch_related`
- **Unbounded queries**: Always use `LIMIT` on user-facing endpoints
- **SELECT ***: Select only needed columns — reduces I/O and memory
- **Missing indexes**: Use `EXPLAIN ANALYZE` to find sequential scans on large tables

### Window Functions
```sql
-- Running total, rank within groups, moving average
SELECT
  date,
  amount,
  SUM(amount) OVER (ORDER BY date) AS running_total,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY amount DESC) AS rank
FROM transactions;
```

### Recursive CTEs (Hierarchical Queries)
```sql
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, 1 AS depth
  FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.name, t.depth + 1
  FROM categories c JOIN tree t ON c.parent_id = t.id
  WHERE t.depth < 10  -- always add depth limit
)
SELECT * FROM tree;
```

## Caching Architecture

| Layer | Technology | Cache | Invalidation |
|-------|-----------|-------|-------------|
| Edge | CDN | Static assets, API responses | TTL, purge API |
| Application | Redis | Session, computed values | Write-through, TTL |
| Query | Materialized views | Aggregations | Refresh on schedule |
| Database | Connection pool | Connections | Pool config |

## Checklist

- [ ] Schema is at least 3NF, denormalized only with measured justification
- [ ] All foreign keys are indexed
- [ ] Migrations are backward-compatible (can roll back without data loss)
- [ ] Queries use `EXPLAIN ANALYZE` for optimization
- [ ] Connection pooling is configured (PgBouncer, HikariCP)
- [ ] Backups are tested (not just configured)
