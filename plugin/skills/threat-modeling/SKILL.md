---
name: threat-modeling
description: "STRIDE-based threat modeling for system design. Analyzes attack surfaces, data flows, trust boundaries, and generates threat matrices with mitigations. Use only when explicitly requested for security-critical design."
argument-hint: "<system or component to model>"
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# Threat Modeling

Systematic identification of security threats during the design phase — before code is written. Based on the STRIDE methodology.

**Invoked only on explicit request.**

## Process

### 1. Define Scope

- What system/component are we modeling?
- What are the trust boundaries? (user ↔ server, service ↔ service, internal ↔ external)
- What data flows across boundaries?
- What are the most valuable assets? (user data, credentials, financial data, business logic)

### 2. Data Flow Diagram

Map how data moves through the system:

```
[User] → HTTPS → [API Gateway] → internal → [Auth Service] → internal → [Database]
                        ↓
                   [Cache (Redis)]
                        ↓
               [Background Worker] → external → [Email Service]
```

At each boundary crossing, threats exist.

### 3. STRIDE Analysis

For each component and data flow, systematically check:

| Threat | Question | Example |
|--------|----------|---------|
| **S**poofing | Can someone pretend to be someone else? | Forged JWT, stolen API key, session hijacking |
| **T**ampering | Can someone modify data they shouldn't? | Man-in-the-middle, SQL injection, parameter manipulation |
| **R**epudiation | Can someone deny performing an action? | Missing audit logs, unsigned transactions |
| **I**nformation Disclosure | Can someone access data they shouldn't? | Verbose errors, unencrypted storage, IDOR |
| **D**enial of Service | Can someone make the system unavailable? | Resource exhaustion, algorithmic complexity attacks, unbounded queries |
| **E**levation of Privilege | Can someone gain higher access than intended? | Missing auth middleware, insecure deserialization, path traversal |

### 4. Risk Assessment

For each identified threat:

| Factor | Scale | Description |
|--------|-------|-------------|
| **Likelihood** | 1-5 | How likely is this to be exploited? |
| **Impact** | 1-5 | How bad is it if exploited? |
| **Risk Score** | L × I | Priority for mitigation |

### 5. Mitigations

For each high-risk threat (score >= 12), define:
- **Mitigation**: What control prevents or reduces this threat
- **Implementation**: Specific code/config change needed
- **Verification**: How to confirm the mitigation works
- **Residual risk**: What risk remains after mitigation

## Common Mitigations by STRIDE Category

| Threat | Mitigations |
|--------|------------|
| Spoofing | MFA, strong authentication, certificate pinning, API key rotation |
| Tampering | Input validation, HMAC signatures, checksums, parameterized queries |
| Repudiation | Audit logging, digital signatures, immutable event logs |
| Info Disclosure | Encryption (AES-256 rest, TLS 1.2+ transit), access controls, data masking |
| DoS | Rate limiting, input size limits, circuit breakers, auto-scaling |
| Privilege Escalation | Least privilege, RBAC, middleware on all routes, input sanitization |

## Output

Provide:
- **Data flow diagram**: Components, data flows, trust boundaries
- **Threat matrix**: Each threat with STRIDE category, likelihood, impact, risk score
- **Mitigation plan**: Ordered by risk score, with specific implementation guidance
- **Assumptions**: Security assumptions that must hold (e.g., "TLS termination at load balancer")
