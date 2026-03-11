---
name: hr-legal
description: "HR operations and legal document generation. Structured hiring (JDs, interview rubrics, scorecards), onboarding plans, PTO policies, performance management, and legal templates (privacy policies, ToS, DPA). Use only when explicitly requested."
argument-hint: "<task: job-description | interview-kit | onboarding | pto-policy | performance-review | privacy-policy | terms-of-service>"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# HR & Legal Operations

Practical HR playbooks and legal templates with jurisdiction awareness. Not legal advice — templates for review by qualified counsel.

**Invoked only on explicit request.**

**Disclaimer**: All outputs are templates requiring review by qualified legal/HR professionals. Jurisdiction-specific requirements must be validated.

## Hiring

### Job Description Template
```
{{CompanyName}} — {{RoleTitle}}

Mission: [What this role exists to accomplish — not a task list]

What you'll do in your first 90 days:
1. [Specific outcome, not activity]
2. [Specific outcome]
3. [Specific outcome]

Must-have:
- [Skill/experience with specific level]
- [Maximum 5-7 items]

Nice-to-have:
- [Non-essential but valued]

Compensation: ${{MinPay}}-${{MaxPay}} + [benefits summary]

{{CompanyName}} is an equal opportunity employer.
```

### Structured Interview Kit

**Rubric design** (per competency):
| Score | Anchor |
|-------|--------|
| 1 | No evidence of competency |
| 2 | Limited evidence, significant gaps |
| 3 | Meets expectations for the level |
| 4 | Exceeds expectations, strong examples |
| 5 | Exceptional, could teach others |

**Question types** (8-12 per interview):
- **Behavioral** (past): "Tell me about a time you [situation]. What did you do?"
- **Situational** (hypothetical): "How would you handle [scenario]?"
- **Technical** (skills): Relevant to must-haves in JD

**Panel structure**: Each interviewer covers different competencies. No duplication. Debrief with scorecard comparison before discussion to prevent anchoring.

### Bias Mitigation
- Standardized questions (same for all candidates)
- Score independently before group discussion
- Diverse interview panel
- Objective rubric anchors (not "culture fit")
- Blind resume review where possible

## Onboarding

### 30/60/90 Day Plan

| Period | Focus | Deliverables |
|--------|-------|-------------|
| Day 1-7 | Setup | IT access, payroll, compliance training, buddy assignment |
| Day 1-30 | Learn | Stakeholder introductions, process documentation, shadowing |
| Day 31-60 | Contribute | First independent deliverables, feedback checkpoint |
| Day 61-90 | Own | Full responsibility for role scope, formal review |

**Feedback loops**: Days 7 (setup issues?), 30 (learning gaps?), 90 (formal review).

**Metrics**: Time-to-productivity, new hire satisfaction (eNPS), 90-day retention rate.

## PTO & Leave Policy

### Template Elements
- Accrual model: Fixed annual grant vs. accrual rate per pay period
- Pro-rating: Mid-year hires receive proportional allocation
- Carry-over: Maximum days, expiration rules
- Minimum staffing: Coverage plan requirements
- **Jurisdiction prompt**: "What jurisdiction(s) does this apply to?" (always ask first)

## Performance Management

### Review Framework
1. **Competency matrix** by level (IC1-IC5, M1-M3)
2. **SMART goals**: Specific, Measurable, Achievable, Relevant, Time-bound
3. **Review packet**: Self-assessment + peer feedback + manager assessment
4. **Calibration**: Cross-team comparison to ensure fair scoring

### Performance Improvement Plan (PIP)
- Objective evidence only (metrics, incidents, documented feedback)
- Specific improvement targets with deadlines
- Support provided (training, mentoring, resources)
- Clear consequences if targets not met
- Regular check-ins (weekly minimum)

## Legal Templates

### Privacy Policy Checklist (GDPR/CCPA)
- [ ] Data collected (enumerate each type)
- [ ] Purpose for each data type
- [ ] Legal basis (consent, contract, legitimate interest)
- [ ] Data retention periods
- [ ] Third-party sharing (list processors)
- [ ] User rights (access, delete, export, opt-out)
- [ ] Contact information for requests
- [ ] Cookie policy
- [ ] Children's data handling (if applicable)
- [ ] International transfer mechanisms

### Terms of Service Essentials
- [ ] Acceptable use policy
- [ ] Account termination conditions
- [ ] Intellectual property ownership
- [ ] Limitation of liability
- [ ] Dispute resolution (arbitration vs. court, jurisdiction)
- [ ] Modification notification process
- [ ] Governing law

### Data Processing Agreement (DPA)
- [ ] Processing scope and purpose
- [ ] Data categories and subjects
- [ ] Processor obligations (security, breach notification, deletion)
- [ ] Sub-processor approval process
- [ ] Audit rights
- [ ] Cross-border transfer mechanisms (SCCs)

## Escalation Rules

**Always escalate to qualified counsel for:**
- Terminations and separations
- Protected leave (FMLA, disability, pregnancy)
- Immigration and work authorization
- Union/works council matters
- International employment across jurisdictions
- Discrimination or harassment complaints
- Data breach notification obligations
