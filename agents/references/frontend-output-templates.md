# Frontend Planner — Output Templates

Fill these skeletons and write them to the paths shown. Four tables recur across skeletons — they are defined ONCE here as **canonical**; each skeleton names the subset/delta it uses instead of repeating them.

## Canonical Tables

### Semantic Color Palette (16 roles)
| Role | Light | Dark | Usage |
|------|-------|------|-------|
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

Deltas: **Brand identity** adds two rows — Success and Warning (Light/Dark/Usage). A **color-theme** spec uses a 12-role subset (Primary, On Primary, Secondary, On Secondary, Accent, Background, Foreground, Card, Muted, Border, Destructive, Ring). A **component** spec uses only the component-scoped tokens it needs (see Component Spec). The **design-system** doc lists these roles single-mode as `| Role | Hex | Usage |`.

### States & Variants
| State | Background | Border | Text | Shadow | Transform |
|-------|-----------|--------|------|--------|-----------|
| Default | ... | ... | ... | ... | — |
| Hover | ... | ... | ... | ... | translateY(-1px) |
| Active | ... | ... | ... | ... | translateY(0) |
| Focus | ... | ... | ... | ring | — |
| Disabled | ... | ... | ... | none | — |

### Motion & Animation
| Pattern | Duration | Easing | Usage |
|---------|----------|--------|-------|
| Hover lift | 200ms | ease-out | Cards, buttons |
| Press | 150ms | ease-in | Active state |
| Fade in | 200ms | ease-out | Appearing elements |
| Slide in | 300ms | ease-out | Panels, drawers |
| Stagger | 50ms per item | ease-out | Lists, grids |

**Reduced motion:** all animations collapse to opacity-only or instant transitions.

### Contrast Verification
| Pair | Light Ratio | Dark Ratio | WCAG AA | WCAG AAA |
|------|------------|------------|---------|----------|
| Foreground / Background | X:1 | X:1 | PASS/FAIL | PASS/FAIL |
| On Primary / Primary | X:1 | X:1 | PASS/FAIL | PASS/FAIL |

---

## Component Spec (`.devline/component-spec.md`)

```markdown
# Component Spec: [Component Name]

**Type:** [button / color-theme / menu / card / etc.]
**Generated:** [date]

## Color Tokens
[ONLY the component-scoped tokens this component needs — not the full palette]

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| --component-bg | #xxx | #xxx | Background |
| --component-fg | #xxx | #xxx | Text/icons |
| --component-border | #xxx | #xxx | Border |
| --component-hover | #xxx | #xxx | Hover state |
| --component-active | #xxx | #xxx | Active/pressed |
| --component-focus-ring | #xxx | #xxx | Focus ring |

## Typography
[Only if relevant] Font: [name] — [why] | Size / Weight / Line-height: [values]

## States & Variants
Canonical States & Variants table (above).

## Animation
Canonical Motion & Animation table (above) — list only the patterns this component uses. Library: [CSS only / Motion / etc.]. Reduced motion: [fallback].

## CSS Implementation
[Complete CSS with all states, using the tokens above]

## Accessibility
- Touch target: [size] | Focus indicator: [description] | ARIA: [attributes] | Contrast: [ratio per text/bg pair]

## Preview
Open `.devline/component-preview.html`.
```

## Color Theme Spec (alternative component-spec format)

```markdown
# Color Theme: [Theme Name]

**Mood:** [description]
**Generated:** [date]

## Palette
Canonical Semantic Color Palette (above), 12-role subset.

## Contrast Verification
Canonical Contrast Verification table (above).

## CSS Variables
​```css
:root { /* Light */ }
.dark { /* Dark */ }
​```

## Tailwind Config
​```js
[Tailwind theme extension]
​```
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
Canonical States & Variants + Motion & Animation tables (above), using the project's existing transition timing and patterns.

### CSS / Component Code
[Uses existing project tokens exclusively]

## Preview
Open `.devline/harmonize-preview.html`.
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
States/variants and CSS — canonical States & Variants table (above), using existing tokens where possible.

### Animation
Canonical Motion & Animation table (above) — new pattern if needed, else reference an existing one.

### Integration Notes
[How this connects to existing components]
```

## Brand Identity (`design-system/BRAND.md`)

```markdown
# Brand Identity: [Project Name]

**Created:** [date] | **Last Updated:** [date]
**Product Type:** [category] | **Platform:** [web/mobile/desktop] — [framework]

## Brand Personality
[2-3 sentences]

## Style Direction
**Primary Style:** [name] — [rationale] | **Secondary Style:** [complement/contrast]

## Color System
### Semantic Tokens
Canonical Semantic Color Palette (above), all 16 roles, PLUS two brand rows:
| Success | #xxx | #xxx | Success states |
| Warning | #xxx | #xxx | Warning states |

### Contrast Verification
Canonical Contrast Verification table (above).

### CSS Variables
​```css
:root { --primary: [hsl]; /* ... */ }
.dark { --primary: [hsl]; /* ... */ }
​```

### Tailwind Config
​```js
colors: { primary: 'hsl(var(--primary))', /* ... */ }
​```

## Typography
**Heading / Body / Mono Font:** [name] — [mood, weight range] each

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
​```css
@import url('[url]');
​```

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
**Library:** [CSS only / Motion / GSAP] | **Base timing:** [e.g., 200ms ease-out]
Canonical Motion & Animation table (above).

## Anti-Patterns
[Product-specific anti-patterns from reasoning rules]

## Component Index
- [Button](components/button.md) · [Card](components/card.md) · [Input](components/input.md) · [Badge](components/badge.md)
```

## Brand Component Spec (`design-system/components/[name].md`)

```markdown
# [Component Name]

**Brand reference:** [design-system/BRAND.md]
**Created:** [date]

## Variants
[List all variants with token mappings]

## States
Canonical States & Variants table (above), with cells referencing BRAND.md tokens (e.g. Default bg = var(--primary), text = var(--on-primary), shadow = var(--shadow-sm)).

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

**Product Type:** [matched category] | **Platform:** [web/mobile/desktop] — [framework]
**Generated:** [date]

## Style Direction
**Primary Style:** [name] — [why] | **Secondary Style:** [complement] | **Layout Pattern:** [recommended]

## Color Palette
Canonical Semantic Color Palette (above), 16 roles, single-mode: `| Role | Hex | Usage |`.
**Color Mood:** [from reasoning rules] | **Notes:** [contrast, WCAG compliance]

## Typography
**Heading / Body Font:** [names] | **Google Fonts Import:** `@import url('[url]');` | **Tailwind Config:** [font config]

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
