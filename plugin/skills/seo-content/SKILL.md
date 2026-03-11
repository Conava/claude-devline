---
name: seo-content
description: "SEO content planning, writing, and auditing. Topic cluster architecture, keyword-optimized articles with E-E-A-T signals, content calendars, and quality scoring. Use only when explicitly requested."
argument-hint: "<task: topic-clusters | outline | write | audit>"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# SEO Content

Structured content creation and optimization with measurable quality criteria. Not generic writing advice — specific frameworks with numbers.

**Invoked only on explicit request.**

## Topic Cluster Architecture

### Structure
```
Pillar Page (comprehensive guide, 3000-5000 words)
├── Supporting Article (subtopic deep dive, 1500-2500 words)
├── Supporting Article
├── How-To Guide (step-by-step, 1000-2000 words)
├── FAQ Page (structured data, 800-1500 words)
├── Comparison Post (vs competitor/alternative, 1500-2500 words)
└── Case Study (real example, 1000-2000 words)
```

### Internal Linking
- Pillar ↔ every supporting article (bidirectional)
- Supporting articles link to each other where relevant
- Anchor text = target keyword of destination page
- Every page within 3 clicks of homepage

## Content Outline

### Process
1. **Primary keyword**: One main keyword per page
2. **Search intent**: Informational / Navigational / Commercial / Transactional
3. **Competitor analysis**: Read top 3-5 ranking pages, identify gaps
4. **Header structure**: H1 (primary keyword) → H2s (subtopics) → H3s (details)
5. **Content gap**: What do competitors miss that you can cover?

## Writing Framework

### Technical Specs
| Element | Target |
|---------|--------|
| Keyword density | 0.5-1.5% for primary keyword |
| Reading level | Grade 8-10 (Flesch-Kincaid) |
| Paragraph length | 2-3 sentences max |
| Introduction | 50-100 words: hook, value prop, primary keyword |
| Meta title | 50-60 characters, primary keyword near start |
| Meta description | 150-160 characters, include keyword + CTA |

### E-E-A-T Signals (Include In Every Article)

**Experience**: First-hand examples, "in my experience", process documentation, screenshots/photos of real work

**Expertise**: Specific data points with sources, technical terminology used correctly, comprehensive coverage of edge cases

**Authority**: External citations from authoritative sources, expert quotes, references to published research

**Trust**: Author bio with credentials, publication date, "last updated" date, fact-check citations, clear disclosure of affiliations

### Article Structure
```
Title (H1): Primary keyword + compelling modifier
Introduction: Hook → value prop → what you'll learn
Body:
  H2: Major subtopic 1
    H3: Detail / example
    H3: Detail / example
  H2: Major subtopic 2
    ...
  H2: FAQ (structured data eligible)
Conclusion: Summary + CTA
```

## Content Audit

### Quality Scorecard (1-10 per category)

| Category | What to Check |
|----------|---------------|
| **Depth** | Does it fully answer the search query? Missing subtopics? |
| **E-E-A-T** | Author credentials visible? Sources cited? Original insights? |
| **Readability** | Grade level appropriate? Short paragraphs? Scannable headers? |
| **Keywords** | Primary keyword in title, H1, first 100 words, meta? Density in range? |
| **Freshness** | Statistics current? Examples relevant? Technology up-to-date? |
| **Technical** | Schema markup present? Images optimized? Page speed acceptable? |

### Content Refresh Priorities

| Priority | Trigger |
|----------|---------|
| **Immediate** | Ranking dropped 3+ positions, outdated facts, high-traffic page declining |
| **This month** | Stagnant 6+ months, competitor published better version, missing recent developments |
| **Quarterly** | Update statistics, add new case studies, refresh examples, add FAQ |

### Cannibalization Check
When multiple pages target the same keyword:
1. Identify which page ranks best
2. Consolidate content into the winner
3. 301 redirect losers to the winner
4. Update internal links

## Schema Markup

Use structured data for rich results:
- `Article`: For blog posts and articles
- `FAQ`: For frequently asked questions sections
- `HowTo`: For step-by-step guides
- `BreadcrumbList`: For site navigation
- `Review`: For product/service reviews

## Output
- Topic cluster map with keyword assignments
- Content outlines with header structure and word count targets
- Full articles meeting the technical specs above
- Audit reports with scorecard and prioritized improvements
