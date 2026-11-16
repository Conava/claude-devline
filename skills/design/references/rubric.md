# Rubric: how the critic scores

The critic did not build the design and judges only from captures: stills (desktop first view, mid-scroll, an 8-frame scroll sheet, narrow, reduced motion, stills along the demo script), the frame-change list, the slop scan and the page error list. It may open the HTML to check a specific doubt, never to read the designer's intent.
Anchors written for devline, informed by Charles' polish scoring (paraphrased) and Impeccable's critique (Apache-2.0).

## Two scores, 3-10 each
**Wow**: would someone stop scrolling, screenshot it, copy it?
| Score | Meaning |
|---|---|
| 3 | Looks like everything else (template, AI look) |
| 5 | A clear idea, but it stays on the surface: decoration, not structure |
| 7 | The idea shapes the page and its motion; nothing yet worth a screenshot |
| 8 | One moment people would screenshot, and the motion carries meaning (`signature.md` holds) |
| 9 | That moment holds across the whole page and every width; a rival would copy it |

**Craft**: does everything that's there work?
| Score | Meaning |
|---|---|
| 3 | Broken states, unreadable text, layout falls apart |
| 5 | Designed at rest; motion, states or narrow layout are default |
| 7 | Every state designed, motion correct, small visible defects |
| 8 | No visible defect at the viewing size; contrast, alignment, rhythm, reduced motion all hold |
| 9 | Holds under stress: long content, odd widths, no WebGL, keyboard only |

10 is not awarded. **Done** = both ≥ 8 and no high finding.

## Caps and fails
- No screenshot-worthy moment → Wow ≤ 7.
- **Grounding:** if the subject's name were swapped and it still fit → Wow ≤ 5.
- **Signature claimed but absent:** the design names a 3D, interactive or motion signature but the captures show a static, placeholder or broken piece → high finding, Wow ≤ 5.
- Any transition with no answer to "what becomes the next thing?" (`signature.md`) → medium; more than one → high.
- Strict mode: any off-spec token, component or motion value (`M3E:` checklist) → high; a choice made where the spec allows it but not listed with its spec reference → medium.

## Each critique states
1. **Wow** and **Craft**, each with a one-line justification against the anchors.
2. **The screenshot-worthy moment** in one sentence, or "none".
3. **Grounding** test result.
4. **Signature check:** the `signature.md` items that hold and those that fail.
5. **Weakest thing on screen.**
6. **Findings** high / medium / low, each naming the capture that shows it: high = broken state, unreadable text, jank or a pop (a spike in the frame list where nothing should jump, or a flat stretch where the page claims to move), a high slop-scan hit, a fake signature, off-spec in strict mode; medium = people notice; low = only a designer notices.
7. **Next verb(s)** from `verbs.md` (one or two), or `done`.

## Cull (sketch round)
Sketches are cheap stills plus a storyboard; judge the idea, not the polish.
- Score each sketch 3-10 on **idea strength** (does the signature moment in the storyboard have a real "what becomes the next thing" chain; would it be worth building), and note grounding (name-swap test) and whether it obeys its seed.
- Drop: below 6, failed grounding, a storyboard with no real transition chain, an off-spec seed in strict mode, and the weaker of any two that share a world or motion idea.
- Keep 4-8 ranked (fewer only if fewer deserve it). Always keep the best ambitious interactive/3D sketch if it scored 6 or more.
- Format per sketch: `s<k> | score | keep/drop | one line why | for kept: the quality to protect`.

Scores from earlier rounds are not shown to a new critic; each critic starts fresh.
