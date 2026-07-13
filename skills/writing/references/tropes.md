# AI writing tropes

Any pattern used once might be fine. The problem is when multiple tropes stack or a single trope repeats. The fix is always the same: say the thing plainly, with specifics.

---

## Write like this (the DOs)

Removing tropes is half the job. Two kinds of DO, both required: **craft** makes the writing good; **voice** makes it read as human, not machine.

**Craft -- good writing, any author:**
- **Active voice, actor first.** "The team shipped it", not "It was shipped by the team."
- **Strong verbs, not verb+noun.** "decide", not "make a decision"; "analyze", not "carry out an analysis."
- **Cut every word that isn't working.** If the sentence survives without it, delete it.
- **One main idea per sentence, in the main clause.** Subordinate the rest; don't chain equal clauses with "and ... and".
- **Old info first, new info last.** Open with what the reader already knows, land on the new point -- that's what makes prose flow.
- **Keep subject and verb close, end on the strongest word.** The last word of a sentence carries the most weight; put the payload there, not a trailing qualifier.
- **Be concrete.** Names, numbers, dates over abstractions. "Cut build times 40%", not "significantly improved performance."
- **Lead with the point; stop when done.** No warm-up, no signposted conclusion.

**Voice -- reads as human:**
- **Plain copulas.** "is", "has" -- not "serves as", "stands as", "represents".
- **The shorter word.** used not utilized, wrote not authored, about not regarding, help not facilitate.
- **Commit to superlatives when they're true.** "the first", "the only", "the largest" -- AI hedges away from these even when earned.
- **Keep natural hedges and intensifiers.** "very", "roughly", "tends to" -- AI strips them, then over-hedges elsewhere.
- **Repeat a word rather than synonym-dodge it.** A river stays "the river" -- not "the waterway", then "the watercourse".
- **Vary rhythm on purpose.** After two medium sentences, a five-word one. Let one paragraph run long, the next be a single line. Burstiness is the strongest human signal.
- **Have a point of view.** Commit to an opinion where the genre allows it. Neutral-on-everything reads like a press release.
- **Contractions, and let small imperfections stand.** "it's", "don't", a fragment for emphasis, a sentence that opens with "But".

---

## Word choice

### "Quietly" and other magic adverbs

Adverbs like "quietly", "deeply", "fundamentally", "remarkably", "arguably" that inflate mundane descriptions.

Bad: "quietly orchestrating workflows", "a quiet intelligence behind it"
Fix: Cut the adverb. If the thing matters, the facts show it.

### "Delve" and friends

"Delve" went from rare to ubiquitous in AI text. Family: "certainly", "utilize", "leverage" (verb), "robust", "streamline", "harness".

Bad: "Let's delve into the details...", "We certainly need to leverage these robust frameworks..."
Fix: "Let's look at...", "We need to use these frameworks..."

### "Tapestry" and "landscape"

Ornate nouns where plain ones work: "tapestry" for anything interconnected, "landscape" for any field. Also "paradigm", "synergy", "ecosystem", "framework" (when not literal).

Bad: "The rich tapestry of human experience...", "Navigating the complex landscape of modern AI..."
Fix: Name the thing directly.

### The "serves as" dodge

Replacing "is" with "serves as", "stands as", "marks", "represents" -- AI avoids plain copulas because repetition penalties push it toward fancier constructions.

Bad: "The building serves as a reminder of the city's heritage."
Fix: "The building is a reminder of the city's heritage." (Or cut the sentence if it says nothing.)

### Overused AI vocabulary

Words far more common in post-2023 text: Additionally, align with, boasts (meaning "has"), bolstered, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract), meticulous/meticulously, pivotal, robust, seamless, showcase, tapestry (abstract), testament, underscore (verb), valuable, vibrant.

The set drifts: "delve" peaked in 2023-24 then faded; 2025-era text leans on "emphasizing", "enhance", "highlighting", "showcasing". One or two is coincidence; a paragraph full of them is a signature, and they travel in packs.

Fix: Use the plain word -- "important" not "crucial", "show" not "showcase", "improve" not "enhance". Applies to the specific word, not its synonyms; swapping "crucial" for "pivotal" changes nothing.

### Promotional / travel-brochure tone

Even asked for neutral tone, AI drifts to ad copy or tourism-guide puffery. Tells: "boasts a", "nestled in the heart of", "rich cultural heritage", "breathtaking natural beauty", "hidden gem", "vibrant", "renowned", "must-visit", "home to", "stands as a testament to".

Bad: "Nestled in the heart of the valley, the town boasts a rich cultural heritage and breathtaking natural beauty."
Fix: Plain facts. "The town is in the valley, founded in 1780, known for its textile mills." Cut anything that sounds like selling.

