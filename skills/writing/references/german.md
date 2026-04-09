# German language reference

**This file adds to the general tropes catalog — it does not replace it.** Every pattern in `tropes.md` applies to German text too, just with German words. Negative parallelism becomes „Es ist nicht X – es ist Y." Tricolon abuse uses German words. Stakes inflation sounds like „Dies wird grundlegend verändern, wie wir über alles denken." The structural tells (uniform sentence/paragraph length, predictable word choice, no contractions, perfect grammar, fractal summaries) are identical.

**Apply ALL patterns from tropes.md first.** Then layer these German-specific patterns on top.

Sources: ContentConsultants, Ströer, Martin Moeller, Advertext, German Wikipedia (Anzeichen für KI-generierte Inhalte), LanguageTool, RoboPhilosophy, Meinrad Blog, KONVENS 2024.

---

## AI vocabulary tells in German

Words and phrases that appear far more in AI-generated German than in human writing:

**Overused "impressive" words:**
- „revolutionieren" (revolutionize)
- „optimieren" (optimize)
- „ganzheitlich" (holistic)
- „umfassend" (comprehensive)
- „präzise" (precise)
- „eintauchen" (dive in/immerse -- the German "delve")
- „atemberaubend" (breathtaking) in contexts where nothing is breathtaking

Fix: Use the plain word. „ändern" not „revolutionieren". „genau" not „präzise". „vollständig" not „umfassend" (or better: just say what's included).

**Overused transition phrases (Floskeln):**
- „In der heutigen Zeit ist es wichtiger denn je, ..." (In today's time, it is more important than ever...)
- „In einer Welt, in der..." (In a world where...)
- „Immer mehr Menschen fragen sich, ..." (More and more people ask themselves...)
- „Es ist jedoch wichtig zu beachten, dass..." (It is however important to note that...)
- „Zusammenfassend lässt sich sagen, dass..." (In summary, one can say that...)
- „Darüber hinaus" (Furthermore) -- appears multiple times per paragraph
- „Viele Experten sind sich einig, dass..." (Many experts agree that...)
- „Eine Vielzahl an" (a multitude of), „eine breite Palette an" (a broad palette of)

Fix: Cut the filler. Start with the actual point. Vary connectors naturally.

**Overused rhetorical constructions:**
- „nicht nur..., sondern auch..." (not only... but also...) -- used excessively
- „steht als Zeugnis für" (stands as testimony to)
- „Tauchen Sie ein" (Immerse yourself / Dive in)
- „eine Welt" (a world) as in "discover a world of..."
- „Zauber der..." (magic of...)
- „aufs nächste Level bringen" (take to the next level)

---

## German-specific AI structural patterns

### Partizip-I constructions

In English, "-ing" forms are natural everywhere. In German, extended present participle constructions like „gewährleistend" (ensuring), „hervorhebend" (highlighting), „berücksichtigend" (considering) are extremely rare in normal prose. Extended Partizipialattribute (e.g., „die sich auf dem Tisch befindende Vase") are valid only in highly formal scientific/bureaucratic German and sound jarring elsewhere.

Bad: „Die sich stetig verändernde Technologielandschaft gewährleistend..."
Fix: Use a relative clause: „Die Technologie verändert sich ständig." Or a subordinate clause with „die" / „der" / „das".

### Always-three pattern

AI loves „drei Tipps, drei Argumente, drei Schritte" (three tips, three arguments, three steps). Combined with em-dashes followed by three comma-separated adjectives (– sicher, garantiert und zweifellos), the probability of AI text is near 100%.

### Excessive auxiliary verbs

ChatGPT over-relies on „werden", „kann", and „haben" as auxiliaries.

Bad: „Wir werden Ihre Träume erfüllen" (We will fulfill your dreams)
Fix: „Wir erfüllen Ihre Träume." Direct present tense is more natural in German.

### Missing human elements

