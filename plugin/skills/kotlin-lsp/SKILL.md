---
name: kotlin-lsp
description: "Kotlin language server guidance for code intelligence, refactoring, and analysis. Auto-loaded when working with .kt or .kts files."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# Kotlin LSP Integration

Guidance for leveraging the Kotlin language server (kotlin-lsp) for code intelligence.

## Supported File Types

`.kt`, `.kts`

## Installation

```bash
brew install JetBrains/utils/kotlin-lsp
```

## Kotlin Conventions

### Naming
- Classes: `PascalCase`
- Functions/Properties: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Packages: lowercase with dots

### Null Safety
- Use nullable types explicitly: `String?`
- Prefer safe calls `?.` and elvis `?:` over `!!`
- Use `let`, `run`, `also`, `apply` for null-safe scoping
- Never use `!!` except in tests

### Data Classes
- Use `data class` for DTOs and value objects
- Use `sealed class` / `sealed interface` for restricted hierarchies
- Use `value class` for type-safe wrappers (inline classes)

### Coroutines
- Use `suspend` functions for async operations
- Use `CoroutineScope` and structured concurrency
- Use `Flow` for reactive streams
- Handle cancellation properly with `ensureActive()` or `yield()`

### Extension Functions
- Use for adding behavior to types you don't own
- Keep extension functions close to their usage
- Don't overuse — if it's core behavior, it belongs in the class

### Idioms
- Use `when` expression (exhaustive) over if-else chains
- String templates: `"Hello, $name"` and `"Total: ${items.size}"`
- Use scope functions idiomatically: `apply` for config, `let` for transforms, `also` for side effects
- Prefer `listOf`, `mapOf`, `setOf` for immutable collections
- Use `sequence` for lazy evaluation of large collections
