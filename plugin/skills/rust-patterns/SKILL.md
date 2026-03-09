---
name: rust-patterns
description: "Rust development conventions, patterns, and best practices. Auto-loaded when working with .rs files."
disable-model-invocation: false
user-invocable: false
---

# Rust Patterns

Domain knowledge for Rust development. Follow these conventions when implementing Rust code.

## Project Structure

- Use Cargo workspaces for multi-crate projects
- `src/lib.rs` for library crate, `src/main.rs` for binary
- `src/bin/` for multiple binaries
- `tests/` for integration tests, unit tests in same file with `#[cfg(test)]` module
- `benches/` for benchmarks

## Ownership and Borrowing

- Prefer borrowing (`&T`, `&mut T`) over ownership transfer when caller still needs the value
- Use `Clone` sparingly — understand when a clone is actually needed vs. restructuring ownership
- Prefer `&str` over `String` in function parameters
- Prefer `&[T]` over `Vec<T>` in function parameters
- Use `Cow<'_, str>` when a function might or might not need to allocate

## Error Handling

- Use `Result<T, E>` for recoverable errors, reserve `panic!` for unrecoverable bugs
- Define error types with `thiserror` crate for libraries
- Use `anyhow` for applications (not libraries)
- Use `?` operator for error propagation
- Provide context with `.context()` / `.with_context(|| ...)` (anyhow) or custom error variants
- Never unwrap in library code — always propagate errors

## Type Design

- Use newtypes for domain concepts: `struct UserId(u64)` instead of bare `u64`
- Use enums to make invalid states unrepresentable
- Implement `Display` for user-facing types, `Debug` for all types
- Use builder pattern for types with many optional fields
- Derive common traits: `Debug`, `Clone`, `PartialEq`, `Eq`, `Hash` as appropriate

## Traits and Generics

- Implement standard traits: `From`/`Into` for conversions, `Display` for formatting
- Use trait bounds on `impl` blocks, not individual functions where possible
- Prefer `impl Trait` in argument position for simple generics
- Use `where` clauses for complex bounds
- Blanket implementations over manual implementations when possible

## Concurrency

- Use `tokio` or `async-std` for async runtime — follow project convention
- Use `Arc<Mutex<T>>` for shared mutable state across threads
- Prefer `RwLock` over `Mutex` when reads dominate
- Use channels (`mpsc`, `crossbeam`) for message passing
- Use `rayon` for data parallelism

## Testing

- Unit tests in `#[cfg(test)] mod tests { ... }` at bottom of file
- Use `#[test]` attribute, `assert!`, `assert_eq!`, `assert_ne!`
- Use `#[should_panic]` for panic tests
- Use `proptest` or `quickcheck` for property-based testing
- Test error conditions, not just happy paths

## Common Anti-Patterns to Avoid

- `.unwrap()` and `.expect()` in production code paths
- Unnecessary `clone()` — restructure ownership first
- Overusing `Rc`/`Arc` — often indicates a design problem
- Fighting the borrow checker with unsafe — redesign instead
- Monolithic modules — split into focused modules
