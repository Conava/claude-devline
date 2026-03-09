---
name: dx-audit
description: "Developer experience audit and optimization. Analyzes onboarding friction, workflow bottlenecks, repetitive manual steps, and tooling gaps. Suggests concrete improvements."
argument-hint: "[focus: onboarding | workflow | tooling | full]"
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# Developer Experience Audit

Analyze the development experience and identify friction points that slow down daily work. Focus on measurable improvements: time saved, steps eliminated, errors prevented.

## DX Principles

Good DX means:
- **Clone to running app in < 5 minutes** for any developer
- **Zero manual steps** that can be automated
- **Fast feedback loops**: tests, linting, type checking run quickly
- **Clear error messages** that tell you what to do, not just what went wrong
- **Consistent tooling** across the team

## Audit Areas

### 1. Onboarding Experience

Check how long it takes to go from `git clone` to a working development environment:

- [ ] README or setup guide exists and is accurate
- [ ] Dependencies install cleanly (`npm install`, `pip install`, etc.)
- [ ] Environment variables are documented with example `.env.example`
- [ ] Database setup/seeding is automated (not manual SQL scripts)
- [ ] All required tools are listed with version requirements
- [ ] IDE/editor configuration is shared (`.editorconfig`, `.vscode/settings.json`)
- [ ] `CLAUDE.md` exists with build/test/lint commands

**Measure**: Time from clone to first successful test run.

### 2. Workflow Efficiency

Identify repetitive manual steps:

- [ ] Build and test commands are short and memorable
- [ ] Hot reload / watch mode is configured for development
- [ ] Database migrations run automatically or with one command
- [ ] Code generation (types, schemas, mocks) is automated
- [ ] PR template exists with useful checklist
- [ ] Branch naming and commit format are enforced (not just documented)

**Measure**: Steps per common task (new feature, bug fix, PR review).

### 3. Feedback Speed

How fast do developers get feedback on their changes:

- [ ] Unit tests run in < 30 seconds locally
- [ ] Linting/formatting runs on save or pre-commit
- [ ] Type checking is fast enough to not interrupt flow
- [ ] CI/CD pipeline completes in < 10 minutes for PRs
- [ ] Error messages include enough context to fix without searching

**Measure**: Time from code change to pass/fail feedback.

### 4. Tooling Gaps

Identify missing automation:

- [ ] Pre-commit hooks for formatting and linting
- [ ] Git hooks for commit message format
- [ ] Makefile/Taskfile/package.json scripts for common operations
- [ ] Docker compose for local development environment
- [ ] Seed data scripts for development and testing
- [ ] Debug configurations (launch.json, debugger scripts)

### 5. Pain Points

Look for signs of friction in the codebase:

- Long, complex build commands in CI/CD that developers have to remember
- Manual steps documented in comments ("remember to run X after Y")
- Workaround scripts in developer home directories
- Inconsistent development setups causing "works on my machine"
- Slow tests that developers skip locally

## Output

Provide:

1. **DX Score**: Rate each area (onboarding, workflow, feedback, tooling) on 1-5 scale
2. **Quick Wins**: Changes that take < 1 hour and save time daily
3. **Medium Improvements**: Changes that take 1-4 hours for significant impact
4. **Strategic Improvements**: Larger investments for long-term DX
5. **Concrete Actions**: For each suggestion, specify exactly what to create/change

## Integration

This skill's findings can inform other plugin workflows:
- **Brainstorm**: Factor DX improvements into feature design
- **Plan**: Include DX tasks alongside feature tasks
- **Review**: Check that new code doesn't regress DX (e.g., adding manual steps, slow tests)
