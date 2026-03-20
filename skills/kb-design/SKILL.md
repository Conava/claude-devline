---
name: kb-design
description: Design intelligence for UI/UX — injected into the frontend-planner agent. Provides BM25-searchable database of 67 styles, 161 color palettes, 57 font pairings, 160 animated component patterns, 161 industry rules, plus framework-agnostic design guidelines. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Frontend Development

Create distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices. Framework-agnostic — covers web, mobile, and desktop platforms.

## Design Thinking

Before writing any code, understand the context and commit to a **BOLD** aesthetic direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick a clear direction and commit fully. Options for inspiration: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian. Use these as starting points but design something true to the specific context.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work — the key is intentionality, not intensity.

Then implement working code that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details.

## Aesthetics Guidelines

### Typography

Choose fonts that are beautiful, unique, and interesting. **NEVER** default to generic fonts like Arial, Inter, Roboto, or system fonts. Pair a distinctive display font with a refined body font. Every project should use different type choices — never converge on the same fonts across designs.

**How to pick:** Match the typeface personality to the aesthetic direction. A luxury UI needs an elegant serif, a brutalist UI needs raw aggressive type, a retro UI needs angular or monospace display fonts. Browse Google Fonts by category (Serif, Display, Handwriting) — the interesting ones are rarely on the first page of popularity.

- Limit to 2-3 font sizes per view/screen
- Use font weight for emphasis, not font size
- Ensure minimum readable size (16px web, 14sp Android, 17pt iOS)
- Maintain line height of 1.4-1.6 for body text

### Color & Theme

Commit to a cohesive aesthetic. Use CSS variables (or platform equivalent) for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.

**NEVER** use cliched color schemes, particularly purple gradients on white backgrounds. Vary between light and dark themes across designs. No two designs should look the same.

- Maintain WCAG AA contrast ratios (4.5:1 text, 3:1 large text/icons)
- Semantic colors for feedback: success, warning, error, info
- Support dark mode when applicable

### Motion & Animation

Create **memorable, interactive experiences** through animated components. Focus on high-impact moments: one well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.

**Animation Component Categories** (search `--domain animation` for implementation details):
- **Text** (26): Split reveals, scramble/decrypt, typewriter, glitch, gradient fill, blur reveal, variable font cursor, circular text, count-up, flip words, jitter, wave reveal, text explode, mirror, mask text, bold copy, text highlight, text along SVG path, animated number ticker
- **Background** (25): Aurora gradients, particles, noise grain, liquid chrome, grid distortion, waves, iridescence, plasma, meteor shower, spotlight/lamp, background beams, vortex, tracing beam, canvas reveal, dither shader, border trail, ripple, sparkles, background boxes, glowing stars, noise field
- **Interaction** (23): Click spark, elastic line, drag elements, sticker peel, electric/star border, following pointer, lens effect, link preview, animated tooltip, multi-step loader, ripple button, swipe button, file upload drag, vanishing input, confetti, countdown timer, accordion, morphing button, webcam pixel grid, animated gradient button
- **Card** (16): Tilt 3D, flip, stacking, swap/swipe, bounce entrance, glass, spotlight, decay, evervault, direction-aware hover, wobble, expandable, glowing, LED board, card spread, fluid glass
- **Scroll** (10): Parallax layers, scroll reveal, velocity text, stacking cards, horizontal scroll, stagger grid, progress bar, smooth snap, scroll storytelling, scroll-linked video
- **Navigation** (8): Dock magnify, gooey nav, staggered menu, flowing menu, pill indicator, animated sidebar, elastic slider, infinite menu
- **Data Visualization** (8): GitHub globe, world map connections, animated timeline, 3D pin map, commit graph, animated bar/donut/gauge charts
- **Hero** (7): Hero parallax images, Macbook scroll, lamp effect, shape shifter, sticky scroll reveal, compare slider, container cover
- **Cursor/Hover** (7): Blob cursor, magnetic elements, spotlight, tilt 3D, image trail, glare, proximity reactions
- **Physics** (6): Spring animations, gravity drops, elastic interactions, magnetic snap, floating elements, ballpit
- **SVG** (5): Gooey filter, morphing shapes, path drawing, metaballs, pixelate filter
- **Marquee** (5): Infinite horizontal/vertical, logo loops, along SVG path, orbiting elements
- **Layout** (5): Bento grid, layout grid stagger, 3D marquee, animated list, morphing dialog
- **Transitions** (5): Page transitions, shared element/hero, modal/sheet, skeleton loading, pixelated image transition
- **3D** (4): Model viewer, 3D card stack, orbit gallery, cubes background

