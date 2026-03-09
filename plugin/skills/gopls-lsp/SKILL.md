---
name: gopls-lsp
description: "gopls (Go language server) guidance for code intelligence and analysis. Auto-loaded when working with .go files alongside golang-patterns."
disable-model-invocation: false
user-invocable: false
allowed-tools: Bash
---

# gopls LSP Integration

Guidance for leveraging gopls for Go code intelligence.

## Supported File Types

`.go`

## Installation

```bash
go install golang.org/x/tools/gopls@latest
```

## gopls-Specific Guidance

### Workspace Configuration
- Use Go modules (`go.mod`) — gopls requires modules
- Multi-module workspaces: use `go.work` file
- Set `GOPATH` correctly for gopls to find dependencies

### Code Actions
- Organize imports automatically
- Generate interface implementations
- Extract function/method refactoring
- Fill struct literal fields
- Add/remove struct tags

### Diagnostics
- `gopls` runs `go vet` and `staticcheck` by default
- Pay attention to shadow variable warnings
- Fix unused variable/import errors immediately (Go requires this)
- Use build tags correctly for conditional compilation

### Performance
- Large codebases: ensure `go.sum` is committed for faster analysis
- Use `-modcacherw` to allow gopls to modify module cache
- Exclude vendor directory if not using vendor mode
