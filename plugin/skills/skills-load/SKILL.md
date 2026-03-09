---
name: skills-load
description: "Use when the user asks to 'load skill', 'load skills', 'activate skill', 'I need kotlin patterns', or wants to load domain/LSP skills ad-hoc. Also invoked automatically by the brainstorm agent when it detects missing skills."
argument-hint: "[skill name or technology]"
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# Load Skills Ad-Hoc

Intelligently detect, load, and persist domain and LSP skills based on natural language input, project context, or brainstorm analysis.

## Trigger Sources

This skill is invoked in three ways:
1. **User request**: "/skills-load kotlin and api design" or "I need rust patterns"
2. **Natural language**: "I'm building a REST API with Spring Boot and PostgreSQL"
3. **Brainstorm auto-trigger**: Brainstorm agent detects technologies not covered by loaded skills

## Procedure

### Step 1: Analyze Intent

Parse the input — whether a direct skill name, fuzzy shorthand, or a natural language description of what's being built. Identify all technologies, languages, frameworks, and domains mentioned or implied.

Examples of inference:
- "I'm building a REST API with Kotlin and PostgreSQL" → kotlin-lsp, api-design, database-migrations
- "Spring Boot microservice with JPA" → java-coding-standards, jdtls-lsp, springboot-patterns, jpa-patterns, api-design
- "React dashboard with TypeScript" → frontend-design, typescript-lsp
- "CLI tool in Rust" → rust-patterns, rust-analyzer-lsp
- "Python data pipeline with FastAPI" → python-patterns, pyright-lsp, api-design

Fuzzy name resolution:
- "python" / "py" → python-patterns, pyright-lsp
- "rust" / "rs" → rust-patterns, rust-analyzer-lsp
- "go" / "golang" → golang-patterns, gopls-lsp
- "java" → java-coding-standards, jdtls-lsp
- "kotlin" / "kt" → kotlin-lsp
- "typescript" / "ts" → typescript-lsp
- "c++" / "cpp" / "c" → cpp-patterns, clangd-lsp
- "csharp" / "c#" / "cs" → csharp-lsp
- "swift" / "swiftui" / "ios" / "macos" → swift-patterns
- "spring" / "springboot" → springboot-patterns
- "jpa" / "hibernate" → jpa-patterns
- "django" / "drf" → django-patterns, python-patterns, pyright-lsp
- "api" / "rest" / "endpoints" → api-design
- "database" / "migrations" / "db" / "schema" → database-migrations
- "postgres" / "postgresql" / "sql" → postgres-patterns
- "docker" / "container" / "dockerfile" → docker-patterns
- "deploy" / "ci" / "cd" / "cicd" / "pipeline" → deployment-patterns
- "e2e" / "playwright" / "cypress" → e2e-testing
- "backend" / "server" / "node" / "express" → backend-patterns
- "frontend" / "ui" / "css" / "react" / "vue" → frontend-design, frontend-patterns
- "writing" / "article" / "blog" / "newsletter" → article-writing
- "content" / "social" / "marketing" → content-engine
- "pitch" / "deck" / "investor" / "fundraising" → investor-materials, investor-outreach
- "research" / "market" / "competitor" → market-research
- "debug" / "debugging" / "bug" / "investigate" / "root cause" → systematic-debugging
- "claude-md" / "project-memory" → claude-md-management

### Step 2: Check What's Already Loaded

Read the current session context to see which skills are already active. Only load skills that aren't already present. If all requested skills are already loaded, say so and skip.

### Step 3: Load Skills

For each skill to load, read `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/SKILL.md`. If a skill directory doesn't exist, report it and suggest `/skills-list` to see what's available.

Output a confirmation:
```
Loaded: kotlin-lsp, api-design, database-migrations
Already active: python-patterns
Not found: custom-framework (use /skills-list to see available skills)
```

### Step 4: Auto-Persist to Project Config

After loading, automatically persist the skills to the project config so they're available in future sessions without needing `/skills-load` again.

1. Check if `${CLAUDE_PROJECT_DIR}/.claude-plugin-config.yaml` exists
2. If it exists, read it and merge new skills into `skills.enabled` (don't duplicate)
3. If it doesn't exist, create it with:
```yaml
skills:
  enabled:
    - <newly-loaded-skill-1>
    - <newly-loaded-skill-2>
```
4. Confirm to the user:
```
Persisted to .claude-plugin-config.yaml — these skills will auto-load in future sessions.
```

Use the Edit tool for existing files, Write tool for new files. Add `.claude-plugin-config.yaml` to `.gitignore` if not already there (this is personal/local config).

### Step 5: Update .gitignore if Needed

If `.claude-plugin-config.yaml` was just created, check if it's in `.gitignore`. If not, append it:
```
# Claude Code plugin config (local overrides)
.claude-plugin-config.yaml
```

## Unloading

Skills in context can't be removed mid-session. To prevent a skill from loading in future sessions:
```yaml
# .claude-plugin-config.yaml
skills:
  disabled: [frontend-design, clangd-lsp]
```
The `disabled` list takes precedence over both `enabled` and auto-detection.
