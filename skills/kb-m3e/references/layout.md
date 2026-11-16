# M3E layout, density and desktop input

Breakpoints (formerly window size classes), panes, spacing, density, elevation and pointer/keyboard behaviour, then the deviations real desktop projects have made deliberately. Units are dp (on desktop, logical pixels at 1:1).

Item style: `**Rule.** Why. Check: how to verify`. `Room for choice:` lines mark what may be decided.

## Breakpoints

| Breakpoint | Width | Margins | Spacer | Panes (recommended / allowed) | Navigation |
|---|---|---|---|---|---|
| Compact | < 600 | 16 | n/a | 1 | navigation bar; modal expanded rail |
| Medium | 600–839 | 24 | 24 | 1 / 2 (low-density only) | navigation bar (horizontal items) or collapsed rail; modal expanded rail |
| Expanded | 840–1199 | 24 | 24 | 2 / 1 | collapsed rail; modal or standard expanded rail |
| Large | 1200–1599 | 24 | 24 | 2 / 1 | collapsed or expanded rail |
| Extra-large | ≥ 1600 | 24 | 24 | 2 / 1 or 3 | expanded rail (collapse when space is needed) |

Height breakpoints (compact/medium/expanded) exist on Android but rarely matter for scrolling layouts.

- **Classify by the window, not the device.** Window space changes with resizing, split screen and multi-window. Check: layout switches on the current window width; resizing a desktop window across 600/840/1200/1600 swaps layouts live.
- **Margins and spacers come from the table.** Check: outer margins 16 on compact and 24 elsewhere; spacers between panes 24.
- **Swap only functionally equivalent components across breakpoints.** Bar ↔ collapsed rail ↔ expanded rail; full-screen dialog ↔ basic dialog; bottom sheet ↔ menu. Never swap a button for a chip or menu. Check: each swap is in this list.
- **Keep reading order and colour mapping the same across breakpoints.** Body stays surface, navigation stays surface-container at every size; element order stays the same for screen readers and keyboard. Check: compare compact and expanded screenshots for role changes and tab order.
- **Line length 40–60 characters.** Check: text columns on large and extra-large windows are constrained (max width) or split into panes.
  Room for choice: which breakpoints a product designs for; the spec says large and extra-large are optional and platform-dependent.

## Panes

- **Every layout has 1–3 panes and at least one flexible pane.** Check: count panes; more than three is off-spec.
- **Fixed pane widths.** Fixed-and-flexible layout: fixed pane 360 on expanded, 412 on large and extra-large. Side sheet as third pane on extra-large only, max width 400. Check: fixed panes use these widths.
- **Split-pane keeps the spacer visually centred.** With a rail or drawer, the navigation plus the first pane take 50% of the window. Check: spacer x-centre equals window centre.
- **Resizable panes use a drag handle and snap to 360 or 412 when snapping is enabled.** Check: drag handle present; a tap/double-tap/long-press toggles sizes.
  Room for choice: split-pane vs fixed-and-flexible; persistent (remembered) vs temporary resizing (spec recommends persistent for most); snapping on or off; where the fixed pane sits (either side).
  Room for choice: single pane on large/extra-large for dense or media content.
- **Large windows adapt down dynamically.** Leaving full screen, entering split view or resizing a free-form window drops to the smaller layout. Check: resize test.

## Spacing and density

- **Spacing groups and directs attention; it is not decoration.** Related elements sit closer (implicit grouping), unrelated ones further (or use outlines/dividers for explicit grouping); similar items share sizes and spacing; leading elements align. Check: equal gaps between peer items; leading icons/avatars on one vertical line.
  Room for choice: generous vs dense spacing as product tone (the spec notes desktop layouts can be more generous than mobile).
- **Density is opt-in and never automatic.** Component density steps 0, −1, −2, −3, each usually −4dp of height or vertical padding; text size never changes; targets stay 48×48. Density must not change across breakpoints or orientation unless the person changes it, and the setting that controls it uses default (0) density. Check: dense variants only appear behind a user setting; dense targets ≥ 48; no density on menus' focused selection, snackbars or dialogs.
  Room for choice: offering a density setting and which surfaces it affects (lists, tables, long forms, toolbars, web menus).
- **Elevation levels.** 0 = 0, 1 = 1, 2 = 3, 3 = 6, 4 = 8, 5 = 12dp. Resting levels: 3 for FAB, extended FAB, FAB menu close button, modal dialogs, search, date/time pickers; 2 for scrolled app bar, menu, navigation bar, rich tooltip, toolbar; 1 for elevated button, elevated card, elevated chips, banner, modal sheets and drawers; 0 for filled/tonal/outlined buttons, button groups, filled/outlined cards, chips, lists, rail, icon buttons, sliders, split buttons, tabs, full-screen dialog, FAB in a rail. Hover usually raises one level. Surface tint is deprecated. Check: shadow level per component; no tint overlays.

## Pointer, hover and keyboard (desktop)

