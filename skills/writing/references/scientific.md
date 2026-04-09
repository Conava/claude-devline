# Scientific Writing

Reference for academic and scientific writing — primarily CS/engineering, with a bias toward IEEE/ACM conventions. Applies to all languages; language-specific references layer on top. **This file is mandatory reading when the purpose is scientific. Do not produce a single sentence of scientific text without having read it end-to-end first.**

Most rules below are drawn from the sources listed at the end of this file. When in doubt, consult them directly — this reference distills, it does not replace.

---

## The citation contract — non-negotiable

**Rule 0: Never attribute a claim, finding, statistic, method, idea, definition, or named concept to prior work without an inline citation mark attached to that sentence or clause. If you cannot cite it, you cannot claim it. No exceptions.**

Violations include:
- `Smith showed that X.` — missing cite. Write: `Smith [3] showed that X.`
- `Recent work demonstrates X.` — missing cite. Write: `Recent work [3], [7], [12] demonstrates X.`
- `BPMN is widely used in industry.` — unsupported factual claim. Either cite, or cut.
- `It is well-known that X.` — appeal to consensus without evidence. Cite or cut.
- `Studies show that 60% of projects fail.` — fabricated-looking statistic without source. Cite the exact study or cut the number.
- Paraphrasing across two sentences from one source and only citing the second — cite at first use and whenever ambiguity could arise.

When synthesizing from multiple sources, cite them all in the same clause: `Several studies [3], [7], [12] report that...`. Never cite only the most prominent one and drop the rest.

**Named-attribution rule:** Whenever a person, group, or prior system is named (`Vaswani et al.`, `the Raft algorithm`, `OpenTOSCA`), the citation is attached to the named entity itself at first mention, not floated to the end of the paragraph: `TOSCA [6] is an OASIS standard...`, `long short-term memory [13]`, `the Raft algorithm [22]`.

**Paraphrase rule:** Paraphrasing does *not* remove the citation requirement. If the idea is someone else's, it needs a cite, even if every word is yours. APA and ACM are explicit about this.

**No secondary citations.** If `[A]` cites `[B]` and you want to use `[B]`'s claim, locate and read `[B]`, then cite `[B]` directly. IEEE style requires citing the original wherever possible; "as cited in" is only acceptable when the original is genuinely unobtainable, and you should say so explicitly.

**No fabricated citations.** LLMs hallucinate citations at alarming rates. Verify every single citation:
1. The paper exists (check DOI, arXiv ID, or venue).
2. The authors and year match.
3. The paper actually says what you claim it says — read at least the abstract and the specific section you are citing.
4. The citation is relevant, not decorative. ACM classifies manufactured or irrelevant citations as publication misconduct.

**Self-plagiarism.** Reusing your own prior writing without citing yourself is also a violation (ACM policy). If you lift a sentence from your own earlier paper or proposal, cite it.

**Quotes.** Direct quotes need quotation marks plus citation with page number: `"..." [3, p. 42]`. For block quotes, APA 7 uses a ≥40-word threshold (indented, unquoted, citation after terminal punctuation); IEEE has no fixed threshold — use judgment and match your target venue's template. In CS, prefer paraphrase + cite over direct quotes — direct quotes are rare in CS papers and draw reviewer attention.

**Common knowledge is narrow.** In a thesis or paper, "everyone in the field knows this" is not a license to skip citation. When in doubt, cite.

---

## Structure: IMRaD and its CS variants

Most CS papers and theses follow IMRaD or a CS-specific variant (Introduction, Background, Approach, Evaluation, Related Work, Conclusion). Use whichever matches the target venue.

### Introduction — the single most important section

Reviewers decide on your paper in the Introduction. It must, in order:

1. **Open with one short definitional sentence** that situates the object. Examples from peer-reviewed papers:
   - "Consensus algorithms allow a collection of machines to work as a coherent group..." (Raft)
   - "The Topology and Orchestration Specification for Cloud Applications (TOSCA [6]) is an OASIS standard..." (Winery)
   - Expand acronyms in full on first use, with the citation embedded at the name.

2. **Establish context and motivation** with cited, quantified anchors. Never say "limited portability" — say "only 43% of features are portable across engines [15]". Every qualitative claim should be anchored to a number or a citation.

3. **Pivot to the gap** using an explicit transition: `Unfortunately, ...`, `However, ...`, `Despite this, ...`. State what is missing, what is broken, or what tension exists. This pivot is near-universal in peer-reviewed CS writing.

4. **State the contribution explicitly.** Either a single sentence (`The major contributions of this work are ...` — MapReduce style) or a bulleted/enumerated list (`Our contributions are: (i) ...; (ii) ...; (iii) ...` — Düllmann, Ivanchikj, Raft style). Never leave contributions implicit. Peyton Jones: "nail your contributions to the wall."

