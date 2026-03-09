---
name: database-migrations
description: "Database migration conventions and patterns. Auto-loaded when working in migrations/ or db/ directories."
disable-model-invocation: false
user-invocable: false
---

# Database Migration Patterns

Domain knowledge for database schema migrations. Follow these conventions for safe, reversible schema changes.

## General Principles

- Every schema change is a migration — never modify the database manually
- Migrations are ordered and immutable — never edit an applied migration
- Each migration does one logical change
- All migrations must be reversible (provide both up and down)
- Test migrations on a copy of production data before deploying

## Migration Naming

- Sequential numbering or timestamps: `001_create_users.sql` or `20240115_093000_create_users.sql`
- Descriptive names: `add_email_index_to_users`, `create_order_items_table`
- Prefix with action: `create_`, `add_`, `remove_`, `rename_`, `alter_`

## Safe Migration Practices

### Adding Columns
- Always add columns as nullable or with a default value
- Never add NOT NULL columns without a default to tables with existing data
- Add the column, backfill data, then add NOT NULL constraint in separate migrations

### Removing Columns
- First deploy code that stops reading/writing the column
- Then remove the column in a separate migration
- Two-phase approach prevents errors during rolling deployments

### Renaming Columns
- Add new column, copy data, update code, remove old column (4-step process)
- Never use `RENAME COLUMN` in production — breaks running code during deployment

### Adding Indexes
- Use `CREATE INDEX CONCURRENTLY` (PostgreSQL) to avoid table locks
- Index columns used in WHERE, JOIN, and ORDER BY clauses
- Composite indexes: most selective column first
- Partial indexes for commonly filtered subsets

### Table Changes
- Create new tables freely — no impact on existing data
- Drop tables only after all code references are removed
- Rename tables with the same multi-step approach as columns

## Framework-Specific

### Flyway (Java/Spring)
- Files in `src/main/resources/db/migration/`
- Naming: `V1__Create_users_table.sql`, `V2__Add_email_to_users.sql`
- Repeatable migrations: `R__Create_views.sql`
- Undo migrations: `U1__Create_users_table.sql`

### Alembic (Python/SQLAlchemy)
- Auto-generate: `alembic revision --autogenerate -m "add users table"`
- Always review auto-generated migrations for correctness
- Use `op.batch_alter_table()` for SQLite compatibility

### ActiveRecord (Ruby/Rails)
- Generate: `rails generate migration AddEmailToUsers email:string`
- Use `change` method for reversible migrations
- Use `reversible` block for complex up/down logic

### Prisma (TypeScript/Node)
- `prisma migrate dev --name add_users_table`
- Schema-first approach — edit `schema.prisma`, generate migration
- Use `prisma migrate deploy` for production

### Knex (JavaScript/Node)
- `knex migrate:make create_users_table`
- Use `up()` and `down()` exports
- Use transactions in migrations: `return knex.schema.createTable(...)`

## Data Migrations

- Separate schema migrations from data migrations
- Data migrations should be idempotent (safe to run multiple times)
- Use batched processing for large tables — don't update millions of rows in one transaction
- Log progress for long-running data migrations
- Always have a rollback strategy for data migrations

## Common Anti-Patterns to Avoid

- Editing applied migrations — creates inconsistencies across environments
- Missing down migrations — can't rollback deployments
- Locking tables during migration — use concurrent operations
- Running migrations in a transaction that also serves traffic
- Not testing migrations with production-like data volumes
- Hardcoding data in migrations instead of using seed files