**Library Selection** (pick ONE motion library per project):
- **CSS only**: Simple transitions, hover effects, continuous loops, marquees — zero bundle cost
- **Motion (Framer Motion)**: Declarative React animations, layout transitions, gestures, springs (~30KB)
- **GSAP**: Complex timelines, scroll-driven, SVG morphing — framework-agnostic (~25KB)
- **Three.js / R3F**: 3D scenes, WebGL effects, model viewers — only when actual 3D needed (~150KB)
- **Lenis**: Smooth scrolling, scroll velocity tracking (~5KB)

**Implementation Rules**:
- Prioritize CSS-only solutions; add JS libraries only when CSS can't achieve the effect
- Keep functional animations under 300ms; complex transitions under 400ms
- Animate only `transform` and `opacity` — never `width`, `height`, `top`, `left`
- Respect `prefers-reduced-motion` — provide static or instant fallback for every animation
- Disable cursor-following effects on touch devices (`pointer: coarse`)
- Reduce particle counts and effect complexity on mobile / low-end devices
- Use `will-change` sparingly; `contain: layout paint` on animated elements
- All animations must be interruptible — never block user input during animation
- Use platform-native animation libraries when available

### Spatial Composition

Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.

- Use CSS Grid and Flexbox for layout (web)
- Fluid typography with clamp() or responsive units
- Container queries for component-level responsiveness
- Avoid cookie-cutter layouts — design for the specific content and context

### Backgrounds & Visual Details

Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic:

- Gradient meshes, noise textures, geometric patterns
- Layered transparencies, dramatic shadows, decorative borders
- Custom cursors, grain overlays
- Creative forms that serve the design direction

### Anti-Patterns (NEVER DO)

- Overused font families (Inter, Roboto, Arial, system fonts)
- Cliched color schemes (purple gradients on white)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character
- Converging on common "safe" choices across designs (e.g. always picking Space Grotesk)

## Platform Detection

Before starting UI work, detect the project's platform and framework:

1. Check `package.json` for web frameworks (React, Vue, Angular, Svelte, Next.js, Nuxt)
2. Check `pubspec.yaml` for Flutter
3. Check `build.gradle`/`pom.xml` for JavaFX or Android
4. Check for `.xcodeproj`/`Package.swift` for iOS/macOS (SwiftUI/UIKit)
5. Check `Cargo.toml` + `tauri.conf.json` for Tauri
6. Check for `electron-builder` or `electron-forge` config for Electron

If a `.claude/devline.local.md` file exists, check for `frontend_framework` override.

Use the find-docs skill (`npx ctx7@latest`) to look up current documentation for the detected framework.

## Accessibility (a11y)

Accessibility is non-negotiable — beautiful AND accessible:

- All interactive elements must be keyboard accessible (web/desktop)
- All images must have alt text (or aria-hidden if decorative)
- Form inputs must have associated labels
- Focus indicators must be visible — style them to match the design, don't hide them
- Screen reader announcements for dynamic content
- Touch targets minimum 44x44pt (iOS) / 48x48dp (Android)
- Use semantic HTML elements (`button`, `nav`, `main`, `header`, not `div` for everything)
- ARIA attributes only when semantic HTML is insufficient

## Component Design

- Single responsibility: one component, one purpose
- Composable: combine small components into larger ones
- Configurable: props/parameters for variants, not separate components
- Stateless when possible: lift state to parent containers
- Components: PascalCase (`UserProfile`, `NavigationBar`)
- Events: on + action (`onClick`, `onSubmit`, `onValueChanged`)

## Responsive Design

