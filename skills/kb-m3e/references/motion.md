# M3E motion

Material 3 Expressive replaces easing-and-duration motion with a physics system built on springs. Every animated property in an M3E product uses a spring token, picked by **type** (spatial or effects) and **speed** (fast, default, slow), under one **scheme** (expressive or standard). Durations and cubic curves survive only as a fallback for platforms without springs and for page transitions. Units are dp and ms.

Item style: `**Rule.** Why. Check: how to verify`. Lines starting `Room for choice:` mark the only places a design may decide; everything else is fixed in strict mode.

## Schemes and spring tokens

Token names are `md.sys.motion.spring.<speed>.<type>`; the scheme is chosen once at product level and is not part of the token name. A spring is a damping ratio plus a stiffness (initial velocity comes from the gesture).

| Token | Expressive damping / stiffness | Standard damping / stiffness |
|---|---|---|
| fast.spatial | 0.6 / 800 | 0.9 / 1400 |
| default.spatial | 0.8 / 380 | 0.9 / 700 |
| slow.spatial | 0.8 / 200 | 0.9 / 300 |
| fast.effects | 1.0 / 3800 | 1.0 / 3800 |
| default.effects | 1.0 / 1600 | 1.0 / 1600 |
| slow.effects | 1.0 / 800 | 1.0 / 800 |

Effects springs are identical in both schemes (critically damped, no overshoot). Material Web's `md-sys-motion` publishes the standard values only; the expressive values come from Compose's `ExpressiveMotionTokens`.

- **Use the expressive scheme unless the product is utilitarian.** The spec calls expressive Material's opinionated default, especially for hero moments and key interactions; standard eases in with minimal bounce. Check: one scheme is declared at theme level (a `MotionScheme`, a QML singleton, CSS custom properties), and components read tokens from it rather than literals.
  Room for choice: expressive or standard as the product scheme; a custom scheme built from the same six slots.
  Room for choice: swapping to the other scheme for a specific element or screen (the spec's "level 3" customization), when the reason is stated.
- **Spatial springs for anything that moves or changes geometry; effects springs for colour and opacity.** Spatial overshoots and settles (position, size, rotation, corner radius); effects must not overshoot. Check: every colour/alpha animation uses an `effects` token; every x/y/width/height/scale/rotation/corner animation uses a `spatial` token. An overshooting opacity or colour is off-spec.
- **Pick speed by the size of what moves.** The spec's table: fast for small components (switches, buttons; effects example: switch handle colour), default for things that partially cover the screen (bottom sheet, expanded navigation rail; effects example: opacity of rail content), slow for full-screen animations (full-screen content refresh). Check: a full-screen change on `fast`, or a button press on `slow`, is off-spec.
- **Component motion uses the fast tokens.** The spec states that all component motion is driven by expressive fast spatial and fast effects; the per-component entries in `components.md` list the exceptions the tokens and Compose implementation define. Check: a component animation names its token and matches the component entry.
- **Never hand-tune damping or stiffness per animation.** The point of the token set is predictability; per-device tuning is done by the platform, which may use different values per form factor (wearable, phone, tablet) as long as fast is faster than default and default faster than slow. Check: no literal spring constants outside the theme's motion scheme.

## Without a spring engine (web curves)

The spec's conversion table for animations without interruption or gestures. Use real springs whenever the platform has them (QML `SpringAnimation` or a custom spring; CSS `linear()` easing sampled from a spring; Web Animations with a spring-generated curve).

| Spring | cubic-bezier | Duration |
|---|---|---|
| Expressive fast spatial | 0.42, 1.67, 0.21, 0.90 | 350ms |
| Expressive default spatial | 0.38, 1.21, 0.22, 1.00 | 500ms |
| Expressive slow spatial | 0.39, 1.29, 0.35, 0.98 | 650ms |
| Expressive fast effects | 0.31, 0.94, 0.34, 1.00 | 150ms |
| Expressive default effects | 0.34, 0.80, 0.34, 1.00 | 200ms |
| Expressive slow effects | 0.34, 0.88, 0.34, 1.00 | 300ms |
| Standard fast spatial | 0.27, 1.06, 0.18, 1.00 | 350ms |
| Standard default spatial | 0.27, 1.06, 0.18, 1.00 | 500ms |
| Standard slow spatial | 0.27, 1.06, 0.18, 1.00 | 750ms |
| Standard fast / default / slow effects | as expressive effects | 150 / 200 / 300ms |

- **A curve fallback must come from this table, paired with its duration.** Check: every `cubic-bezier` or `Easing.Bezier` in M3E code matches a row and its duration; legacy curves on component motion are off-spec.
- **Interruptible or gesture-driven motion needs a real spring.** Curves cannot retarget mid-flight with velocity. Check: drags, flings, press/release morphs and anything retargeted while running use a spring, not a curve.
- **QML mapping.** `SpringAnimation` takes `spring`, `damping` and `mass` in its own units, not Compose's ratio/stiffness pair (exact unit mapping unverified); the safe route is a small custom integrator driven by the token values (unit mass: ω = √stiffness, ζ = damping ratio). Check: the project documents its conversion once, in the motion singleton, and tests that fast settles before default.

## Legacy easing and duration (transitions only)

The spec keeps these "no longer maintained" tokens for page transitions and teams not yet on springs. Transitions (container transform, forward/backward, lateral, top level, enter/exit) still use them.

- Easing: emphasized `cubic-bezier(0.2, 0, 0, 1)` as CSS fallback (Android uses a two-segment path); emphasized decelerate `0.05, 0.7, 0.1, 1`; emphasized accelerate `0.3, 0, 0.8, 0.15`; standard `0.2, 0, 0, 1`; standard decelerate `0, 0, 0, 1`; standard accelerate `0.3, 0, 1, 1`; legacy `0.4, 0, 0.2, 1`; linear.
- Durations: short1–4 = 50/100/150/200ms; medium1–4 = 250/300/350/400ms; long1–4 = 450/500/550/600ms; extra-long1–4 = 700/800/900/1000ms.
- **Transitions use these tokens and a simple style.** The spec forbids overt effects such as bouncy springs on common transitions. Check: no spatial-expressive overshoot on page-to-page navigation; top-level destination switches (bar, rail, drawer) use a quick fade, not a lateral slide.
  Room for choice: which transition pattern fits (container transform for hero moments and shallow hierarchies, platform forward/backward for common navigation, lateral for peers, top level fade for nav destinations, enter/exit for sheets and dialogs).
- **Fade out fully before fading in.** Cross-faded half-transparent frames look messy; a needed cross-fade stays short. Check: frame-step a transition; no frame shows two layers of content at partial alpha for long.
- **Prefer an animated transition over a jump cut.** Jump cuts disorient. Exception the spec names: pure-efficiency surfaces such as a productivity menu. Check: any instant swap is one of the named exceptions.

## Reduced motion

- **Honour the platform's reduce-motion setting.** When it is on, the spec says transitions use subtle fades instead of sliding or scaling, and decorative effects such as parallax and shape morphing are disabled. Check: toggle the setting (or the app's own animation-speed control); morphs (button press, toggle, loading-indicator sequence, menu corner) stop, slides become fades, nothing important becomes invisible.
- **Reduced motion keeps state changes visible.** Turning motion off must not drop the state change itself (selected shape, colour, indicator position snap to their end values). Check: with motion off, every end state still renders.
- **Dense desktop menus may open instantly.** The spec allows instant menus on desktop to reduce motion. Room for choice: instant or animated menu open on desktop.

