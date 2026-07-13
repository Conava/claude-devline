---
name: design
description: Standalone design skill for individual components, color themes, brand identity, or fitting within an existing project theme. Use when the user asks to "design a button", "create a color theme", "create a brand identity", "make this match our site", "show me 6 card styles", "add a modal to the brand", or any targeted UI design request. Also triggers on mood-based requests like "warm dark theme", "cool minimalist colors", "playful typography".
argument-hint: "<what to design>"
user-invocable: true
disable-model-invocation: false
---

# Design — Standalone UI Design

Launch the **frontend-planner** agent for targeted design work outside the full devline pipeline.

## What You Do

Parse the user's request, detect the right mode, and launch the frontend-planner agent with a clear prompt. You are a router, not a designer.

## Mode Detection

The frontend-planner has three modes. Route the request to one — and for `design-one`, also pick the token source:

| Mode | Trigger | Example |
|------|---------|---------|
| **brand-init** | First-time persistent brand identity (no `design-system/BRAND.md` yet) | "create a brand identity", "set up our brand" |
| **generate** | Multiple directions at once — a full design system, or N showcase variations | "create a design system for a fintech app", "show me 8 button styles" |
| **design-one** | A single element from one token source (see below) | "design a button", "add a modal to the brand", "match our site" |

**design-one — pick the token source:**

| Token source | Trigger |
|--------------|---------|
| **brand** | `design-system/BRAND.md` exists + adding an element ("add a table to the brand") |
| **project-theme** | Fit the project's existing theme ("match our site", "our current colors") |
| **design-system** | `.devline/design-system.md` exists + new element ("add a modal that fits our system") |
| **scratch** | Standalone piece, no existing system ("design a dark button", "warm earth palette") |

**Priority order when ambiguous:**
1. `design-system/BRAND.md` exists and the request adds a component → **design-one** (brand)
2. "match", "fit", "our site", "current theme" → **design-one** (project-theme)
3. "brand", "identity", "persistent" and no `BRAND.md` → **brand-init**
4. A count ("8 buttons", "6 cards") → **generate** (showcase)
5. "design system for [product]" → **generate** (pipeline)
6. `.devline/design-system.md` exists → **design-one** (design-system)
7. Default → **design-one** (scratch)

## Execution

Launch the **frontend-planner** agent with the mode — and for design-one, the token source.

### brand-init:
```
Mode: brand-init

Brand request: [user's request]
Product context: [any product/mood/industry context]
Platform: [if mentioned]

Create the brand identity system at design-system/BRAND.md with initial component specs.
```

### generate (pipeline — full design system):
```
Mode: generate
Variant: pipeline

Product context: [user's description]
Platform: [if mentioned, otherwise ask]

No brainstorm file exists — use this description directly as the product context. Write the full design system to .devline/design-system.md.
```

### generate (showcase — N variations):
```
Mode: generate
Variant: showcase

Component: [what to showcase]
Count: [N from request, default 8]
Constraints: [any constraints mentioned]

Output showcases to .devline/showcases/
```

### design-one:
If the token source is `brand` or `design-system`, first verify `design-system/BRAND.md` / `.devline/design-system.md` exists. Then launch:
```
Mode: design-one
Token source: [scratch | project-theme | design-system | brand]

Design request: [user's request]
Context: [product/mood/constraints — or the existing brand/system/theme to read tokens from]

Read the token source first (if any), then output the spec to .devline/component-spec.md and preview to .devline/component-preview.html. For the brand source, add the component under design-system/ and update BRAND.md.
```

## After Agent Completes

Report the result to the user:
- **brand-init**: "Brand identity at `design-system/BRAND.md` with N component specs. Add more: `/design add [component] to the brand`"
- **generate (pipeline)**: "Design system at `.devline/design-system.md`"
- **generate (showcase)**: "N showcases at `.devline/showcases/`, open `index.html` for the gallery"
- **design-one**: "Component spec at `.devline/component-spec.md`, preview at `.devline/component-preview.html`" (brand source: component added under `design-system/`, BRAND.md updated)

## Rules

- Do NOT run the full devline pipeline (no brainstorm, no plan, no implementation)
- Do NOT ask unnecessary questions — if the user says "design a dark button", just design it
- Do launch the frontend-planner agent — do not design anything yourself
- If the user's request is ambiguous about mode, follow the priority order above
- `brand-init` and `design-one` (brand source) outputs are PERSISTENT (in `design-system/`) — they survive pipeline cleanup
- All other mode outputs are in `.devline/` and are temporary

## Live Design System (`docs/design-system/`)

Beyond the mode outputs above, the frontend-planner maintains one durable, corrections-aware design system per repo at `docs/design-system/` (`MASTER.md` + `pages/<page>.md`). It survives across sessions. The agent:
- **Reads it first** — before designing, it checks `docs/design-system/MASTER.md` (and `pages/<page>.md` for the current page, which overrides MASTER) and works within it, including the `## Corrections & Decisions` log, so past mistakes aren't repeated.
- **Persists on generate** — establishing or changing the shared system writes/regenerates `docs/design-system/` (via `search.py --design-system --persist --output-dir docs`).
- **Persists on correction** — when you correct a design or a choice fails, it appends a dated bullet to `## Corrections & Decisions` (MASTER for global, the page file for page-specific) and updates the affected spec. Nothing is lost between sessions.
