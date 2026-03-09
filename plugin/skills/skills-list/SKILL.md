---
name: skills-list
description: "Use when the user asks to 'list skills', 'show available skills', 'what skills are available', or '/skills'."
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# List Available Skills

Scan `${CLAUDE_PLUGIN_ROOT}/skills/` for all subdirectories containing `SKILL.md` files. For each, extract the `name` and `description` from YAML frontmatter.

Present as a table grouped by type:

**Pipeline Skills** (workflow stages):

| Skill | Description |
|-------|-------------|
| pipeline | Full development pipeline |
| brainstorm | Design exploration |
| plan | Implementation planning |
| implement | Task implementation |
| review | Deep code review |
| docs-update | Documentation updates |
| merge-prep | Pre-merge cleanup |

**Domain Skills** (language/framework knowledge modules loaded by agents):

| Skill | Description |
|-------|-------------|
| frontend-design | Distinctive UI/UX principles |
| python-patterns | Python idioms and best practices |
| golang-patterns | Go idioms and best practices |
| rust-patterns | Rust idioms and best practices |
| java-coding-standards | Java coding standards |
| springboot-patterns | Spring Boot conventions |
| jpa-patterns | JPA/Hibernate patterns |
| api-design | API design principles |
| database-migrations | Database migration best practices |

**LSP Skills** (language server integration for diagnostics):

| Skill | Description |
|-------|-------------|
| typescript-lsp | TypeScript language server diagnostics |
| pyright-lsp | Python type checking via Pyright |
| gopls-lsp | Go language server diagnostics |
| rust-analyzer-lsp | Rust language server diagnostics |
| kotlin-lsp | Kotlin language server diagnostics |
| clangd-lsp | C/C++ language server diagnostics |
| jdtls-lsp | Java language server diagnostics |
| csharp-lsp | C# language server diagnostics |

**Management Skills** (project and plugin management):

| Skill | Description |
|-------|-------------|
| claude-md-management | CLAUDE.md file management |
| skills-list | List available skills |
| skills-load | Load skills ad-hoc into current session |

List actual skills found on disk, not this hardcoded example. Categorize each discovered skill into the appropriate group based on its name and description.
