---
name: design
description: Design distinctive, crafted interfaces from real content instead of the default AI look, and build cheap interactive mockups of anything. Use when the user asks to design a page, site, app screen, widget or design system ("design the homepage", "explore directions for…", "redesign this UI"), or to mock something up ("mock up the new edit mode", "make a mockup of the battery widget").
argument-hint: "[mockup] <what to design>"
user-invocable: true
disable-model-invocation: false
---

# Design

Two modes, one **designer** agent that does one step per launch:
- **Exploration** (default): new looks for a page, site or app. Many cheap sketches, a critic culls, the user picks, only the picks become full prototypes, then refine against rendered captures until they score 8+.
- **Mockup** (`mockup <what>`, or any request that says "mockup"/"mock up"): one cheap, interactive HTML mockup of exactly the surface a change touches. See `references/mockup.md`.

Nobody scores their own work: every critique is a fresh designer launch that sees only captures.

This skill's base directory (shown above as "Base directory for this skill") holds `references/` and `scripts/`. Pass the absolute `references/` path to every launch as `References:`. You run the scripts yourself:
```bash
node <base>/scripts/capture.mjs <file.html> <outdir> --sheet --frames --video scroll                     # web page
node <base>/scripts/capture.mjs <file.html> <outdir> --narrow 420 --video script --demo <steps.json>     # app UI, widget, mockup
node <base>/scripts/capture.mjs <file.html> <outdir> --stills-only                                      # sketch
node <base>/scripts/slop-scan.mjs <file.html> > <outdir>/slop.json
python3 -I <base>/scripts/gallery.py <workdir> <items-subdir> <captures-subdir> "<title>"
```
capture needs playwright-core in `~/.cache/devline/capture`. If it's missing, ask before installing (about 150 MB): `npm i --prefix ~/.cache/devline/capture playwright-core && node ~/.cache/devline/capture/node_modules/playwright-core/cli.js install chromium`. Without it, the critic judges from the HTML only and the report says so.

## Settings
Read `.claude/devline.local.md` (repo), then `~/.claude/devline.local.md` (user); the repo wins. All keys optional:
- `design_model` (default `opus`), `mockup_model` (default `sonnet`)
- `design_sketches` (default 10), `design_pick`: `ask` (default) | `auto`
- `design_mode`: `auto` (default) | `m3e-strict` | `default`

**Precedence for counts and who picks:** the user's request (a number, "you pick", "just build three") > settings > ask when it isn't obvious. Never override an explicit instruction in the request.

## Inputs (both modes)
- **Facts**: the real content (files, a facts file, the project itself). Never invent content.
- **Taste brief**: loves, dislikes, musts, references. Ask briefly if absent and not inferable.
- **Target**: `web page` | `app UI` (desktop window 1440x900 + narrow ~420) | `component/widget` (real size, in its real context).
- **Mode**: `m3e-strict` when `design_mode` says so, the user asks for M3E, or the project uses Material 3 Expressive (M3E tokens or components in the code, an M3E theme, docs or a design system naming it). Strict mode needs the `kb-m3e` skill: pass its absolute `references/` path as `M3E:` (`<base>/../kb-m3e/references`). If that directory doesn't exist, stop and tell the user strict mode needs the kb-m3e skill; never fall back to remembered M3E values. Otherwise `default`.
- **Design system**: if `docs/design-system/MASTER.md` exists, pass it; its Corrections section is binding. See `references/design-system.md`.

## Exploration loop (work dir `.devline/design/`)
1. **Seeds**: one launch, `Step: seeds` → `seeds.md` with `design_sketches` seeds per `seeds.md`.
2. **Sketch**: one launch per seed, **all in one message**, `Step: sketch` → `sketches/s<k>.html` + `sketches/s<k>.story.md`. Cheap: a finished first screen and a storyboard; no 3D or interaction code.
3. **Capture** each sketch with `--stills-only` into `captures/s<k>/`.
4. **Cull**: one fresh launch, `Step: cull`, all capture folders and story files → `cull.md`: drops weak, generic and sibling sketches, keeps 4-8 ranked (fewer only if fewer deserve it), each with the quality to protect.
5. **Pick**: build the sketch gallery (`gallery.py .devline/design sketches captures "Sketches"`), give the user the serve command (`cd <abs>/.devline/design/gallery && python3 -m http.server 8092`) and ask which to build with AskUserQuestion (multi-select over the kept sketches, usually 2-4). With `design_pick: auto` or a request that delegates the choice, take the top 3 from `cull.md`.
6. **Build**: one launch per pick, in parallel, `Step: build` → `final/<k>.html`, plus `final/<k>.demo.json` for app UIs and widgets: the full working prototype.
7. **Capture** each (web: `--sheet --frames --video scroll`; app UI: `--narrow 420 --video script --demo final/<k>.demo.json`) + slop scan into `captures/final/<k>/`.
8. **Critique**: one fresh launch per design, `Step: critique` → `critique-<round>-<k>.md` with Wow and Craft scores and the next verb(s) or `done`.
9. **Refine**: `Step: refine` with the critic's verb(s), same output path; then 7-8 again. Stop per design at `done` (both scores ≥ 8, nothing high), after 3 refine rounds, or when neither score moved in two rounds.
10. **Report**: rebuild the gallery over `final/` (`gallery.py .devline/design final captures/final "Final"`). Per design: path, Wow/Craft, the screenshot-worthy moment, assumptions, and in strict mode the decisions taken where the spec allowed. Ask with AskUserQuestion which one to take forward unless the request already said; record the answer and feedback verbatim in `.devline/design/feedback.md`. On approval, write `docs/design-system/MASTER.md` from the chosen design per `design-system.md`.

## Mockup flow
1. `Step: mockup` launch (model `mockup_model`) with the request verbatim, the project root (if any), facts, taste, the M3E path in strict mode, and `Output:` (as the user gives it; else `.devline/mockups/<slug>.html`). It writes the mockup and `<slug>.demo.json`.
2. Capture it (`--narrow 420 --video script --demo <slug>.demo.json`; pages: `--video scroll`) + slop scan. One `Step: mockup` fix pass for anything broken (page errors, a broken state, a high slop hit). A critique only if the user asked (`--critique`).
3. Report the path, how to open it, and what works in it. Each later change request: `Step: mockup` with `Input:` = the same file and the request verbatim; the designer appends to `<slug>.feedback.md` and re-reads it before every edit.

## Launch prompt
```
Step: seeds | sketch | cull | build | refine | critique | mockup
References: <abs path>          M3E: <abs path, strict mode only>
Mode: default | m3e-strict      Target: web page | app UI | component/widget
Facts: <path(s)>   Taste: <path or inline>   Design system: <MASTER.md path or none>
Seed: <k>          Input: <file>   Verbs: <refine>   Critique file: <refine>
Captures: <folder(s)>   Request: <verbatim, mockup>   Project: <root, mockup>
Output: <path>
```
Launch the designer with `model:` from settings: `design_model` for exploration steps, `mockup_model` for mockups.