### Elegant variation (synonym dodging)

The mirror image of predictable word choice: rather than repeat a noun, AI reaches for an ever-fancier synonym -- "river" -> "waterway" -> "watercourse" -- because the repetition penalty pushes it off the natural word.

Bad: "The startup raised funding. The venture secured capital. The firm's coffers grew."
Fix: "The startup raised funding, then raised more." Repeat the word; it's not a sin.

---

## Sentence structure

### Negative parallelism

"It's not X -- it's Y." The most common AI tell -- false profundity via constant reframe. One per piece is fine; ten insults the reader.

Variants: "not because X, but because Y", the em-dash dismissal "X -- not Y", the cross-sentence "The question isn't X. The question is Y.", the reversal "chose X rather than Y".

Bad: "It's not bold. It's backwards.", "Half the bugs you chase aren't in your code. They're in your head."
Fix: State Y directly.

### "Not X. Not Y. Just Z."

Dramatic countdown that negates two things before the point.

Bad: "Not a bug. Not a feature. A fundamental design flaw."
Fix: "It's a design flaw." (Context supplies the emphasis.)

### "The X? A Y."

Self-posed rhetorical questions answered immediately. Nobody was asking.

Bad: "The result? Devastating.", "The worst part? Nobody saw it coming."
Fix: Fold the answer into the preceding sentence.

### Anaphora abuse

Repeating the same sentence opening several times in a row.

Bad: "They could expose... They could offer... They could provide... They could create..."
Fix: Vary the structure or combine into one sentence.

### Tricolon abuse

Overusing rule-of-three, often stretched to four or five. One is elegant; three back-to-back is a pattern failure.

Bad: "Products impress people; platforms empower them. Products solve problems; platforms create worlds."
Fix: Keep the strongest, cut the rest.

### "It's worth noting"

Filler transitions that signal nothing. Also "It bears mentioning", "Importantly", "Interestingly", "Notably".

Bad: "It's worth noting that this approach has limitations."
Fix: "This approach has limitations."

### Superficial -ing analyses

Present-participle phrases tacked on for fake depth: "highlighting its importance", "reflecting broader trends", "contributing to the development of..."

Bad: "contributing to the region's rich cultural heritage"
Fix: Cut it. If the contribution matters, state it as its own sentence with specifics.

### False ranges

"From X to Y" where X and Y aren't on any scale. Real use implies a spectrum; AI uses it to list two loosely related things.

Bad: "From innovation to implementation to cultural transformation."
Fix: Name the things without pretending they're a continuum.

---

## Paragraph structure

### Short punchy fragments

Sentence fragments as standalone paragraphs for manufactured emphasis. RLHF pushes toward one-thought-per-sentence; no one drafts this way.

Bad: "He published this. Openly. In a book. As a priest."
Fix: Combine into real sentences with natural rhythm.

### Listicle in a trench coat

Numbered points disguised as prose: "The first... The second... The third..." to hide that it's really a list.

Bad: "The first wall is the absence of a free API... The second wall is the lack of delegated access..."
Fix: Use an actual list (honest) or write connected prose (better).

---

## Tone

### "Here's the kicker"

False-suspense transitions. Also "Here's the thing", "Here's where it gets interesting", "Here's what most people miss".

Bad: "Here's the kicker.", "Here's where it gets interesting."
Fix: State the point.

### "Think of it as..."

Patronizing analogies that assume the reader needs a metaphor -- often less clear than the concept itself.

Bad: "Think of it like a highway system for data."
Fix: If the concept needs explaining, explain it directly.

### "Imagine a world where..."

The AI futurism pitch: "imagine" followed by a list of wonderful things.

Bad: "Imagine a world where every tool you use has a quiet intelligence behind it..."
Fix: Describe what exists or what you're proposing. Skip the invitation to dream.

### False vulnerability

Performative self-awareness that fake-breaks the fourth wall. Real vulnerability is specific and uncomfortable; AI's is polished and risk-free.

Bad: "And yes, I'm openly in love with the platform model"
Fix: State your position without performing honesty about it.

### "The truth is simple"

Asserting something is obvious instead of proving it. Also "The reality is...", "History is clear...".

Bad: "The reality is simpler and less flattering"
Fix: Show the evidence. If you must say it's clear, it probably isn't.

### Grandiose stakes inflation

Everything is the most important thing ever -- a post on API pricing becomes a meditation on civilization.

Bad: "This will fundamentally reshape how we think about everything."
Fix: State the actual impact at actual scale.

### "Let's break this down"

Hand-holding pedagogical voice. Also "Let's unpack this", "Let's explore", "Let's dive in".