5. **Roadmap paragraph** as the last paragraph: `The remainder of this paper is organized as follows. Section 2 ... Section 3 ...`. Expected by LNCS/Springer/IEEE reviewers; omit at your peril.

### Background / Related Work

- Open by tying prior work to *your* goal, not by listing papers chronologically.
- Use explicit delta-statements: `Our work differs from [3] by (i) considering a broader class of models, (ii) ...`. Avoid the lazy "many works exist but none do X."
- Put Related Work at the end, not after the Introduction, unless the venue requires otherwise (Peyton Jones). It should not block the reader from your idea.

### Methods / Approach

- **Reproducibility is the goal.** Another researcher must be able to replicate your work from this section plus the references.
- Describe materials, procedures, data sources, analysis methods.
- Justify choices — why this method over alternatives? Cite the alternatives.
- State limitations of the methodology honestly.
- Enumerate and label design decisions: `The second design decision was to ...` (Ivanchikj style). This makes rationales auditable.
- Situate the contribution in a lifecycle/architecture figure early (Kopp, Düllmann). A diagram on the first substantive page pre-empts half of reviewer confusion.

### Results / Evaluation

- **Present findings without interpretation.** Save "what this means" for Discussion.
- Use tables and figures for complex data — never describe in prose what a table shows more clearly (Whitesides).
- Report effect sizes, confidence intervals, and context — not just p-values.
- Report negative results too. Publication bias harms science.
- Classify each claim's validation type: analysis, evaluation, experience, or example (Shaw). Validation by persuasion alone is insufficient.

### Discussion

- Interpret results in context of prior work.
- Address contradictions with prior research honestly.
- Acknowledge limitations explicitly — this is a strength, not a weakness.
- Suggest future directions only if they follow logically from your findings. `Future work is needed` without specifying what is an empty sentence.

### Conclusion

- Summarize without verbatim repetition of the introduction.
- Do not overclaim. Scope-check every "this shows / proves / implies" against the actual evidence.
- No generic `The future looks bright` closers.

---

## Citation style: IEEE (CS default)

- Numeric, bracketed: `[1]`, `[2]`, `[3]`, numbered in order of first appearance.
- Reuse the same number on subsequent mentions.
- Range: `[1]–[3]` for three consecutive.
- Multiple sources: IEEE Transactions style prefers separate brackets `[1], [3], [7]`; some venues accept `[1, 3, 7]`. Follow the target venue's template.
- The bracketed number is grammatically equivalent to a noun: `as shown in [3]` or `Smith [3] showed`.
- Reference list ordered by first citation in text, not alphabetically.
- Every in-text `[N]` must resolve to a reference list entry and vice versa.

ACM style (numeric or author-year) and APA (author-year, default in social sciences) are the main alternatives. Pick one per document and apply it consistently.

---

## Style rules drawn from Zobel and peer-reviewed CS

### Clarity over complexity
- Short, direct sentences. Academic writing is not fancy writing (Zobel).
- `We found that X increases Y by 30%`, not `Our investigation revealed a statistically significant positive correlation between X and Y variables`.
- Define each technical term once, precisely, and use it consistently throughout. No synonyms for the same concept (Shaw).
- Sentences rarely exceed ~25 words in peer-reviewed CS. Long sentences are broken by enumerations or em-dashes, not nested clauses.

### Paragraph construction
- One claim per paragraph. Topic sentence first, then support, evidence, citation.
- Paragraph template (Kopp/IAAS style, observed repeatedly): goal (`To enable X, ...`) → mechanism (`we have developed Y, which ...`) → consequence (`Thus, ...`).

### Hedging — calibrated, not excessive
Appropriate hedging signals epistemic honesty:
- `The results suggest...` (not proven beyond doubt)
- `This may indicate...` (tentative interpretation)
- `One possible explanation is...` (speculation clearly marked)

Over-hedging signals nothing: `It could potentially possibly be argued that this might have some effect...` — cut to `This may affect outcomes.`

### Tense conventions
- **Present tense:** established facts, your arguments, general truths (`X causes Y`, `We argue that ...`).
- **Past tense:** your specific methods and results (`We measured ...`, `Participants reported ...`).
- **Present perfect:** literature review (`Several studies have shown ...`).

### First person is fine
`We propose`, `We present`, `We designed` is standard in peer-reviewed CS (Vaswani, MapReduce, Raft, Kopp). Do not retreat to clumsy passive voice to sound "objective".

