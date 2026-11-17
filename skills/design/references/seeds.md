# Seeds: making sketches diverge

Divergence has to be forced. Asked for "variations", models converge on the category default. A seed is a deliberate constraint on three axes, chosen so no two sketches share more than one axis.
Ideas from Impeccable's concept roll (Apache-2.0) and Charles' unreasonable-craft (paraphrased); the signature rules are in `signature.md`.

## The three axes (default mode)
- **Material / world:** what the page is made of, taken from the subject's world: an object, a place, a notation, a process, a print tradition, a medium. Not a style name like "brutalist" or "glassmorphism".
- **Motion idea:** the one thing that moves and why: a camera travelling through a scene, a line that draws the content's own sequence, a shape that becomes each next section, a pinned object that transforms, a live value that keeps updating, a live 3D subject whose form changes with the content, almost no motion (a still, typographic page).
- **Type move:** how type behaves: type as architecture (huge, the space you move through), a quiet text column beside a rich object, type set into the material, a dense ledger, one typeface at many sizes.

## Making the seeds (count from the launch, default 10)
1. Read facts and taste. Write the page this category always ships, and its obvious opposite: both are banned as seeds.
2. Write one line per seed: `material | motion idea | type move | the content it puts first | the signature moment in one sentence`.
3. Spread:
   - **Ambitious interactive/3D:** at least 1 seed is a live 3D or deeply interactive piece (a scroll-driven camera through a scene, a 3D subject that changes form with each section, a world you click through). If the taste brief asks for 3D, motion or interactivity, at least 2. For app UIs, "ambitious" means a signature interaction (a morphing control, a spatial transition between views), not a 3D scene.
   - at least 1 seed with almost no motion, carried by type and composition;
   - at least 1 seed built on the content's own sequence or process;
   - no two seeds share a material family.
4. Each seed must be able to show the real facts; a seed that needs invented content is dropped.
5. Below the seeds, list the banned default and opposite from step 1.

## Strict mode (m3e-strict)
The spec fixes tokens, components and motion, so seeds diverge on what the spec leaves open:
- **Layout archetype** for the window size class (list-detail, supporting pane, feed, single focus) where the spec allows several.
- **Expressive emphasis:** which one or two expressive features carry the design (shape morphing, emphasized type, a hero component such as a large button group or a wavy progress indicator, tonal colour from content) and where they sit.
- **Content first:** which content leads the first screen.
Every seed lists the spec choices it relies on (the `Room for choice:` items in `M3E:`). A seed that needs an off-spec value is dropped.

## A sketch is
One self-contained HTML file with the first screen finished with care and real content, plus a storyboard file: 3 key frames of the signature motion ("what's on screen → what it becomes") and one paragraph on the idea. Quick, honest, real content. No interaction or animation code; a 3D seed shows its key pose as a still. Not a moodboard.
