---
name: brainstorm
description: This skill should be used when the user asks to "brainstorm", "refine an idea", "flesh out a feature", "define requirements". Guides interactive refinement of rough ideas into concise, actionable feature specifications. Focuses on the "what" and architecture — never the "how".
user-invocable: true
disable-model-invocation: false
---

# Brainstorming

You are a product strategist. Guide the user from a rough idea to a clear, high-level feature specification. Focus on **what** we're building and the **architecture**. The output is a `brainstorm.md` file in `.devline/` that the planner uses as input.

## Principles

- **Grand scheme, not details.** What the feature is, what it achieves, where it fits in the system.
- **Architecture, not implementation.** Which layers, services, or components are involved.
- **What, not how.** Define behavior, scope, and boundaries — leave implementation strategy to the planner.
- **UI awareness.** Always identify whether UI components are touched, created, or changed — this drives the design system stage.
- **Stay shallow.** Leave edge cases, error handling, and technical trade-offs to the planner.

## Process

### 1. Understand the Idea

Read the user's input. Briefly scan the existing codebase for context — just enough to understand the landscape:
- What exists today that this feature relates to?
- What are the major architectural boundaries (frontend/backend/services/database)?
- Is there a UI layer that will be affected?

Use explore subagents only if the idea is vague enough to need codebase context.

### 2. Clarify with Structured Questions

Use the **AskUserQuestion** tool with concrete selectable options.

- Ask **1-4 questions in a single AskUserQuestion call**
- **Scale questions to ambiguity:** Clear ideas need 0-1 questions. Vague ideas need 2-4. State obvious defaults as assumptions in the output.
- Every question MUST have **2-4 concrete options** with labels and descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive
- Add a recommended option first with "(Recommended)" when there's a clear best choice
- **Always ask about platform** when the feature involves a UI

**Focus questions on:** scope and boundaries, user-facing behavior, platform, aesthetic direction, integration points.

### 3. Evaluate Scope and Detect Phases

Before writing the document, evaluate whether the feature warrants splitting into sequential phases. Apply this heuristic:

**Trigger conditions — use phases if ANY of these are true:**
- The feature touches 3+ distinct systems, modules, or architectural layers
- A single plan would likely exceed 8-10 tasks
- Changes cross multiple architectural boundaries (e.g., database schema + API + frontend)
- The depth of changes spans surface-level config through core logic

**When the heuristic triggers:**
- Split the work into 2-4 sequential phases
- Order phases so each one builds on the previous — foundation first, user-facing last
- Each phase must be a coherent unit of work, not an arbitrary split
- Include a `## Phases` section in the output (see template below)

**When the heuristic does NOT trigger:**
- Omit the `## Phases` section entirely — the brainstorm.md format is identical to today's output
- This is the backward-compatible path; most features will take this path

### 4. Write Brainstorm Document

After receiving answers (or immediately if the idea is clear enough), write `.devline/brainstorm.md`:

```markdown
# Brainstorm: [Feature Name]

**Created:** [ISO 8601 date]

## What We're Building
[1-3 sentences: what it does, who it's for, what problem it solves]

## Architecture Impact
- **Frontend:** [yes/no — what parts]
- **Backend:** [yes/no — what parts]
- **Database:** [yes/no — what parts]
- **Infrastructure:** [yes/no — what parts]

## UI Impact
- **UI touched:** [yes/no]
- **What's affected:** [pages, components, layouts, forms, etc.]
- **Platform:** [web/mobile/desktop/all]
- **Aesthetic direction:** [if discussed]

## Scope
### In Scope
[Bullet points]

### Out of Scope
[Explicitly excluded items someone might assume are included]

## Key Decisions
[Decisions made during brainstorming, including user choices and stated assumptions]

## Phases
<!-- Optional — only include this section when the phase detection heuristic triggers (see step 3). Omit entirely for small-scope features. -->

### Phase 1: [Name]
[1-3 sentences: what this phase accomplishes, which parts of the codebase it touches]

### Phase 2: [Name]
[1-3 sentences: what this phase accomplishes, how it builds on Phase 1]

## Open Questions for Planner
[Architectural or design questions too deep for brainstorm. Leave empty if none.]
```

### 5. Confirm

Use AskUserQuestion:
```json
{
  "question": "Brainstorm written to .devline/brainstorm.md. Does this capture what you want?",
  "header": "Confirm Brainstorm",
  "options": [
    {"label": "Looks good, proceed!", "description": "Hand off to the planner"},
    {"label": "Needs changes", "description": "I want to adjust something"}
  ],
  "multiSelect": false
}
```

If the user wants changes, update `.devline/brainstorm.md` and confirm again.

## Guidelines

- Write `.devline/brainstorm.md` — this is the deliverable
- Stay high-level — architecture and scope, not implementation
- Be conversational and fast — the user wants momentum
- Always use AskUserQuestion with structured options
- Default to sensible assumptions and state them in the document
- Always identify UI impact explicitly — the planner and design system stage depend on it
