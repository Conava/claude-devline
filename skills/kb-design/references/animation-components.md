# Animation Components Reference

Comprehensive guide for creating animated UI components. Covers library selection, implementation patterns, performance optimization, and accessibility requirements.

## Animation Library Selection

Choose libraries based on project stack, complexity needs, and performance requirements.

### Library Decision Matrix

| Library | Best For | Bundle Size | Learning Curve | React | Vue | Vanilla |
|---------|----------|-------------|----------------|-------|-----|---------|
| **CSS Animations** | Simple transitions, hover effects, continuous loops | 0 KB | Low | Yes | Yes | Yes |
| **Motion (Framer Motion)** | Declarative React animations, layout transitions, gestures | ~30 KB | Medium | Yes | No | Partial |
| **GSAP** | Complex timelines, scroll-driven, SVG morphing, high-performance | ~25 KB | Medium | Yes | Yes | Yes |
| **React Spring** | Physics-based, natural feel, spring animations | ~20 KB | Medium | Yes | No | No |
| **Three.js + R3F** | 3D scenes, WebGL effects, model viewers | ~150 KB | High | Yes | No | Yes |
| **Lenis** | Smooth scrolling, scroll velocity tracking | ~5 KB | Low | Yes | Yes | Yes |
| **@use-gesture** | Drag, pinch, scroll gestures with spring physics | ~10 KB | Medium | Yes | No | No |
| **Matter.js** | 2D physics simulation (gravity, collision, constraints) | ~80 KB | Medium | Yes | Yes | Yes |

### Library Selection Rules

1. **CSS-first**: If achievable with CSS transitions/animations and `@keyframes`, don't add a JS library
2. **One motion library**: Pick Motion OR GSAP for a project, not both (bundle size + API consistency)
3. **Physics**: Use Motion springs for simple spring effects; Matter.js only for actual physics simulations
4. **3D**: Only add Three.js if the design calls for actual 3D rendering; CSS 3D transforms handle perspective/tilt
5. **Scroll**: Lenis for smooth scrolling; GSAP ScrollTrigger or IntersectionObserver for scroll-triggered animations

## Implementation Patterns

### Text Animations

**Core techniques:**
- Split text into individual `<span>` elements per character or word
- Apply staggered animations with `animation-delay` or Motion's `staggerChildren`
- Use `overflow: hidden` on containers for slide-in/reveal effects
- Variable fonts: animate `font-variation-settings` for weight/width changes

**Common text animation recipe (CSS):**
```css
.text-reveal span {
  display: inline-block;
  opacity: 0;
  transform: translateY(100%);
  animation: reveal 0.6s ease-out forwards;
}
.text-reveal span:nth-child(1) { animation-delay: 0ms; }
.text-reveal span:nth-child(2) { animation-delay: 50ms; }
/* ... stagger by 50ms per character */

@keyframes reveal {
  to { opacity: 1; transform: translateY(0); }
}
```

**Common text animation recipe (Motion/React):**
```tsx
const container = { hidden: {}, visible: { transition: { staggerChildren: 0.03 } } };
const child = { hidden: { y: 20, opacity: 0 }, visible: { y: 0, opacity: 1 } };

<motion.div variants={container} initial="hidden" animate="visible">
  {text.split("").map((char, i) => (
    <motion.span key={i} variants={child}>{char}</motion.span>
  ))}
</motion.div>
```

**Scramble/decrypt effect pattern:**
```ts
const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
function scramble(target: string, progress: number): string {
  return target.split("").map((char, i) =>
    i < target.length * progress ? char : chars[Math.floor(Math.random() * chars.length)]
  ).join("");
}
// Drive `progress` from 0→1 over 600ms with requestAnimationFrame
```

### Scroll Animations

**IntersectionObserver pattern (vanilla):**
```ts
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target); // once
    }
  });
}, { threshold: 0.15 });
document.querySelectorAll('.animate-on-scroll').forEach(el => observer.observe(el));
```

**Scroll-triggered with Motion:**
```tsx
<motion.div
  initial={{ opacity: 0, y: 40 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-100px" }}
  transition={{ duration: 0.5, ease: "easeOut" }}
/>
```

**Parallax layer pattern (CSS):**
```css
.parallax-container {
  perspective: 1px;
  height: 100vh;
  overflow-x: hidden;
  overflow-y: auto;
}
.parallax-layer--back { transform: translateZ(-1px) scale(2); }
.parallax-layer--base { transform: translateZ(0); }
```

