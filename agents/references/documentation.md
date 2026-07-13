# Documentation Reference

On-demand guidance for the docs-keeper: separate documentation files (README, API docs, architecture, guides). Inline code docs (JSDoc, docstrings) are the implementer's job — don't duplicate them.

## Documentation Detection

Before writing, check what exists: `docs/`, `README.md`, `CHANGELOG.md`; doc generators (`typedoc.json`, `mkdocs.yml`, `docusaurus.config.js`, `.readthedocs.yml`, javadoc); `.claude/devline.local.md` `doc_format` override. Match the existing format, style, and structure.

## Writing Standards

Present tense, active voice, second person ("Run the command"). Lead with the most important info; hierarchical headings. Code examples must be copy-pasteable, runnable, with language identifiers. Tables for structured reference data. Update what exists — only create new files when a genuinely new topic has no home.

## Documentation Types

**README** — name + one-line description; prerequisites/setup; quick start; commands (build/test/run); project structure; contributing (if OSS).
**API** — endpoint list (methods+paths); request/response schemas with examples; auth; error codes; rate limits/pagination.
**Architecture** — system overview + component diagram; data flow; key design decisions + rationale; tech stack; deployment.
**User guides** — getting-started tutorial; feature walkthroughs; FAQ/troubleshooting; config reference.

## Templates

### README
```markdown
# Project Name
One-line description.

## Prerequisites
- [Requirement] (version X.Y+)

## Quick Start
​```bash
git clone <repo-url> && cd project-name
[install command]
[run command]
​```

## Usage
### [Feature]
[Description and examples]

## Development
### Setup / Testing / Building
​```bash
[commands]
​```

## Project Structure
​```
src/
├── [dir]/    # [Purpose]
└── [file]    # [Purpose]
​```

## Contributing / License
```

### API Reference
```markdown
# API Reference

## Authentication
[How to authenticate]

## Endpoints
### Create [Resource]  —  `POST /api/resource`
**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Resource name |

**Response:** `201 Created`
​```json
{ "id": "abc123", "name": "Example" }
​```

**Errors:** | Code | Description | — 400 Invalid input, 401 Unauthorized

### List [Resources]  —  `GET /api/resources?page=1&limit=20`
**Query Parameters:** | Parameter | Type | Default | Description | — page (int, 1), limit (int, 20)
```

### Architecture
```markdown
# Architecture Overview

## System Diagram
[Description or ASCII diagram]

## Components
### [Component]
- **Purpose / Technology / Key files:** ...

## Data Flow
1. [User action] → 2. [Processing] → 3. [Response]

## Design Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Database | PostgreSQL | ACID needed for financial data |

## Deployment
[How/where deployed]
```

### Changelog (Keep a Changelog style)
```markdown
# Changelog
## [Unreleased]
### Added / Changed / Fixed / Removed
- ...
## [1.0.0] - 2024-01-15
### Added
- Initial release
```

### ADR
Follow the project's existing ADR format. If none: **Status, Date, Context, Decision, Rationale, Consequences**.

## Documentation Tools

**Static site generators:** MkDocs (`mkdocs.yml`, Material theme, `mkdocs serve`); Docusaurus (`docusaurus.config.js`, versioning/i18n/search, MDX); VitePress (`.vitepress/config.js`, Vue-powered, fast HMR).

**API docs:** OpenAPI/Swagger (`openapi.yaml`; Swagger UI, Redoc, Stoplight; generate client SDKs); TypeDoc (`typedoc.json`, from TSDoc); Javadoc (`@param`/`@return`/`@throws`); Godoc (first sentence = summary); Rustdoc (`cargo doc`, runs doc tests).

**Inline doc formats** (implementer's responsibility — for reference): JSDoc (`@param {type} name - desc`, `@returns`, `@throws`); Python docstrings (Args/Returns/Raises); KDoc (`@param name`, `@return`, `@throws`).
