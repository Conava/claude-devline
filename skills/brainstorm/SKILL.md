---
name: brainstorm
description: This skill should be used when the user asks to "brainstorm", "refine an idea", "flesh out a feature", "define requirements". Guides interactive refinement of rough ideas into concise, actionable feature specifications. Focuses on the "what" and architecture — never the "how".
user-invocable: true
disable-model-invocation: false
---

# Brainstorming

Guide the user from a rough idea to a clear, high-level feature specification. Focus on **what** we're building and the **architecture** — never on implementation details or the "how." The output is a `brainstorm.md` file in `.devline/` that the planner uses as input.

## Principles

- **Grand scheme, not details.** Think about what the feature is, what it achieves, and where it fits in the system — not how to code it.
- **Architecture, not implementation.** Identify which layers, services, or components are involved — not which functions to call or patterns to use.
- **What, not how.** Define behavior, scope, and boundaries — leave implementation strategy to the planner.
- **UI awareness.** Always identify whether UI components are touched, created, or changed — this drives the design system stage.
- **Stay shallow.** Don't rabbit-hole into edge cases, error handling strategies, or technical trade-offs. Those are the planner's job.

## Process

### 1. Understand the Idea

Read the user's input. Briefly scan the existing codebase for context — just enough to understand the landscape:
- What exists today that this feature relates to?
- What are the major architectural boundaries (frontend/backend/services/database)?
- Is there a UI layer that will be affected?

Use explore subagents only if the idea is vague enough to need codebase context. Keep exploration focused on the "what exists" — not deep code analysis.

### 2. Clarify with Structured Questions

Use the **AskUserQuestion** tool with concrete selectable options — never ask open-ended text questions. The user should be able to pick answers with arrow keys, select multiple where applicable, or type a custom response via "Other".

**Rules:**
- Ask **1-4 questions in a single AskUserQuestion call** — never a second round
- **Scale questions to ambiguity:** A clear idea needs 0-1 questions. A vague idea needs 2-4. Don't ask about things with obvious defaults — state assumptions in the output.
- Every question MUST have **2-4 concrete options** with labels and descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive
- Use `multiSelect: false` for single-choice decisions
- Add a recommended option first with "(Recommended)" in the label when there's a clear best choice
- **Always ask about platform** when the feature involves a UI — never assume

**Focus questions on:**
- Scope and boundaries (what's in, what's out)
- User-facing behavior (what should the user experience)
- Platform (web, mobile, desktop) — when UI is involved
- Aesthetic direction — when UI is involved
- Integration points (what existing systems does this touch)

**Do NOT ask about:**
- Technical implementation details (libraries, patterns, algorithms)
- Error handling strategies
- Testing approaches
- Performance optimization approaches
- Database schema design

### 3. Write Brainstorm Document

After receiving answers (or immediately if the idea is clear enough), write `.devline/brainstorm.md` with this structure:

```markdown
# Brainstorm: [Feature Name]

**Created:** [ISO 8601 date]

## What We're Building
[1-3 sentences describing the feature at a high level — what it does, who it's for, what problem it solves]

## Architecture Impact
[Which layers/services/components are involved. Keep it to bullet points identifying areas, not implementation plans]

- **Frontend:** [yes/no — and what parts: new pages, modified components, new UI flows]
- **Backend:** [yes/no — and what parts: new endpoints, modified services, new data models]
- **Database:** [yes/no — new tables, schema changes, migrations]
- **Infrastructure:** [yes/no — new services, config changes, CI/CD updates]

## UI Impact
[Explicitly state whether UI components are touched, created, or changed. This section drives the design system stage.]

- **UI touched:** [yes/no]
- **What's affected:** [list of UI areas: pages, components, layouts, navigation, forms, etc.]
- **Platform:** [web/mobile/desktop/all — only if UI is involved]
- **Aesthetic direction:** [if discussed — e.g., "match existing", "clean & minimal", "bold & vibrant"]

## Scope
### In Scope
[Bullet points of what the feature includes]

### Out of Scope
[Bullet points of what's explicitly excluded — things someone might assume are included but aren't]

## Key Decisions
[Bullet points of decisions made during brainstorming, including user choices and stated assumptions]

## Open Questions for Planner
[Any architectural or design questions that are too deep for brainstorm but the planner should address. Leave empty if none.]
```

### 4. Confirm

Use AskUserQuestion to check:

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

## Rules

- **Write `.devline/brainstorm.md`** — this is the brainstorm output, read by the planner
- Stay high-level — architecture and scope, not implementation
- Be conversational and fast — the user wants momentum, not process
- ALWAYS use AskUserQuestion with structured options — never plain text questions
- Default to sensible assumptions and state them in the document
- Always identify UI impact explicitly — the planner and design system stage depend on it
