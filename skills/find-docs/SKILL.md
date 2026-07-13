---
name: find-docs
description: >-
  Retrieves authoritative, up-to-date technical documentation, API references,
  configuration details, and code examples for any developer technology.

  Use this skill whenever answering technical questions or writing code that
  interacts with external technologies. This includes libraries, frameworks,
  programming languages, SDKs, APIs, CLI tools, cloud services, infrastructure
  tools, and developer platforms.

  Common scenarios:
  - looking up API endpoints, classes, functions, or method parameters
  - checking configuration options or CLI commands
  - answering "how do I" technical questions
  - generating code that uses a specific library or service
  - debugging issues related to frameworks, SDKs, or APIs
  - retrieving setup instructions, examples, or migration guides
  - verifying version-specific behavior or breaking changes

  Prefer this skill whenever documentation accuracy matters or when model
  knowledge may be outdated.
user-invocable: false
disable-model-invocation: true
---

# Documentation Lookup

Fetch current library docs and code examples via the Context7 CLI — at plan or
implementation time, whenever doc accuracy matters or model knowledge may be stale.

Two steps: resolve the name to a `/org/project` ID, then fetch docs. Always pass a
specific query (the user's full question, not a single word) — it drives result ranking.
Never put secrets (API keys, credentials) in a query.

```bash
# 1. Resolve the library ID (skip only if the user gave an explicit /org/project[/version] ID)
npx -y ctx7 library react "How to clean up useEffect with async operations"

# 2. Fetch docs with that ID
npx -y ctx7 docs /facebook/react "How to clean up useEffect with async operations"

# version-specific ID (versions are listed in the library output):
npx -y ctx7 docs /vercel/next.js/v14.3.0-canary.87 "How to set up app router"
```

Pick the best match from step 1 by name/description relevance, code-snippet count, and
source reputation. Max 3 attempts per question, then use the best result you have.

Critical gotchas: library IDs need the `/` prefix (`/facebook/react`, not `facebook/react`);
`docs` needs a real ID from step 1 (`docs react "hooks"` fails).

**Rate limits:** works unauthenticated; for higher limits set `CONTEXT7_API_KEY` (or
`npx -y ctx7 login`). On a quota error, tell the user why Context7 was skipped, suggest
authenticating, and if they decline, answer from training knowledge noting it may be
outdated — never fall back silently.
