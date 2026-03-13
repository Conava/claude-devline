---
name: dl-documentation
description: Domain logic for documentation — injected into the docs-keeper agent. Provides guidance on creating and maintaining separate documentation files (README, API docs, guides). Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Documentation

Guidance for creating and maintaining separate documentation files. This skill covers README files, API documentation, architecture docs, and user guides. Inline code documentation (JSDoc, docstrings, etc.) is handled by the implementer during coding — do not duplicate what's already in the code.

## Pipeline Context

When running as part of the devline pipeline, the docs-keeper agent receives this skill after implementation and review are complete. Key context to leverage:

- **Read the implementation plan** to understand what was built and why
- **Read the implementer's output** to see which files were created/modified — the implementer already added inline docs
- **Check git diff** to see exactly what changed — documentation should reflect the delta, not re-describe existing unchanged features
- **Focus on user-facing documentation** — architecture decisions and API contracts that aren't obvious from the code itself

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

### Style

- Write in present tense, active voice
- Use second person for instructions ("Run the command", not "The command should be run")
- Keep sentences short and direct
- Use code blocks for commands, file paths, and code snippets
- Use tables for structured reference data

### Structure

- Start with the most important information
- Use headings hierarchically (h1 → h2 → h3)
- Keep sections focused — one topic per section
- Include a table of contents for docs longer than 3 screens

### Code Examples

- Every API endpoint needs a working request/response example
- Code examples must be copy-pasteable and runnable
- Include language identifiers in fenced code blocks
- Show common use cases, not edge cases

## Keeping Docs in Sync

When updating documentation after code changes:

1. Identify what changed (new endpoints, modified parameters, removed features)
2. Find all documentation that references the changed code
3. Update each reference to match the new behavior
4. Verify code examples still work
5. Update version numbers and changelogs if applicable

## Additional Resources

### Reference Files

For format-specific patterns:

- **`references/doc-templates.md`** — Templates for README, API docs, architecture docs
- **`references/doc-tools.md`** — Documentation generators and their configuration
