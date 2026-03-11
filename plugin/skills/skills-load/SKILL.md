---
name: skills-load
description: "Use when the user asks to 'load skill', 'load skills', 'activate skill', 'I need kotlin patterns', or wants to load domain skills ad-hoc."
argument-hint: "[skill name or technology]"
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# Load Skills Ad-Hoc

Intelligently detect, load, and persist domain skills based on natural language input, project context, or brainstorm analysis.

## Trigger Sources

This skill is invoked in two ways:
1. **User request**: "/skills-load kotlin and api design" or "I need rust patterns"
2. **Natural language**: "I'm building a REST API with Spring Boot and PostgreSQL"

Note: pipeline agents (implementer, etc.) load domain skills automatically via frontmatter — this skill is for loading knowledge into the **main chat** session.

## Procedure

### Step 1: Analyze Intent

Parse the input — whether a direct skill name, fuzzy shorthand, or a natural language description of what's being built. Identify all technologies, languages, frameworks, and domains mentioned or implied.

Examples of inference:
- "I'm building a REST API with Kotlin and PostgreSQL" → api-design, database-migrations
- "Spring Boot microservice with JPA" → java-coding-standards, springboot-patterns, jpa-patterns, api-design
- "React dashboard with TypeScript" → frontend-design, frontend-patterns
- "CLI tool in Rust" → rust-patterns
- "Python data pipeline with FastAPI" → python-patterns, api-design

Fuzzy name resolution:
- "python" / "py" → python-patterns
- "rust" / "rs" → rust-patterns
- "go" / "golang" → golang-patterns
- "java" → java-coding-standards
- "typescript" / "ts" → frontend-patterns
- "c++" / "cpp" / "c" → cpp-patterns
- "swift" / "swiftui" / "ios" / "macos" → swift-patterns
- "spring" / "springboot" → springboot-patterns
- "jpa" / "hibernate" → jpa-patterns
- "django" / "drf" → django-patterns, python-patterns
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
- "claude-md" / "project-memory" / "docs" / "documentation" → docs-update

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

The project config lives at `${CLAUDE_PROJECT_DIR}/.claude/plugin-config.yaml` (inside `.claude/` to keep the repo root clean).

1. Check if `${CLAUDE_PROJECT_DIR}/.claude/plugin-config.yaml` exists
2. If it exists, read it and merge new skills into `skills.enabled` (don't duplicate)
3. If it doesn't exist, create `.claude/` directory if needed, then create the file with:
```yaml
skills:
  enabled:
    - <newly-loaded-skill-1>
    - <newly-loaded-skill-2>
```
4. Confirm to the user:
```
Persisted to .claude/plugin-config.yaml — these skills will auto-load in future sessions.
```

Use the Edit tool for existing files, Write tool for new files.

### Step 5: Update .gitignore if Needed

`.claude/` is typically already gitignored or committed intentionally. Check if `.claude/plugin-config.yaml` or `.claude/` is in `.gitignore`. If neither is, append:
```
# Claude Code plugin config (local overrides)
.claude/plugin-config.yaml
```

## Unloading

Skills in context can't be removed mid-session. To prevent a skill from loading in future sessions:
```yaml
# .claude/plugin-config.yaml
skills:
  disabled: [frontend-design, cpp-patterns]
```
The `disabled` list takes precedence over both `enabled` and auto-detection.
