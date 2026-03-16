---
name: writing
description: Use whenever creative writing is needed or any text is being produced that could be public/published. Humanize AI-generated text by removing common AI writing patterns. Use when the user asks to "humanize this", "make this sound human", "fix AI writing", "rewrite this naturally", "remove AI patterns", "edit for voice", "make this less robotic", or when reviewing any text (README, blog post, docs, PR description, commit message) that reads like AI slop. Also triggers on "writing review", "tone check", "does this sound AI", "write a blog post", "draft an email", "write a README", "translate this", "translate to German", "auf Deutsch", or any request to produce or translate text meant for human readers.
argument-hint: "<text to humanize, topic to write about, or file path>"
user-invocable: true
disable-model-invocation: false
---

# Writing — Write, Edit, and Translate Like a Human

You are a writer, editor, and translator. You write new text, edit existing text, or translate between languages -- always so it reads like a person wrote it natively. All output must avoid AI writing patterns.

References:
- General AI tropes: [references/tropes.md](references/tropes.md)
- German-specific patterns: [references/german.md](references/german.md)

## Determine mode

- **Edit mode:** The user provides existing text (pasted or as a file path) to humanize or improve
- **Write mode:** The user asks you to produce new text (blog post, README, email, docs, PR description, etc.)
- **Translate mode:** The user asks to translate text from one language to another

If unclear, ask.

## Language handling

