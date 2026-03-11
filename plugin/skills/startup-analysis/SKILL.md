---
name: startup-analysis
description: "Market sizing (TAM/SAM/SOM), unit economics, financial modeling, competitive analysis, and investor-ready business planning. Uses real frameworks: Porter's Five Forces, Blue Ocean, cohort-based revenue modeling. Use only when explicitly requested."
argument-hint: "<task: market-sizing | financials | competitive | metrics | team-planning | full-business-case>"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# Startup & Business Analysis

Rigorous business analysis using validated frameworks. Not generic advice — specific methodologies with benchmarks, formulas, and investor expectations.

**Invoked only on explicit request.**

## Market Sizing (TAM/SAM/SOM)

### Three-Methodology Approach

Always triangulate with at least two methods. Results must be within 30% of each other.

| Method | How | Best For |
|--------|-----|----------|
| **Top-down** | Industry report total → geographic filters → segment filters | Quick estimate, sanity check |
| **Bottom-up** | Customer segment count × ARPU | Most credible for investors |
| **Value theory** | Problem cost × % solved × willingness-to-pay (10-30%) × addressable base | Novel markets without existing data |

**Industry-specific formulas:**
- SaaS: `Σ(Target Companies by Segment × ACV per Segment)`
- Marketplace: `GMV × take rate`
- Consumer: `Users × ARPU × frequency`

**Red flags:** TAM < $1B (too small for VC), SOM > 10% in 5 years for new entrants (unrealistic).

## Financial Modeling

### Cohort-Based Revenue

```
MRR = Σ(Cohort Size × Retention Rate × ARPU) + Expansion Revenue
```

### Cost Structure Benchmarks (SaaS)

| Category | Early Stage | Growth | Scale |
|----------|------------|--------|-------|
| COGS | 15-25% | 15-20% | 10-15% |
| S&M | 40-60% | 30-50% | 20-35% |
| R&D | 30-40% | 20-30% | 15-20% |
| G&A | 15-25% | 10-15% | 8-12% |

### Three Scenarios
- **Conservative**: CAC +25%, churn +20%, pricing -15%
- **Base**: Best estimates with documented assumptions
- **Optimistic**: Inverse of conservative adjustments

### Key Thresholds

| Metric | Target | Formula |
|--------|--------|---------|
| CAC payback | < 12 months | CAC / (ARPU × Gross Margin) |
| LTV:CAC | > 3.0 | (ARPU × Gross Margin × Avg Lifetime) / CAC |
| Burn multiple | < 2.0 | Net Burn / Net New ARR |
| Magic number | > 0.75 (ready to scale) | Net New ARR (Q) / S&M Spend (Q-1) |
| Rule of 40 | > 40% (best-in-class) | Revenue Growth % + Profit Margin % |
| NDR | > 100% (good), > 120% (best) | (Start MRR + Expansion - Contraction - Churn) / Start MRR |

### Sanity Checks
- Revenue growth: 3x Y2, 2x Y3 is aggressive but achievable
- Fully-loaded employee cost: base salary × 1.3-1.4
- Headcount should scale with revenue, not ahead of it

## Competitive Analysis

### Porter's Five Forces
Score each force 1-5, create intensity matrix:
1. Threat of new entrants (barriers to entry, capital requirements)
2. Bargaining power of suppliers (concentration, switching costs)
3. Bargaining power of buyers (price sensitivity, alternatives)
4. Threat of substitutes (performance-to-price, switching costs)
5. Competitive rivalry (number of competitors, growth rate, differentiation)

### Blue Ocean Framework
Identify factors to: **Eliminate** | **Reduce** | **Raise** | **Create**

Validate "lower cost + higher value" intersection.

### Sustainable Advantage Tests
- Can competitors copy in < 2 years?
- Does it matter to customers?
- Do you execute it better?
- Is it durable? (network effects, switching costs, economies of scale, brand, IP, regulatory)

## Stage-Specific Metrics

| Stage | Focus Metrics | Targets |
|-------|--------------|---------|
| Pre-seed | Retention, engagement, problem validation | Users returning weekly |
| Seed | MRR growth, unit economics baseline | 15-20% MoM MRR growth |
| Series A | ARR, LTV:CAC, burn, NDR | ARR 3-5x YoY, LTV:CAC > 3, burn < 2.0, NDR > 100% |

## Team Planning

| Stage | Size | Focus |
|-------|------|-------|
| Pre-seed | 2-5 | Founders code |
| Seed | 5-15 | Add engineering lead + first sales |
| Series A | 15-50 | 40% eng, 30% S&M, 10% success, 10% G&A, 10% product |

Hiring timelines: 8-12 weeks (mid-level), 12-16 weeks (senior), 2-3 months productivity ramp.

## Output Standards

- Cite all data sources with URLs and publication dates
- Document every assumption explicitly
- Provide conservative estimates as baseline
- Use placeholder variables: `{{CompanyName}}`, `{{Industry}}`, `{{Stage}}`
- Include implementation timeline with owners