**Scroll velocity tracking (Lenis):**
```ts
const lenis = new Lenis();
lenis.on('scroll', ({ velocity }) => {
  // velocity is negative (scroll up) or positive (scroll down)
  // Use velocity to drive transform speed
  element.style.transform = `translateX(${velocity * 2}px)`;
});
function raf(time) { lenis.raf(time); requestAnimationFrame(raf); }
requestAnimationFrame(raf);
```

### Cursor & Hover Effects

**Cursor tracking pattern:**
```ts
document.addEventListener('mousemove', (e) => {
  // Raw position
  const x = e.clientX;
  const y = e.clientY;

  // Smooth with lerp (apply in rAF loop)
  currentX += (x - currentX) * 0.1;
  currentY += (y - currentY) * 0.1;

  cursor.style.transform = `translate(${currentX}px, ${currentY}px)`;
});
```

**Tilt effect pattern:**
```ts
card.addEventListener('mousemove', (e) => {
  const rect = card.getBoundingClientRect();
  const x = (e.clientX - rect.left) / rect.width - 0.5;  // -0.5 to 0.5
  const y = (e.clientY - rect.top) / rect.height - 0.5;
  card.style.transform = `perspective(1000px) rotateY(${x * 20}deg) rotateX(${-y * 20}deg)`;
});
card.addEventListener('mouseleave', () => {
  card.style.transform = 'perspective(1000px) rotateY(0) rotateX(0)';
  card.style.transition = 'transform 0.5s ease';
});
```

**Magnetic element pattern:**
```ts
const THRESHOLD = 100; // px radius of magnetic field
element.addEventListener('mousemove', (e) => {
  const rect = element.getBoundingClientRect();
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  const dx = e.clientX - cx;
  const dy = e.clientY - cy;
  const dist = Math.sqrt(dx * dx + dy * dy);
  if (dist < THRESHOLD) {
    const pull = 1 - dist / THRESHOLD; // 0 at edge, 1 at center
    element.style.transform = `translate(${dx * pull * 0.3}px, ${dy * pull * 0.3}px)`;
  }
});
```

### Background Effects

**Aurora/gradient mesh (CSS only):**
```css
.aurora {
  background:
    radial-gradient(ellipse at 20% 50%, rgba(120, 80, 255, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(255, 80, 120, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 50% 80%, rgba(80, 200, 255, 0.3) 0%, transparent 50%);
  animation: aurora 8s ease-in-out infinite alternate;
}
@keyframes aurora {
  0% { filter: hue-rotate(0deg); transform: scale(1) translate(0, 0); }
  100% { filter: hue-rotate(30deg); transform: scale(1.1) translate(-5%, 5%); }
}
```

**Noise grain overlay (SVG filter):**
```html
<svg style="position:fixed;width:0;height:0">
  <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" stitchTiles="stitch"/></filter>
</svg>
<div class="grain-overlay" style="
  position:fixed; inset:0; pointer-events:none; z-index:9999;
  filter:url(#grain); opacity:0.04; mix-blend-mode:overlay;
"></div>
```

**Infinite marquee (CSS only):**
```css
.marquee { overflow: hidden; white-space: nowrap; }
.marquee-content {
  display: inline-flex; gap: 2rem;
  animation: marquee 30s linear infinite;
}
.marquee-content::after { /* duplicate for seamless loop */
  content: attr(data-content); /* or duplicate DOM nodes */
  display: inline-flex; gap: 2rem; padding-left: 2rem;
}
@keyframes marquee { to { transform: translateX(-50%); } }
```

### Physics Animations

**Spring config presets (Motion):**
```ts
const SPRING_PRESETS = {
  gentle:  { stiffness: 120, damping: 14, mass: 1 },    // Soft, floaty
  snappy:  { stiffness: 300, damping: 20, mass: 1 },    // Quick, responsive
  bouncy:  { stiffness: 400, damping: 10, mass: 1 },    // Playful overshoot
  stiff:   { stiffness: 500, damping: 30, mass: 1 },    // Firm, controlled
  wobbly:  { stiffness: 180, damping: 12, mass: 1 },    // Wobbly settle
};
```

**Gravity simulation (CSS approximation):**
```css
@keyframes drop {
  0% { transform: translateY(-200px); opacity: 0; }
  60% { transform: translateY(10px); }   /* overshoot */
  80% { transform: translateY(-5px); }   /* bounce */
  100% { transform: translateY(0); opacity: 1; }
}
.drop { animation: drop 0.8s cubic-bezier(0.34, 1.56, 0.64, 1) forwards; }
```

