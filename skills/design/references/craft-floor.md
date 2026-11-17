# Craft floor

Build to this without announcing it. It holds the mechanics; it never picks the direction.
Sources: Impeccable craft floor + typeset (Apache-2.0), vercel web-interface-guidelines (MIT), Emil Kowalski (MIT), unslop (CC BY 4.0). Paraphrased.

## Type
- One family, or two clearly distinct ones (plus mono only for code/data). Sizes from a deliberate scale; at most ~5 text sizes per screen, display counted separately.
- Body measure 45-75ch; body leading 1.4-1.6 (serif a little more); display leading 0.9-1.1; display max ~6rem on desktop, `clamp()` down to phones.
- Tracking: none below ~28px; slightly negative only on display (floor -0.04em).
- `text-wrap: balance` on headings, `pretty` on prose. Typographic quotes and apostrophes. Tabular, lining numerals for figures that change or align.
- Theme the browser surfaces: `::selection`, caret, focus ring, scrollbar, underline offset.

## Space and layout
- One spacing scale (4px base). Tight inside groups, generous between them; more space above a heading than below.
- At most ~3 dominant vertical alignment lines per breakpoint. Icons on a spine, text on an edge.
- Radius by hierarchy, inner = outer - padding. One depth cue per surface.
- Works at 375, ~1024 and 1440 wide: adapted, not shrunk; the phone is its own composition (`phone.md`). Check 1000-1100 px for overflow.

## Color and contrast
- Palette from the world: 4-6 named values. Neutrals tinted toward the world; one accent used rarely.
- Contrast computed, not guessed: body ≥4.5:1, large text and icons ≥3:1, **control borders ≥3:1 against every background they sit on**, text over images/canvas measured over the real backdrop.
- Never convey state by color alone.

## Interaction and states
- Hit targets ≥40px desktop, ≥44px touch with ≥8px between them (pseudo-element if the visual is smaller). Action links people must notice are real buttons: icon + label, one primary per section.
- Visible `:focus-visible` ring, neutral, never clipped by `overflow`/masks; keyboard reaches everything in visual order.
- Hover inside `@media (hover: hover)`, named properties, ~150ms, no layout change, no `transition: all`.
- Press feedback `scale(.97)`; enter from `scale(.95)` + opacity, never from 0.
- Design every state that the content implies: empty, loading, error, offline/unreachable, no JS, no WebGL, reduced motion.
- Inputs 16px (iOS), real labels, Enter submits.
- `forced-colors` and `prefers-contrast` don't break the page.

## Content and assets
- Real content only. No placeholder copy, no invented facts, no fake logos or avatars.
- Third-party marks unaltered, with clear space, labelled.
- No content hidden at rest waiting for a script: without JS the page reads fully.
- First paint already correct (theme, fonts loaded with `font-display: swap` and sensible fallbacks); no flash of a wrong state.
- Self-contained file: inline CSS/JS. Allowed externals: Google Fonts, and pinned ES modules from jsdelivr (`three@0.170.0`, `gsap@3.12.5`) when the design needs them.
