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

### Phase 0: Audit Existing Structure

Before generating anything, assess what already exists and whether it matches the tier model.

**Tier model:**
- Tier 1 (always current): `CLAUDE.md`, `README.md`, `docs/architecture.md`
- Tier 2 (updated on change): ADRs in `docs/decisions/`, API spec, runbooks, `docs/deferred-findings.md`
- Tier 3 (generated on demand): component deep-dives, onboarding guides, full API reference

**Audit steps:**

1. List all files in `docs/` and the project root (`README.md`, `CLAUDE.md`, `CHANGELOG.md`)
2. For each Tier 1 path (from `project_structure` config), check if it exists
3. Identify structural problems:
   - Tier 1 files missing entirely
   - Content in the wrong file (e.g., architecture content buried in README, CLAUDE.md written as narrative prose)
   - Duplicate content across multiple files
   - Stale content referencing removed code

**Decision point — ask the user before proceeding:**

If significant structural problems exist (more than one Tier 1 file missing, or content is clearly misplaced across multiple files), present the findings and ask:

> "The existing docs have structural issues:\n> - [list findings]\n>\n> I can:\n> A) Generate/update docs within the current structure\n> B) Restructure the docs to fix these issues, then generate\n> C) Both: restructure first, then generate\n>\n> Which would you prefer?"

Wait for the user's answer before proceeding. If the user says B or C, pass `restructure: true` to the docs-architect agent. If the user says A, or if there are no significant structural problems, proceed directly to Phase 1.

**Skip the question if:** The user explicitly said "don't restructure", "keep the current structure", or "just generate". In that case, pass `restructure: false`.

---

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

### Phase 3: Generate (and optionally Restructure)

Spawn the **docs-architect agent** with:
- The scope requested
- The codebase analysis from Phase 1
- `restructure: true` or `restructure: false` based on the Phase 0 decision
- Paths to all existing documentation files

The agent produces documentation following this structure (sections scaled to scope):

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
- **Check tier placement**: Content is in the right file for its tier

## Output

Write documentation to the `docs_dir` path from `project_structure` config (default: `docs/`). Use descriptive filenames matching the scope.

## Rules

- Reference specific files and line numbers — not abstract descriptions
- Include code examples from the actual codebase, not invented ones
- Document behavior, not implementation details that change frequently
- Keep language clear and direct — no marketing copy, no filler
- If something is unclear or undocumented in the code, note it as "undocumented" rather than guessing
- CLAUDE.md: dense and structured (bullets/tables). README: human-readable narrative. Don't conflate them.
