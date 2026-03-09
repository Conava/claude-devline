---
name: typescript-lsp
description: "TypeScript language server guidance for type checking, refactoring, and code intelligence. Auto-loaded when working with .ts, .tsx, .js, .jsx files."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# TypeScript LSP Integration

Guidance for leveraging the TypeScript language server for code intelligence.

## Supported File Types

`.ts`, `.tsx`, `.js`, `.jsx`, `.mts`, `.cts`, `.mjs`, `.cjs`

## Installation

```bash
npm install -g typescript-language-server typescript
```

## TypeScript Conventions

### Type Safety
- Enable `strict: true` in tsconfig.json
- Avoid `any` — use `unknown` for truly unknown types, then narrow
- Use discriminated unions over type assertions
- Prefer `interface` for object shapes, `type` for unions/intersections/utilities

### Types
- Use `readonly` for immutable properties and arrays
- Use `as const` for literal types
- Use template literal types for string patterns
- Use `satisfies` operator (5.0+) for type checking without widening
- Prefer `Record<K, V>` over index signatures

### Functions
- Use explicit return types on exported functions
- Use function overloads for complex signatures
- Prefer arrow functions for callbacks, function declarations for named exports
- Use `never` return type for functions that throw or loop forever

### Modules
- Use ES modules (`import`/`export`) exclusively
- Barrel exports (`index.ts`) for clean public APIs
- Use `type` imports: `import type { Foo } from './foo'`
- Avoid circular dependencies

### Error Handling
- Use discriminated unions for typed errors: `type Result<T> = { ok: true; data: T } | { ok: false; error: Error }`
- Narrow error types in catch blocks: `if (error instanceof SpecificError)`
- Use `Error` cause chain: `new Error('context', { cause: originalError })`

### React (TSX)
- Use `FC` type sparingly — prefer explicit props types
- Use `PropsWithChildren` when accepting children
- Use `ComponentProps<typeof Component>` to extract prop types
- Discriminated unions for component variants
