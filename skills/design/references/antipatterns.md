# Antipatterns: the AI look, why it fails, what to do instead

Sources: Anthropic frontend-design (Apache-2.0), Impeccable craft floor (Apache-2.0), unslop by Damir Sokolovsky (CC BY 4.0), Emil Kowalski (MIT). Paraphrased.

Every item below is a default, not a choice: it appears whatever the subject is. The brief's own words can ask for any of them; a free axis must never be spent on one. When you find one, rewrite the element, don't soften it.

## The five current clusters (check the whole plan against these first)
1. Warm cream ground (~#F4F1EA) + high-contrast serif display + terracotta/clay accent (~#D97757).
2. Near-black ground with one acid-green, vermilion or neon accent, often with glow.
3. Broadsheet: hairline rules everywhere, zero radius, dense newspaper columns.
4. SaaS card kit: content chopped into identical rounded cards, one radius on everything, the same soft grey shadow, gradient washes.
5. Template chrome: tracked ALL-CAPS eyebrow above every heading, `A · B · C` meta strings, `WORD — fragment` labels, #0B0B0B/#111 as black, monospace for small labels, `→` appended to buttons.

## Layout and structure
| Default | Why it fails | Instead |
|---|---|---|
| Hero = big headline + subtext + two buttons, centered | Every template | Open with the most characteristic thing in the subject's world (an object, a live demo, a process, a scene) |
| Hero metric block (huge number, small label, side stats, accent) | The commonest "data" costume | A number only where it is the point, with its denominator |
| Three equal feature cards (icon + heading + text) | Lazy container, says nothing | Structure from the content: a sequence, a comparison, a map, a ledger |
| Nested cards, border + wide shadow pairs, colored side stripes | Noise as hierarchy | One depth cue per surface; space shows grouping |
| Section numbers 01/02/03 | Only true for real sequences | Number only a real sequence |
| Eyebrow/kicker above a heading | Ban. The heading carries its weight | Delete it |
| Everything centered | Template default | Left-aligned reading edge; center only short lines or a device frame |
| Modal for something that can open in place | Interrupts for nothing | Disclose in place |
| Bento grid of mixed tiles as the page | 2024 Apple-pastiche | Only when the content really is a set of unequal items |

## Surface
| Default | Why | Instead |
|---|---|---|
| Purple/blue gradients, gradient text, gradient borders | The canonical AI tell | Color from the subject's world; emphasis from size/weight |
| Glassmorphism, backdrop blur as decoration | Costume | Blur only where something really sits over content (a sheet over a page) |
| Glows, radial halos, colored shadows, neon borders | Decoration that competes with content | Neutral soft shadow with offset, or none |
| Grain/noise overlays, dot grids, line grids, aurora blobs, orbs, floating shapes | Filler that says nothing | A real material or a real object from the world, or nothing |
| Pills (999px) on every button/tag | Uniformity, not design | Radius by hierarchy; inner = outer - padding |
| Emoji or unicode glyphs as icons (✨ → ↗ ✓) | Cheap and inconsistent | One drawn SVG set, one stroke weight |
| Shape-assembled fake illustrations, stock-photo stand-ins | Lies about the product | Real assets, honest diagrams, or rendered objects |
| Light/dark picked by category ("tech = dark") | Not a decision | Pick from the use scene and the world |

## Type
| Default | Why | Instead |
|---|---|---|
| Inter, Roboto, Arial, system UI as display; Space Grotesk, DM Sans, Plus Jakarta, Instrument Sans/Serif, Geist, Fraunces, Playfair, Newsreader as reflex picks | The faces every model reaches for | Choose for the character; look past the first page of Google Fonts; one family or two clearly distinct ones |
| Italic or colored accent on one word of a headline | Commonest typographic tell | Let the whole line carry it, or change the sentence |
| ALL-CAPS tracked labels, mono labels as "technical" costume | Template chrome | Sentence case; mono only for code, data, measurement |
| 700-900 weight everywhere, tight tracking on small text | Shouting | Scale and color for hierarchy; tracking only on display sizes |

## Motion
| Default | Why | Instead |
|---|---|---|
| Fade-and-slide-up on every section, staggered | The single most recognisable AI motion | One authored moment; most content is simply there |
| Identical hover lift on every card | Says nothing | Hover only where it tells the user something, inside `@media (hover:hover)` |
| 3D tilt cards, magnetic buttons, custom cursors, cursor trails, spotlight-follow | Toy effects | Motion that answers a question (where did this come from, what changed, what comes next) |
| Count-up numbers, typewriter, text scramble, glitch | Delays content for show | Show the number; animate only the delta when it changes |
| Bounce/elastic easing, springs on everything | Wobble | One easing family; bounce only for physical, playful things |
| Scroll progress that jumps station to station, timed animation triggered by scroll | Disconnects the hand from the screen | Scroll-linked progress is scrubbed and continuous |
| Things that appear and vanish (ambient layers that come and go) | Feels broken | Ambient layers persist, subordinate, and hand over without an edge |
| Animating keyboard/frequent actions | Feels slow | No animation for things done 100 times a day |

## Copy
- No slogans, aphorisms, rule-of-three lists, "X. Not Y." rebuttals, punchline headings, hype words (seamless, robust, powerful, unlock, supercharge).
- No invented numbers, testimonials or logos. Use only the facts given.
- Controls name their action; the same action keeps one name. Errors name the problem and the fix, never apologize.
- Headings are plain topic titles unless the brief asks otherwise.
