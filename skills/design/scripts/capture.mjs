#!/usr/bin/env node
// Capture a page for design review: stills, an optional recording, and a frame-diff report.
// Usage: node capture.mjs <file.html|url> <outdir> [--stills-only] [--sheet] [--frames] [--narrow 420]
//                         [--video scroll | --video script --demo <steps.json>]
//   stills: desktop.png (1440x900 first view), desktop-mid.png (scrolled 50%), phone.png (390x844;
//           narrow.png when --narrow is not 390), reduced.png (1440x900, prefers-reduced-motion)
//   --stills-only:  desktop.png and phone/narrow.png only (fast; for sketches)
//   --sheet:        8 stills at 0..100% scroll (scroll-0..7.png), reached by wheel scrolling
//   --frames:       scroll in 40 steps, report per-step pixel change (pops = spikes, dead = ~0)
//   --video scroll: 10 s webm of a slow scroll to the end and back (1440x900)
//   --video script: webm of the --demo steps (1440x900), plus demo-<i>.png after each step.
//                   Steps: {"click": sel, "button"?: "right"}, {"hover": sel}, {"press": key},
//                   {"type": [sel, text]}, {"drag": [sel, dx, dy]}, {"scroll": px}, {"wait": ms};
//                   sel is CSS or text=...
// Writes errors.json (page errors, console errors, failed demo steps).
import { createRequire } from 'node:module';
import { mkdirSync, renameSync, writeFileSync, readdirSync, readFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import os from 'node:os';

const require = createRequire(join(os.homedir(), '.cache/devline/capture/'));
const { chromium } = require('playwright-core');

const usage = 'usage: capture.mjs <file|url> <outdir> [--stills-only] [--sheet] [--frames] [--narrow W] [--video scroll | --video script --demo steps.json]';
const [src, outArg, ...rest] = process.argv.slice(2);
if (!src || !outArg) { console.error(usage); process.exit(2); }
const opt = (k, d) => { const i = rest.indexOf(k); return i < 0 ? d : (rest[i + 1] && !rest[i + 1].startsWith('--') ? rest[i + 1] : true); };
const url = /^https?:/.test(src) ? src : pathToFileURL(resolve(src)).href;
const out = resolve(outArg); mkdirSync(out, { recursive: true });
const narrow = Number(opt('--narrow', 390));
const stillsOnly = opt('--stills-only', false);
const video = stillsOnly ? null : opt('--video', null);
if (video && !['scroll', 'script'].includes(video)) { console.error(usage); process.exit(2); }
const demoPath = opt('--demo', null);
if (video === 'script' && typeof demoPath !== 'string') { console.error('--video script needs --demo <steps.json>'); process.exit(2); }
const steps = video === 'script' ? JSON.parse(readFileSync(demoPath, 'utf8')) : [];
const errors = [];

const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
function watch(page) {
  page.on('pageerror', e => errors.push(String(e).slice(0, 200)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text().slice(0, 200)); });
}
async function open(vp, extra = {}) {
  const ctx = await browser.newContext({ viewport: vp, deviceScaleFactor: 1, ...extra });
  const page = await ctx.newPage();
  watch(page);
  await page.goto(url, { waitUntil: 'load', timeout: 30000 }).catch(e => errors.push('load: ' + e.message));
  await page.waitForTimeout(1500);
  return { ctx, page };
}
const maxScroll = p => p.evaluate(() => Math.max(0, document.scrollingElement.scrollHeight - innerHeight));
async function slowScroll(page, to, ms) {
  const from = await page.evaluate(() => scrollY), steps = Math.max(1, Math.round(ms / 50));
  for (let i = 1; i <= steps; i++) { await page.mouse.wheel(0, (to - from) / steps); await page.waitForTimeout(50); }
}
async function runStep(page, s) {
  const el = sel => page.locator(sel).first();
  const t = { timeout: 5000 };
  if (s.click) await el(s.click).click({ button: s.button || 'left', ...t });
  else if (s.hover) await el(s.hover).hover(t);
  else if (s.press) await page.keyboard.press(s.press);
  else if (s.type) { await el(s.type[0]).click(t); await page.keyboard.type(s.type[1], { delay: 40 }); }
  else if (s.drag) {
    const [sel, dx, dy] = s.drag, box = await el(sel).boundingBox(t);
    if (!box) throw new Error('not visible');
    const x = box.x + box.width / 2, y = box.y + box.height / 2;
    await page.mouse.move(x, y); await page.mouse.down();
    await page.mouse.move(x + dx, y + dy, { steps: 20 }); await page.mouse.up();
  } else if (s.scroll) await slowScroll(page, (await page.evaluate(() => scrollY)) + s.scroll, 600);
  else if (s.wait) await page.waitForTimeout(s.wait);
  else throw new Error('unknown step');
}