## Motion is mandatory

- **Every component state change has a defined animation.** Strict mode treats a missing animation as off-spec just like a wrong one. Check: for each component in a mockup or diff, `components.md` names its motion; the implementation animates exactly those properties with exactly those tokens.

## Sources

- Material Design 3, "Motion physics system: How it works" and "Specs" (including the web spring-to-curve table), https://m3.material.io/styles/motion/overview/how-it-works and https://m3.material.io/styles/motion/overview/specs. Google, vendor documentation, paraphrased, facts only. Read 2026-11-16.
- Material Design 3, "Easing and duration: Tokens & specs", https://m3.material.io/styles/motion/easing-and-duration/tokens-specs. Vendor documentation, paraphrased, facts only.
- Material Design 3, "Transitions: Applying transitions" and "Transition patterns" (reduced-motion and fade rules), https://m3.material.io/styles/motion/transitions/applying-transitions. Vendor documentation, paraphrased.
- Material Design 3, "Menus: Guidelines" (instant open on desktop), https://m3.material.io/components/menus/guidelines. Vendor documentation, paraphrased.
- androidx Compose Material3 `tokens/ExpressiveMotionTokens.kt`, `tokens/StandardMotionTokens.kt`, `tokens/MotionSchemeKeyTokens.kt`, `tokens/MotionTokens.kt`, `MotionScheme.kt`, https://github.com/androidx/androidx/tree/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3. Apache-2.0, token values as facts.
- Material Web `tokens/versions/latest/sass/_md-sys-motion.scss`, https://github.com/material-components/material-web/tree/main/tokens/versions/latest/sass. Apache-2.0, token values as facts.
