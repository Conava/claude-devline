# Design system: MASTER.md and the Corrections log

After the user picks a design, its decisions become the project's design system, so later work builds on it instead of redesigning from scratch.

## Where
`docs/design-system/MASTER.md` in the project (the user may name another path). One file; page-specific additions as sections, not new files.

## Written from the chosen design
Extract what the approved design actually uses; never regenerate or "improve" it while writing it down.
1. **Concept**: the world, the signature moment, and the "X becomes Y" chain of its transitions.
2. **Tokens**: every colour (with role and the contrast pairs it's checked for), type scale (family, sizes, line heights, weights, tracking), spacing scale, radii, shadows/elevation, motion (easings or springs, durations), breakpoints. Names follow the project's toolkit (CSS custom properties, Tailwind theme, QML singleton, etc.).
3. **Components**: each component in the design with its states (default, hover, focus, pressed, disabled, selected, error, loading, empty) and its motion.
4. **Rules**: what this design never does (its own don't list), reduced-motion behaviour, no-JS/no-WebGL fallbacks.
5. **Acceptance checklist**: the checks every later UI task is verified against (contrast pairs, signature transitions still answer "what becomes the next thing", tokens only, states covered, reduced motion).
6. **Corrections**: append-only, newest last. Each entry: date, what was wrong, the rule now. Binding for every later design or implementation step; never edited or removed except by the user.

## The tokens rule
Every colour, size, radius, shadow and duration in code comes from a token. No literal values in component code; a value the spec or design needs that has no token yet becomes a new named token first. Reviewers flag literals.

## Using it
- Exploration and mockup steps read MASTER.md first; the design stays inside it unless the request is to change the design system.
- When the user corrects a design decision, append it to Corrections in the same turn.
- Strict mode (M3E): MASTER.md records only the choices taken where the spec allows, each with its spec reference; spec values themselves are not copied in.