### SVG Effects

**Gooey filter (reusable):**
```html
<svg style="position:absolute;width:0;height:0">
  <filter id="gooey">
    <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur"/>
    <feColorMatrix in="blur" type="matrix"
      values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 18 -7" result="gooey"/>
    <feComposite in="SourceGraphic" in2="gooey" operator="atop"/>
  </filter>
</svg>
<!-- Apply: style="filter: url(#gooey)" -->
```

**Path drawing animation:**
```css
.draw-path {
  stroke-dasharray: 1000; /* must match or exceed path length */
  stroke-dashoffset: 1000;
  animation: draw 2s ease-in-out forwards;
}
@keyframes draw { to { stroke-dashoffset: 0; } }
```
```ts
// Calculate exact path length:
const length = document.querySelector('path').getTotalLength();
```

### Hero Patterns

**Sticky scroll reveal (content swaps while pinned):**
```tsx
// GSAP ScrollTrigger approach
sections.forEach((section, i) => {
  ScrollTrigger.create({
    trigger: section,
    start: "top center",
    end: "bottom center",
    onEnter: () => setActiveImage(i),
    onEnterBack: () => setActiveImage(i),
  });
});
// Visual panel uses position: sticky; top: 0; height: 100vh
```

**Compare slider (before/after):**
```tsx
const [position, setPosition] = useState(50);
<div className="relative overflow-hidden">
  <img src={after} className="w-full" />
  <div className="absolute inset-0" style={{ clipPath: `inset(0 ${100-position}% 0 0)` }}>
    <img src={before} className="w-full" />
  </div>
  <input type="range" min={0} max={100} value={position}
    onChange={e => setPosition(Number(e.target.value))}
    className="absolute inset-0 w-full opacity-0 cursor-ew-resize" />
  <div className="absolute top-0 bottom-0 w-0.5 bg-white"
    style={{ left: `${position}%` }} />
</div>
```

**Meteor shower (CSS only):**
```css
.meteor {
  position: absolute;
  width: 2px; height: 80px;
  background: linear-gradient(to bottom, rgba(255,255,255,0.8), transparent);
  transform: rotate(215deg);
  animation: meteor 3s linear infinite;
  opacity: 0;
}
@keyframes meteor {
  0% { transform: rotate(215deg) translateX(0); opacity: 1; }
  70% { opacity: 1; }
  100% { transform: rotate(215deg) translateX(-500px); opacity: 0; }
}
/* Stagger multiple meteors with animation-delay */
```

### Data Visualization Animations

**Animated bar chart entrance (CSS):**
```css
.bar {
  transform-origin: bottom;
  animation: grow-bar 0.6s ease-out forwards;
  transform: scaleY(0);
}
@keyframes grow-bar { to { transform: scaleY(1); } }
.bar:nth-child(1) { animation-delay: 0ms; }
.bar:nth-child(2) { animation-delay: 100ms; }
/* stagger per bar */
```

**Donut chart with SVG stroke animation:**
```tsx
const circumference = 2 * Math.PI * radius;
const offset = circumference - (percentage / 100) * circumference;
<circle r={radius} cx="50%" cy="50%"
  fill="none" stroke={color} strokeWidth={8}
  strokeDasharray={circumference}
  strokeDashoffset={offset}
  style={{ transition: 'stroke-dashoffset 1s ease-out' }}
/>
```

**GitHub-style commit graph (CSS Grid):**
```css
.commit-grid {
  display: grid;
  grid-template-rows: repeat(7, 12px);
  grid-auto-flow: column;
  gap: 3px;
}
.commit-cell {
  width: 12px; height: 12px; border-radius: 2px;
  /* Color intensity mapped to commit count */
}
```

### Interactive Element Patterns

**Ripple button (Material Design):**
```ts
button.addEventListener('click', (e) => {
  const ripple = document.createElement('span');
  const rect = button.getBoundingClientRect();
  ripple.style.left = `${e.clientX - rect.left}px`;
  ripple.style.top = `${e.clientY - rect.top}px`;
  ripple.className = 'ripple';
  button.appendChild(ripple);
  ripple.addEventListener('animationend', () => ripple.remove());
});
```
```css
.ripple {
  position: absolute; border-radius: 50%;
  background: rgba(255,255,255,0.3);
  transform: scale(0);
  animation: ripple 0.6s linear;
  pointer-events: none;
}
@keyframes ripple { to { transform: scale(4); opacity: 0; } }
```

