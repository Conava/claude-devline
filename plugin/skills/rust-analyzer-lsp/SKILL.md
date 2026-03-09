---
name: rust-analyzer-lsp
description: "rust-analyzer guidance for code intelligence and analysis. Auto-loaded when working with .rs files alongside rust-patterns."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# rust-analyzer LSP Integration

Guidance for leveraging rust-analyzer for Rust code intelligence.

## Supported File Types

`.rs`

## Installation

```bash
rustup component add rust-analyzer
```

## rust-analyzer Specific Guidance

### Key Features
- Inlay hints for types, parameter names, chaining
- Magic completions: `expr.if`, `expr.match`, `expr.dbg`
- Assist: fill match arms, add missing trait implementations
- Structural search and replace

### Cargo Integration
- rust-analyzer uses Cargo for project structure
- Ensure `Cargo.toml` is at workspace root
- Use `rust-analyzer.cargo.features` to enable specific features
- `check on save` runs `cargo check` for fast feedback

### Common Diagnostics
- Lifetime errors — restructure ownership rather than adding lifetime annotations
- Unused code — prefix with `_` or remove
- Missing trait implementations — use code actions to auto-generate
- Borrow checker errors — check for multiple mutable borrows or moves

### Workspace Settings
- `rust-analyzer.checkOnSave.command`: use `clippy` for stricter linting
- `rust-analyzer.cargo.allFeatures`: enable all features for complete analysis
- `rust-analyzer.procMacro.enable`: needed for derive macros
