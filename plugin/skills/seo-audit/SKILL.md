---
name: seo-audit
description: "SEO site audit: E-E-A-T scoring, keyword cannibalization detection, content freshness analysis, technical SEO checks, and authority building recommendations. Use only when explicitly requested."
argument-hint: "<task: eeat-audit | cannibalization | freshness | technical | full-audit>"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# SEO Audit

Analyze and improve search engine performance with structured scoring and prioritized recommendations.

**Invoked only on explicit request.**

## E-E-A-T Audit

### Scoring Framework (1-10 per signal)

**Experience Score**
- [ ] First-hand experience indicators (case studies, process docs, screenshots)
- [ ] Original research or data
- [ ] "I did this" language with specific details
- [ ] Unique insights not found elsewhere

**Expertise Score**
- [ ] Author page with credentials and bio
- [ ] Technical depth appropriate to topic
- [ ] Comprehensive coverage (no major gaps)
- [ ] Expert quotes or contributor content

**Authority Score**
- [ ] External links from authoritative sites
- [ ] Brand mentions in relevant publications
- [ ] Speaking, research, or published work
- [ ] Industry awards or certifications displayed

**Trust Score**
- [ ] Contact information accessible
- [ ] Privacy policy and terms of service
- [ ] HTTPS with valid certificate
- [ ] Reviews and testimonials
- [ ] Editorial guidelines and fact-checking process
- [ ] Clear disclosure of affiliations/sponsorships

### Enhancement Plan
For each score below 7, provide specific actions:
- What to add (content, pages, signals)
- Where to add it (specific pages/locations)
- Expected impact on score
- Implementation effort (low/medium/high)

## Keyword Cannibalization Detection

### Process
1. **Map keywords to pages**: For each target keyword, list all pages ranking for it
2. **Identify conflicts**: Multiple pages targeting the same primary keyword
3. **Assess intent**: Do the competing pages serve different search intents? If yes, they may coexist.

### Resolution Matrix

| Situation | Action |
|-----------|--------|
| Two pages, one clearly better | Consolidate content into winner, 301 redirect loser |
| Two pages, different intents | Differentiate keywords, adjust titles and H1s |
| Many pages, spread thin | Merge into one comprehensive page |
| Blog + product page | Keep both — different intent (informational vs transactional) |

### Prevention
- Keyword mapping spreadsheet: one primary keyword per page
- Pre-publish check: search site for target keyword before publishing
- Quarterly audit of keyword rankings by page

## Content Freshness Analysis

### Decay Signals
- Statistics older than 2 years
- Year references in titles (e.g., "Best Tools 2023" in 2026)
- Technology examples that are deprecated or superseded
- Broken external links
- Declining organic traffic over 3+ months

### Update Priority

| Priority | Criteria | Action |
|----------|----------|--------|
| **Critical** | High-traffic page losing rankings | Immediate comprehensive update |
| **High** | Outdated facts on indexed pages | Update within 1 week |
| **Medium** | Stagnant 6+ months, competitor updated | Update within 1 month |
| **Low** | Minor freshness improvements | Next quarterly refresh |

### Freshness Signals to Update
- `dateModified` in Article schema markup
- Updated publish date (with "last updated" visible)
- New internal links from recent content
- Fresh images and media
- Updated statistics and examples
- New FAQ entries

## Technical SEO Checklist

### On-Page
- [ ] Unique title tags (50-60 chars) with primary keyword
- [ ] Meta descriptions (150-160 chars) with keyword + CTA
- [ ] One H1 per page containing primary keyword
- [ ] Logical H2-H6 hierarchy (no skipped levels)
- [ ] Image alt text descriptive and keyword-relevant
- [ ] Internal links with descriptive anchor text
- [ ] Canonical tags on all pages

### Performance
- [ ] Core Web Vitals passing (LCP < 2.5s, FID < 100ms, CLS < 0.1)
- [ ] Images compressed and served in modern formats (WebP/AVIF)
- [ ] CSS/JS minified and deferred where possible
- [ ] Mobile-responsive design

### Crawlability
- [ ] XML sitemap submitted and up-to-date
- [ ] robots.txt not blocking important pages
- [ ] No orphan pages (every page linked from at least one other)
- [ ] 301 redirects for moved/deleted pages
- [ ] No redirect chains (A → B → C should be A → C)

### Structured Data
- [ ] Schema markup validated (Google Rich Results Test)
- [ ] Article, FAQ, HowTo, BreadcrumbList as applicable
- [ ] No errors or warnings in schema validation

## Output
- Scorecard with current ratings per category
- Prioritized issue list (critical → high → medium → low)
- Specific remediation actions with expected impact
- Implementation checklist with estimated effort
