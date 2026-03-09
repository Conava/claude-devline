---
name: clangd-lsp
description: "clangd (C/C++ language server) guidance for code intelligence and diagnostics. Auto-loaded when working with .c, .cpp, .h, .hpp files."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# clangd LSP Integration

Guidance for leveraging clangd for C/C++ code intelligence.

## Supported File Types

`.c`, `.h`, `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx`, `.C`, `.H`

## Installation

```bash
# macOS
brew install llvm
# Linux
sudo apt install clangd
```

## clangd Specific Guidance

### Compilation Database
- clangd requires `compile_commands.json` for accurate analysis
- CMake: `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
- Bear: `bear -- make` to generate from Makefile
- Place at project root or use `.clangd` config to specify path

### Configuration (.clangd)
```yaml
CompileFlags:
  Add: [-std=c++20, -Wall, -Wextra]
Diagnostics:
  UnusedIncludes: Strict
  ClangTidy:
    Add: [modernize-*, performance-*]
```

### Key Features
- Include path resolution and unused include detection
- Code completion with semantic awareness
- Rename across files
- Format with clang-format integration

### C/C++ Conventions
- Use RAII for resource management
- Prefer smart pointers (`unique_ptr`, `shared_ptr`) over raw pointers
- Use `const` liberally — const references for parameters, const methods
- Use `auto` when type is obvious from initialization
- Prefer range-based for loops: `for (const auto& item : collection)`
- Use `std::optional` instead of sentinel values
- Use `std::variant` instead of unions with type tags
