# M3E components

Per component: anatomy, token values (dp), colours by state, shape, motion, and the spec's room for choice. Everything not under `Room for choice:` is fixed in strict mode. Colour names are roles (`color.md`); shapes are scale tokens (`shape.md`); springs are `md.sys.motion.spring.*` in the product scheme (`motion.md`). State layers follow `color.md` (hover 0.08, focus 0.10, pressed 0.10, dragged 0.16, colour = content colour) unless an entry says otherwise; disabled content is on-surface at 0.38, disabled containers on-surface at 0.10.

Where sources disagree the entry says which value wins: Material Web's `latest` tokens (2026) over Compose's generated tokens, and the spec page over both when it states a number in prose.

Common rules for every entry:

- **Minimum target 48×48dp.** Smaller visuals (XS/S buttons, chips, switch handle) extend their target. Check: hit area measured in the mockup or code.
- **Each component that changes state animates it.** The `Motion:` line is mandatory. Check: the implementation animates exactly the listed properties with the listed springs; no extra bounce on colour or opacity.

## Actions

### Button

Anatomy: container, label text, optional leading icon (trailing in RTL). Variants: default and toggle. Colour styles: elevated, filled (default), tonal, outlined, text (no toggle text button). Sizes XS, S (default), M, L, XL; shapes round (default) or square.

| Size | Height | Leading/trailing padding | Icon | Icon–label gap | Label | Outline | Square radius | Pressed radius |
|---|---|---|---|---|---|---|---|---|
| XS | 32 | 12 | 20 | 8 | label-large | 1 | 12 | 8 |
| S | 40 | 16 | 20 | 8 | label-large | 1 | 12 | 8 |
| M | 56 | 24 | 24 | 8 | title-medium | 1 | 16 | 12 |
| L | 96 | 48 | 32 | 12 | headline-small | 2 | 28 | 16 |
| XL | 136 | 64 | 40 | 16 | headline-large | 3 | 28 | 16 |

Round shape = full. XS padding is 12 in Material Web, 16 in Compose; use 12. The baseline 24dp padding for S is "not recommended"; use 16.

| Style | Default container / content | Toggle unselected | Toggle selected | Elevation rest / hover |
|---|---|---|---|---|
| Elevated | surface-container-low / primary | surface-container-low / primary | primary / on-primary | 1 / 2 (disabled 0) |
| Filled | primary / on-primary | surface-container / on-surface-variant | primary / on-primary | 0 / 1 |
| Tonal | secondary-container / on-secondary-container | same | secondary / on-secondary | 0 / 1 |
| Outlined | none, outline-variant 1–3dp / on-surface-variant | same | inverse-surface / inverse-on-surface | 0 |
| Text | none / primary | n/a | n/a | 0 |

- Shape: pressed → pressed radius (same for round and square). Toggle: round → square when selected; a square-resting toggle becomes round when selected (Material Web: selected round = the square radius of that size, selected square = full).
- Label: 1–3 words, sentence case, one line, never truncated or wrapped; width hugs the label, never narrower; icon and label stay grouped and centred when the button stretches. Toggle: outlined icon unselected, filled icon selected; keep label length similar in both states.
- Motion: corner radius to the pressed shape and to the selected shape on `fast.spatial` (Material Web token `pressed-container-corner-size-motion-spring`); colour and elevation changes on `fast.effects`; state layers fade on effects. Compose drives the button corner with `default.effects` to avoid bounce; either is acceptable, but no spring slower than default.
- Room for choice: colour style, size and round vs square per button, by emphasis. One filled button per view is the guidance ("ideally only one action on a page").
- Room for choice: another accent pair (e.g. tertiary / on-tertiary) when container and label keep 3:1.
- Room for choice: elevated style only when the button must separate from a busy background.

### Icon button

Anatomy: icon, container (none for standard). Colour styles: filled (default), tonal, outlined, standard. Sizes XS–XL; widths narrow, default, wide; shapes round/square; default or toggle.