**Confetti burst:**
```ts
import confetti from 'canvas-confetti';
confetti({
  particleCount: 100,
  spread: 70,
  origin: { y: 0.6 },
  colors: ['#ff0000', '#00ff00', '#0000ff'],
});
```

**Expandable card (Motion layoutId):**
```tsx
// Grid view
<motion.div layoutId={`card-${id}`} onClick={() => setSelected(id)}>
  <motion.img layoutId={`img-${id}`} src={img} />
  <motion.h3 layoutId={`title-${id}`}>{title}</motion.h3>
</motion.div>

// Expanded overlay
<AnimatePresence>
  {selected && (
    <motion.div layoutId={`card-${selected}`} className="fixed inset-4 z-50">
      <motion.img layoutId={`img-${selected}`} src={img} />
      <motion.h3 layoutId={`title-${selected}`}>{title}</motion.h3>
      <p>{description}</p>
    </motion.div>
  )}
</AnimatePresence>
```

### Page Transitions

**View Transitions API (modern browsers):**
```ts
document.startViewTransition(() => {
  // Update the DOM
  updateContent();
});
```
```css
::view-transition-old(root) { animation: fade-out 0.3s ease; }
::view-transition-new(root) { animation: fade-in 0.3s ease; }
```

**Shared element with Motion layoutId:**
```tsx
// List view
<motion.img layoutId={`image-${id}`} src={src} />

// Detail view
<motion.img layoutId={`image-${id}`} src={src} />
<!-- Motion auto-animates between positions/sizes -->
```

## Performance Guidelines

### Critical Performance Rules

1. **Only animate `transform` and `opacity`** — these are composited on the GPU. Never animate `width`, `height`, `top`, `left`, `margin`, `padding`, `border-width`, or `box-shadow` width
2. **`will-change` sparingly** — Add `will-change: transform` only on elements that will animate; remove after animation completes; never apply to more than ~10 elements simultaneously
3. **`requestAnimationFrame`** — All JS-driven animations must run in rAF, never `setTimeout`/`setInterval`
4. **Debounce/throttle events** — `mousemove`, `scroll`, `resize` handlers must be throttled (16ms for 60fps)
5. **Reduce on mobile** — Fewer particles, simpler effects, no cursor-following; check `navigator.hardwareConcurrency`
6. **Canvas over DOM** — For 50+ moving elements, Canvas/WebGL outperforms DOM manipulation
7. **`contain: layout paint`** — On animated elements to prevent layout recalculation of siblings
8. **Cleanup** — Remove event listeners, cancel rAF, dispose Three.js scenes on unmount

### Performance Budget by Animation Type

| Type | Target FPS | Max Elements | GPU Usage |
|------|-----------|--------------|-----------|
| CSS transition | 60 | Unlimited | Low |
| CSS @keyframes | 60 | ~50 concurrent | Low |
| Motion/GSAP | 60 | ~30 concurrent | Medium |
| Canvas 2D | 60 | ~500 particles | Medium |
| WebGL/Three.js | 60 | Scene-dependent | High |
| SVG filter | 30-60 | ~5 filtered elements | High |

### Mobile Optimization

```ts
// Detect reduced capability
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const isMobile = window.matchMedia('(pointer: coarse)').matches;
const isLowEnd = navigator.hardwareConcurrency <= 4;

// Scale animation complexity
const particleCount = isLowEnd ? 20 : isMobile ? 50 : 200;
const enableCursorEffects = !isMobile;
const enablePhysics = !isLowEnd;
```

## Accessibility Requirements

### Non-negotiable Rules

1. **`prefers-reduced-motion`** — Every animation must respect this. Provide instant state or static fallback:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

2. **Content first** — Animation must never prevent or delay access to content. Never hide content behind an animation that hasn't completed.

3. **No seizure triggers** — Avoid flashing more than 3 times per second. No rapid strobing or high-contrast flashing.

4. **Pause control** — Continuous animations (marquees, particles, backgrounds) must be pausable or have a visible pause control.

5. **Focus management** — During transitions (page, modal, accordion), manage focus appropriately. After a page transition, focus the main content heading.

6. **Screen reader announcements** — Dynamic content changes triggered by animation should use `aria-live` regions.

### Reduced Motion Fallback Patterns

