# M3E typography

One type scale, 30 styles: 15 baseline and 15 emphasized, Display Large to Label Small. Sizes in sp on Android, rem on web (sp / 16), px in QML at 1:1 with dp. Tracking given in px (web rem × 16).

Item style: `**Rule.** Why. Check: how to verify`. `Room for choice:` lines mark what may be decided.

## Baseline scale

Token `md.sys.typescale.<role>-<size>`. Brand typeface for display, headline and title-large; plain typeface for the rest.

| Style | Size | Line height | Tracking | Weight | Face |
|---|---|---|---|---|---|
| display-large | 57 | 64 | −0.25 | 400 | brand |
| display-medium | 45 | 52 | 0 | 400 | brand |
| display-small | 36 | 44 | 0 | 400 | brand |
| headline-large | 32 | 40 | 0 | 400 | brand |
| headline-medium | 28 | 36 | 0 | 400 | brand |
| headline-small | 24 | 32 | 0 | 400 | brand |
| title-large | 22 | 28 | 0 | 400 | brand |
| title-medium | 16 | 24 | 0.15 | 500 | plain |
| title-small | 14 | 20 | 0.1 | 500 | plain |
| body-large | 16 | 24 | 0.5 | 400 | plain |
| body-medium | 14 | 20 | 0.25 | 400 | plain |
| body-small | 12 | 16 | 0.4 | 400 | plain |
| label-large | 14 | 20 | 0.1 | 500 | plain |
| label-medium | 12 | 16 | 0.5 | 500 | plain |
| label-small | 11 | 16 | 0.5 | 500 | plain |

Tracking values are Material Web's; Compose's `TypeScaleTokens` rounds display-large to −0.2 and body-medium to 0.2.

## Emphasized scale

Token `md.sys.typescale.emphasized.<role>-<size>`. Same size, line height, tracking and face as baseline; only weight rises.

| Styles | Weight token | Variable `wght` axis |
|---|---|---|
| display-*, headline-*, title-large, body-* | medium (500) | 500 |
| title-medium, title-small, label-* | bold (700) | 600 |

Material Web's emphasized tokens set the remaining variable axes to neutral values: `wdth` 100, `opsz` = font size, `GRAD`, `ROND`, `slnt`, `FILL`, `CRSV`, `HEXP` all 0. (Compose's emphasized tracking differs slightly for body-large and display; Material Web values are used here.)

## Typefaces and axes

- **Brand and plain are tokens; Roboto is the default for both.** `md.ref.typeface.brand` and `.plain`; weights regular 400, medium 500, bold 700. Check: font family comes from the two typeface tokens, not per-component literals.
  Room for choice: replacing the brand and/or plain typeface (the spec encourages it for brand expression). Google Sans Flex and Roboto Flex are variable options; the spec notes Roboto Flex is not yet part of the M3 type scale, and presents Google Sans Flex (six variable axes, now open source) as sharing its roundness with the M3 shape library.
  Room for choice: different typefaces for baseline and emphasized sets.
- **Customize metrics, not sizes.** When swapping fonts the spec says adjust line height and tracking but avoid changing sizes, which components depend on; apply to both sets and keep emphasized consistently heavier. Check: font sizes match the table even with a custom face.
- **Variable fonts get a fallback chain.** Spec order for Roboto Flex: Roboto Flex → Roboto → Noto Sans. Check: the font stack names the static fallback and Noto for unsupported scripts.
- **Variable axes on a variable face:** Roboto Flex exposes slant, width, weight, grade, optical size plus parametric axes; Google Sans Flex has six axes including roundness (`ROND`, which Material Web's tokens carry; full axis list unverified). Check: `opsz` tracks the rendered size when the font has it; axes not named by a token stay at defaults.
  Room for choice: axis values (width, roundness, grade) in editorial and hero treatments; components keep the token values.

## When emphasized is allowed

- **Emphasized marks state, selection or importance, never body copy by default.** Components use baseline styles by default; the spec recommends emphasized for selection, actions, headlines and editorial treatments, and lists badges, buttons for primary actions, extended FAB, selected list items, and selected menu items as good fits. Swap the baseline token for the emphasized token of the same role and size. Check: an emphasized style sits on a selected/active element, a primary action, a headline, or editorial text; a whole paragraph in emphasized body is off-spec.
  Room for choice: whether a listed component (badge, primary-action button, extended FAB, selected list/menu item, headline) uses emphasized.
  Room for choice: emphasized on text that already uses weight to show hierarchy ("weight") or on selective places to show state ("context").

## Applying the scale

- **Components use the role their tokens name.** Examples: button XS/S label-large, M title-medium, L headline-small, XL headline-large; extended FAB S title-medium, M title-large, L headline-small; nav rail/bar vertical item label-medium, rail horizontal item label-large; list label body-large, supporting body-medium; menu item label-large; dialog headline headline-small, supporting body-medium; tabs title-small; search input body-large; slider value label-large. Check: against `components.md`.
- **Use few styles.** No product needs all 15; the scale is Major Second (1.125) on a 14 base. Check: a screen uses a small, consistent subset; no in-between sizes.
- **Text size does not scale with density.** Check: dense variants keep font sizes and only change padding/height.
- **Line length 40–60 characters** across breakpoints (lists allow up to 120 on large screens with increased line height). Check: measure long-form text columns.
- **Language height.** The spec adapts line height to script height categories (small: Latin/Greek/Cyrillic/Hebrew; medium ~7% taller: most others incl. CJK, Arabic, Indic, Thai, Vietnamese; large ~30%: Burmese, Telugu; extra large ~100%: Nastaliq). Components with vertical padding adapt; fixed-height components are built for small. Check: localized builds in medium/large scripts do not clip.
- **Never truncate or wrap button labels; sentence case.** Check: per `components.md`.

## Sources

- Material Design 3, "Typography: Overview", "Type scale & tokens", "Fonts", "Applying type", "Editorial treatments", https://m3.material.io/styles/typography/overview and sibling pages. Google, vendor documentation, paraphrased, facts only. Read 2026-11-16 (token tables there are collapsed; values taken from the token sources below).
- Material Web `_md-sys-typescale.scss`, `_md-sys-typescale-emphasized.scss`, `_md-ref-typeface.scss`, component typescale mixins, https://github.com/material-components/material-web/tree/main/tokens/versions/latest/sass. Apache-2.0, token values as facts.
- androidx Compose Material3 `tokens/TypeScaleTokens.kt`, `TypographyTokens.kt`, `TypefaceTokens.kt`, https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens. Apache-2.0, facts only.