### Banned or suspect phrasing
- Vague quantifiers without evidence: `many`, `often`, `most systems`, `a wide range of`.
- Unsupported superlatives: `optimal`, `best`, `state-of-the-art`, `the most important`.
- Anthropomorphism: `the system believes`, `the algorithm wants to`.
- Exclamation marks — banned (Zobel).
- Inconsistent hyphenation and capitalization of technical terms.
- Rhetorical self-questions (`What does this mean? It means ...`).
- Stakes inflation (`groundbreaking`, `revolutionary`, `paradigm-shifting`).
- Throat-clearing openers (`In today's fast-paced world ...`, `As researchers, we all know ...`).

### Common AI tells in academic text
- Sweeping claims without evidence.
- Fabricated or vague citations.
- Uniform sentence length and paragraph structure.
- Overly balanced `on one hand / on the other hand` constructions.
- Generic conclusions (`Future research is needed` without specifying what).
- Superlatives without comparative evidence.
- Dense em-dash usage replacing commas and parentheses.

---

## CS-specific conventions

- **Abstract = problem → gap → mechanism → headline result.** Prefer at least one quantitative anchor (Bischof/Kopp 2009, Düllmann 2021 `70%`, Friedrich 2011 `77%`, Ivanchikj 2022 `77 ms average`). Pure-theory and vision papers are the exception — there, the headline is the theorem or claim itself.
- **Figures introduced at the end of the explanatory sentence**, parenthetically: `... (see Fig. 1)` or `as shown in Figure 1`. Never `In Figure 1 we see ...`.
- **Contribution list** as `(i)...(ii)...(iii)...` or a bulleted block with parallel verbs (`We define / We describe / We illustrate`).
- **`e. g.,`** and **`i. e.,`** with a thin space (`\,`) and a trailing comma — Springer LNCS / German typographic convention, consistently used in Kopp-coauthored work. Mixing `eg` or `e.g.,` (no thin space) is a drafting tell.
- **Problem pivots** using `Unfortunately, ...` or `However, ...` at paragraph start (Raft, Wagner/Kopp, TOSCA Light).
- **Scoping a subset of a standard** should cite zur Muehlen & Recker 2008 if BPMN is involved — that is the community convention.
- **Bidirectional / round-trip mapping** claims should be stated explicitly and early (Bischof/Kopp 2009 template).

---

## Kopp-style notes (for work supervised by Dr. Oliver Kopp)

Patterns observed across Winery (ICSOC 2013), BPELscript (SEAA 2009), and Wagner/Breitenbücher/Leymann (CLOSER 2016, Kopp-adjacent):

- Opens the Introduction by expanding the central acronym in full, followed immediately by its bracketed citation: `The Topology and Orchestration Specification for Cloud Applications (TOSCA [6]) is ...`.
- Uses inline `(i) ... (ii) ...` and `(1) ... (2) ... (3) ...` enumerations to preemptively structure definitions.
- Uses `e. g.,` and `i. e.,` with thin space, consistently (Springer LNCS convention).
- Pivots with `Unfortunately, ...` or `However, ...` at paragraph start.
- Contributions introduced with `In this paper, we present / In this work, we present`, often followed by a bulleted list with parallel verbs.
- Figures referenced at end of sentence: `(see Fig. 1)`.
- Paragraph template: goal → mechanism → consequence.
- Dense inline citation style: multiple adjacent bracketed refs at clause boundaries, never floating at paragraph ends.
- Related Work often merged as `Background & Related Work`, opening with a roadmap of subsections.
- Short-to-medium sentence length throughout (see *Clarity over complexity* above).

When writing for a Kopp-supervised thesis or paper, prefer this style by default.

---

## Mandatory verification workflow

Before any scientific text is finalized, run every single one of these checks. None are optional.

1. **Citation-mark audit.** Re-read every sentence. For each one, ask: *does this sentence attribute a claim, number, method, definition, or named concept to anyone other than us?* If yes, is there an inline citation in that sentence? If not, add one or delete the sentence. There is no third option.
2. **Citation existence check.** For every `[N]`, confirm the paper exists (DOI, arXiv, venue proceedings). Open it.
3. **Citation accuracy check.** For every `[N]`, read at least the abstract plus the section you are citing. Does the source actually support the claim? If not, fix the claim or the citation.
4. **Causation vs. correlation.** For every causal claim (`X causes Y`, `X leads to Y`, `X improves Y`), confirm the cited study actually demonstrates causation, not just correlation.
5. **Statistic check.** For every number, confirm it is accurate and in the correct context. Report effect sizes and confidence intervals where possible.
6. **Term consistency check.** For each technical term, grep the document. Is it used consistently? Are there accidental synonyms?
7. **Contribution scope check.** Re-read the contributions list. Does every contribution appear in the paper with corresponding evidence? Does the paper claim anything not in that list?
8. **Reviewer overclaim check.** Re-read the Discussion and Conclusion. Does any sentence claim more than the evidence supports?
9. **Reference list integrity.** Every `[N]` in text has a reference entry. Every reference entry is cited at least once. No orphans on either side.
10. **No-secondary-citation check.** For every citation, confirm you read the original source, not a citation in someone else's paper.
11. **Self-plagiarism check.** Confirm no sentence is lifted from your own prior work without a self-citation.
12. **Paragraph sanity.** For each paragraph: is there one claim? Does the topic sentence announce it? Is the evidence present?