- **Hover is a state layer at 0.08 of the content colour, faded on an effects spring.** One hover at a time. Hover applies to action, selection and input components (buttons, cards, chips, list items, sliders, switches, text fields, pickers) but not to app bars, badges, dialogs, menus as a whole, navigation containers, sheets or tabs as a whole; actionable children inside them get their own hover. Disabled components show no hover. Check: hover a mockup's every interactive element; the container of a bar or menu does not light up.
- **Show the right cursor.** Pointer by default; hand for links and linked images; resize arrows on resizable edges (pane handles, windows); I-beam over selectable or editable text. Check: cursor shapes in code (`cursorShape`, CSS `cursor`).
- **Secondary click opens a context menu.** Check: right-click (and two-finger click) on actionable objects opens their menu; it never triggers the primary action.
- **Tooltips on hover where applicable.** Check: icon-only buttons have tooltips.
- **Mouse wheel and two-finger scroll move the scroll area under the cursor**, horizontally too (carousels, horizontal chip rows). Dragging in text with a mouse selects; it does not scroll. Check: only the pane under the cursor scrolls.
- **Text selection by pointer uses one highlight colour and the context menu, not touch handles.** Click places the caret, double-click selects a word, triple-click a paragraph.
- **Keyboard: everything reachable by Tab, with a visible focus ring.** Focus ring 3dp secondary, offset 2 outside (−3 inside list/menu items); focus state layer 0.10. One focus at a time. A physical keyboard supports every action the virtual one does. Check: tab through a screen; every interactive element shows the ring and can be activated from the keyboard.
- **Targets stay 48×48 even with a mouse.** The spec's density rules keep 48 as the default target. Check: dense desktop variants only behind an opt-in.
- **Menus may open instantly on dense desktop products.** Room for choice: instant or animated open.

## Deliberate desktop deviations (from real projects)

Patterns that desktop shells and settings apps built on M3E have adopted on purpose, each documented as a decision against a specific spec line. In strict mode they are **not** defaults: apply one only when the project's own docs record the same decision; otherwise the spec wins. When applying one, cite the project decision in the output.

- **Primary page action as a centred bottom FAB bar at every width.** Spec: extended FAB moves to the bottom-right (or into the rail) at expanded widths. Deviation: settings pages keep it bottom-centre at all sizes, sometimes with two extended FABs in one bar, for consistency across pages. Check: the project's decision record names it.
- **Switches that commit on Save inside forms.** Spec: switches act immediately; settings that need saving use checkboxes. Deviation: forms keep switch rows and commit with a pending-changes FAB, so one form uses one control style.
- **Inline confirm row instead of a confirmation dialog for destructive actions.** Spec: a dialog. Deviation: "no popups" in settings; the inline row still names the object (no bare "Are you sure?").
- **Selected cards shown with a primary outline and a check badge.** Spec: cards have no selected state; lists show selection with a filled container and corner morph. Deviation: gallery cards keep thumbnails readable.
- **Card grid gaps above 8dp and one shared card shape.** Spec: at most 8dp between cards; optical roundness for nested media. Deviation: one gap token and one card shape shared by every gallery in the product.
- **One shared field style; no outlined text fields.** Spec offers filled and outlined fields. Deviation: a single field style product-wide.
- **Corner radii clamped to what an external consumer can render.** Compositor or window-manager rounding has its own upper limits (one such limit is 20); values passed to it are clamped instead of mapped to larger scale steps.

Practices those projects follow that are consistent with the spec (apply in strict mode as normal rules): forms and detail panes as one connected segmented list (2dp gaps, large outer radius); one filled button per section with tonal secondary actions and text-button dialog dismissal; labels left and controls right in setting rows with one inset; whole clickable surfaces show hover and the hover background is never clipped; right-click never triggers the primary action; every tunable size or alpha lives in the theme or metrics file, never inline; all motion respects a global animation-speed or reduced-motion setting.

## Sources

- Material Design 3, "Breakpoints" overview and the compact, medium, expanded and large & extra-large pages, https://m3.material.io/foundations/layout/applying-layout/window-size-classes (and sibling pages). Google, vendor documentation, paraphrased, facts only. Read 2026-11-16.
- Material Design 3, "Scaffold: Panes", https://m3.material.io/foundations/layout/applying-layout/pane-layouts. Vendor documentation, paraphrased.
- Material Design 3, "Grids & spacing: Spacing" and "Density", https://m3.material.io/foundations/layout/understanding-layout/spacing and https://m3.material.io/foundations/layout/understanding-layout/density. Vendor documentation, paraphrased.
- Material Design 3, "Elevation: Tokens", https://m3.material.io/styles/elevation/tokens. Vendor documentation, facts only.
- Material Design 3, "States: Applying states", https://m3.material.io/foundations/interaction/states/applying-states, and "Inputs", https://m3.material.io/foundations/interaction/inputs. Vendor documentation, paraphrased.
- Material Design 3, "Menus: Guidelines" (instant open on desktop), https://m3.material.io/components/menus/guidelines. Vendor documentation, paraphrased.
- Material Web `_md-sys-elevation.scss`, `_md-sys-state-focus-indicator.scss`, https://github.com/material-components/material-web/tree/main/tokens/versions/latest/sass. Apache-2.0, token values as facts.
- Deliberate deviations: design decision records of open-source desktop shell and settings projects built on Material 3 Expressive, generalized from the plugin author's own project work (own work, ideas only; no project text copied).
