---
name: frontend-design
description: "Use when the user asks to 'build a UI', 'create a web page', 'design a component', 'frontend design', 'make it look good', or when implementing tasks tagged with the frontend-design domain skill. Provides aesthetic principles for distinctive, production-grade interfaces."
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Frontend Design Skill

## Design Thinking Framework

Before writing any code, work through the following four considerations. Do not skip this step — it is the foundation of every design decision that follows.

1. **Purpose.** Identify the problem being solved. Understand who the user is, what context they arrive in, and what outcome they need. Every visual decision must serve this purpose.

2. **Tone.** Choose a bold, intentional aesthetic direction. Commit fully to it. Select from approaches such as:
   - Brutally minimal — stripped to essentials, every element earns its place
   - Maximalist chaos — dense, layered, overwhelming in a controlled way
   - Retro-futuristic — blending nostalgia with speculative technology aesthetics
   - Organic/natural — fluid shapes, earth tones, textures from the physical world
   - Luxury/refined — restrained elegance, premium materials, precise spacing
   - Playful/toy-like — rounded, colorful, tactile, inviting interaction
   - Editorial/magazine — strong typographic hierarchy, grid-driven, content-first
   - Brutalist/raw — exposed structure, harsh contrasts, deliberately unpolished
   - Art deco/geometric — bold symmetry, metallic accents, ornamental precision
   - Soft/pastel — gentle gradients, muted palette, approachable warmth
   - Industrial/utilitarian — functional, monospaced, dashboard-like density

   Do not blend directions timidly. Pick one and push it far enough that the design has unmistakable character.

3. **Constraints.** Identify the framework in use, performance budgets, browser support requirements, and accessibility standards. Design within these boundaries — never ignore them, but never let them flatten the aesthetic into generic safe choices.

4. **Differentiation.** Define one unforgettable element. This is the single detail a user remembers after closing the tab — an unusual transition, a striking color choice, a typographic flourish, an unexpected interaction pattern. Build the rest of the design to support this moment.

## Typography

Choose beautiful, distinctive fonts. Never default to generic typefaces. Arial, Inter, Roboto, and system font stacks are explicitly forbidden as primary choices. They signal indifference.

Pair a distinctive display font with a refined body font. The display font carries personality — use it for headings, hero text, and moments of emphasis. The body font carries readability — use it for paragraphs, labels, and interface text. The pairing should create tension and harmony simultaneously.

Prefer unexpected, characterful choices. Seek out fonts with strong opinions: exaggerated x-heights, unusual letterforms, distinctive weight distributions, or historical references. Use Google Fonts, Fontsource, or self-hosted options to access a wide range.

Establish a typographic scale and stick to it. Define sizes, weights, line heights, and letter spacing as design tokens. Apply them consistently. Use CSS custom properties or framework-level theme variables to enforce the scale across every component.

Set line lengths for readability — aim for 50 to 75 characters per line in body text. Use `max-width` on text containers rather than letting paragraphs stretch to fill available space.

## Color and Theme

Commit to a cohesive color system. Define all colors as CSS custom properties at the root level. Build light and dark themes from the same variable structure. Never hardcode hex values inside component styles.

Use a dominant color with sharp accents. A palette that leans heavily on one or two primary colors and deploys a contrasting accent sparingly will always outperform a timid, evenly-distributed rainbow. Let the dominant color own the experience. Let the accent color punctuate it.

Avoid cliched purple gradients on white backgrounds. This combination has become the default output of lazy generative tools. It communicates nothing. If the design calls for gradients, make them unexpected — use warm-to-cool shifts, duotone overlays, or angular gradients that break the linear norm.

Ensure sufficient contrast ratios for all text. Meet WCAG AA at minimum (4.5:1 for normal text, 3:1 for large text). Test every color combination. Accessibility is non-negotiable and does not conflict with bold aesthetics — it demands more creative solutions, not safer ones.

Define semantic color tokens: `--color-surface`, `--color-text-primary`, `--color-text-secondary`, `--color-accent`, `--color-error`, `--color-success`. Map these tokens to actual values per theme. Components reference tokens, never raw colors.

## Motion and Animation

Use animations for effects and micro-interactions. Motion communicates state changes, draws attention, and creates delight. Static interfaces feel dead. Animated interfaces feel alive.

Prefer CSS-only solutions when working with HTML. Use `transition`, `animation`, `@keyframes`, and modern CSS features like `view-transition-api` where supported. Reach for JavaScript animation libraries only when CSS cannot achieve the desired effect.

Orchestrate page load sequences. Stagger the reveal of elements using animation delays. Let content cascade onto the screen rather than appearing all at once. Control the sequence so the eye follows a deliberate path — most important elements first, supporting elements after.

