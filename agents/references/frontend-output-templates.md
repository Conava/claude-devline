# Frontend Planner — Output Templates

## Component Spec (`.devline/component-spec.md`)

```markdown
# Component Spec: [Component Name]

**Type:** [button / color-theme / menu / card / etc.]
**Generated:** [date]

## Color Tokens
[ONLY the tokens this component needs]

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| --component-bg | #xxx | #xxx | Background |
| --component-fg | #xxx | #xxx | Text/icons |
| --component-border | #xxx | #xxx | Border |
| --component-hover | #xxx | #xxx | Hover state |
| --component-active | #xxx | #xxx | Active/pressed |
| --component-focus-ring | #xxx | #xxx | Focus ring |

## Typography
[Only if relevant]
- Font: [name] — [why it fits]
- Size: [value] | Weight: [value] | Line-height: [value]

## States & Variants
| State | Background | Border | Text | Shadow | Transform |
|-------|-----------|--------|------|--------|-----------|
| Default | ... | ... | ... | ... | — |
| Hover | ... | ... | ... | ... | translateY(-1px) |
| Active | ... | ... | ... | ... | translateY(0) |
| Focus | ... | ... | ... | ring | — |
| Disabled | ... | ... | ... | none | — |

## Animation
- **Interaction**: [specific animation with timing]
- **Library**: [CSS only / Motion / etc.]
- **Reduced motion**: [fallback behavior]

## CSS Implementation
[Complete CSS with all states, using tokens above]

## Accessibility
- Touch target: [size]
- Focus indicator: [description]
- ARIA: [required attributes]
- Contrast: [ratio for each text/bg pair]

## Preview
Open `.devline/component-preview.html` to see the component in context.
```

## Color Theme Spec (alternative component-spec format)

```markdown
# Color Theme: [Theme Name]

**Mood:** [description]
**Generated:** [date]

## Palette

| Role | Light Mode | Dark Mode | Usage |
|------|-----------|-----------|-------|
| Primary | #xxx | #xxx | Interactive elements, CTAs |
| On Primary | #xxx | #xxx | Text/icons on primary |
| Secondary | #xxx | #xxx | Supporting elements |
| On Secondary | #xxx | #xxx | Text/icons on secondary |
| Accent | #xxx | #xxx | Highlights, badges |
| Background | #xxx | #xxx | Page background |
| Foreground | #xxx | #xxx | Default text |
| Card | #xxx | #xxx | Card surfaces |
| Muted | #xxx | #xxx | Disabled, secondary surfaces |
| Border | #xxx | #xxx | Borders, dividers |
| Destructive | #xxx | #xxx | Error, danger |
| Ring | #xxx | #xxx | Focus rings |

## Contrast Verification
| Pair | Ratio | WCAG AA | WCAG AAA |
|------|-------|---------|----------|
| Foreground on Background | X:1 | PASS/FAIL | PASS/FAIL |
| On Primary on Primary | X:1 | PASS/FAIL | PASS/FAIL |

## CSS Variables
```css
:root { /* Light */ }
.dark { /* Dark */ }
```

## Tailwind Config
```js
[Tailwind theme extension]
```
```

## Harmonized Component Spec (`.devline/component-spec.md`)

```markdown
# Harmonized Component: [Name]

**Fits within:** [project name / detected framework]
**Generated:** [date]

## Project Theme Reference
[Summary of the project's visual identity]

## Component Design
[Spec using the project's existing tokens]

### Using Project Tokens
| Element | Token/Class | Value | Source |
|---------|------------|-------|--------|
| Background | var(--card) / bg-card | #xxx | tailwind.config.ts |
| Text | var(--foreground) / text-foreground | #xxx | globals.css |

### New Tokens Needed
[ONLY if the component requires something not in the project's theme — ideally empty]

### States & Animation
[Using the project's existing transition timing and patterns]

### CSS / Component Code
[Uses existing project tokens exclusively]

## Preview
Open `.devline/harmonize-preview.html`
```

## Extension Spec (appended to `.devline/design-system.md`)

```markdown
---

## Extension: [Component Name]
**Added:** [date]

### New Tokens
[ONLY tokens that don't already exist]
| Token | Value | Usage |

### Component Spec
[States, variants, CSS — using existing tokens where possible]

### Animation
[New animation if needed, or reference to existing]

### Integration Notes
[How this connects to existing components]
```

## Brand Identity (`design-system/BRAND.md`)

