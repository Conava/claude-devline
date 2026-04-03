# Project Content — Website Copy, READMEs, Documentation

Reference for project-facing writing. Applies to all languages; language-specific references add on top.

---

## READMEs

### Essential sections (in order)

1. **Project name** — clear, bold
2. **One-line description** — what it does, who it's for
3. **Visual demo** — GIF, screenshot, or link to live demo (this hooks readers)
4. **Installation** — step-by-step, copy-pasteable commands
5. **Usage** — minimal working example
6. **Configuration** — if applicable
7. **Contributing** — for open source
8. **License**

### Writing style

- **Answer "what does this do?" in the first 10 seconds.** Don't make readers scroll.
- **Code blocks for every command.** Language-tagged, copy-pasteable.
- **Scan-friendly.** Headers, bullets, spacing. Not walls of text.
- **Honest about limitations.** "This doesn't support X yet" builds more trust than silence.
- **Active voice, present tense.** "The library handles..." not "The library can be used to handle..."
- **Keep the README as a high-level hub.** Link to detailed docs rather than putting everything in one file.

### Common mistakes

- Making readers guess what the project does
- Missing installation steps (people leave immediately)
- Outdated examples that don't work
- Explaining implementation details instead of usage

---

## Website copy

### Core principles (UX writing)

- **Clarity > cleverness.** Users scan, they don't read. Every word must earn its place.
- **User-centric language.** "What does the user need to know right now?" not "What do we want to say?"
- **Reduce cognitive load.** Shorter sentences, simpler words, fewer choices per screen.
- **Specificity converts.** "Cuts deploy time from 45 minutes to 3" beats "Dramatically faster deployments."

### Page-specific guidance

**Landing page / Hero:**
- Headline: what you do + for whom, in under 10 words
- Subheadline: the key benefit or differentiator
- CTA: specific action ("Start your free trial" > "Get started" > "Learn more")
- No jargon in above-the-fold content

**Feature pages:**
- Lead with the user's problem, not your feature
- One feature per section with a concrete example
- Screenshots or visuals for every feature

**Pricing page:**
- Transparent. No "contact us for pricing" unless enterprise.
- Comparison table for tiers
- Anchor the most popular plan visually

### Microcopy that matters

- Button text: "Start my free trial" (personal) > "Start your free trial" > "Submit"
- Error messages: say what went wrong AND how to fix it
- Empty states: guide the user to the first action, don't just say "Nothing here yet"
- Loading states: set expectations ("This takes about 30 seconds")

---

## Technical documentation

### Diátaxis framework (4 types)

| Type | Purpose | Style | Example |
|------|---------|-------|---------|
| **Tutorial** | Learning | Step-by-step, hand-holding, complete | "Build your first app" |
| **How-to guide** | Solving a problem | Goal-oriented, assumes knowledge | "How to configure SSO" |
| **Reference** | Looking up facts | Concise, indexed, complete | "API endpoint reference" |
| **Explanation** | Understanding | Conceptual, narrative | "How authentication works" |

**Don't mix types.** A tutorial that stops to explain theory loses the reader. A reference that tries to teach is too verbose to scan.

### Style (Google Developer Docs)

- Write like "a knowledgeable friend who understands what the developer wants to do"
- Conversational but precise. Not chatty, not robotic.
- Use "you" for the reader, not "the user" or "one"
- Present tense, active voice
- Code examples must be runnable — test them
- Change docs in the same commit as code — keeps them fresh

### Common doc failures

- Docs that describe the API but never show how to USE it
- Missing "getting started" — the first 5 minutes experience
- Assuming context the reader doesn't have
- Outdated examples (the #1 trust destroyer)
