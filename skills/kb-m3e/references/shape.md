# M3E shape

M3E shape is a ten-step corner radius scale, a 35-shape library, and shape morphing driven by spatial springs. Units are dp.

Item style: `**Rule.** Why. Check: how to verify`. `Room for choice:` lines mark what may be decided; everything else is fixed in strict mode.

## Corner radius scale

| Token (`md.sys.shape.corner.*`) | Value | Corner-value token |
|---|---|---|
| none | 0 | `corner-value-none` |
| extra-small | 4 | `corner-value-extra-small` |
| small | 8 | `corner-value-small` |
| medium | 12 | `corner-value-medium` |
| large | 16 | `corner-value-large` |
| large-increased | 20 | `corner-value-large-increased` |
| extra-large | 28 | `corner-value-extra-large` |
| extra-large-increased | 32 | `corner-value-extra-large-increased` |
| extra-extra-large | 48 | `corner-value-extra-extra-large` |
| full | fully rounded (Material Web writes 9999px) | none |

Asymmetric families: `extra-small-top` (4 4 0 0), `large-top` (16 16 0 0), `large-start` (16 0 0 16), `large-end` (0 16 16 0), `extra-large-top` (28 28 0 0); order is top-start, top-end, bottom-end, bottom-start.

- **Every corner radius is a scale token.** The scale is the whole vocabulary; component tokens map onto it. Check: grep radii in code and mockup; each is one of 0, 4, 8, 12, 16, 20, 28, 32, 48 or full. Any other number is off-spec unless a component entry names it (for example a 50% inner corner, or the optical-roundness rule below).
- **Full means fully rounded, not 50% of the size.** The expressive update changed full from "50% of component size" to a true full token. Check: pills stay pills when their height changes (radius tracks height/2 or uses a full/circle shape).
- **Inner corners map to corner-value tokens.** Groups of closely set items (connected button groups, split buttons, segmented lists, menus) use a small inner radius and the component's outer radius. Check: inner corners use the component entry's inner value; outer corners stay full or the named outer token.
- **Nested rounded shapes use optical roundness.** Inner radius = outer radius − padding (spec example 48 − 14 = 34). Same radius on nested shapes looks unbalanced. Check: a rounded element inside a rounded container with padding p has radius outer − p (clamped at 0); this computed value is allowed even when it is not on the scale.
- **Information-dense components do not get large or full corners.** The spec cautions against large/full corners on dense components such as cards. Check: cards keep `medium` (12).
  Room for choice: remapping a component to another scale step, or customising a scale step itself, for hero moments or custom components. The spec allows it but notes it forfeits token updates; in strict mode it must be recorded as a deliberate project decision, otherwise the component's default token applies.
  Room for choice: the corner family (rounded or cut). Cut corners need extra padding in dense components.

## Shape library

35 shapes, available in Compose as `MaterialShapes` and in QML through a rounded-polygon port: Circle, Square, Slanted, Arch, Fan, Arrow, SemiCircle, Oval, Pill, Triangle, Diamond, ClamShell, Pentagon, Gem, VerySunny, Sunny, Cookie4Sided, Cookie6Sided, Cookie7Sided, Cookie9Sided, Cookie12Sided, Ghostish, Clover4Leaf, Clover8Leaf, Burst, SoftBurst, Boom, SoftBoom, Flower, Puffy, PuffyDiamond, PixelCircle, PixelTriangle, Bun, Heart.

- **Abstract shapes are for visual and decorative elements, used sparingly.** The spec: shapes are not semantic, avoid unconventional shapes on text-heavy containers, and every unusual shape needs a reason. Check: library shapes appear on avatars, image crops, icons-as-graphics, loading indicator, decorative accents; not on text containers, buttons with labels, list rows or dialogs.
  Room for choice: which library shape to use for avatar masks, image crops, decorative and hero graphics.
- **Rectangular components are fully rounded by default, and individual corners may differ.** Check: asymmetric shapes only appear where a component entry defines inner corners.
- **Tension (square next to round) is allowed when it communicates.** The spec encourages contrasting round and square shapes, for example to convey state. Check: square/round contrast maps to a state or emphasis difference, not decoration on similar items.

## Shape morphing

Where the spec specifies morphing (fixed in strict mode):