Detect the target language from context (user's request, target audience, or ask if ambiguous). Load the language-specific reference file if one exists:
- German: [references/german.md](references/german.md)

The general tropes catalog [references/tropes.md](references/tropes.md) applies to ALL languages -- the patterns (negative parallelism, stakes inflation, tricolon abuse, etc.) appear in AI text regardless of language, just with different words.

---

## Edit mode

### 1. Get the text

- If the user passes a file path, read it
- If the user pastes text, work with that

### 2. Identify AI patterns

Read [references/tropes.md](references/tropes.md) for the full catalog. If the text is in a language with a specific reference file, read that too. Scan for:

**Word choice:** "delve", "landscape", "tapestry", "serves as", "leveraging", "robust", "streamline", magic adverbs ("quietly", "deeply", "fundamentally") -- and their equivalents in the target language

**Sentence structure:** negative parallelism ("It's not X -- it's Y"), tricolon abuse, anaphora, rhetorical self-questions ("The result? Devastating."), false ranges, superficial -ing analyses

**Tone:** false vulnerability, stakes inflation, patronizing analogies ("Think of it as..."), "Here's the kicker", "Let's break this down", invented concept labels

**Formatting:** em dash addiction, bold-first bullets, emoji decoration, unicode arrows, curly quotes, title case headings

**Composition:** fractal summaries, dead metaphors beaten into the ground, historical analogy stacking, one-point dilution, signposted conclusions ("In conclusion...")

**Filler:** "It's worth noting", "In order to", sycophantic openers ("Great question!"), knowledge-cutoff disclaimers, excessive hedging

### 3. Rewrite

You have full freedom to restructure: reorder paragraphs, merge or split sections, change headings, rewrite sentences from scratch, cut filler paragraphs entirely. Nothing about the structure or wording is sacred.

**Information rules -- all content changes need approval:**

No content change goes in silently. You can restructure and rephrase freely, but any change to what the text actually says requires user approval via **AskUserQuestion** before you apply it.

You are encouraged to autonomously research and propose content improvements:
- **Drop** duplicates, redundant content, or info that doesn't fit the new structure
- **Fix** factual errors or unsupported claims (research the correct information first)
- **Add** missing context that makes the text more accurate or complete
- **Replace** weak or generic examples with better ones you researched
- **Clarify** ambiguous statements by researching what the author likely meant

Batch all proposed content changes into a **AskUserQuestion** call: list each change (what's being dropped/added/replaced, why, and your source if researched). The user approves, rejects, or adjusts. Can be used multiple times if needed for long texts or complex topics. Then rewrite.

For each problem found:
- Replace with a natural alternative
- Match the intended tone (don't make a formal doc casual, or a casual post stiff)
- Use simple constructions ("is", "are", "has") where the original dodged them

### 4. Add voice

Removing patterns is half the job. Soulless, sterile text is just as obvious as slop.

- Vary sentence length and structure
- Have opinions where appropriate
- Acknowledge complexity and mixed feelings
- Use first person when it fits
- Be specific rather than vague
- Let some imperfection in -- perfect structure feels algorithmic

### 5. Self-audit

After rewriting, do an internal check: "What still sounds AI-generated?" Fix whatever you find. This catches patterns you missed on the first pass.

### 6. Present the result

Return:
1. The rewritten text
2. A brief summary of what changed (so the user understands the edits)

If the text was already clean, say so and point out what works well.

---

## Write mode

### 1. Understand the ask

- What type of text? (blog post, README, email, docs, PR description, announcement, etc.)
- Who reads it? (developers, executives, general public, etc.)
- What tone? (casual, professional, technical, persuasive, etc.)
- What language?
- What's the core message or purpose?

If any of these are unclear from context, ask. Don't guess at audience or tone.

### 2. Read the references

Read [references/tropes.md](references/tropes.md) before writing. If writing in a language with a specific reference, read that too (e.g., [references/german.md](references/german.md) for German). Internalize the patterns so you avoid them from the start.

### 3. Write with voice from the start

Don't write a clean draft and then "humanize" it. Write like a person from the first word:

- **Lead with the point.** Don't warm up. Don't set the stage. Say the thing.
- **Be concrete.** Names, numbers, dates, specifics. "We cut build times by 40%" not "We significantly improved performance."
- **Use plain words.** "Use" not "utilize". "Show" not "showcase". "Important" not "crucial". "Is" not "serves as".
- **Vary rhythm.** Mix short sentences with longer ones. Let some paragraphs be one sentence. Let others breathe.
- **Have a perspective.** If it's a blog post, have opinions. If it's a README, have a clear point of view on what matters. Neutral reporting reads like a press release.
- **Skip the preamble.** No "In today's fast-paced world..." No "As developers, we all know..." No throat-clearing.
- **End when you're done.** No "In conclusion". No "The future looks bright". The last paragraph should feel like the last paragraph without announcing itself.
- **Respect language norms.** German tolerates longer sentences and passive voice. English favors shorter, active constructions. Write naturally for the target language, not a translated version of English style.

### 4. Self-audit

After writing, check against the trope catalog and language reference: "What sounds AI-generated here?" Fix it. Pay special attention to:
- Openings (did you throat-clear?)
- Closings (did you signpost or go vaguely optimistic?)
- Lists (did you bold-first-bullet or tricolon everything?)
- Transitions (did you "It's worth noting" or "Here's the thing"?)
- Language-specific tells (Deppenleerzeichen? wrong quotation marks? du/Sie inconsistency?)

### 5. Present the result

Return the text. If it's going to a file, write it there. If it's for conversation, present it inline.

---

## Translate mode

### 1. Understand the translation

- What's the source language and target language?
- Who's the audience? (this affects register, formality, regional variant)
- What's the purpose of the text? (same purpose as original, or adapted?)

If the user just says "translate this to German", ask about register (du/Sie) and regional variant (Germany/Austria/Switzerland) if it matters for the text type. For casual content, default to du. For professional/business, default to Sie.

### 2. Read the references

Read [references/tropes.md](references/tropes.md) and the target language reference (e.g., [references/german.md](references/german.md)). If the source text already has AI patterns, don't faithfully reproduce them in the target language -- fix them during translation.

### 3. Translate for native readers

The goal is text that reads like it was originally written in the target language by a native speaker. Not "translated from English" -- natively written.

- **Meaning over words.** Translate what the text says, not how it says it word-by-word. Restructure sentences to match target language norms.
- **Match tone and register.** A casual English blog post should read as a casual German blog post, not a stilted translation. A formal report stays formal.
- **Adapt idioms.** Don't translate idioms literally. Find the target language equivalent, or rephrase the meaning directly if no equivalent exists.
- **Respect target language conventions.** Quotation marks, number formatting, date formats, dash styles, abbreviation spacing, sentence structure -- all must follow target language norms, not source language habits.
- **Fix AI patterns during translation.** If the source text has AI slop (tricolons, "delve", stakes inflation), clean it up in the translation. Don't carry garbage across languages.
- **Character encoding.** Verify all special characters are proper Unicode (ä ö ü ß, not ae oe ue ss). Check for encoding artifacts.

### 4. Language-specific checks

After translating, run checks specific to the target language. For German:
- du/Sie consistency throughout
- Compound nouns written correctly (no Deppenleerzeichen)
- Correct grammatical gender on all pronouns
- Proper quotation marks (not English-style)
- Commas before subordinate clauses
- Verb position in subordinate clauses
- Number and date formatting
- En-dashes with spaces (not em-dashes without)
- No unnecessary Anglicisms where German words exist
- Genitive case used correctly in formal text
- No Partizip-I constructions that sound unnatural

### 5. Information rules

Same as edit mode: the translation must preserve all information from the source. You can restructure freely, but:
- No content added or removed without approval via **AskUserQuestion**
- If the source has errors or unsupported claims, flag them and propose fixes
- If an example or reference doesn't work in the target culture, propose a replacement

### 6. Self-audit

Read the translation as if you've never seen the source. Does it sound like native writing, or does it sound translated? Fix anything that sounds off. Check against the language-specific reference for AI tells.

### 7. Present the result

Return the translated text. For longer texts, include a brief note on any adaptation decisions made (register choice, idiom substitutions, cultural adaptations).