### Web
- Mobile-first design: start with smallest screen, scale up
- Responsive breakpoints: 640px, 768px, 1024px, 1280px
- Avoid fixed widths — use max-width, min-width, percentages

### Mobile
- Adapt layout for portrait and landscape
- Platform-specific navigation patterns (bottom tabs iOS, drawer Android)
- Handle keyboard appearance, support dynamic type / font scaling
- Safe areas for mobile (notch, home indicator, status bar)

### Desktop
- Support window resizing with minimum dimensions
- Split panes and panels for information density
- Keyboard shortcuts for power users
- High-DPI/Retina display support

## Performance

- Lazy load below-the-fold content and routes
- Optimize images (WebP/AVIF for web, asset catalogs for mobile)
- Minimize re-renders (memoization, virtual DOM optimization)
- Skeleton screens over spinners for loading states
- Debounce search/filter inputs

## Additional Resources

### Reference Files

- **`references/design-rules.md`** — Priority-ordered design rules (200+ rules across 10 categories: accessibility, touch, performance, style, layout, typography, animation, forms, navigation, charts) with pre-delivery checklist
- **`references/aesthetics-guide.md`** — Detailed aesthetic philosophy, examples, and anti-patterns
- **`references/animation-components.md`** — Comprehensive animated component guide: library selection, implementation patterns (text, scroll, cursor, background, physics, SVG, transitions), performance budgets, accessibility requirements

#### Design System Tokens
- **`references/token-architecture.md`** — Three-layer token system (primitive → semantic → component)
- **`references/primitive-tokens.md`** — Raw values: colors, sizes, spacing, radii, shadows
- **`references/semantic-tokens.md`** — Purpose-based aliases: primary, secondary, error, surface
- **`references/component-tokens.md`** — Component-specific tokens: button, input, card, etc.
- **`references/component-specs.md`** — Component specification patterns and anatomy
- **`references/states-and-variants.md`** — Interactive states (hover, pressed, disabled, focus) and variant systems
- **`references/tailwind-integration.md`** — Mapping design tokens to Tailwind CSS theme configuration

#### UI Framework References
- **`references/shadcn-components.md`** — shadcn/ui component catalog with usage patterns
- **`references/shadcn-theming.md`** — shadcn/ui theme customization and CSS variables
- **`references/shadcn-accessibility.md`** — Accessibility patterns for shadcn/ui components
- **`references/tailwind-utilities.md`** — Tailwind CSS utility class reference and patterns
- **`references/tailwind-responsive.md`** — Responsive design with Tailwind breakpoints and container queries
- **`references/tailwind-customization.md`** — Extending Tailwind with custom utilities, plugins, @theme
- **`references/canvas-design-system.md`** — Canvas-based visual design system patterns

### Data Files (BM25-searchable via scripts/)

- **`data/styles.csv`** — 67 UI styles with keywords, colors, effects, accessibility ratings
- **`data/colors.csv`** — 161 color palettes mapped to product types (full semantic token set)
- **`data/typography.csv`** — 57 font pairings with Google Fonts imports and Tailwind config
- **`data/products.csv`** — 161 product types with recommended styles, patterns, palettes
- **`data/ui-reasoning.csv`** — 161 industry-specific decision rules (pattern, style priority, anti-patterns)
- **`data/ux-guidelines.csv`** — 99 UX guidelines with Do/Don't and code examples
- **`data/charts.csv`** — 25 chart types with accessibility grades and library recommendations
- **`data/landing.csv`** — Landing page patterns with CTA placement and conversion strategies
- **`data/icons.csv`** — Icon library recommendations by category
- **`data/app-interface.csv`** — App interface guidelines
- **`data/animations.csv`** — 160 animated component patterns across 15 categories (text, scroll, cursor, background, physics, card, navigation, SVG, marquee, transition, hero, interaction, data visualization, layout, 3D) with library recommendations, implementation hints, complexity ratings, and accessibility notes
- **`data/react-performance.csv`** — React/Next.js performance guidelines (45 entries)
- **`data/google-fonts.csv`** — Google Fonts catalog (1,924 fonts with classifications, variable axes, popularity)
- **`data/stacks/*.csv`** — Stack-specific guidelines for 13 frameworks
