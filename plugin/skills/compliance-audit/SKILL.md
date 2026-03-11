---
name: compliance-audit
description: "Security compliance validation against GDPR, HIPAA, SOC 2, PCI-DSS, and ISO 27001 frameworks. Data classification, access control audit, encryption verification, and regulatory checklist generation. Use only when explicitly requested."
argument-hint: "<framework: gdpr | hipaa | soc2 | pci-dss | iso27001 | all>"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Grep, Glob
---

# Compliance Audit

Systematic compliance validation against regulatory frameworks. This skill analyzes code, configuration, and infrastructure for compliance gaps.

**This skill is invoked only on explicit request.** It is not part of the standard pipeline.

## Frameworks

### GDPR (General Data Protection Regulation)

Data protection for EU residents.

#### Checklist
- [ ] **Data inventory**: All PII fields are documented (name, email, IP, location, etc.)
- [ ] **Lawful basis**: Each data collection has documented legal basis (consent, contract, legitimate interest)
- [ ] **Consent management**: Consent is recorded with timestamp, scope, and withdrawal mechanism
- [ ] **Right to erasure**: User data can be fully deleted on request (including backups within retention period)
- [ ] **Right to export**: User data can be exported in machine-readable format (JSON, CSV)
- [ ] **Data minimization**: Only necessary data is collected — no "just in case" fields
- [ ] **Encryption**: PII encrypted at rest (AES-256) and in transit (TLS 1.2+)
- [ ] **Access logging**: All PII access is logged with who, when, what, why
- [ ] **Breach notification**: Process exists to notify authorities within 72 hours
- [ ] **DPA with processors**: Data Processing Agreements with all third-party services handling PII
- [ ] **Privacy policy**: Accurate, up-to-date, accessible

#### Code Patterns to Check
```
# Search for PII handling
grep -r "email\|phone\|address\|birth\|ssn\|passport" --include="*.{ts,py,java,go}"

# Check for unencrypted PII storage
grep -r "plaintext\|plain_text\|raw_email" --include="*.{ts,py,java,go}"

# Check for PII in logs
grep -r "log.*email\|log.*password\|log.*token\|console\.log.*user" --include="*.{ts,py,java,go}"
```

### HIPAA (Health Insurance Portability and Accountability Act)

Protected Health Information (PHI) for US healthcare.

#### Checklist
- [ ] **PHI identification**: All PHI fields documented (medical records, diagnoses, treatment, insurance)
- [ ] **Access controls**: Role-based access with minimum necessary principle
- [ ] **Audit trail**: All PHI access logged immutably (who, when, what, from where)
- [ ] **Encryption**: PHI encrypted at rest AND in transit, key management documented
- [ ] **Business Associate Agreements**: BAAs with all vendors handling PHI
- [ ] **Backup and recovery**: PHI backups encrypted, tested, with documented recovery procedure
- [ ] **Workforce training**: Documentation that all PHI handlers completed training
- [ ] **Incident response**: Breach response plan with notification within 60 days
- [ ] **Physical safeguards**: Server access controls, workstation security (if self-hosted)
- [ ] **Automatic logoff**: Sessions timeout after inactivity

### SOC 2 (Service Organization Control)

Trust service criteria for service providers.

#### Checklist by Category

**Security (Common Criteria)**
- [ ] MFA enabled for all infrastructure access
- [ ] Network segmentation between environments
- [ ] Vulnerability scanning (automated, regular)
- [ ] Incident response plan documented and tested
- [ ] Change management process (PR reviews, approval gates)

**Availability**
- [ ] Uptime SLOs defined and monitored
- [ ] Disaster recovery plan documented and tested
- [ ] Backup procedures automated and verified
- [ ] Capacity planning process exists

**Processing Integrity**
- [ ] Input validation on all user-facing endpoints
- [ ] Data reconciliation checks for critical processes
- [ ] Error handling prevents data corruption

**Confidentiality**
- [ ] Data classification policy (public, internal, confidential, restricted)
- [ ] Encryption at rest for confidential data
- [ ] Access reviews conducted regularly (quarterly minimum)
- [ ] Secrets management (vault, not .env files)

**Privacy**
- [ ] Privacy notice accurate and accessible
- [ ] Data retention policies defined and automated
- [ ] Data disposal procedures documented

### PCI-DSS (Payment Card Industry Data Security Standard)

Cardholder data protection.

#### Checklist
- [ ] **Never store CVV/CVC** after authorization — ever
- [ ] **Encrypt card numbers** at rest (AES-256) or tokenize via payment processor
- [ ] **Mask card numbers** in display (show last 4 only)
- [ ] **No card data in logs**: Grep all logging for card number patterns
- [ ] **Network segmentation**: Cardholder data environment isolated
- [ ] **Strong access control**: Need-to-know basis, unique IDs, MFA
- [ ] **Regular testing**: Vulnerability scans, penetration tests
- [ ] **Use payment processor SDK**: Don't handle raw card data — use Stripe Elements, Braintree Drop-in, etc.

## Process

### 1. Scope Definition
- Which framework(s) apply?
- What data types are handled?
- What components touch regulated data?

### 2. Code Scan
- Search for PII/PHI/cardholder data patterns in code, logs, and config
- Check encryption configuration
- Verify access control implementation
- Audit logging completeness

### 3. Infrastructure Review
- Encryption at rest and in transit
- Network segmentation
- Secret management
- Backup and recovery procedures

### 4. Gap Analysis
- Map findings to specific framework requirements
- Classify gaps by severity (critical, high, medium, low)
- Prioritize remediation

## Output

Provide:
- **Compliance score**: Requirements met / total requirements per framework
- **Critical gaps**: Issues that would fail an audit
- **Remediation plan**: Ordered list of fixes with effort estimates
- **Evidence inventory**: Documentation and artifacts that demonstrate compliance
