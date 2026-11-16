# Signature: what makes a design worth a screenshot

A page without a signature is a template with nice type. These rules describe what the memorable pages share; they don't prescribe a look. Read with `motion.md` (tools, timings, budgets).
Written for devline from studies of award-level scroll pieces and product reels; paraphrased.

## The rules
1. **One continuous world, no cuts.** Nothing pops in. Every new state is something already on screen turning into the next thing, so the eye never has to find its place again.
2. **Matched transitions: "what becomes the next thing?"** The end of one motion is the start of the next. A shape, object or line is the bridge between sections: a pour becomes the next vessel, a wireframe block becomes the glow above a wordmark, a node becomes a card. Every transition needs a written answer; if there is none, redesign it.
3. **Two layers of motion.** The container moves (a scene opens, a camera travels, a layout reshapes) while the content inside keeps living at rest (a line rewrites itself, a value updates, a detail lights up). Small and calm, never wobble.
4. **One physical model.** One light source, consistent shadows, one easing family, weight in the motion. Because it obeys rules, it reads as real rather than as "animation".
5. **The subject's own process is the narrative.** The structure of the content is the structure of the motion: brewing for a coffee brand, dusk to dark for an observatory, a request travelling through services for a backend engineer.
6. **Type is part of the scene.** Headlines are big, short and layered between objects (an object overlaps the word it names). One idea per screen.
7. **Rhythm: hold, decisive move, hold.** Calm for a beat, a fast eased transition, calm again.
8. **Bookend.** The end resolves back to the opening state or shape, so it feels finished.
9. **Shape-led layout.** Content sits in masks and non-rectangular shapes; geometry carries over from one state to the next.
10. **Still the subject.** However ambitious, it must read as what it is (an engineer's portfolio, an observatory, a music app), not as a design studio's showreel.

## Worked patterns (describe the quality, never copy a layout)
- **Live 3D subject on a natural scroll.** One 3D object stays on screen through the whole page and changes form to picture each section's content, and each form causes the next: a stream of tokens gathers into one block, the block splits into several, most of them move, they compile into a diagram, the diagram's lanes run in parallel, and everything closes into a ring that echoes the opening. Native scroll, no hijack; type in a serif display + clean sans beside it.
- **Type as architecture.** Giant words are the scenery. The camera flies through a letter's counter (the hole in an "O") into the room behind it, where the next section lives; each room ends in another word to fly through; the last flight lands on the opening word. One exponential dolly per flight, no snap, no parallax.
- **The object you leaf through.** A closed book on a lit desk opens in 3D; every spread is a section; pages curl and darken as they tilt from the light; while a spread rests, its content keeps living; at the end the book closes into the opening frame.
- **Morphing wireframe.** Coloured blocks labelled by role slide and reshape into the next layout and real content fills the exact shapes; the last shape becomes a graphic element of the final screen.

## What counts as "real" 3D or interaction
- It runs: the captures show it moving and changing with scroll or input, at 60 fps (frame list with no spikes where nothing should jump).
- It carries content: the 3D or interactive piece pictures the section it sits in, not a spinning decoration beside it.
- It degrades: a designed static fallback (no WebGL) and a reduced-motion state that shows the key frames.
- A static image, a looping decorative blob, a canvas that only reacts to the cursor, or a 3D scene that doesn't change with the content is **not** a signature.

## Craft checks for any signature
- Every transition: write "X becomes Y". Missing → redesign.
- One light/shadow model, one easing family, one rhythm.
- Every resting state has one small living detail.
- Reduced motion and no-JS: the clean static page, fully readable.
- Lightest tool first: CSS scroll-driven animations and View Transitions, then GSAP, then three.js (`motion.md` chooser).
