---
name: docs-generate
description: "Generate comprehensive technical documentation from codebases — architecture docs, API references, component guides, and onboarding docs. Progressive disclosure from overview to implementation details."
argument-hint: "[scope: full | architecture | api | component <name> | onboarding]"
user-invocable: true
---

# Documentation Generation

Generate comprehensive, self-contained technical documentation by analyzing the actual codebase. Not summaries — real documentation that a new team member can use to understand and contribute to the project.

## When to Use

- `/docs-generate full` — Complete project documentation (architecture + API + components + onboarding)
- `/docs-generate architecture` — System architecture document with component diagrams and data flow
- `/docs-generate api` — API reference from route definitions, handlers, and types
- `/docs-generate component <name>` — Deep documentation for a specific module/component
- `/docs-generate onboarding` — New developer setup and contribution guide

## Process

### Phase 1: Codebase Analysis

1. **Read `CLAUDE.md`** and `project_structure` config for existing documentation paths
2. **Map the codebase structure**: entry points, modules, layers, external dependencies
3. **Identify patterns**: Architecture style (MVC, hexagonal, microservices), framework conventions, data flow
4. **Extract API surface**: Routes, handlers, request/response types, status codes
5. **Find configuration**: Environment variables, feature flags, build config
6. **Read existing docs**: Don't duplicate — extend, update, or replace outdated content

### Phase 2: Documentation Architecture

Use progressive disclosure — readers should get value at every depth level:

1. **Bird's-eye view**: System purpose, key components, how they connect (1 page)
2. **Component overview**: Each component's responsibility, interfaces, dependencies (1 page each)
3. **Implementation details**: Internal patterns, data models, algorithms, trade-offs (as deep as needed)

### Phase 3: Generate Documentation

Spawn the **docs-architect agent** with the scope and codebase analysis. The agent produces documentation following this structure (sections scaled to scope):

#### Full Documentation Structure

```
1. Overview
   - Purpose and problem solved
   - Key concepts and terminology
   - System context diagram

2. Architecture
   - High-level component diagram
   - Data flow (request lifecycle, event flow)
   - Key design decisions and rationale
   - Technology choices and why

3. Components
   - For each component:
     - Responsibility (single sentence)
     - Public interface (functions, types, events)
     - Dependencies (what it uses)
     - Dependents (what uses it)
     - Configuration
     - Error handling approach

4. API Reference (if applicable)
   - Endpoints grouped by resource
   - Request/response schemas
   - Authentication requirements
   - Error responses
   - Examples

5. Data Model
   - Entity relationships
   - Schema definitions
   - Migration history (key changes)
   - Data flow between components

6. Development Guide
   - Setup instructions (verified by running them)
   - Build and test commands
   - Common development tasks
   - Debugging tips
   - Contributing workflow

7. Deployment
   - Environment configuration
   - Infrastructure requirements
   - Deployment process
   - Monitoring and health checks
```

### Phase 4: Verification

- **Cross-reference code**: Every documented path, function, and type must exist in the codebase
- **Run documented commands**: Setup instructions, build commands, test commands must work
- **Check completeness**: No undocumented public APIs, no missing components

## Output

Write documentation to the `docs_dir` path from `project_structure` config (default: `docs/`). Use descriptive filenames matching the scope.

## Rules

- Reference specific files and line numbers — not abstract descriptions
- Include code examples from the actual codebase, not invented ones
- Document behavior, not implementation details that change frequently
- Keep language clear and direct — no marketing copy, no filler
- If something is unclear or undocumented in the code, note it as "undocumented" rather than guessing