| Size | Height | Icon | Padding narrow / default / wide (each side) | Outline | Square radius | Pressed radius |
|---|---|---|---|---|---|---|
| XS | 32 | 20 | 4 / 6 / 10 | 1 | 12 | 8 |
| S | 40 | 24 | 4 / 8 / 14 | 1 | 12 | 8 |
| M | 56 | 24 | 12 / 16 / 24 | 1 | 16 | 12 |
| L | 96 | 32 | 16 / 32 / 48 | 2 | 28 | 16 |
| XL | 136 | 40 | 32 / 48 / 72 | 3 | 28 | 16 |

Width = icon + 2 × padding (S default = 40).

| Style | Default | Toggle unselected | Toggle selected |
|---|---|---|---|
| Filled | primary / on-primary | surface-container / on-surface-variant | primary / on-primary |
| Tonal | secondary-container / on-secondary-container | same | secondary / on-secondary |
| Outlined | outline-variant / on-surface-variant | same | inverse-surface / inverse-on-surface |
| Standard | none / on-surface-variant | on-surface-variant | primary icon |

- Shape and morph rules as Button.
- Motion: as Button (pressed and selected corner on `fast.spatial`; colour on effects). Compose uses `default.effects` for the shape.
- Room for choice: style, size, width and shape by emphasis and density; another accent pair with 3:1.

### Button group (standard and connected)

Invisible container that spaces buttons and adds interaction. Holds buttons and/or icon buttons of one size; use filled, tonal, outlined or elevated colour styles (not standard icon buttons or text buttons, which have no container).

| Size | Height | Standard gap | Connected gap | Connected inner corner | Connected inner pressed |
|---|---|---|---|---|---|
| XS | 32 | 18 | 2 | 4 (spec) | 4 |
| S | 40 | 12 | 2 | 8 | 4 |
| M | 56 | 8 | 2 | 8 | 4 |
| L | 96 | 8 | 2 | 16 | 12 |
| XL | 136 | 8 | 2 | 20 | 16 |

Connected groups: outer corners full (round) or the size's square radius; inner corners per table; selected button's inner corners become 50% (fully round). Material Web lists XS inner as 8; the spec page states 4, use 4. XS and S connected groups have 48dp targets and min width 48.

- Standard group: pressing or selecting a button widens it by 15% (`pressed-item-width-multiplier`) and morphs its shape; neighbours shrink to compensate, the group's outer bounds do not move. Toggle selection switches round/square.
- Connected group: selection changes only the selected button's shape; neighbours are unaffected. Replaces the segmented button; use for single-select, multi-select or selection-required sets of opposing options.
- Motion: pressed width and shape on `fast.spatial` (tokens `pressed-item-width-motion-spring`); colour on effects. Overflowing buttons move into a menu as the window narrows.
- Room for choice: standard vs connected; size; round vs square; which buttons; give the primary action more emphasis by size, colour or shape. A maximum width for connected groups on large windows.

### Split button

Leading button (icon, label or both) + trailing menu button with a chevron, 2dp apart. Colour styles elevated, filled, tonal, outlined (as Button; selected trailing button gets a state layer, not a colour change). Sizes XS–XL; outer corners full.

| Size | Height | Leading btn padding (start / end) | Trailing icon | Trailing padding | Inner corner rest / hover-press |
|---|---|---|---|---|---|
| XS | 32 | 12 / 10 | 22 | 13 | 4 / 8 |
| S | 40 | 16 / 12 | 22 | 13 | 4 / 12 |
| M | 56 | 24 / 24 | 26 | 15 | 4 / 12 |
| L | 96 | 48 / 48 | 38 | 29 | 8 / 20 |
| XL | 136 | 64 / 64 | 50 | 43 | 12 / 20 |

Menu icon sits optically offset when unselected (XS −1, S −1, M −2, L −3, XL −6 from centre) and centres when selected; selected trailing button becomes fully round (inner 50%).

- Motion: inner corners grow on hover/focus/press (spatial); opening the menu rotates the chevron 180° inward and morphs the trailing button round, using the **standard** scheme for the rotation (spec says so explicitly). Compose animates the shape on `default.effects`.
- Room for choice: leading content (icon, label, both); colour style; size. Menu position may move around the button but stays aligned to one of its edges.

### FAB

Sizes: FAB 56 (icon 24, radius large 16), medium 80 (icon 28, radius large-increased 20), large 96 (icon 36, radius extra-large 28). Small FAB (40, medium radius) is "not recommended". Margin 16 from window edges.