| Animation | Full Motion | Reduced Motion |
|-----------|------------|----------------|
| Scroll reveal | translateY + opacity | opacity only (or instant) |
| Page transition | slide/morph | fade or instant |
| Hover effect | scale + rotate | opacity change only |
| Background particles | Full simulation | Static image |
| Marquee | Continuous scroll | Static display |
| Physics sim | Full physics | Instant final position |

## Component Categories Quick Reference

### By Trigger Type

| Trigger | Components | Notes |
|---------|-----------|-------|
| **Load** | Text reveal, skeleton, aurora, floating, lamp hero, meteor shower, typewriter | Use sparingly; don't delay content |
| **Scroll** | Parallax, reveal, stagger, velocity text, stack cards, macbook scroll, sticky reveal, scroll storytelling, timeline, scroll-linked video | IntersectionObserver; `once: true` for perf |
| **Hover** | Tilt, glare, magnetic, spotlight, letter swap, direction-aware, wobble, scramble hover, evervault, link preview | Touch fallback required; no critical info |
| **Click** | Card flip, spark, modal animation, page transition, expandable card, confetti, ripple button, morphing button, morphing dialog | Keep under 300ms; don't block interaction |
| **Cursor** | Blob, trail, proximity, variable font, following pointer, pointer highlight, lens, canvas reveal | Disable on touch; lerp for smoothness |
| **Continuous** | Marquee, aurora, particles, floating, orbit, meteor, beams, sparkles, countdown, background boxes | Must be pausable; respect reduced-motion |
| **Drag** | Card swap, elastic, reorder, free position, compare slider, swipe button, elastic slider | @use-gesture; keyboard alternative required |

### By Complexity

| Level | Components | Libraries Needed |
|-------|-----------|-----------------|
| **Low** | Scroll reveal, hover transitions, marquee, gradient text, floating, skeleton, ripple button, animated tooltip, accordion, countdown, text highlight, mirror text, typing cursor, gradient button, sparkles | CSS only |
| **Medium** | Text split, tilt card, spring animation, stagger grid, pill nav, path drawing, expandable card, sticky scroll reveal, compare slider, animated timeline, bento grid, morphing button, wobble card, animated list, bold copy | Motion or GSAP |
| **High** | Blob cursor, physics sim, 3D model, shared element, grid distortion, liquid chrome, macbook scroll, GitHub globe, scroll-linked video, beams with collision, vortex, morphing dialog, scroll storytelling, webcam pixel grid | Three.js, Matter.js, WebGL, GSAP ScrollTrigger |

### By Category (160 components)

| Category | Count | Highlights |
|----------|-------|------------|
| **Text** | 26 | Scramble, typewriter, glitch, gradient, blur reveal, split reveal, flip words, wave reveal, text explode, number ticker, bold copy, text highlight |
| **Background** | 25 | Aurora, particles, liquid chrome, meteors, beams, spotlight, vortex, sparkles, noise, grid distortion, dither shader, border trail |
| **Interaction** | 23 | Click spark, ripple button, confetti, lens, link preview, swipe button, morphing button, accordion, countdown, file upload drag, vanishing input |
| **Card** | 16 | Tilt 3D, flip, expandable, evervault, direction-aware, wobble, glowing, LED board, card spread, fluid glass, decay |
| **Scroll** | 10 | Parallax, reveal, velocity text, horizontal scroll, stagger grid, scroll storytelling, scroll-linked video |
| **Navigation** | 8 | Dock, gooey, staggered menu, flowing menu, pill nav, elastic slider, infinite menu |
| **Data Viz** | 8 | GitHub globe, world map, animated timeline, commit graph, bar/donut/gauge charts, 3D pin map |
| **Hero** | 7 | Hero parallax, macbook scroll, lamp effect, shape shifter, sticky scroll reveal, compare slider, container cover |
| **Cursor** | 7 | Blob cursor, magnetic, spotlight, tilt, image trail, glare, proximity |
| **Physics** | 6 | Spring, gravity, elastic, magnetic snap, floating, ballpit |
| **SVG** | 5 | Gooey filter, morphing, path drawing, metaballs, pixelate |
| **Marquee** | 5 | Infinite H/V, logo loop, along path, circling |
| **Layout** | 5 | Bento grid, grid stagger, 3D marquee, animated list, morphing dialog |
| **Transition** | 5 | Page transition, shared element, modal/sheet, skeleton, pixelated image |
| **3D** | 4 | Model viewer, card stack, orbit gallery, cubes background |
