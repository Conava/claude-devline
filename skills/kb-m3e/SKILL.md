---
name: kb-m3e
description: Material 3 Expressive (M3E) knowledge base with token-level values for motion springs, shape and morphing, colour roles, type scale, components, layout and desktop input, plus the strict-mode compliance checklist. Applies when the project uses Material 3 Expressive (detected from dependencies, design tokens, docs or a setting), never merely because a UI framework is present. Read by the designer, its critic and implementers in M3E projects. Not invoked directly.
user-invocable: false
disable-model-invocation: false
---

# Material 3 Expressive Knowledge Base

This file routes; the values live in `references/`. Items read `**Rule.** Why. Check: how to verify`, and every file ends with `## Sources`.

## When it applies (detection)

Load this skill only when at least one signal says the project follows M3E. A framework alone (Compose, QML, Flutter, Lit) is not a signal.

| Signal | Example |
|---|---|
| Dependency on an M3E-era Material library | `androidx.compose.material3` 1.4+ with `MaterialExpressiveTheme`, `MotionScheme.expressive()`, `MaterialShapes`; `@material/web` with `md-sys-motion-spring-*` or `md-comp-button-xsmall` tokens |
| Design tokens in the repo | `md.sys.motion.spring.*`, `corner-extra-large-increased`, `typescale.emphasized.*`, `md.comp.button-group.*`, `md.comp.toolbar.*`, `md.comp.loading-indicator.*` |
| Shape-morph or M3E component code | rounded-polygon/`RoundedPolygon` morphs, loading-indicator shape sequence, wavy progress, button groups, split buttons, floating toolbars |
| Docs | README, CLAUDE.md, ADRs or design docs that say "Material 3 Expressive", "M3E" or "M3 Expressive" |
| Setting | the project's devline configuration names M3E as its design system |

Plain M3 (2021–2024) without these signals is not M3E; use the general design knowledge instead.

## How strict mode uses it

In strict mode every colour, shape, type style, spring, component and layout value must come from these files. The designer may decide only where a line starts `Room for choice:`; everything else is fixed. The critic runs `references/checklist.md` and cites the item plus the reference section for each finding. Implementers use the same files as the source of truth for token values and the `Motion:` line of each component.

**Motion is mandatory.** Every component entry states its animation; a missing animation is a finding, like a wrong one.

When sources disagree, the files say which value wins and why. Values the sources could not confirm are marked `(unverified)`; treat them as advisory, not as grounds for an off-spec finding.

Deliberate desktop deviations at the end of `layout.md` are not defaults. Apply one only when the project's own docs record that decision.

## Which file for what

| Question | Read |
|---|---|
| Which spring, which scheme, curve fallbacks, transitions, reduced motion | `references/motion.md` |
| Corner radii, shape library, when shapes morph, implementing morphs (web, QML) | `references/shape.md` |
| Colour roles and tones, dynamic colour, contrast levels, state layers, focus ring | `references/color.md` |
| Type scale, emphasized styles and when they are allowed, typefaces and axes | `references/type.md` |
| A specific component: sizes, colours by state, shape, motion, choices | `references/components.md` |
| Breakpoints, panes, margins, density, elevation, hover/cursor/keyboard, desktop deviations | `references/layout.md` |
| Reviewing a mockup or diff for compliance | `references/checklist.md` |

Read `${CLAUDE_SKILL_DIR}/references/<file>`. A design task usually needs `components.md` plus `motion.md` and `color.md`; a review always starts from `checklist.md`.

## Sources

- Material Design 3 guidelines, https://m3.material.io (Google, vendor documentation; paraphrased, facts only).
- androidx Compose Material3 token and component sources, https://github.com/androidx/androidx (Apache-2.0).
- Material Web tokens, https://github.com/material-components/material-web (Apache-2.0).
- material-color-utilities, https://github.com/material-foundation/material-color-utilities (Apache-2.0).
- end-4/rounded-polygon-qmljs, https://github.com/end-4/rounded-polygon-qmljs (Apache-2.0; implementation note only).
