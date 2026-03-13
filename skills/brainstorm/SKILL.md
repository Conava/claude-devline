---
name: brainstorm
description: This skill should be used when the user asks to "brainstorm", "refine an idea", "flesh out a feature", "define requirements", or when the devline pipeline starts with a rough idea via "/devline" or "/devline:brainstorm". Guides interactive refinement of rough ideas into concise, actionable feature specifications.
user-invocable: true
disable-model-invocation: false
---

# Brainstorming

Guide the user from a rough idea to a clear feature understanding through quick, structured interaction. This is lightweight — no documents, no files. Everything stays in the conversation context for the planner to pick up.

## Process

### 1. Understand the Idea

Read the user's input. Briefly scan the existing codebase for context:
- What tech stack is in use?
- What patterns exist?
- Is there relevant existing code to build on?

### 2. Clarify with Structured Questions

Use the **AskUserQuestion** tool with concrete selectable options — never ask open-ended text questions. The user should be able to pick answers with arrow keys, select multiple where applicable, or type a custom response via "Other".

**Rules:**
- Ask **1-4 questions in a single AskUserQuestion call** — never a second round
- **Scale questions to ambiguity:** A clear, specific idea (e.g., "add webhooks to my Express API") needs only 1-2 questions on the genuinely open decisions. A vague idea (e.g., "I need some kind of notification system") warrants 3-4. Don't ask about things that have obvious answers or industry-standard defaults — just state your assumption in the summary.
- Every question MUST have **2-4 concrete options** with labels and descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive (e.g., "which platforms?")
- Use `multiSelect: false` for single-choice decisions (e.g., "what visual tone?")
- If the idea is already clear enough, skip questions entirely
- Add a recommended option first with "(Recommended)" in the label when there's a clear best choice
- **Always ask about platform** when the feature involves a UI (web, mobile, desktop, etc.) — never assume

**Example question patterns:**

For scope decisions:
```json
{
  "question": "Which platforms should this support?",
  "header": "Platforms",
  "options": [
    {"label": "Web only", "description": "Browser-based SPA or SSR app"},
    {"label": "Web + Mobile", "description": "Web app with iOS/Android companion"},
    {"label": "Desktop", "description": "Native desktop application"},
    {"label": "All platforms", "description": "Web, mobile, and desktop"}
  ],
  "multiSelect": false
}
```

For UI-related features:
```json
{
  "question": "What visual tone fits this feature?",
  "header": "Aesthetic",
  "options": [
    {"label": "Clean & minimal", "description": "Spacious, understated, refined typography"},
    {"label": "Bold & vibrant", "description": "Strong colors, large type, energetic feel"},
    {"label": "Match existing UI", "description": "Follow the current design system and patterns"},
    {"label": "Dark & technical", "description": "Data-dense, monospace accents, utilitarian"}
  ],
  "multiSelect": false
}
```

For technical decisions:
```json
{
  "question": "What authentication method should we use?",
  "header": "Auth method",
  "options": [
    {"label": "JWT (Recommended)", "description": "Stateless tokens, good for APIs and SPAs"},
    {"label": "Session-based", "description": "Server-side sessions, simpler for traditional apps"},
    {"label": "OAuth/SSO", "description": "Third-party login (Google, GitHub, etc.)"}
  ],
  "multiSelect": false
}
```

For feature selection:
```json
{
  "question": "Which capabilities should this include?",
  "header": "Features",
  "options": [
    {"label": "Real-time updates", "description": "WebSocket/SSE for live data"},
    {"label": "Offline support", "description": "Works without internet, syncs later"},
    {"label": "Export/import", "description": "CSV, JSON, or PDF export"},
    {"label": "Search & filter", "description": "Full-text search with filters"}
  ],
  "multiSelect": true
}
```

### 3. Summarize Understanding

After receiving answers, write a brief **in-conversation summary** (NOT a file) that captures:
- What we're building (1-2 sentences)
- Key decisions made (bullet points from the answers)
- Scope boundaries (in/out)
- Aesthetic direction (if UI is involved)
- Any assumptions made

This summary is just regular text output in the conversation — **do NOT write any files, documents, or specs.** The planner agent will read the full conversation context including the user's original idea, the questions, the answers, and this summary.

### 4. Confirm

Use AskUserQuestion to check:

```json
{
  "question": "Does this capture what you want? The planner will use this to design the implementation.",
  "header": "Confirm",
  "options": [
    {"label": "Looks good, proceed!", "description": "Hand off to the planner"},
    {"label": "Needs changes", "description": "I want to adjust something"}
  ],
  "multiSelect": false
}
```

If the user wants changes, adjust the summary and confirm again.

## Rules

- **Do NOT write any files** — no spec documents, no markdown files, nothing. Everything stays in conversation context.
- Be conversational and fast — the user wants momentum, not process
- ALWAYS use AskUserQuestion with structured options — never plain text questions
- Default to sensible assumptions and state them briefly
- The planner will have full access to this conversation, so just make sure the decisions are clear in the text