Colour pairs: primary-container / on-primary-container (default), secondary-container, tertiary-container, primary, secondary, tertiary (each with its on-colour). Surface FABs are not recommended. Elevation 3 rest, 4 hover, 3 focus/press; 0 when nested in a navigation rail.

- One FAB per screen; the action must be the screen's primary one and not duplicated elsewhere. If the action is unavailable, hide the FAB (no disabled FAB).
- Motion: enters by scaling out from its centre (`fast.spatial` scale, `fast.effects` alpha); FAB ↔ extended FAB width on `fast.spatial` with label fade `fast.effects`; disappears and reappears across layout changes rather than moving with body content.
- Room for choice: size by hierarchy; any of the six colour pairs (state layer = icon colour).

### Extended FAB

Sizes: small 56 (padding 16, icon 24, gap 8, title-medium, radius large 16), medium 80 (padding 26, icon 28, gap 12, title-large, radius large-increased 20), large 96 (padding 28, icon 36, gap 16, headline-small, radius extra-large 28). The baseline extended FAB (56, label-large) is not recommended. Colours and elevation as FAB. Margin 16.

- Placement: compact/medium windows bottom, centred or trailing; expanded and larger: bottom-right edge (both LTR and RTL) or inside the navigation rail. One per screen; label 1–2 words; not one option in a set of actions.
- Motion: collapse = label `fast.effects` fade out + width shrink on `default.spatial`; expand = label `default.effects` fade in + width on `fast.spatial` (Compose implementation); transforms into a FAB with available space.
- Room for choice: size; colour pair; icon optional; centred vs trailing on compact/medium.

### FAB menu

Opens from a FAB: close button (56, fully round, elevation 3, icon 20) plus up to six menu items (height 56, padding 24, icon 24, gap 8, title-medium, fully round, elevation 0, 4dp apart); close button 8 above the items' anchor. Items share medium-button measurements.

Colour sets (container/content): primary set = items primary-container / on-primary-container with close button primary / on-primary; secondary and tertiary sets likewise.

- Animates from the FAB's top trailing corner; FAB and close button share that anchor; larger FABs push the menu higher. On web it inherits baseline menu behaviour, 4dp gap recommended.
- Motion: FAB → close button morph on `fast.spatial`; item width on `fast.spatial`, item alpha `fast.effects`; item stagger driven by a `slow.effects` spring (Compose).
- Room for choice: colour set (primary, secondary, tertiary); 2–6 items.

## Containment and navigation

### Toolbar (docked and floating)

Replaces the bottom app bar (not recommended). Slots hold icon buttons, buttons, text fields.

- Docked: height 64, full width, surface-container, corner none, padding 16 at ends, item spacing 4–32 (default 32 between groups, 8 when centred). On web and large screens the docked toolbar may be rounded and use dividers.
- Floating: height 64 (vertical width 64), corner full, elevation 3, padding 8 at ends, 4 between items; margin 16 from window edge horizontally, 24 vertically. Optional FAB beside it (56, radius large, elevation 1; medium 80 / large-increased / elevation 2), 8 apart.
- Colours: standard = surface-container, icons on-surface-variant, selected toggle secondary-container / on-secondary-container, FAB secondary-container; vibrant = primary-container, icons on-primary-container, selected toggle surface-container / on-surface, FAB tertiary-container.
- Never shown together with a navigation bar. Targets 48.
- Motion: scrolls offscreen or collapses on `default.effects` snap; expand/collapse of a floating toolbar's content on `fast.spatial`; padding bounce on effects (Compose). It either collapses or leaves, not both.
- Room for choice: docked vs floating; standard vs vibrant; horizontal vs vertical (vertical on larger windows, either side); stay, hide on scroll, or (floating) collapse to one action; arrangement of controls as long as 16dp end padding holds; square buttons in docked toolbars; other colour roles for more or less emphasis (spec explicitly invites experimenting).

### Navigation rail (collapsed and expanded)

Leading edge of the window, outside panes, never inside body content. Collapsed: width 96 (narrow 80), top space 44, items 4 apart; item = active indicator 56×32 (fully round) with icon 24 and label below (label-medium, gap 4); 3–7 destinations; never hidden on medium+ unless the menu button stays reachable. Expanded: width 220–360, items horizontal (indicator height 56, padding 16, icon–label 8, label-large), shows secondary destinations; modal expanded = surface-container, elevation 2, radius large. Optional menu button and FAB/extended FAB at top (FAB elevation 0 in the rail).

