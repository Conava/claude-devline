---
name: writing
description: Use whenever text is being produced or edited that could be public/published. Covers 4 purposes: communication (emails, LinkedIn), project content (READMEs, website copy, docs), scientific writing (papers, theses), and fiction (books, stories). Humanize AI-generated text by removing common AI writing patterns. Triggers on "humanize this", "make this sound human", "fix AI writing", "rewrite this naturally", "write a blog post", "draft an email", "write a README", "translate this", "translate to German", "auf Deutsch", "write a chapter", "scientific paper", or any request to produce, edit, or translate text meant for human readers.
argument-hint: "<text to humanize, topic to write about, or file path>"
user-invocable: true
disable-model-invocation: false
---

# Writing: write, edit and translate like a person

## Mandatory steps

Every one of these runs every time. A brevity, lazy or terse mode shortens your prose, never this list.

1. Pick the purpose and language (below), and read the layer and references for them. For scientific text, also pass the HARD GATE below before the first sentence.
2. Write, edit or translate the text.
3. Save the text to a file and run `bash ${CLAUDE_PLUGIN_ROOT}/skills/voice/scripts/check-tells.sh [--de] [--fiction] FILE`. Fix every hard hit. Rewrite every `warn` line unless it is deliberate.
4. Do one self-audit: read the text as a stranger would. What still sounds machine-made? Did you add the DOs from tropes.md, or only strip the patterns? For a translation, run the German checks under Translate. Fix what you find.
5. Finish with a summary that lists every change to what the text says: facts dropped, added, replaced or corrected, and examples swapped. Leave none out. Restructuring and rephrasing need no listing. When editing or translating, you may research and apply content improvements (drop duplicates, fix errors, add missing context, swap weak examples). The user reviews the list afterwards, so give each entry its reason and, if researched, its source.

## Reading

Read each file with the Read tool, one file per call. Never read several files in one shell command: a failure or a size cut-off then hides all of them. The core voice is already in context (injected at session start), so don't re-read it.

Defaults come from the devline config (lookup and precedence: `${CLAUDE_PLUGIN_ROOT}/skills/setup/references/config.md`). `voice_dir` defaults to `${CLAUDE_CONFIG_DIR:-~/.claude}/devline/voice` and holds the personal voice layer. Read its `contexts/email.md` for emails or `contexts/pr.md` for PR and commit text, only if a personal layer was injected or the directory exists. A missing directory is normal and changes nothing else. Never apply the personal layer to fiction or scientific writing.

Always read [tropes.md](../voice/references/tropes.md) (the DOs first, then the patterns to avoid). It applies to every language. Then read the purpose reference and the layer from these tables. Paths are relative to `${CLAUDE_PLUGIN_ROOT}/skills/writing/` unless stated.

| Purpose | Triggers | Reference |
|---------|----------|-----------|
| Communication | email, LinkedIn, message, announcement, cover letter, social post | [references/communication.md](references/communication.md) |
| Project content | README, website copy, docs, landing page, changelog | [references/project-content.md](references/project-content.md) |
| Scientific | paper, thesis, research, citations, evidence | [references/scientific.md](references/scientific.md) |
| Creative | book, story, chapter, novel, poem | [references/creative.md](references/creative.md), plus [references/creative-de.md](references/creative-de.md) for German |

For German also read [references/german.md](references/german.md). If the purpose is unclear, ask.

| Text | English layer | German layer |
|------|---------------|--------------|
| Fiction | `layers/fiction.md` | `layers/fiction.md` + `layers/german.md` |
| Email | core voice only | `layers/email.md` + `layers/german.md` |
| Scientific | `layers/science.md` | `layers/science.md` |
| PR, commit, technical text | `layers/pr.md` | `layers/pr.md` + `layers/german.md` |
| Anything else in German | | `layers/german.md` |

Layers override the references where they disagree. The core voice's hard bans override both.

## HARD GATE: scientific purpose

For a paper, thesis, proposal, literature review or any text that cites sources:

1. Read [references/scientific.md](references/scientific.md) end to end before you produce or edit a sentence, even if you read it earlier in the session.
2. Every factual claim gets an inline citation in the same sentence or clause. Never attribute anything to prior work, a person, a system or a study without one.
3. Never fabricate citations. Check that each one exists and supports the claim. A fabricated or irrelevant citation is publication misconduct.
4. Follow the verification workflow at the end of `scientific.md` before you return the text.

## Modes

**Write.** Write like a person from the first word instead of drafting clean and humanizing afterwards. If audience, tone or language are unclear, ask. Don't guess. For fiction, read the creativity section of `creative.md` first. Context material is a palette, not a checklist, so omit and vary freely.

**Edit.** Take the text from a file path or from the message. You may restructure freely: reorder, merge, split, change headings, cut filler. Keep the tone of the original (don't make a formal doc casual). If the text is already clean, say so and name what works.

**Translate.** The result should read as if a native wrote it. Translate meaning, not words: restructure sentences, adapt idioms, follow the target language's conventions for quotes, numbers, dates and dashes, and keep the register of the source. Don't carry the source's AI patterns across, fix them. For German ask about du/Sie and regional variant when it matters (default du for casual, Sie for business). Preserve all information and flag source errors or examples that don't work in the target culture in the summary. After translating, check:

- du/Sie consistent, and correct gender on pronouns
- compounds written correctly (no Deppenleerzeichen)
- German quotation marks, commas before subordinate clauses, verb position in subordinate clauses
- number and date formats
- no dashes as a pause, spaced or not (en dash only in ranges, 3–5)
- no needless Anglicisms, genitive used correctly in formal text, no stilted Partizip-I constructions
- proper Unicode characters (ä ö ü ß, not ae oe ue ss)

## Rhythm

Vary sentence length on purpose. If sentence lengths cluster at 15 to 25 words, rewrite some to 5 to 8 and others to 35 or more. Vary paragraph length too, but don't string together one-sentence paragraphs: the checker warns on runs of them. German tolerates longer sentences and passive voice more than English does, so write for the target language, not a translated English style.
