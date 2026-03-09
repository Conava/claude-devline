---
name: csharp-lsp
description: "C# language server guidance for code intelligence and diagnostics. Auto-loaded when working with .cs files."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# C# LSP Integration

Guidance for leveraging the C# language server for code intelligence.

## Supported File Types

`.cs`

## Installation

```bash
dotnet tool install --global csharp-ls
```

Requires .NET SDK 6.0+.

## C# Conventions

### Naming
- Classes/Methods/Properties: `PascalCase`
- Local variables/parameters: `camelCase`
- Private fields: `_camelCase` (with underscore prefix)
- Constants: `PascalCase` (C# convention, not UPPER_SNAKE)
- Interfaces: `IPascalCase` (prefix with I)

### Modern C# Features
- Use records for immutable data types: `record Person(string Name, int Age);`
- Pattern matching: `is`, `switch` expressions with patterns
- Nullable reference types: enable `<Nullable>enable</Nullable>` in .csproj
- Use `required` modifier (C# 11) for required properties
- Use `init` setters for immutable-after-construction properties
- Primary constructors (C# 12) for simple dependency injection

### Async/Await
- Suffix async methods with `Async`: `GetUserAsync()`
- Always use `async/await` — never `.Result` or `.Wait()` (deadlock risk)
- Use `CancellationToken` parameter for cancellable operations
- Use `ValueTask<T>` for hot-path async methods that often complete synchronously

### Dependency Injection
- Constructor injection via built-in DI container
- Register services in `Program.cs` or `Startup.cs`
- Use `IOptions<T>` for configuration binding
- Scoped services for per-request lifetime, Singleton for shared state

### Error Handling
- Use specific exception types
- Use `when` clause in catch: `catch (HttpRequestException ex) when (ex.StatusCode == 404)`
- Use Result pattern for expected failures instead of exceptions
- Global exception handling via middleware in ASP.NET
