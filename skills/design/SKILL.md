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

Analyze the user's request and route to the correct mode:

| Mode | Trigger | Example |
|------|---------|---------|
| **Brand** | Create/extend persistent brand identity | "create a brand identity", "set up a design system", "add a table to the brand" |
| **Harmonize** | Fit within project's existing theme | "make this match our site", "design a card for our current theme", "fit within our colors" |
| **Component** | Single design piece, standalone | "design a button", "create a dark color theme", "warm earth tone palette" |
| **Showcase** | Multiple variations requested | "show me 8 button styles", "create 6 different card designs" |
| **Extend** | `.devline/design-system.md` exists + new element | "add a table to the design system", "design a modal that fits our system" |
| **Full System** | Full design system for pipeline | "create a design system for a fintech app" |

**Priority order when ambiguous:**
1. If `design-system/BRAND.md` exists and request is for a new component → **Brand** (extend)
2. If request mentions "match", "fit", "our site", "current theme" → **Harmonize**
3. If request mentions "brand", "identity", "persistent" → **Brand** (create)
4. If request has a number ("8 buttons", "6 cards") → **Showcase**
5. If `.devline/design-system.md` exists → **Extend**
6. Default → **Component**

## Execution

### For Brand mode (create):
Launch the **frontend-planner** agent with:
```
Mode: Brand

Brand request: [user's request]
Product context: [any product/mood/industry context]
Platform: [if mentioned]

Create the brand identity system at design-system/BRAND.md with initial component specs.
```

### For Brand mode (extend):
First verify `design-system/BRAND.md` exists. Then launch the **frontend-planner** agent with:
```
Mode: Brand (extend)

Existing brand: design-system/BRAND.md
New element: [what to add]
Context: [any constraints]

Read the existing brand first, then add the new component spec.
```

### For Harmonize mode:
Launch the **frontend-planner** agent with:
```
Mode: Harmonize

Design request: [what to design]
Project: [current working directory]

Read the project's actual theme files (tailwind config, CSS variables, theme.ts, etc.) and design [component] to fit within the existing visual identity. Output to .devline/component-spec.md.
```

### For Component mode:
Launch the **frontend-planner** agent with:
```
Mode: Component

Design request: [user's request]
Context: [any product/mood/constraint context from the user]

Output the component spec to .devline/component-spec.md and preview to .devline/component-preview.html.
```

### For Showcase mode:
Launch the **frontend-planner** agent with:
```
Mode: Showcase

Component: [what to showcase]
Count: [N from user's request, default 8]
Constraints: [any constraints mentioned]

Output showcases to .devline/showcases/
```

### For Extend mode:
First verify `.devline/design-system.md` exists. Then launch the **frontend-planner** agent with:
```
Mode: Extend

Existing design system: .devline/design-system.md
New element: [what to add]
Context: [any constraints]

Read the existing design system first, then output the extension.
```

### For Full System mode:
Launch the **frontend-planner** agent with:
```
Mode: Pipeline

Product context: [user's description]
Platform: [if mentioned, otherwise ask]

Note: No brainstorm file exists. Use the user's description directly as the product context for design intelligence searches. Skip brainstorm.md reading — use the prompt as your input. Write the full design system to .devline/design-system.md.
```

## After Agent Completes

Report the result to the user:
- For **Brand (create)**: "Brand identity at `design-system/BRAND.md` with N component specs. To add more: `/design add [component] to the brand`"
- For **Brand (extend)**: "Added `design-system/components/[name].md`, BRAND.md index updated"
- For **Harmonize**: "Component spec at `.devline/component-spec.md`, designed to fit your project's existing theme"
- For **Component**: "Component spec at `.devline/component-spec.md`, preview at `.devline/component-preview.html`"
- For **Showcase**: "N showcases at `.devline/showcases/`, open `index.html` for the gallery"
- For **Extend**: "Extension added to `.devline/design-system.md`, preview at `.devline/extend-preview.html`"
- For **Full System**: "Design system at `.devline/design-system.md`"

## Rules

- Do NOT run the full devline pipeline (no brainstorm, no plan, no implementation)
- Do NOT ask unnecessary questions — if the user says "design a dark button", just design it
- Do launch the frontend-planner agent — do not design anything yourself
- If the user's request is ambiguous about mode, follow the priority order above
- Brand mode outputs are PERSISTENT (in `design-system/`) — they survive pipeline cleanup
- All other mode outputs are in `.devline/` and are temporary