Bad: "Let's break this down step by step."
Fix: Just start explaining.

### Vague attributions

"Experts", "observers", "industry reports" with no names -- and inflating one source into widespread agreement.

Bad: "Experts argue that this approach has significant drawbacks."
Fix: Name the expert and cite the argument, or cut it.

### Invented concept labels

Compound labels that sound analytical but aren't grounded -- an abstract problem-noun (paradox, trap, creep, divide, vacuum, inversion) bolted to a domain word.

Bad: "the supervision paradox", "the acceleration trap", "workload creep"
Fix: Describe the actual problem instead of coining a term.

### Sycophantic/servile tone

People-pleasing language left over from chatbot conversation.

Bad: "Great question!", "You're absolutely right!", "That's an excellent point!"
Fix: Skip the flattery, address the substance.

### Knowledge-cutoff disclaimers and gap-filling speculation

Hedging about missing information, then guessing anyway -- announcing the gap and speculating in the same breath as if it were fact. For a private person it defaults to "maintains a low profile" or "keeps personal details private", itself speculation.

Bad: "While specific details are limited based on available information...", "Though not widely documented, the site likely supported...", "She keeps her personal life private."
Fix: State what you know, then stop. Don't backfill with "likely" and "presumably".

### Situating in broader debates and trends

Puffing up an ordinary subject by parking it in a "broader movement", "growing debate", or "ongoing discussions" -- usually generic and invented. Tells: "has sparked debate about", "raises questions about", "part of a broader shift toward", "reflects a growing trend", "prompted broader reflection on".

Bad: "The app has sparked debate about privacy, autonomy, and what it means to be human in a digital age."
Fix: Cut it, or give a specific sourced fact. If a real debate exists, name who's debating and what they said.

### Canned notability

Asserting the subject is important by cataloguing its coverage or reach. "Maintains an active social media presence" is almost pure AI. Also "has been featured in numerous outlets", "profiled in", "widely recognized as".

Bad: "The chef maintains an active social media presence and has been featured in numerous prominent publications."
Fix: Show, don't assert -- name the outlet and what it said, or drop it. Importance is shown by specifics, not announced.

### Chatbot correspondence leakage

Chat-to-the-user text leaking into the deliverable: offers to continue, meta-commentary about the draft, unfilled placeholders.

Bad: "I hope this helps! Would you like me to expand this section?", "Here's a draft you can customize:", "I am writing to request an edit for [Article Name].", "[Describe the specific change here]."
Fix: Delete every line addressed to the reader-as-user -- no preamble, sign-off, offers, or placeholders. The deliverable is the text itself.

---

## Formatting

### Em dash overuse

The problem is frequency, not the character. AI reaches for a dash 10-20+ times per piece as a rhythm crutch, usually to punch up a parallelism; keep the one that earns its pause and turn the rest into commas or separate sentences.

Which dash: where one genuinely fits, a hyphen "-" or double hyphen "--" is fine, and better in casual or plain-text writing (chat, READMEs, commits, comments). Save the true em dash "—" for professional or formal prose -- the kind written in Word, where "--" auto-converts to "—" anyway. Don't hand-insert "—" into plain-text output.

Bad: "The problem -- and this is the part nobody talks about -- is systemic. The fix -- if there is one -- requires rethinking the entire approach -- from top to bottom."
Fix: "The problem is systemic, and nobody talks about it. Fixing it -- if it can be fixed -- means rethinking the whole approach."

### Bold-first bullets and key-takeaways bolding

Every list item opens with a bolded label-and-colon -- almost nobody formats lists this way by hand. The same reflex bolds phrases mid-prose for "key takeaways", the way a slide deck or sales README does.

Bad: "**Security**: Environment-based configuration with...", "This is the **single most important** factor, and it **fundamentally changes** the outcome."
Fix: Plain-sentence list items; keep bold only for a genuine scanning label. In prose, let strong words carry emphasis -- don't bold them.

### Title case headings

Capitalizing Every Main Word. AI prefers title case; most running-text writing uses sentence case.

Bad: "Impact Of Technology And Digitalization"
Fix: "Impact of technology and digitalization" (unless the style guide requires title case).

### Unicode decoration and curly quotes

Unicode arrows, hard-to-type characters, and curly/smart quotes (“ ” ‘ ’) and apostrophes (’) where straight ones are expected. ChatGPT and DeepSeek default to curly -- not proof alone (Word and macOS do it too), but it adds up with other tells. Watch for curly and straight mixed in one text.

Bad: "Input → Processing → Output", "the city’s “golden age”"
Fix: "Input -> Processing -> Output" (or describe the flow); straight quotes and apostrophes unless the medium calls for typographic ones.

