# M3E colour

Colour in M3E is a set of roles filled from five tonal palettes. Components reference roles, never raw colours, so dynamic colour, dark theme and contrast levels work without touching components.

Item style: `**Rule.** Why. Check: how to verify`. `Room for choice:` lines mark what may be decided.

## Roles and baseline tones

Palettes: primary, secondary, tertiary, neutral, neutral-variant, plus a static error palette. Tones run 0–100 (0 black, 100 white). The table gives the tone each role takes in the baseline (standard contrast) scheme.

| Role | Light | Dark |
|---|---|---|
| primary / on-primary | P40 / P100 | P80 / P20 |
| primary-container / on-primary-container | P90 / P30 | P30 / P90 |
| secondary / on-secondary | S40 / S100 | S80 / S20 |
| secondary-container / on-secondary-container | S90 / S30 | S30 / S90 |
| tertiary / on-tertiary | T40 / T100 | T80 / T20 |
| tertiary-container / on-tertiary-container | T90 / T30 | T30 / T90 |
| error / on-error | E40 / E100 | E80 / E20 |
| error-container / on-error-container | E90 / E30 | E30 / E90 |
| primary-fixed / primary-fixed-dim | P90 / P80 | same |
| on-primary-fixed / on-primary-fixed-variant | P10 / P30 | same |
| (secondary-, tertiary-fixed: same pattern) | | |
| surface, background, surface-bright | N98 | N6 (bright N24) |
| surface-dim | N87 | N6 |
| surface-container-lowest / low / (default) / high / highest | N100 / 96 / 94 / 92 / 90 | N4 / 10 / 12 / 17 / 22 |
| on-surface / on-background | N10 | N90 |
| surface-variant / on-surface-variant | NV90 / NV30 | NV30 / NV80 |
| outline / outline-variant | NV50 / NV80 | NV60 / NV30 |
| inverse-surface / inverse-on-surface / inverse-primary | N20 / N95 / P80 | N90 / N20 / P40 |
| scrim, shadow | N0 | N0 |

The on-*-container roles in light theme moved from tone 10 to 30 in the August 2024 update ("more colourful text and icons"); Material Web and Material Color Utilities use 30, while Compose's static `ColorLightTokens` still lists 10. Use 30.

Baseline source colour: primary40 = `#6750A4` (Material Web `md-ref-palette`).

- **Every colour is a role token.** Roles keep pairs accessible across dynamic schemes and contrast levels. Check: no hex literal outside the generated scheme file or theme singleton; every component colour maps to a role in `components.md` or the component's tokens.
- **Use roles only in their intended pairs.** On-X goes on X; container roles are fills, never text or icon colours; on-surface and on-surface-variant go on any surface or surface-container. Wrong pairs break when contrast changes. Check: text or icon on `primary-container` uses `on-primary-container`; text never uses a `*-container` role; nothing uses `primary-container` as text on `surface`.
- **Accent roles by emphasis.** Primary for the most prominent actions and active states (FAB, high-emphasis buttons); secondary for less prominent elements (filter chips, tonal buttons, selected nav indicator); tertiary for contrasting accents (badges, highlighted inputs). Check: the role choice matches the component entry; tertiary used decoratively across large areas is suspect.
  Room for choice: tertiary roles may be applied at the designer's discretion for colour expression (spec wording).
  Room for choice: a component's container/on-container pair may be swapped for another accent pair where the component entry says the spec allows it (buttons, icon buttons: any pair with 3:1 container/text contrast, e.g. tertiary; FAB and extended FAB: six listed pairs).
- **Error roles are static.** They do not follow the dynamic source but still adapt to light and dark. Check: error colours are not regenerated from content or wallpaper.
- **Surfaces build hierarchy with surface-container roles, not elevation tint.** Surface tint overlays are deprecated; tone-based surface containers replaced them in 2023. Check: no primary-tinted overlays for elevation; nested containers step through lowest → highest.
  Room for choice: which surface-container step a custom region uses, provided it stays the same across breakpoints (spec: body uses surface and navigation uses surface-container on every window size; larger windows may add container steps consistently).
  Room for choice: remapping neutral components (bars, menus, dialogs) to another surface-container role; the spec allows it "to suit user needs".
- **Fixed roles stay the same in light and dark.** Use them only for elements that must not change with theme. Check: `*-fixed` roles are not used for ordinary themed surfaces.
- **Inverse roles only for deliberately contrasting elements** (snackbars, tooltips, selected outlined toggle buttons). Check: inverse-surface appears only on components whose entry names it.

## Dynamic colour

The source colour is quantized from an image (user wallpaper or in-app content) or hand-picked; Material Color Utilities (MCU) derives five key colours, builds tonal palettes, and assigns tones to roles for light and dark.

