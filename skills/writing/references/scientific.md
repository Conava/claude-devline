# Scientific Writing

Reference for academic and scientific writing. Applies to all languages; language-specific references add on top. Every claim must be verifiable.

---

## Non-negotiable rules

1. **Every factual claim needs a source.** No exceptions. No "research shows" without citing the research.
2. **Every citation must be verified.** LLMs hallucinate citations at alarming rates (19.9% of GPT-4o citations are fabricated, ~2/3 contain errors). Verify that: the source exists, the quote actually appears in it, and the source actually supports the claim.
3. **No hedging as a substitute for evidence.** Don't write "It could be argued that..." — either present the argument with evidence or don't include it.
4. **Transparent about limitations.** State what you don't know. State the boundaries of your evidence. This is a strength, not a weakness.

---

## Structure: IMRaD

Most scientific papers follow IMRaD. Use it unless the discipline has a different convention:

### Introduction
- **What is the problem?** — Context and motivation
- **Why does it matter?** — Significance and gap in existing knowledge
- **What did you do?** — Brief overview of approach (not results)
- End with a clear thesis statement or research question

### Methods
- **Reproducibility is the goal.** Another researcher should be able to replicate your work from this section alone.
- Describe materials, procedures, data sources, analysis methods
- Justify choices — why this method over alternatives?
- State limitations of the methodology

### Results
- **Present findings without interpretation.** Save "what this means" for Discussion.
- Use tables and figures for complex data — don't describe in prose what a table shows more clearly
- Report statistical significance, confidence intervals, effect sizes — not just p-values
- Report negative results too — publication bias harms science

### Discussion
- **Interpret results in context.** What do they mean? How do they relate to existing work?
- Address contradictions with prior research
- Acknowledge limitations honestly
- Suggest future directions — but only if they follow logically from your findings

---

## Citation practices

### When to cite

- Any factual claim that is not common knowledge in the field
- Any specific data, statistic, or finding from another source
- Any theory, framework, or model developed by someone else
- Paraphrases and summaries of others' work (not just direct quotes)
- Methods or tools you adopted from other studies

### How to cite

**In-text (APA style — default for social/behavioral sciences):**
- Parenthetical: (Author, Year)
- Narrative: Author (Year) found that...
- Direct quote: (Author, Year, p. XX)
- Multiple sources: (Author1, Year; Author2, Year) — alphabetical

**In-text (IEEE style — default for CS/engineering):**
- Numbered: [1], [2], [3] — order of first appearance
- Range: [1]–[3] for consecutive sources

### Source quality hierarchy

1. Peer-reviewed journal articles (strongest)
2. Conference proceedings (strong in CS/engineering)
3. Preprints (acceptable with caveats — state "preprint, not peer-reviewed")
4. Books and textbooks (authoritative but may be dated)
5. Government/institutional reports (reliable for data)
6. Reputable news sources (for current events, not scientific claims)
7. Blog posts, opinion pieces (cite only for the opinion itself, not as evidence)

Never cite: Wikipedia (cite its sources instead), random websites, social media posts as evidence.

---

## Writing style for academic text

### Clarity over complexity

- Simple, direct sentences. Academic writing is not fancy writing.
- "We found that X increases Y by 30%" not "Our investigation revealed a statistically significant positive correlation between X and Y variables."
- Use technical terms precisely but don't use jargon to sound smart.

### Hedging — calibrated, not excessive

Appropriate hedging signals epistemic honesty:
- "The results suggest..." (not proven beyond doubt)
- "This may indicate..." (tentative interpretation)
- "One possible explanation is..." (speculation clearly marked)

Over-hedging signals nothing:
- "It could potentially possibly be argued that this might have some effect..."
- Cut to: "This may affect outcomes."

### Tense conventions

- **Present tense:** established facts, general truths, your arguments ("X causes Y", "We argue that...")
- **Past tense:** your specific methods and results ("We measured...", "Participants reported...")
- **Present perfect:** literature review ("Several studies have shown...")

### Common AI tells in academic writing

- Sweeping claims without evidence ("This groundbreaking approach revolutionizes...")
- Fabricated or vague citations ("As demonstrated by Smith et al., 2023")
- Uniform sentence length and paragraph structure
- Overly balanced "on one hand / on the other hand" structures
- Generic conclusions ("Future research is needed" without specifying what research)
- Superlatives ("the most important", "the best approach") without comparative evidence

---

## Verification workflow

Before submitting any scientific text:

1. **Check every citation.** Does the paper exist? Does it say what you claim it says?
2. **Check every statistic.** Is the number accurate? Is the context correct?
3. **Check every causal claim.** Did the cited study actually demonstrate causation, or only correlation?
4. **Check methodology descriptions.** Are they accurate and complete enough for replication?
5. **Read the abstract of every cited paper.** If the abstract contradicts your use of the citation, investigate further.