### Emojis as decoration

Emoji-prefixed headings or bullet points.

Bad: "rocket Launch Phase:", "bulb Key Insight:"
Fix: Drop the emojis.

---

## Composition

### Fractal summaries

"What I'll tell you; what I'm telling you; what I told you" at every level. Every section, the document, and the summary each get a summary.

Fix: Trust the reader. State things once.

### The dead metaphor

Latching onto one metaphor and beating it through the whole piece. A human uses it once and moves on.

Bad: "The ecosystem needs ecosystems to build ecosystem value."
Fix: Use it once where it works, then drop it.

### Historical analogy stacking

Rapid-fire historical companies or tech revolutions for false authority. Common in technical writing.

Bad: "Take Spotify... Or consider Uber... Airbnb followed a similar path... Shopify is another example..."
Fix: Pick the one example that fits best and develop it.

### One-point dilution

One argument restated ten ways -- an 800-word point padded to 4000 words of circular repetition.

Fix: Say it once, well. If 800 words covers it, stop.

### The signposted conclusion

"In conclusion", "To sum up", "In summary". The reader feels the ending coming; announcing it means you're following a template.

Fix: Just end. The last paragraph should feel final without a label.

### "Despite its challenges..."

Formula: acknowledge problems, then dismiss them -- "Despite its [positive words], [subject] faces challenges..." then "Despite these challenges, [optimistic close]."

Bad: "Despite these challenges, the initiative continues to thrive."
Fix: State the problems concretely and what's being done. Drop the formula.

### Generic positive conclusions

Vague upbeat endings that say nothing.

Bad: "The future looks bright. Exciting times lie ahead."
Fix: End with something specific -- a next step, a concrete plan, an honest uncertainty.

---

## Rhythm and variation (statistical tells)

### Uniform sentence length

AI sentences cluster at 15-25 words. Human writing is "bursty" -- short and long scattered together. Three medium sentences in a row is a tell.

Fix: Map sentence lengths after writing. After two medium ones (18-22 words), drop a very short one (5-8), then a long one (35+). One of the most effective humanization moves.

### Uniform paragraph length

AI paragraphs are all ~3-4 sentences. Humans vary wildly.

Fix: After a 4-sentence paragraph, write 2. Then 6. Then 1. Let content set the length, not a template.

### Predictable word choice

AI picks the statistically likely next word. Human writing has higher "perplexity" -- apt but unexpected choices.

Fix: Swap obvious words for less expected, still-accurate ones: "important" -> "critical", "essential", "matters"; "different" -> "distinct", "divergent". Not the first word anyone would guess.

### No contractions

AI avoids contractions ("it is", "do not", "that is") because training favors formal register. Humans contract in everything but the most formal writing.

Fix: Add them where natural -- "it's", "don't", "that's", "won't", "can't". In casual text, most "it is" -> "it's".

### Perfect grammar

Flawless grammar is itself a tell. Humans make choices that aren't wrong but wouldn't score perfectly -- fragments for emphasis, opening with "And"/"But", clear-in-context dangling modifiers.

Fix: Don't add errors, but don't polish away every imperfection. If a fragment sounds right, keep it.

---

## Filler and hedging

### Filler phrases

- "In order to" -> "To"
- "Due to the fact that" -> "Because"
- "At this point in time" -> "Now"
- "In the event that" -> "If"
- "Has the ability to" -> "Can"
- "It is important to note that" -> (cut; state the thing)

### Excessive hedging

Over-qualifying until the statement says nothing.

Bad: "It could potentially possibly be argued that the policy might have some effect."
Fix: "The policy may affect outcomes."

### Affirmation openers

Opening with "Absolutely," "Certainly," "Of course," "Yes, definitely" -- chatbot conversation artifacts.

Bad: "Absolutely! This approach has several benefits..."
Fix: State the benefits directly.

---

## Don't over-correct

None of these patterns is a tell in isolation. Chasing them too hard produces sterile, gutted text that reads just as artificial. In particular, these alone prove nothing and should not be stripped from otherwise good writing:

- **Perfect grammar** -- plenty of humans write cleanly.
- **A single em dash, curly quote, or "Additionally"** -- one instance is normal punctuation and normal writing.
- **Formal or academic prose** -- "fancy"-sounding is not the same as AI. The tell is a small set of *specific* overused words, not all sophisticated vocabulary.
- **Any one word from the vocab list** -- the signal is density and stacking, not a lone "crucial".

The goal is text that reads like a person wrote it -- not text scrubbed of every feature until no voice remains. When a construction is genuinely the best choice, keep it. Fix patterns that *repeat* or *stack*; leave the ones that earn their place.
