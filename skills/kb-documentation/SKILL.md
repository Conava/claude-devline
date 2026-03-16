---
name: kb-documentation
description: Domain logic for documentation — injected into the docs-keeper agent. Provides guidance on creating and maintaining separate documentation files (README, API docs, guides). Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Documentation

Guidance for creating and maintaining separate documentation files. This skill covers README files, API documentation, architecture docs, and user guides. Inline code documentation (JSDoc, docstrings, etc.) is handled by the implementer during coding — do not duplicate what's already in the code.

## Pipeline Context

In the devline pipeline, read the plan and git diff to understand what changed. Focus on the delta — don't re-describe unchanged features. Inline docs were handled by implementers.

## Documentation Types

### README

Every project needs a README covering:
- Project name and one-line description
- Prerequisites and setup instructions
- Quick start / getting started
- Available commands (build, test, run)
- Project structure overview
- Contributing guidelines (if open source)

### API Documentation

For projects exposing APIs:
- Endpoint list with methods and paths
- Request/response schemas with examples
- Authentication requirements
- Error codes and handling
- Rate limits and pagination

### Architecture Documentation

For complex projects:
- System overview and component diagram
- Data flow between components
- Key design decisions and rationale
- Technology stack and justification
- Deployment architecture

### User Guides

For end-user-facing projects:
- Getting started tutorial
- Feature walkthroughs
- FAQ and troubleshooting
- Configuration reference

## Documentation Detection

Before writing documentation, check what already exists:

1. Look for `docs/` directory, `README.md`, `CHANGELOG.md`
2. Check for doc generators (`typedoc.json`, `mkdocs.yml`, `docusaurus.config.js`, `.readthedocs.yml`, `javadoc`)
3. Match existing format, style, and structure
4. Check `.claude/devline.local.md` for `doc_format` override

## Writing Standards

- Present tense, active voice, second person ("Run the command")
- Start with the most important information; use hierarchical headings
- Code examples must be copy-pasteable, runnable, with language identifiers
- Use tables for structured reference data

## Keeping Docs in Sync

Identify what changed, find all docs referencing changed code, update to match, verify examples still work.

## Additional Resources

### Reference Files

For format-specific patterns:

- **`references/doc-templates.md`** — Templates for README, API docs, architecture docs
- **`references/doc-tools.md`** — Documentation generators and their configuration
