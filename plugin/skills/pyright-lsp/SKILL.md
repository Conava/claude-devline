---
name: pyright-lsp
description: "Pyright/Python language server guidance for type checking and code intelligence. Auto-loaded when working with .py files alongside python-patterns."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# Pyright LSP Integration

Guidance for leveraging Pyright for Python type checking and code intelligence.

## Supported File Types

`.py`, `.pyi`

## Installation

```bash
pip install pyright
# or: npm install -g pyright
```

## Pyright-Specific Guidance

### Type Checking Modes
- `basic` — catches common errors
- `standard` — recommended for most projects
- `strict` — maximum type safety, requires full annotations

### Configuration (pyrightconfig.json)
- Set `typeCheckingMode` to match project needs
- Configure `include` and `exclude` paths
- Set `pythonVersion` to target version
- Use `stubPath` for custom type stubs

### Type Annotations for Pyright
- All public function signatures need annotations for strict mode
- Use `typing.overload` for functions with multiple signatures
- Use `TypeGuard` for custom type narrowing functions
- Use `assert_type()` to verify inferred types during development
- Use `# type: ignore[error-code]` with specific error codes, never bare

### Common Pyright Errors
- `reportMissingTypeStubs` — install type stubs or create `py.typed` marker
- `reportGeneralClassIssues` — check class hierarchy and method signatures
- `reportPrivateUsage` — respect underscore-prefixed private members
- `reportUnnecessaryIsInstance` — type is already narrowed
