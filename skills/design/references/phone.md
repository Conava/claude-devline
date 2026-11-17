# Phone: its own composition, not a shrunk desktop

Web pages are always designed for desktop and phone. App UIs and widgets get a phone layout when the product runs on phones. The phone is designed with the same care as desktop, not left to whatever the desktop layout collapses to.
Sources: written for devline; platform facts from MDN (viewport units, `env()` safe areas, `hover`/`pointer` media features) and the Apple and Material touch-target guidance. Paraphrased.

## Composition
- **Decide the first phone screen on its own.** What leads at 390x844 may differ from desktop: often the one thing a visitor came for (the opening hours, the next event, the install command), with the signature in view. Write it down before building.
- **One idea per screen.** A desktop row of three becomes three moments in reading order, not three squeezed columns or a stacked pile with equal weight.
- **Reading order is the DOM order.** Re-order with grid areas where the phone story differs; never by absolute positioning.
- **Collapse with intent.** Secondary detail moves behind a disclosure (`<details>`, a sheet, a tab) or further down; nothing important is only reachable on desktop.
- **Thumb reach.** Primary actions sit in the lower half or a bottom bar; navigation at the bottom where the product has a few top-level places. Nothing essential only in the top corners.
- **Touch, not hover.** Every hover affordance has a tap equivalent; nothing is hover-only (`@media (hover: hover)` for the hover layer, `(pointer: coarse)` for larger targets). Targets ≥44px with ≥8px between them.
- **Type and measure.** Body 16-18px, measure 30-45ch; display sized with `clamp()` so the longest real headline fits without breaking words; fewer sizes than desktop.
- **Viewport and safe areas.** `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`. Full-height scenes use `100svh` (or `dvh` when it should follow the toolbar), never `100vh`. Pad fixed bars and edge content with `env(safe-area-inset-*)`.
- **No horizontal scroll** unless it's a designed carousel with a visible next item. Landscape (844x390) still works: nothing cut off, pinned scenes fit or unpin.

## The signature on phones
The moment has to exist on the phone too, adapted rather than dropped:
- **Driven by scroll and touch**, never by the cursor: anything that follows the pointer on desktop follows scroll progress, a drag or device tilt on phone.
- **Lighter 3D:** DPR cap 1.5 (1 on low-end), fewer draw calls, simpler materials (no transmission, no real-time shadows where a baked one does), smaller textures, a smaller canvas when the scene doesn't need full screen. It must hold 60fps on a mid-range phone.
- **Pinned scenes** are shorter on phone and never trap the scroll.
- **A designed fallback** when it can't run (no WebGL, low power, reduced motion): the key frames as stills that still tell the transition chain, not an empty box.
- Storyboards and builds say in one line how the signature works on the phone.