// stills
{
  const { ctx, page } = await open({ width: 1440, height: 900 });
  await page.screenshot({ path: join(out, 'desktop.png') });
  const m = stillsOnly ? 0 : await maxScroll(page);
  if (m > 0) { await slowScroll(page, m / 2, 1500); await page.waitForTimeout(800); await page.screenshot({ path: join(out, 'desktop-mid.png') }); }
  if (opt('--sheet', false) && m > 0) {
    await page.evaluate(() => scrollTo(0, 0)); await page.waitForTimeout(400);
    for (let i = 0; i <= 7; i++) { await slowScroll(page, (m * i) / 7, 600); await page.waitForTimeout(500); await page.screenshot({ path: join(out, `scroll-${i}.png`) }); }
  }
  if (opt('--frames', false) && !stillsOnly) {
    await page.evaluate(() => scrollTo(0, 0)); await page.waitForTimeout(500);
    const shots = [];
    for (let i = 0; i <= 40; i++) { await page.evaluate(y => scrollTo(0, y), (m * i) / 40); await page.waitForTimeout(120); shots.push((await page.screenshot({ type: 'png' })).toString('base64')); }
    const diffs = await page.evaluate(async list => {
      const load = b => new Promise(r => { const im = new Image(); im.onload = () => r(im); im.src = 'data:image/png;base64,' + b; });
      const c = new OffscreenCanvas(360, 225), g = c.getContext('2d', { willReadFrequently: true });
      let prev = null; const res = [];
      for (const b of list) { g.drawImage(await load(b), 0, 0, 360, 225); const d = g.getImageData(0, 0, 360, 225).data;
        if (prev) { let n = 0; for (let i = 0; i < d.length; i += 4) if (Math.abs(d[i] - prev[i]) + Math.abs(d[i + 1] - prev[i + 1]) + Math.abs(d[i + 2] - prev[i + 2]) > 30) n++; res.push(+(n / (360 * 225)).toFixed(3)); }
        prev = d; }
      return res;
    }, shots);
    writeFileSync(join(out, 'frames.json'), JSON.stringify({ step: 'scroll 1/40 of page per step', changedShare: diffs }, null, 1));
  }
  await ctx.close();
}
{
  const { ctx, page } = await open({ width: narrow, height: 844 }, { isMobile: false, hasTouch: true });
  await page.screenshot({ path: join(out, narrow === 390 ? 'phone.png' : 'narrow.png') });
  await ctx.close();
}
if (!stillsOnly) {
  const { ctx, page } = await open({ width: 1440, height: 900 }, { reducedMotion: 'reduce' });
  await page.screenshot({ path: join(out, 'reduced.png') });
  await ctx.close();
}
// recording
if (video) {
  const vdir = join(out, '.video'); mkdirSync(vdir, { recursive: true });
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, recordVideo: { dir: vdir, size: { width: 1440, height: 900 } } });
  const page = await ctx.newPage();
  watch(page);
  await page.goto(url, { waitUntil: 'load' }).catch(() => {});
  await page.waitForTimeout(1200);
  if (video === 'script') {
    for (const [i, s] of steps.entries()) {
      await runStep(page, s).catch(e => errors.push(`demo step ${i} ${JSON.stringify(s)}: ${String(e.message).split('\n')[0].slice(0, 160)}`));
      await page.waitForTimeout(300);
      await page.screenshot({ path: join(out, `demo-${i}.png`) });
    }
    await page.waitForTimeout(800);
  } else {
    const m = await maxScroll(page);
    await slowScroll(page, m, 6500); await page.waitForTimeout(500); await slowScroll(page, 0, 1800);
  }
  const v = page.video(); await ctx.close();
  renameSync(await v.path(), join(out, 'recording.webm'));
}
await browser.close();
writeFileSync(join(out, 'errors.json'), JSON.stringify(errors, null, 1));
console.log(`captured ${src} -> ${out} (${readdirSync(out).filter(f => !f.startsWith('.')).join(', ')}); page errors: ${errors.length}`);