If any check fails, fix it before continuing. This workflow is the difference between a passing thesis and an embarrassed supervisor.

---

## Thesis-specific mechanics

For bachelor's/master's theses (especially at German universities):

- **Declaration of originality / Eidesstattliche Erklärung.** Non-negotiable at Uni Hamburg and most German universities. The exact wording is prescribed by the faculty — use the official template, do not paraphrase.
- **AI-assistance disclosure.** Uni Hamburg and most German CS faculties now require explicit disclosure of LLM/AI tool use in theses, including which tools and for what purposes. Check your faculty's current policy and disclose honestly. Omitting disclosure is an integrity violation.
- **Reference management.** Use BibTeX with a curated `.bib` file. A clean `.bib` (entries copied from the publisher's official BibTeX export, not typed by hand) is the practical antidote to fabricated citations. Verify every entry against the publisher page.
- **Figure and table captions.** LNCS/IEEE convention: figure captions go *below* the figure; table captions go *above* the table. Number figures and tables in one sequence each (Fig. 1, Fig. 2, ...; Table 1, Table 2, ...).
- **Cross-references.** Every figure, table, section, and equation must be referenced at least once in the prose. Orphan figures are a reviewer red flag.
- **Page limits and word counts.** Check your faculty's regulations (Prüfungsordnung) for formal requirements — page limits, margin rules, font, mandatory sections.

---

## Sources

The rules and patterns above are distilled from:

- **Zobel, J.** *Writing for Computer Science*, 3rd ed., Springer, 2014. https://link.springer.com/book/10.1007/978-0-85729-422-7
- **Peyton Jones, S.** *How to write a great research paper*. https://simon.peytonjones.org/great-research-paper/
- **Shaw, M.** "Writing Good Software Engineering Research Papers," ICSE 2003. https://www.cs.cmu.edu/~Compose/shaw-icse03.pdf
- **Whitesides, G. M.** "Writing a paper," *Advanced Materials* 16(15), 2004 — chemistry-origin but widely applied across STEM. https://www.gmwgroup.harvard.edu/publications/whitesides-group-writing-paper
- **IEEE Editorial Style Manual and Reference Guide.** https://journals.ieeeauthorcenter.ieee.org/your-role-in-article-production/ieee-editorial-style-manual/
- **ACM Policy on Plagiarism, Misrepresentation, and Falsification.** https://www.acm.org/publications/policies/plagiarism-overview
- **APA Style 7th edition** — paraphrasing and citation mechanics. https://apastyle.apa.org/style-grammar-guidelines/citations/paraphrasing

Patterns observed in peer-reviewed CS papers used as exemplars:

- Vaswani et al., "Attention Is All You Need," NeurIPS 2017.
- Dean & Ghemawat, "MapReduce: Simplified Data Processing on Large Clusters," OSDI 2004.
- Ongaro & Ousterhout, "In Search of an Understandable Consensus Algorithm (Raft)," USENIX ATC 2014.
- Kopp, Binz, Breitenbücher, Leymann, "Winery — A Modeling Tool for TOSCA-based Cloud Applications," ICSOC 2013.
- Bischof, Kopp, van Lessen, Leymann, "BPELscript: A Simplified Script Syntax for WS-BPEL 2.0," SEAA 2009.
- Düllmann, Kabierschke, van Hoorn, "StalkCD: A Model-Driven Framework for Interoperability and Analysis of CI/CD Pipelines," SEAA 2021.
- Ivanchikj, Serbout, Pautasso, "Live Process Modeling with the BPMN Sketch Miner," SoSyM 2022.
- zur Muehlen & Recker, "How Much Language Is Enough? Theoretical and Practical Use of the BPMN," CAiSE 2008.
- Compagnucci, Corradini, Fornari, Re, "A Study on the Usage of the BPMN Notation...," BISE 2024.
- Friedrich, Mendling, Puhlmann, "Process Model Generation from Natural Language Text," CAiSE 2011.

Verify each source against its publisher page before citing in your own work.