- **Generate schemes with MCU, never by hand-mixing.** MCU enforces the tone pairs and contrast. Check: the scheme comes from MCU (or a tool that wraps it, e.g. matugen or Material Theme Builder output) and records its variant and contrast level.
- **Scheme variants.** MCU variants: TONAL_SPOT (default; low-to-medium colourfulness), NEUTRAL, VIBRANT, EXPRESSIVE (intentionally detached from source hue), FIDELITY and CONTENT (keep the source colour, placing it in primary-container; for content-based colour), RAINBOW, FRUIT_SALAD, MONOCHROME.
  Room for choice: the variant. TONAL_SPOT is the default for user-generated (wallpaper) colour; CONTENT or FIDELITY for content-based colour.
- **Content-based colour belongs next to its source.** The spec: best for contained regions adjacent to the source image (media players, album art), where content is front and centre. Check: a content-derived scheme is scoped to the region near its image, not the whole app chrome, unless the product is content-first.
  Room for choice: user-generated, content-based, or both (multiple sources) as the product's colour source.
- **Brand or semantic custom colours are harmonized, not dropped in raw.** MCU's custom-colour path generates a matching palette per custom colour. Check: custom colours have light/dark and on-colour pairs generated, not single hex values.

## Contrast levels

Three user-selectable levels: standard (default), medium, high. MCU takes a contrast level from −1 to 1; standard is 0 and maximum is 1; medium is commonly 0.5 (unverified: MCU documents only the endpoints). Material Web ships separate role files per level (`_md-sys-color__medium-contrast`, `__high-contrast`, and dark variants).

- **Support all three levels when the platform exposes a contrast setting.** Roles are tokenized per level so components need no change. Check: switching contrast regenerates roles; no component hard-codes a tone.
- **Contrast floor.** The colour pairs provide at least 3:1; body text needs the WCAG 4.5:1 that the on-roles provide at standard contrast. Disabled states are exempt. Check: measure text on its container; non-text indicators (nav icons, slider track, progress track vs container) at least 3:1, or add a stop indicator where the component entry requires it.

## State layers

A state layer is a translucent overlay of the **content colour** (the on-colour of the container, or the icon/label colour) between container and content. One state layer at a time per element.

| State | Opacity token | Value |
|---|---|---|
| Hover | `md.sys.state.hover.state-layer-opacity` | 0.08 |
| Focus | `md.sys.state.focus.state-layer-opacity` | 0.10 |
| Pressed | `md.sys.state.pressed.state-layer-opacity` | 0.10 |
| Dragged | `md.sys.state.dragged.state-layer-opacity` | 0.16 |
| Disabled content | (component tokens) | 0.38 opacity of on-surface |
| Disabled container | (component tokens) | 0.10 (buttons) / 0.12 (some baseline components) of on-surface |

- **State-layer colour equals the content colour.** Check: filled button state layer is `on-primary`; FAB with a non-default pair uses its icon colour (spec says so explicitly).
- **Disabled = on-surface at 0.38 for content; containers per component tokens.** Check: disabled elements use on-surface, not a greyed accent; disabled elements show no hover/focus/press.
- **Focus indicator for keyboard focus.** Thickness 3dp, outer offset 2dp, inner offset −3dp (`md.sys.state.focus-indicator`), colour secondary. Check: Tab navigation shows a 3dp secondary ring outside the component (inside for list and menu items).

## Sources

- Material Design 3, "Color roles", https://m3.material.io/styles/color/roles. Google, vendor documentation, paraphrased, facts only. Read 2026-11-16.
- Material Design 3, "Color system: Overview" and "How the system works" (contrast levels, 2024 on-container update, dynamic pipeline), https://m3.material.io/styles/color/system/overview and https://m3.material.io/styles/color/system/how-the-system-works. Vendor documentation, paraphrased.
- Material Design 3, "Dynamic color: Choosing a source", https://m3.material.io/styles/color/dynamic/choosing-a-source. Vendor documentation, paraphrased.
- Material Design 3, "States: State layers" and "Applying states", https://m3.material.io/foundations/interaction/states/state-layers. Vendor documentation, paraphrased.
- material-foundation/material-color-utilities, `typescript/dynamiccolor/color_spec_2021.ts`, `variant.ts`, `dynamic_scheme.ts`, `scheme/*.ts`, https://github.com/material-foundation/material-color-utilities. Apache-2.0, facts only.
- Material Web `_md-sys-color*.scss`, `_md-ref-palette.scss`, `_md-sys-state.scss`, `_md-sys-state-focus-indicator.scss`, https://github.com/material-components/material-web/tree/main/tokens/versions/latest/sass. Apache-2.0, token values as facts.
- androidx Compose Material3 `tokens/ColorLightTokens.kt`, `ColorDarkTokens.kt`, `StateTokens.kt`, https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens. Apache-2.0, facts only.