Colours: container surface (optional surface-container); active indicator secondary-container; active icon on-secondary-container; active label secondary (vertical) or on-secondary-container (horizontal); inactive icon and label on-surface-variant; badges error / on-error. The whole rail width is the item's target.

- Motion: indicator grows from the centre on `fast.spatial` (width) with colour on `default.effects`; collapsed ↔ expanded width on `default.spatial` (modal on `fast.spatial`), content alpha `default.effects`; icon position (top ↔ start) on `default.spatial`. The FAB becomes an extended FAB when the rail expands. Destination change uses the top-level fade.
- Room for choice: collapsed or expanded (by window size and content); standard vs modal expanded; hide-when-collapsed behaviour; menu button and FAB presence; container surface vs surface-container.

### Navigation bar (flexible)

Compact and medium windows, full width, height 64, surface-container, elevation 2 (resting), 3–5 destinations. Compact: vertical items (indicator 56×32, icon 24, label-medium, gap 4), items share the width. Medium: horizontal items (indicator height 40, padding 16, gap 4), fixed width, extra space at the ends. Colours as rail (active label secondary). The 80dp baseline bar is not recommended.

- Motion: indicator expands horizontally only (one axis) on `fast.spatial`; colours on `default.effects`; destination change uses the top-level fade.
- Room for choice: whether a destination keeps its state or resets on reselect.

### Card

Elevated (surface-container-low, elevation 1), filled (surface-container-highest, 0), outlined (surface, outline-variant 1dp, 0). Shape medium (12); padding 16; gap between cards at most 8; text start-aligned. Interactive cards show hover/focus/press/drag state layers (on-surface), dragged may raise elevation. Cards have no selected state and no press morph.

- Motion: state layers on effects; elevation change on `fast.spatial`; opening a card uses container transform (hero, shallow hierarchy) or forward/backward.
- Room for choice: which of the three styles; content layout inside the card.

### List (expressive)

Item heights: one line 56, two lines 72, three lines 88; padding 16 start/end, 10 top/bottom, 12 between elements; leading icon 24 (expressive 20), avatar 40 (fully round, primary-container / on-primary-container), image 56 (radius small), video 100×56 / 114×64. Label body-large on-surface; supporting body-medium on-surface-variant; overline and trailing text label-small. Alignment: centred; top-aligned at 88+. Targets 48.

