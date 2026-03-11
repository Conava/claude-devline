---
name: brainstorm
description: "Use when the user explicitly asks to 'brainstorm', 'explore ideas', 'discuss approaches', 'design discussion', or 'think through' a problem without wanting the full pipeline."
argument-hint: "[topic or problem]"
user-invocable: true
---

# Brainstorming Ideas Into Designs

Turn ideas into directional design guidance through natural collaborative dialogue. The output is a short design doc that guides the planner — not an implementation spec.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Process

### 1. Explore project context

Before asking anything, understand what exists:
- Read the project README and CLAUDE.md for conventions and structure
- Check `project_structure` config paths — read the architecture doc, API spec, existing ADRs if they exist
- Use Glob and Grep to find relevant files. Read entry points and modules related to the task.
- Stop when you have enough to ask good questions.

Reference specific files and patterns you find. Do not speak in abstractions when concrete code exists.

### 2. Ask clarifying questions

Ask questions **one at a time** to refine the idea:
- Prefer multiple choice when the options are knowable
- Open-ended when the answer space is too broad to enumerate
- Focus on understanding: **purpose**, **constraints**, **success criteria**
- If a topic needs more exploration, break it into multiple questions across rounds

### 3. Propose 2-3 approaches

When you have enough context:
- Lead with your recommended approach and explain why
- For each approach: one-sentence summary, high-level how, pros/cons, relative effort (small/medium/large)
- **YAGNI ruthlessly** — identify speculative features, call out over-engineering, prefer the simplest solution

### 4. Present the design

Once you believe you understand what you're building, present it for approval. Scale each section to its complexity — a few sentences if straightforward, up to a paragraph if nuanced. Ask after each section whether it looks right.

Sections (use only what is relevant):

- **Overview**: Problem statement and chosen approach
- **Architecture**: High-level structure — main pieces and how they relate
- **Tech Stack / Patterns**: Which technologies or patterns and why
- **Data Model**: What data needs to exist and how it relates (shape, not column types)
- **Key Behaviors**: Important non-obvious behaviors and design decisions
- **Open Questions**: Anything the planner or user still needs to decide

The entire design for a medium feature should be **1-2 pages max**. Bullet points over prose. Skip obvious sections.

### 5. Write design doc

Save the approved design to `docs/plans/YYYY-MM-DD-<topic>-design.md`. Commit it.

### 6. Suggest next step

> Design approved. Run `/plan` to create an implementation plan from this design document.

## Key Principles

- **One question at a time** — don't overwhelm with multiple questions
- **Multiple choice preferred** — easier to answer than open-ended when possible
- **YAGNI ruthlessly** — remove unnecessary features from all designs
- **Explore alternatives** — always propose 2-3 approaches before settling
- **Incremental validation** — present design, get approval section by section
- **Be flexible** — go back and clarify when something doesn't make sense
- **Stay directional** — the planner handles implementation detail, domain patterns, file paths, and task decomposition. Your job is the what and why.