AI German text lacks: dialect coloring (Dialektfärbung), experiential perspective, emotional specificity, unexpected reasoning, humor. When telling stories, it repeats „plötzlich" (suddenly) or „dann" (then) mechanically.

### Missing modal particles (Modalpartikeln)

Modal particles are the single biggest marker of natural German. They add nuance, attitude, and conversational tone. AI almost never uses them, or uses them mechanically.

Key particles and their functions:
- „ja" (shared knowledge): „Das ist ja bekannt." (As we both know, that's well known.)
- „doch" (contradiction/emphasis): „Das stimmt doch gar nicht!" (That's simply not true!)
- „eben" / „halt" (resignation/acceptance): „So ist es eben." (That's just how it is.)
- „mal" (softening): „Schau mal hier." (Take a look here.)
- „schon" (concession): „Das stimmt schon, aber..." (That's true, but...)
- „wohl" (assumption): „Er ist wohl krank." (He's probably sick.)
- „eigentlich" (actually/upon reflection): „Eigentlich wollte ich..." (Actually, I wanted to...)
- „ruhig" (encouragement): „Du kannst ruhig fragen." (Feel free to ask.)

Fix: In casual and semi-formal German, sprinkle modal particles where they fit naturally. In formal/academic German, use them sparingly but don't eliminate them entirely — even formal German uses „ja", „doch", and „wohl". Their complete absence screams AI.

### Uniform subordinate clause patterns

German's subordinate clause system (Nebensätze) is rich — „weil", „obwohl", „während", „nachdem", „bevor", „sobald", „falls", „indem", „damit", etc. AI tends to repeat the same 2-3 conjunctions (usually „dass", „weil", „wenn") and uses uniform clause nesting depth.

Fix: Vary conjunctions naturally. Mix main clauses with subordinate clauses unevenly. Use „obwohl" instead of always „aber". Use „sobald" instead of always „wenn". Vary nesting depth — some sentences with no subordination, others with 2-3 levels.

### Burstiness in German context

The burstiness principle from tropes.md applies differently in German. German naturally tolerates longer sentences, so the variation range is wider: a 5-word sentence followed by a 50-word sentence with nested subordinate clauses is perfectly natural in German. AI German tends to produce uniformly medium-length sentences (15-25 words), which is actually MORE suspicious in German than in English because it avoids the natural long-sentence tradition.

Fix: Let some German sentences be genuinely long (30-50 words with subordinate clauses). Follow with a short, direct sentence. This matches how native German speakers actually write.

---

## Translation pitfalls: English to German

### du/Sie inconsistency

The biggest translation problem. English "you" gives no formality signal, so AI guesses -- often switching mid-text. „Wählen Sie die Datei" (formal) followed by „öffne das Menü" (informal) in the same paragraph.

Rule: Pick du or Sie at the start and enforce it everywhere. When unclear, ask the user. Default to Sie for professional/business content, du for casual/tech community content.

### Pronoun gender across sentences

English "it" has no gender. German requires the pronoun to match the grammatical gender of the referent noun. AI translates segment-by-segment, so "it" often becomes „es" when it should be „sie" (die Datei) or „er" (der Server).

Fix: After translating, check every pronoun against its antecedent noun's grammatical gender.

### False friends

Cognates with different meanings that AI gets wrong:
- become/bekommen: "become" = werden; „bekommen" = to receive
- eventually/eventuell: "eventually" = schließlich; „eventuell" = vielleicht
- actual/aktuell: "actual" = tatsächlich; „aktuell" = current
- Gift/gift: „Gift" (DE) = poison; "gift" (EN) = Geschenk
- sensibel/sensible: „sensibel" = sensitive; "sensible" = vernünftig
- bald/bald: "bald" (EN) = no hair; „bald" (DE) = soon
- Rat/rat: „Rat" (DE) = advice/council; "rat" (EN) = Ratte
- chef/Chef: "chef" (EN) = Koch; „Chef" (DE) = boss
- spenden/spend: „spenden" = donate; "spend" = ausgeben
- Handy/handy: „Handy" (DE) = mobile phone; "handy" (EN) = praktisch

### Anglicisms AI introduces

AI often keeps English terms where natural German equivalents exist, or produces awkward half-translations:
- „Feedback geben" instead of „Rückmeldung geben"
- „Meeting" instead of „Besprechung" or „Treffen"
- „Skills" instead of „Fähigkeiten" or „Kenntnisse"
- „Performance" instead of „Leistung"
- „Content" instead of „Inhalt"

Rule: Use established German words when they exist and sound natural. Keep English loanwords only when they're genuinely established in the target audience's vocabulary (e.g., „Software", „Computer", „E-Mail" are fine).

### Literal translation of idioms

English idioms translated word-for-word produce nonsense in German:
- "It's raining cats and dogs" → „Es gießt wie aus Kübeln" (not „Es regnet Katzen und Hunde")
- "Break a leg" → „Toi, toi, toi" or „Hals- und Beinbruch"
- "The ball is in your court" → „Du bist am Zug" or „Jetzt bist du dran"

Fix: Identify idioms in the source text and find the German equivalent. If none exists, rephrase the meaning directly.

---

## Grammar issues AI gets wrong

### Compound nouns (Deppenleerzeichen)

German compounds are written together or hyphenated, NEVER with spaces. The „Deppenleerzeichen" (idiot space) is a dead giveaway:

Wrong → Right:
- „Kosmetik Produkte" → „Kosmetikprodukte"
- „Rabatt Code" → „Rabattcode"
- „Anti Falten Creme" → „Anti-Falten-Creme"
- „AI Modelle" → „AI-Modelle"
- „Deep Learning Modelle" → „Deep-Learning-Modelle"

Rule: If two nouns form a compound concept, write them together. If the first part is a foreign word or abbreviation, use a hyphen. Never a space.

### Genitive vs. dative

The genitive is declining in spoken German but required in formal writing. AI confuses them:

Wrong → Right:
- „wegen dem Wetter" → „wegen des Wetters" (formal)
- „das Auto von meinem Bruder" → „das Auto meines Bruders"
- „der Titel des Buch" → „der Titel des Buches" (noun ending)

Rule: Use genitive in formal/written contexts. Don't forget noun endings (-es, -s, -er, -en).

### Konjunktiv I in indirect speech

Proper German uses Konjunktiv I for reported speech. AI often drops it:

Wrong: „Er sagte, er ist müde." (indicative -- sounds like the writer confirms it)
Right: „Er sagte, er sei müde." (Konjunktiv I -- neutral reporting)

Also: AI overuses „würde" (would) constructions instead of proper Konjunktiv II for common verbs („käme" not „würde kommen", „hätte" not „würde haben").

### Comma rules

German comma rules are strict and differ from English:
- Subordinate clauses MUST be separated by commas: „Ich weiß, dass er kommt."
- Infinitive clauses with „zu" usually need a comma: „Er versuchte, den Fehler zu beheben."
- NO Oxford comma before „und"/„oder" in lists
- AI frequently misses commas before subordinate conjunctions (dass, weil, obwohl, wenn, als, ob)

### Word order in subordinate clauses

In Nebensätzen, the conjugated verb goes to the end: „Ich weiß, dass er heute nach Hause kommt." AI occasionally places verbs in English-influenced positions.

### Capitalization

German capitalizes all nouns, not just proper nouns. AI sometimes inconsistently capitalizes the same word differently within the same text: „erneuerbare Energien" vs. „Erneuerbare Energien".

---

## Formatting: German conventions

### Quotation marks

German uses different quotation marks than English:
- Standard (Gänsefüßchen): „Text" -- opening LOW (99-shape), closing HIGH (66-shape)
- Books/print (Guillemets): »Text« -- pointing INWARD (opposite of French)
- Nested quotes: ‚Text' -- single low-high marks
- Swiss German: «Text» -- guillemets pointing outward (French style)
- WRONG: "Text" (English straight quotes)

### Number formatting

German reverses commas and periods:
- Decimal separator: comma (3,14 not 3.14)
- Thousands separator: period or thin space (1.234 or 1 234, not 1,234)
- Currency: 3.455,00 EUR (not EUR 3,455.00)

### Date and time

- Date: DD.MM.YYYY with dots (15.03.2026)
- Time: 24-hour format (14:30, never 2:30 PM)
- AI frequently outputs MM/DD/YYYY or AM/PM

### Dashes

German uses the Halbgeviertstrich (en-dash) WITH spaces on both sides: „Wort – Wort"
English/AI uses the Geviertstrich (em-dash) WITHOUT spaces: "Wort—Wort"

The em-dash without spaces is a US convention. In German text it's an AI tell -- German editors have started calling it the „KI-Gedankenstrich" (AI dash).

### Abbreviations

Standard German abbreviations have specific spacing per DIN 5008:
- „z. B." not „z.B." (zum Beispiel)
- „d. h." not „d.h." (das heißt)
- „u. a." not „u.a." (unter anderem)
- „etc." is fine as-is

---

## Regional variants

### Swiss German (Schweizerdeutsch)

- NO Eszett (ß). Always „ss": „Strasse" not „Straße", „gross" not „groß"
- Quotation marks: «guillemets pointing outward» (French style)
- Some vocabulary differs: „parkieren" (CH) vs. „parken" (DE), „Velo" (CH) vs. „Fahrrad" (DE), „Natel" (CH, dated) vs. „Handy" (DE) vs. „Mobiltelefon" (formal)

### Austrian German (Österreichisches Deutsch)

Key vocabulary AI typically ignores:
- Kartoffel (DE) vs. Erdapfel (AT)
- Tomate (DE) vs. Paradeiser (AT)
- Aprikose (DE) vs. Marille (AT)
- Blumenkohl (DE) vs. Karfiol (AT)
- Sahne (DE) vs. Obers/Schlagobers (AT)
- Treppenhaus (DE) vs. Stiegenhaus (AT)

Austrian German also uses „sein" as auxiliary for position verbs: „Ich bin gesessen" (AT) vs. „Ich habe gesessen" (DE).

AI almost always produces German-German (Bundesdeutsch). If writing for an Austrian or Swiss audience, this needs explicit attention.

---

## Character encoding

### Umlaut/Eszett issues

AI sometimes outputs ASCII substitutions instead of proper characters:
- „ae" instead of „ä", „oe" instead of „ö", „ue" instead of „ü"
- „ss" instead of „ß"

This happens due to training on ASCII-degraded text or encoding mismatches. Always verify umlauts and Eszett are proper Unicode characters (ä ö ü ß), not digraph substitutions.

Also watch for: Mojibake (garbled characters like „Ã¤" instead of „ä") from UTF-8/ISO-8859-1 mismatches, and files written in ANSI encoding instead of UTF-8.

---

## German writing style norms

### Sentence length

German tolerates longer sentences than English. The Bandwurmsatz (tapeworm sentence) with nested subordinate clauses is legitimate in formal German prose. AI tends to produce short, choppy, English-style sentences that sound unnatural in German academic or professional contexts.

Rule: Don't artificially shorten German sentences to match English norms. Let subordinate clauses nest naturally. But don't go overboard -- even in German, clarity matters.

### Passive voice

German has two passives: Vorgangspassiv („Das Buch wird gelesen" -- process) and Zustandspassiv („Das Buch ist gelesen" -- state). Unlike English, passive voice carries no stigma in German formal writing. Don't "fix" passives that are natural in German just because English style guides discourage them.

### Paragraph structure

German academic/professional paragraphs develop arguments through longer, more complex individual sentences rather than the short topic-sentence-plus-support pattern common in English. Respect this when translating or writing formal German.
