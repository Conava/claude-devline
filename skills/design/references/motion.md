# Motion

Sources: Emil Kowalski skills (MIT), greensock/gsap-skills (MIT), CloudAI-X/threejs-skills (MIT), enzed/r3f-skills (paraphrased, no licence), Modern Web Guidance (Apache-2.0; see `web/`), plus lessons from shipped scroll-driven work. Paraphrased.

## The qualities (what makes motion feel designed)
1. **Every transition answers "what on screen becomes the next thing?"** Nothing pops in. A new state is something already visible turning into something else: a shape becomes the next frame, a line becomes a border, a dot becomes a node. If nothing carries over, redesign the transition.
2. **Two layers.** The container moves (a scene pins, a frame reshapes) while the content inside keeps living at rest (a value updates, a line draws on, a detail cycles). Nested motion reads as depth.
3. **One physical model.** One light direction, one shadow model, one easing family, one rhythm across the page.
4. **Rhythm: hold, decisive move, hold.** Calm, then a fast eased transition, then calm. Never constant wobble.
5. **The subject's own process is the narrative.** The order of the content is the order of the motion (dusk to dark; source to compiled output; queue to playback).
6. **Type is part of the scene.** Big, short headlines layered with objects; one idea per screen.
7. **Bookends.** It ends where it began, resolved (the opening shape returns as the closing one).
8. **Scroll-scrubbed progress is continuous.** Anything tied to scroll follows every pixel, forwards and backwards. Timed eases are only for discrete events (a click, a state change). Never step from station to station.
9. **Pinned scenes keep moving.** While a section is pinned, the signature element still advances with scroll; nothing freezes.
10. **Ambient layers are subordinate and persistent.** Quieter than the hero, present through every section, handed over without an edge, contrast budget computed against the text over them, paused offscreen and in hidden tabs.
11. **Reduced motion is a designed static state**, not "animations off": same information, final or best frames, nothing hidden.
12. **Nothing decorative touches or overlaps a line or a label.**

## Should it animate? (ask in order)
1. Frequency: done 100+ times a day or from the keyboard → no animation. Tens of times → minimal. Occasional → standard. Rare/first time → may delight.
2. Purpose: spatial continuity, state change, explanation, feedback, preventing a jarring jump. "Looks cool" on a frequent action → cut.
3. Curve: entering/exiting → strong ease-out (`cubic-bezier(.23,1,.32,1)`); moving on screen → ease-in-out (`cubic-bezier(.77,0,.175,1)`); hover/color → ease, ~150ms; constant → linear; follows a finger or can be interrupted → spring without bounce. `ease-in` alone is never an entrance.
4. Duration: press/hover 100-150ms; tooltip/menu 150-250 (exit 20-30% faster); panel 200-300; page-level 300-400; a one-off choreography ≤2.5s with no dead stretch. Scroll-scrubbed motion has no duration: it is the scroll.
5. Interruptible: input is never locked; reversing aims at the current target; scrubbed scenes fully reversible with no end-of-travel jump.

## Chooser: which tool
| Need | Use | Notes |
|---|---|---|
| Scroll-linked reveal, progress, parallax-free scrubbing of transform/opacity/clip-path | **CSS scroll-driven animations** (`animation-timeline: scroll()/view()`, `view-timeline`) | Runs on the compositor, no JS, no jank. Feature-detect with `@supports (animation-timeline: view())`; fallback = the static final state. See `web/scrollytelling.md`, `web/scroll-entry-exit-effects.md`. |
| State change within a page or between pages, shared-element morphs | **View Transitions** (`document.startViewTransition`, `view-transition-name`) | Same-document is widely supported; give morphing elements a stable name. See `web/faster-spa-view-transitions.md`. |
| Pinned multi-step scenes, timelines with many coordinated parts, SVG morphs, scrubbing values CSS can't reach | **GSAP + ScrollTrigger** (`gsap@3.12.5` from jsdelivr ESM) | Put the ScrollTrigger on the timeline, not on child tweens; `scrub: true` (or a small number for smoothing); `pin` the scene; `invalidateOnRefresh`; kill on teardown; use `gsap.matchMedia()` for reduced motion and breakpoints. |
| A live 3D subject, scroll-scrubbed camera through a scene, materials and light | **three.js** (`three@0.170.0` via importmap) | One canvas, fixed behind content or pinned. Map scroll to a normalized progress 0..1, damp it (`p += (target - p) * 0.1` per frame), drive camera and scene from the damped value. `renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5))`. Render only when visible and when progress or time changes; pause on `visibilitychange`. Dispose geometries/materials. Reduced motion: render the key frames as static stills. No-WebGL fallback: a static drawn/SVG version. |
| Simple hover/press/disclosure | CSS transitions | Named properties only. |

Pick the lightest tool that achieves the idea; don't mix GSAP and another JS animation library. Native scroll only: no scroll hijacking, no smooth-scroll libraries that take over the wheel.

## Performance budget
- Animate `transform`, `opacity`, `clip-path`, `filter` (small blur, never scrubbed); avoid layout properties. `stroke-dashoffset` paints on the main thread: fine for small SVGs, not for full-page lines.
- 60fps target: no long task >50ms during scroll; p95 frame gap ≤20ms.
- DPR cap 1.5 for canvases; keep draw calls low; instancing for repeated meshes; textures power-of-two and small.
- Main-thread scroll handlers only read `scrollY` and write one variable; no layout reads in the loop.