| Component | Trigger | From → to |
|---|---|---|
| Button, icon button | press | resting radius → pressed radius (see `components.md`); round and square share one pressed radius |
| Toggle button, toggle icon button | select | round → square (or square → round when the resting shape is square) |
| Standard button group | press / select | pressed button morphs and widens; neighbours compress |
| Connected button group | select | selected button's inner corners → 50% (fully round) |
| Split button | hover, focus, press; menu open | inner corners grow; trailing button becomes fully round (inner 50%) when selected |
| Loading indicator | continuous | seven-shape sequence (below) |
| Expressive list item | select | 4 inner / 16 outer → 16 all round |
| Vertical menu | submenu focus | focused submenu corners rounder, unfocused less rounded |
| Menu item | hover/press/select | item → selected shape `medium` |

- **Morphs run on spatial springs.** Corner radius is geometry. Check: corner animations use `fast.spatial` (the component tokens name `spring-fast-spatial` for pressed corners and button-group width) unless the component entry says otherwise.
- **Morphing uses the expressive scheme by default.** The spec allows switching to standard. Room for choice: standard scheme for morphs in a utilitarian product, applied consistently.
- **Do not invent morphs on components the spec does not morph.** Cards, dialogs, chips and navigation items have no press morph. Check: a press-morph on a card or chip is off-spec; their feedback is the state layer (and elevation where the component entry says so).
- **Reduced motion disables decorative morphing.** The end shape is applied instantly. Check: with reduce-motion on, toggles snap to their selected shape and the loading indicator stops cycling shapes.

### Loading indicator sequence (exact)

Indeterminate: SoftBurst → Cookie9Sided → Pentagon → Pill → Sunny → Cookie4Sided → Oval, looping. Each morph runs on a spring (damping 0.6, stiffness 200) started every 650ms; each completed morph adds a 90° rotation step, and the whole indicator also rotates continuously at one turn per 4666ms, linear. Determinate: morphs Circle → SoftBurst with progress and rotates with it. These constants come from the Compose implementation, not a published token.

## Implementation notes

- **Compose:** `MaterialShapes` and `androidx.graphics.shapes` (`RoundedPolygon`, `Morph`). Spec page says the morph API is not available on web.
- **Web:** for rounded rectangles animate `border-radius` per corner with the spring; for library shapes generate SVG paths from the rounded-polygon geometry and interpolate matched cubic segments (a `Morph` port), or `clip-path: path()` updated per frame. `clip-path` interpolation between unequal path command counts does not work; match segment counts first.
- **QML:** `rounded-polygon-qmljs` (Apache-2.0) is a QML-compatible JavaScript port of the androidx shape library with the 35 Material shapes; render with a `Shape`/`ShapePath` or a Canvas, and drive the morph progress with the spring. For rectangles, animate `topLeftRadius` etc. (Qt 6.7+) or `radius`.
- **Check:** morph progress is a spring-driven 0–1 value; shapes are pre-built once, not re-created per frame.

## Sources

- Material Design 3, "Shape: Overview & principles", https://m3.material.io/styles/shape/overview-principles. Google, vendor documentation, paraphrased, facts only. Read 2026-11-16.
- Material Design 3, "Shape: Corner radius scale", https://m3.material.io/styles/shape/corner-radius-scale. Vendor documentation, paraphrased.
- Material Design 3, "Shape: Shape morph", https://m3.material.io/styles/shape/shape-morph. Vendor documentation, paraphrased.
- Material Design 3 component specs for buttons, icon buttons, button groups, split buttons, lists and menus (morph rows), https://m3.material.io/components. Vendor documentation, paraphrased.
- androidx Compose Material3 `tokens/ShapeTokens.kt`, `tokens/ShapeKeyTokens.kt`, `MaterialShapes.kt`, `LoadingIndicator.kt`, https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3. Apache-2.0, values as facts.
- Material Web `tokens/versions/latest/sass/_md-sys-shape.scss` and component token files, https://github.com/material-components/material-web/tree/main/tokens/versions/latest/sass. Apache-2.0, values as facts.
- end-4/rounded-polygon-qmljs, https://github.com/end-4/rounded-polygon-qmljs. Apache-2.0, named as an implementation option only.
