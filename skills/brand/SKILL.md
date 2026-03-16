---
name: brand
description: Brand voice, visual identity, messaging frameworks, asset management, brand consistency. Activate for "brand", "brand identity", "voice", "visual identity", "brand guidelines", "messaging framework", "brand consistency", branded content, tone of voice, marketing assets, brand compliance, style guides.
user-invocable: true
disable-model-invocation: false
---

# Brand

Brand identity, voice, messaging, asset management, and consistency frameworks.

## When to Use

- Brand voice definition and content tone guidance
- Visual identity standards and style guide development
- Messaging framework creation
- Brand consistency review and audit
- Asset organization, naming, and approval
- Color palette management and typography specs

## Subcommands

| Subcommand | Description | Reference |
|------------|-------------|-----------|
| `update` | Update brand identity — colors, typography, voice, and style | `references/update.md` |

## References

| Topic | File |
|-------|------|
| Voice Framework | `references/voice-framework.md` |
| Visual Identity | `references/visual-identity.md` |
| Messaging | `references/messaging-framework.md` |
| Consistency | `references/consistency-checklist.md` |
| Guidelines Template | `references/brand-guideline-template.md` |
| Asset Organization | `references/asset-organization.md` |
| Color Management | `references/color-palette-management.md` |
| Typography | `references/typography-specifications.md` |
| Logo Usage | `references/logo-usage-rules.md` |
| Approval Checklist | `references/approval-checklist.md` |

## Workflows

### Brand Creation

1. Gather brand inputs (name, mission, audience, personality traits)
2. Define voice using `references/voice-framework.md`
3. Build messaging framework using `references/messaging-framework.md`
4. Establish visual identity (colors, typography, logo rules) using:
   - `references/color-palette-management.md`
   - `references/typography-specifications.md`
   - `references/logo-usage-rules.md`
   - `references/visual-identity.md`
5. Compile into brand guidelines using `references/brand-guideline-template.md`
6. Save as `docs/brand-guidelines.md` in the project

### Brand Update

1. Parse update request from arguments
2. Load current `docs/brand-guidelines.md`
3. Apply changes to the relevant sections (colors, typography, voice, etc.)
4. If design tokens exist (`assets/design-tokens.json`, `assets/design-tokens.css`), update them to match
5. Verify all files are consistent

### Brand Audit

1. Load `references/consistency-checklist.md`
2. Review target materials against brand guidelines
3. Check visual consistency (colors, typography, logo usage)
4. Check voice consistency (tone, language, messaging)
5. Report findings with specific fixes

### Asset Review

1. Load `references/approval-checklist.md`
2. Review asset against all checklist items
3. Verify brand compliance (colors, fonts, logo, voice)
4. Check accessibility requirements
5. Report pass/fail with actionable fixes

## Brand Sync Workflow

When updating brand identity, keep these files in sync:

| File | Purpose |
|------|---------|
| `docs/brand-guidelines.md` | Human-readable brand documentation (source of truth) |
| `assets/design-tokens.json` | Token definitions (if project uses design tokens) |
| `assets/design-tokens.css` | CSS variables (if project uses design tokens) |

**Process:**
1. Edit `docs/brand-guidelines.md` with the brand changes
2. If design token files exist, update them to reflect the new values
3. Verify consistency across all brand files

## Routing

1. Parse subcommand from `$ARGUMENTS` (first word)
2. Load corresponding `references/{subcommand}.md`
3. Execute with remaining arguments
4. If no subcommand, determine workflow from context (create, audit, review, update)