```markdown
# Brand Identity: [Project Name]

**Created:** [date]
**Last Updated:** [date]
**Product Type:** [category]
**Platform:** [web/mobile/desktop] — [framework]

## Brand Personality
[2-3 sentences]

## Style Direction
**Primary Style:** [style name] — [rationale]
**Secondary Style:** [complement/contrast]

## Color System

### Semantic Tokens
| Role | Light Mode | Dark Mode | Usage |
|------|-----------|-----------|-------|
| Primary | #xxx | #xxx | Interactive elements, CTAs, links |
| On Primary | #xxx | #xxx | Text/icons on primary |
| Secondary | #xxx | #xxx | Supporting elements |
| On Secondary | #xxx | #xxx | Text/icons on secondary |
| Accent | #xxx | #xxx | Highlights, badges, notifications |
| On Accent | #xxx | #xxx | Text/icons on accent |
| Background | #xxx | #xxx | Page background |
| Foreground | #xxx | #xxx | Default text |
| Card | #xxx | #xxx | Card/panel surfaces |
| Card Foreground | #xxx | #xxx | Text on cards |
| Muted | #xxx | #xxx | Disabled, secondary surfaces |
| Muted Foreground | #xxx | #xxx | Secondary/placeholder text |
| Border | #xxx | #xxx | Borders, dividers |
| Destructive | #xxx | #xxx | Error, danger |
| On Destructive | #xxx | #xxx | Text on destructive |
| Ring | #xxx | #xxx | Focus rings |
| Success | #xxx | #xxx | Success states |
| Warning | #xxx | #xxx | Warning states |

### Contrast Verification
| Pair | Light Ratio | Dark Ratio | WCAG AA |
|------|------------|------------|---------|
| Foreground / Background | X:1 | X:1 | PASS |

### CSS Variables
```css
:root { --primary: [hsl]; /* ... */ }
.dark { --primary: [hsl]; /* ... */ }
```

### Tailwind Config
```js
colors: { primary: 'hsl(var(--primary))', /* ... */ }
```

## Typography
**Heading Font:** [name] — [mood, weight range]
**Body Font:** [name] — [mood, weight range]
**Mono Font:** [name] — [for code/data]

### Type Scale
| Level | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| Display | 3rem | 700 | 1.1 | -0.02em | Hero headings |
| H1 | 2.25rem | 700 | 1.2 | -0.01em | Page titles |
| H2 | 1.875rem | 600 | 1.3 | 0 | Section headings |
| H3 | 1.5rem | 600 | 1.4 | 0 | Subsections |
| H4 | 1.25rem | 600 | 1.4 | 0 | Card headings |
| Body | 1rem | 400 | 1.6 | 0 | Paragraph text |
| Small | 0.875rem | 400 | 1.5 | 0 | Captions, labels |
| Tiny | 0.75rem | 500 | 1.4 | 0.02em | Badges, overlines |

### Google Fonts Import
```css
@import url('[url]');
```

## Spacing System
| Token | Value | Usage |
|-------|-------|-------|
| --space-1 | 0.25rem | Tight gaps, icon padding |
| --space-2 | 0.5rem | Inline spacing |
| --space-3 | 0.75rem | Form element padding |
| --space-4 | 1rem | Standard padding |
| --space-6 | 1.5rem | Card padding, section gaps |
| --space-8 | 2rem | Section padding |
| --space-12 | 3rem | Large section margins |
| --space-16 | 4rem | Page section spacing |

## Border & Radius
| Token | Value | Usage |
|-------|-------|-------|
| --radius-sm | [value] | Buttons, inputs, badges |
| --radius-md | [value] | Cards, panels |
| --radius-lg | [value] | Modals, large containers |
| --radius-full | 9999px | Avatars, pills |

## Shadow System
| Token | Value | Usage |
|-------|-------|-------|
| --shadow-sm | [value] | Subtle lift |
| --shadow-md | [value] | Cards, dropdowns |
| --shadow-lg | [value] | Modals, floating elements |

## Motion & Animation
**Library:** [CSS only / Motion / GSAP]
**Base timing:** [e.g., 200ms ease-out]

| Pattern | Duration | Easing | Usage |
|---------|----------|--------|-------|
| Hover lift | 200ms | ease-out | Cards, buttons |
| Press | 150ms | ease-in | Active state |
| Fade in | 200ms | ease-out | Appearing elements |
| Slide in | 300ms | ease-out | Panels, drawers |
| Stagger | 50ms per item | ease-out | Lists, grids |

**Reduced motion:** All animations collapse to opacity-only or instant transitions.

## Anti-Patterns
[Product-specific anti-patterns from reasoning rules]

## Component Index
- [Button](components/button.md)
- [Card](components/card.md)
- [Input](components/input.md)
- [Badge](components/badge.md)
```

## Brand Component Spec (`design-system/components/[name].md`)

```markdown
# [Component Name]

**Brand reference:** [design-system/BRAND.md]
**Created:** [date]

## Variants
[List all variants with token mappings]

## States
| State | Background | Border | Text | Shadow | Transform |
|-------|-----------|--------|------|--------|-----------|
| Default | var(--primary) | — | var(--on-primary) | var(--shadow-sm) | — |
| Hover | [derived] | — | var(--on-primary) | var(--shadow-md) | translateY(-1px) |

## Sizes
| Size | Padding | Font Size | Min Height | Icon Size |
|------|---------|-----------|------------|-----------|

## CSS Implementation
[All tokens reference BRAND.md variables]

## Brand Compliance
- [x] Uses only tokens from BRAND.md
- [x] Hover timing matches brand motion pattern
- [x] Border radius uses brand token
- [x] Focus ring uses brand Ring token
```

## Design System (`.devline/design-system.md`)

```markdown
# Design System — [Feature Name]

**Product Type:** [matched category]
**Platform:** [web/mobile/desktop] — [framework]
**Generated:** [date]

## Style Direction
**Primary Style:** [style name] — [why it fits]
**Secondary Style:** [style name] — [complement/contrast]
**Layout Pattern:** [recommended pattern]

## Color Palette
| Role | Hex | Usage |
|------|-----|-------|
| Primary | #XXXXXX | [usage] |
| On Primary | #XXXXXX | Text/icons on primary |
| [... full 16-role palette ...] |

**Color Mood:** [from reasoning rules]
**Notes:** [contrast, WCAG compliance]

## Typography
**Heading Font:** [name] — **Body Font:** [name]
**Google Fonts Import:** `@import url('[url]');`
**Tailwind Config:** [font config]

## Key Effects
[Animation and transition recommendations]

## Animated Components
**Motion Library:** [recommended]
| Component | Category | Trigger | Library | Complexity | Mobile |
|-----------|----------|---------|---------|------------|--------|

## Anti-Patterns
[Product-specific]

## Common UI Issues
| Rule | Do | Avoid |
|------|----|-------|

## Design Rules
[Only relevant priority categories for this feature]

## Stack-Specific Guidelines
[Framework-specific UX guidelines]

## Pre-Delivery Checklist
[Visual quality, interaction, light/dark, layout, accessibility checks]
```
