---
name: business-analytics
description: "KPI framework design, dashboard architecture, data storytelling, cohort analysis, and business metrics. OKR integration, A/B testing design, and industry-specific analytics (SaaS, marketplace, e-commerce). Use only when explicitly requested."
argument-hint: "<task: kpi-design | dashboard | data-story | cohort-analysis | ab-test | metrics-audit>"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# Business Analytics

Frameworks for measuring what matters, building dashboards that drive decisions, and telling stories with data.

**Invoked only on explicit request.**

## KPI Framework Design

### Dashboard Hierarchy

| Level | Audience | Cadence | Example |
|-------|----------|---------|---------|
| **Strategic** | Exec/Board | Monthly/Quarterly | ARR, burn, NDR, market share |
| **Tactical** | Department leads | Weekly/Monthly | Pipeline, CAC, sprint velocity |
| **Operational** | Team/IC | Daily/Real-time | Uptime, error rate, queue depth |

### Department Metrics

**Sales**
- MRR / ARR, pipeline value, win rate, sales cycle length, quota attainment
- SQL: `SUM(mrr) OVER (ORDER BY month) AS running_arr`

**Marketing**
- CAC, MQL → SQL conversion rate, CAC payback period, channel ROI
- SQL: `marketing_spend / COUNT(new_customers) AS cac`

**Product**
- DAU/MAU, stickiness ratio (DAU/MAU), NPS, feature adoption %, retention curves
- Activation: % of signups completing key action within first 7 days

**Engineering**
- Deployment frequency, lead time, change failure rate, MTTR (DORA metrics)

**Finance**
- Gross margin, net profit margin, operating efficiency, cash runway

### SMART KPIs
Every KPI must be: **S**pecific, **M**easurable, **A**chievable, **R**elevant, **T**ime-bound

### Anti-Patterns (Vanity Metrics)
- Total users without retention
- Page views without engagement
- Downloads without activation
- Revenue without unit economics

## Data Storytelling

### Narrative Structure

```
Hook → Context → Rising Action → Climax → Resolution → Call to Action
```

**Three pillars**: Data (evidence) + Narrative (meaning) + Visuals (clarity)

### Headline Formula
`[Specific number] + [Business impact] + [Actionable context]`

Example: "Customer churn dropped 23% after onboarding redesign, saving $180K ARR quarterly"

### Visualization Techniques
- **Progressive reveal**: Simple overview → layered detail on drill-down
- **Contrast**: Before/after, this quarter vs last
- **Annotation**: Highlight key events on time series (product launch, outage, campaign)

### Transition Phrases
- Building: "This leads us to ask..."
- Insight: "The data reveals..."
- Action: "Based on this analysis, we recommend..."

## Cohort Analysis

### Retention Cohort SQL Pattern
```sql
WITH cohorts AS (
  SELECT user_id,
         DATE_TRUNC('month', created_at) AS cohort_month
  FROM users
),
activity AS (
  SELECT user_id,
         DATE_TRUNC('month', event_at) AS activity_month
  FROM events
)
SELECT
  c.cohort_month,
  DATE_DIFF('month', c.cohort_month, a.activity_month) AS months_since_signup,
  COUNT(DISTINCT a.user_id)::FLOAT / COUNT(DISTINCT c.user_id) AS retention_rate
FROM cohorts c
LEFT JOIN activity a ON c.user_id = a.user_id
GROUP BY 1, 2
ORDER BY 1, 2;
```

### Revenue Cohort
Track MRR contribution by signup month to understand:
- Are newer cohorts more valuable than older ones?
- Where does expansion revenue come from?
- When does churn stabilize (the "smile curve")?

## A/B Testing Design

### Checklist
1. **Hypothesis**: "Changing X will improve Y by Z% because [reason]"
2. **Primary metric**: One metric that determines success
3. **Guardrail metrics**: Metrics that must NOT degrade
4. **Sample size**: Calculate before starting (not after)
5. **Duration**: Minimum 1-2 business cycles (avoid day-of-week effects)
6. **Segmentation**: Pre-define segments to analyze (new vs returning, mobile vs desktop)

### Statistical Requirements
- Significance level: p < 0.05 (95% confidence)
- Power: 80% minimum (detect effect of expected size)
- No peeking: Don't stop early on promising results (inflates false positive rate)
- Multiple testing: Bonferroni correction if testing multiple variants

## Industry-Specific Metrics

### SaaS
MRR, ARR, churn (logo + revenue), NDR, CAC, LTV, quick ratio (new + expansion / contraction + churn)

### Marketplace
GMV, take rate, liquidity (% of listings transacted), buyer/seller ratio, repeat rate

### E-commerce
AOV, conversion rate, cart abandonment, return rate, CLV, inventory turnover

## Output
- Metrics definition document with formulas and data sources
- Dashboard wireframe with KPI placement
- SQL queries for each metric
- Interpretation guide (what does good/bad look like?)
