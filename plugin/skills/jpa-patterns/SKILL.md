---
name: jpa-patterns
description: "JPA/Hibernate patterns and conventions. Auto-loaded when working with JPA entities (@Entity, @Repository)."
disable-model-invocation: false
user-invocable: false
---

# JPA Patterns

Domain knowledge for JPA/Hibernate development. Follow these conventions for entity design and data access.

## Entity Design

- Use `@Entity` with explicit `@Table(name = "table_name")`
- Always define a no-arg constructor (can be protected)
- Use `@Id` with `@GeneratedValue(strategy = GenerationType.IDENTITY)` or `SEQUENCE`
- Implement `equals()` and `hashCode()` based on business key, NOT on `@Id` (which is null before persist)
- Use `@Version` for optimistic locking on mutable entities

```java
@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Version
    private Long version;

    @Column(nullable = false)
    private String orderNumber;
}
```

## Relationships

- Default to `FetchType.LAZY` for all associations
- `@OneToMany`: use `mappedBy` on the inverse side, never own the relationship from the collection side
- `@ManyToOne`: this is the owning side — use `@JoinColumn`
- Cascade wisely: `CascadeType.ALL` only for true parent-child (composition). Use specific cascades otherwise
- `orphanRemoval = true` only when child has no meaning without parent
- Avoid `@ManyToMany` — use an explicit join entity for additional attributes

## N+1 Problem Prevention

This is the #1 JPA performance issue.

- Use `@EntityGraph` for specific queries that need eager loading
- Use `JOIN FETCH` in JPQL: `SELECT o FROM Order o JOIN FETCH o.items`
- Use `@BatchSize(size = 20)` on collections as a safety net
- Monitor queries with `spring.jpa.show-sql=true` in development
- Use DTO projections for read-only queries: `SELECT new OrderSummary(o.id, o.total) FROM Order o`

## Repository Patterns

- Extend `JpaRepository<Entity, IdType>` for full CRUD
- Use derived query methods: `findByStatusAndCreatedAtAfter(Status status, Instant after)`
- Use `@Query` for complex queries with JPQL
- Native queries (`nativeQuery = true`) only when JPQL is insufficient
- Use `Specification<T>` for dynamic query building
- Use `Pageable` and return `Page<T>` for paginated queries

## Transaction Management

- Service layer owns transaction boundaries, not repositories
- `@Transactional(readOnly = true)` enables JPA query optimizations
- Keep transactions short — no network calls inside transactions
- Use `@Transactional(propagation = REQUIRES_NEW)` sparingly
- Handle `OptimisticLockException` with retry logic at service level

## Embeddables and Value Objects

- Use `@Embeddable` for value objects: `Address`, `Money`, `DateRange`
- `@Embedded` in the owning entity
- `@AttributeOverrides` for multiple same-type embeddables

## Auditing

- Use `@EntityListeners(AuditingEntityListener.class)` with Spring Data
- `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`
- Create a `BaseEntity` with audit fields for inheritance

## Common Anti-Patterns to Avoid

- Eager fetching by default — causes N+1 and performance issues
- Open Session in View (OSIV) in production — hides lazy loading problems
- Using entities directly in API responses — use DTOs
- Bidirectional relationships without proper `equals/hashCode`
- Long-running transactions with user interaction
- Not using database indexes for frequently queried columns