Styles: standard (container surface) or segmented (items separated by 2dp gaps, inner corners 4, outer corners 16). Selected item: corners 16 all round, container secondary-container with on-secondary-container content (tokens; the spec page's colour list names primary-container, see Room for choice). Divider 1dp outline/outline-variant, insets 16.

- Motion: selection corner morph on `fast.spatial`; colour on `default.effects`; drag elevation on `fast.spatial`; expand/collapse of a nested list on `fast.spatial`.
- Room for choice: standard vs segmented style (visual only); slot contents (leading: avatar, icon, image, video, checkbox, radio, switch; trailing: icon, icon button, text, checkbox, radio, switch); one selection mode per list.
- Room for choice: selected fill secondary-container (tokens) or primary-container (spec colour table); the sources disagree.

### Menu (vertical, expressive)

Container surface-container-low (standard) or tertiary-container (vibrant), elevation 2, radius large (16). Item height 44, padding 16 horizontal / 8 vertical, icon 20, gap 12; items radius extra-small with first/last item medium (16) outer corners; selected item radius medium, standard selected tertiary-container / on-tertiary-container, vibrant selected tertiary / on-tertiary. Groups 2dp apart (group radius small) or separated by dividers. Label label-large, supporting body-small. Baseline menu (radius 4, 48 items, 112–280 wide) still allowed but not the M3E look.

- Opens from its trigger (trigger shows pressed), repositions to stay on screen, submenus open beside the parent without overlap.
- Motion: enter/exit scale on `fast.spatial` + alpha `fast.effects` from the trigger; submenu focus morph (focused rounder, others less round) on `fast.spatial`; item colours on `fast.effects`. On dense desktop products menus may open instantly.
- Room for choice: standard vs vibrant colour (vibrant sparingly); gaps vs dividers between groups; instant open on desktop; density −1 to −3 on web.

### Dialog (basic)

Container surface-container-high, elevation 3, radius extra-large (28); width 280–560; padding 24; icon 24 secondary (centres the layout when present); headline headline-small on-surface; supporting body-medium on-surface-variant; actions text buttons (label-large, primary), trailing-aligned, 8 apart, 24 below the body; title-to-body 16. At most two actions. Scrim behind. Full-screen dialog: corner 0, header 56, surface-container-high, for compact windows.

- Motion: enter/exit transition; any fade kept short (the spec warns against slow fades over content); scrim fades on effects.
- Room for choice: icon, headline and divider are optional; basic vs full-screen by window size.

### Search (bar and view)

Search bar: height 56, fully round, surface-container-high, elevation 3 (app-bar search: surface-container, no elevation), leading icon 24 on-surface, input body-large on-surface, placeholder includes the word "Search", up to two trailing icons or avatar (30) plus one icon. Search view: docked (radius extra-large 28, header 56) or full-screen (corner 0, header 72), surface-container-high, divider outline; contained variant: results gap 2, results radius medium.

- Motion: full-screen expand on `slow.spatial`, collapse on `default.spatial`; contained bar expand/collapse `fast.spatial`; with-gap variant expand `default.spatial`, collapse `fast.spatial`; field colours on `fast.effects`; scroll snap on `default.effects`.
- Room for choice: docked vs full-screen view by window size; leading element (search icon, menu or brand logo); trailing avatar/icons within the limits.

### App bar (top)

Small: height 64, title title-large (subtitle label-medium); medium flexible 112 (136 with subtitle), headline-medium; large flexible 120 (152), display-small. Container surface, scrolled surface-container with elevation 2. Leading/trailing space 4; up to two trailing icon buttons on compact, four on larger windows.

- Motion: container colour change on scroll on `default.effects`; collapse/expand snap on `fast.spatial` (flexible) or `default.effects`.
- Room for choice: small vs medium/large flexible; centred or start title; image logo; two-line headline in flexible variants.

### Tabs

Primary: height 48 (64 with icon and label), indicator 3dp primary with top corners 3, label title-small, active primary / inactive on-surface-variant, divider 1dp surface-variant. Secondary: indicator 2dp primary, active label on-surface. Container surface.

- Motion: indicator position and width on `default.spatial`; label colour fade-in `default.effects`, fade-out `fast.effects`; content switches with a lateral transition.
- Room for choice: fixed vs scrollable; centred or start-aligned fixed group; tabs fixed to top or scrolling away and returning on scroll up; icons and badges optional.

## Communication and selection

### Loading indicator

Container 48×48; active indicator 38. Default: indicator primary, no container. Contained: indicator on-primary-container on a primary-container circle. For short waits (200ms–5s) with unknown duration; centred on the loading element, or in the empty space where new content appears; can sit inside a button.

- Motion: seven-shape morph loop (see `shape.md`: SoftBurst, Cookie9Sided, Pentagon, Pill, Sunny, Cookie4Sided, Oval; spring 0.6/200 every 650ms, +90° per morph, plus one turn per 4666ms). Determinate: Circle → SoftBurst with progress. With reduced motion, stop shape cycling.
- Do not transition a loading indicator into a determinate progress indicator; use an indeterminate progress indicator when progress will become known.
- Room for choice: default vs contained.

### Progress indicator (linear and circular)

Track 4dp secondary-container, active indicator 4dp primary, 4dp gap between them, all fully round; linear determinate has a 4dp primary stop dot at the end (required when the track is under 3:1 against its background). Linear inset 4 from screen edges. Circular size 40. Wavy: linear amplitude 3, wavelength 40 (indeterminate 20), container height 10; circular amplitude 1.6, wavelength 15, size 48. Thick sample: 8dp track and indicator (linear height 8, wavy 14; circular 52).

- Behaviour: determinate fills 0–100% from the leading edge (circular from top, clockwise); indeterminate grows and shrinks along the track; switch indeterminate → determinate when progress becomes known; at low values the indicator shows as a dot. One indicator per group of loading items.
- Motion: determinate progress changes on a non-bouncy, very low stiffness spring (Compose) or linear 500ms (wavy); wave amplitude ramps in over 500ms (standard easing) after 10% and out (emphasized accelerate) at 95%; indeterminate cycles linear 1750ms / circular 6000ms. Wave scales with size.
- Room for choice: flat vs wavy (wavy for longer processes and expressive tone); thickness (the thick values are samples to adjust from); linear vs circular.

### Slider

Sizes (track height / handle height / track corner / inset icon): XS 16 / 44 / 8 / none (default); S 24 / 44 / 8; M 40 / 52 / 12 / 24; L 56 / 68 / 16 / 24; XL 96 / 108 / 28 / 32. Handle 4 wide (2 when pressed or focused), 6dp gap on each side of the handle; tracks fully round outer corners, 2dp inner corners at the handle. Active track primary, inactive secondary-container; handle primary; stop dots 4dp (on-primary on active, on-secondary-container on inactive); value indicator 48×44 inverse-surface with label-large inverse-on-surface. State layer 40. Variants standard, centred, range; horizontal or vertical.

- Motion: handle width narrows on press (spatial); value indicator appears while interacting; colours on effects.
- Room for choice: size (S–XL via tokens), orientation, inset icon, stop indicators, value indicator, range vs single; for range sliders show one value at a time.

### Switch

Track 52×32, outline 2 (unselected), fully round. Handle 16 unselected, 24 selected or with icon, 28 pressed. State layer 40, target 48. Selected: track primary, handle on-primary, icon (16) on-primary-container. Unselected: track surface-container-highest, outline and handle outline, icon surface-container-highest. Adjacent label on-surface. Acts immediately; binary on/off only (opposing options use a connected button group, single choice from a list uses radios).

- Motion: handle position and size on `fast.spatial`; track and handle colour on `fast.effects`.
- Room for choice: icons on none, selected only, or both states.

### Chips (assist, filter, input, suggestion)

Height 32, radius small (8), label label-large, icon 18. Flat: outline-variant 1dp, no elevation; elevated: surface-container-low, elevation 1 (only on busy backgrounds, never directly on the page). Filter selected: secondary-container / on-secondary-container, no outline. Assist icon primary; label on-surface. 8dp between chips; secondary actions need 48dp targets (min chip width 88 or label 42). All chip sets on a page are either single- or multi-select.

- Motion: a selected filter chip's leading check expands in (`fast.spatial` width, `slow.effects` fade) and leaves (`default.effects` shrink, `fast.effects` fade); colours on effects. No press morph by default.
- Room for choice: chip type by purpose and author; flat vs elevated where allowed; optional leading icon/avatar; horizontal scroll for single-row sets.

## Sources

- Material Design 3 component pages, "Specs" and "Guidelines" for buttons, button groups, split button, FAB, extended FAB, FAB menu, icon buttons, toolbars, navigation rail, navigation bar, loading indicator, progress indicators, sliders, cards, lists, menus, dialogs, chips, switch, tabs, search, app bars: https://m3.material.io/components/<name>/specs and /guidelines. Google, vendor documentation, paraphrased, facts only. Read 2026-11-16.
- Material Design 3, "Elevation: Tokens" (resting levels per component), https://m3.material.io/styles/elevation/tokens. Vendor documentation, facts only.
- Material Web component token files (`_md-comp-*.scss`, `latest`), https://github.com/material-components/material-web/tree/main/tokens/versions/latest/sass. Apache-2.0, token values as facts.
- androidx Compose Material3 component token files and implementations (`Button.kt`, `IconButton.kt`, `ButtonGroup.kt`, `SplitButton.kt`, `ToggleButton.kt`, `FloatingActionButton.kt`, `FloatingActionButtonMenu.kt`, `FloatingToolbar.kt`, `NavigationRail.kt`, `WideNavigationRail.kt`, `NavigationBar.kt`, `NavigationItem.kt`, `Chip.kt`, `ListItem.kt`, `Menu.kt`, `SearchBar.kt`, `AppBar.kt`, `Tab.kt`, `TabRow.kt`, `Switch.kt`, `Slider.kt`, `ProgressIndicator.kt`, `WavyProgressIndicator.kt`, `LoadingIndicator.kt`), https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3. Apache-2.0, values and spring assignments as facts.