Design hover states that surprise. A button that subtly shifts color is expected. A button that tilts, casts a deeper shadow, reveals a hidden icon, or inverts its palette is memorable. Push hover interactions beyond the obvious.

Implement scroll-triggered animations. Use `IntersectionObserver` or CSS `animation-timeline: scroll()` to activate elements as they enter the viewport. Fade, slide, scale, or rotate elements into position. Ensure these animations are performant — animate only `transform` and `opacity` to stay on the compositor layer.

Respect `prefers-reduced-motion`. Wrap all animations in a media query check. When the user has requested reduced motion, disable transitions and animations or replace them with simple opacity fades. Never ignore this preference.

## Spatial Composition and Layout

Break out of predictable layouts. Centered content stacks with uniform padding are the default. Reject the default. Explore asymmetry, overlap, diagonal flow, and grid-breaking element placement.

Use CSS Grid for two-dimensional layouts. Define explicit grid templates with named areas. Let elements span multiple rows or columns. Create layouts that could not exist in a simple flexbox column.

Embrace negative space deliberately. Generous whitespace around key elements creates focus and luxury. Controlled density in data-heavy interfaces creates efficiency and power. Choose the spatial strategy that serves the design's tone — do not default to medium spacing everywhere.

Layer elements using `z-index`, absolute positioning, and transforms. Let components overlap, peek from behind others, or extend beyond their containers. Flat, non-overlapping layouts feel like wireframes. Layered layouts feel like designed experiences.

Use viewport units, `clamp()`, and container queries for responsive spatial relationships. Elements should scale fluidly, not jump between breakpoints. Design for the continuum of screen sizes, not just three fixed widths.

## Backgrounds and Visual Details

Create atmosphere and depth. A solid background color is a missed opportunity. Build visual environments using gradient meshes, noise textures, geometric patterns, layered transparencies, or photographic overlays.

Apply subtle grain or noise overlays to large surfaces. A barely-visible noise texture at 2-5% opacity adds organic warmth to digital surfaces. Use CSS `background-image` with inline SVG data URIs or tiny repeated PNGs to achieve this without additional network requests.

Use dramatic shadows to establish hierarchy. Layered box shadows with varying blur radii and offsets create realistic depth. A single `box-shadow: 0 2px 4px rgba(0,0,0,0.1)` is a starting point, not a destination. Build shadow systems with multiple layers — a tight, dark shadow for the edge and a wide, diffused shadow for ambient occlusion.

Add decorative borders, dividers, and separators. Use gradient borders via `border-image`, dotted or dashed patterns, or custom SVG borders. These small details accumulate into a polished, intentional aesthetic.

Consider custom cursors for interactive areas. A unique cursor on a hero section or interactive element adds personality. Use `cursor: url(...)` with a custom SVG or PNG. Ensure the default cursor remains available for standard interface elements.

Implement glassmorphism, frosted glass, or blur effects where appropriate. Use `backdrop-filter: blur()` with semi-transparent backgrounds. These effects create depth and layer separation without hard borders.

## Anti-Patterns

Actively avoid the following. These patterns produce generic, forgettable interfaces that signal a lack of design intention.

- **Generic AI-generated aesthetics ("AI slop").** Avoid the default visual language of AI-generated UIs: soft gradients, generic illustrations, and safe color choices. If the design could be mistaken for an AI template, push harder.
- **Overused fonts.** Inter, Roboto, Arial, Open Sans, and Lato have become invisible through overuse. Choose fonts that have not been flattened into background noise.
- **Cliched color schemes.** Purple-to-blue gradients, teal accents on white, and startup-blue palettes are exhausted. Find color combinations that feel fresh.
- **Predictable layouts.** Centered hero, three-column feature grid, testimonial carousel, footer. This layout has been built a million times. Break the pattern.
- **Cookie-cutter components.** Rounded-corner cards with subtle shadows, pill-shaped buttons, and uniform spacing grids. These components are safe. Safe is boring. Redesign the fundamentals.
- **Convergence on common choices.** When every design tool and every AI model suggests the same solution, that solution has lost its power. Diverge intentionally.

## Execution Principle

Match implementation complexity to the aesthetic vision. A maximalist design demands elaborate, detailed code — many layers, many animations, many custom properties, many carefully tuned values. A minimalist design demands restraint and precision — fewer elements, but each one placed and styled with exacting care. Never pair an ambitious aesthetic vision with lazy implementation. Never pair a simple aesthetic vision with unnecessary complexity. The code serves the design. The design serves the user.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.
