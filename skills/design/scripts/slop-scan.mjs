#!/usr/bin/env node
// Deterministic AI-look scan of one HTML file. Prints JSON findings; exit 1 if any high finding.
// Rule ideas paraphrased from Impeccable's detector (Apache-2.0), Anthropic frontend-design (Apache-2.0)
// and unslop's signs list (CC BY 4.0). Heuristics: a hit is a prompt to look, not a verdict.
import { readFileSync } from 'node:fs';

const file = process.argv[2];
if (!file) { console.error('usage: slop-scan.mjs <file.html>'); process.exit(2); }
const src = readFileSync(file, 'utf8');
const lines = src.split('\n');
const text = src.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/g, ' ').replace(/<[^>]+>/g, ' ');

const rules = [
  ['med', 'reflex-font', /font-family:[^;]*\b(Inter|Roboto|Arial|Space Grotesk|DM Sans|Plus Jakarta|Instrument (Sans|Serif)|Geist|Fraunces|Playfair|Newsreader|Poppins|Montserrat)\b/i, 'Reflex typeface; choose for the character'],
  ['high', 'gradient-text', /background-clip:\s*text|-webkit-background-clip:\s*text/i, 'Gradient text'],
  ['high', 'purple-gradient', /gradient\([^)]*(#(7c3aed|8b5cf6|6366f1|a855f7|9333ea|4f46e5)|purple|violet)/i, 'Purple/violet gradient'],
  ['high', 'cream-terracotta', /#(f4f1ea|d97757)\b/i, 'Cluster 1 colors (cream + terracotta)'],
  ['med', 'glass', /backdrop-filter:\s*blur/i, 'Backdrop blur: only where something really sits over content'],
  ['med', 'glow', /(box|text)-shadow:\s*0(px)?\s+0(px)?\s+\d+px[^;]*(rgba?\([^)]*\)|#[0-9a-f]{3,8})/i, 'Zero-offset glow'],
  ['med', 'pill', /border-radius:\s*(999|9999|100)(px|rem|%)?/i, 'Pill radius'],
  ['med', 'uppercase-label', /text-transform:\s*uppercase/i, 'Uppercase label (check for tracked eyebrows)'],
  ['med', 'transition-all', /transition:\s*all\b/i, 'transition: all'],
  ['med', 'custom-cursor', /cursor:\s*none|mix-blend-mode:\s*difference/i, 'Custom cursor / cursor effect'],
  ['low', 'grain', /feTurbulence|noise\.(png|svg)/i, 'Grain/noise overlay (check it is not decoration)'],
  ['low', 'bounce-ease', /cubic-bezier\(\s*[\d.]+\s*,\s*-?(1\.[1-9]|[2-9])|cubic-bezier\([^)]*,\s*-0?\.\d/i, 'Easing overshoots (bounce/elastic)'],
];
const findings = [];
lines.forEach((l, i) => { for (const [sev, id, re, why] of rules) if (re.test(l)) findings.push({ sev, id, line: i + 1, why, at: l.trim().slice(0, 120) }); });

const textRules = [
  ['med', 'middle-dot-meta', /\S+ · \S+ · \S+/, 'A · B · C meta string'],
  ['med', 'arrow-glyph', /[→↗↘➜]/, 'Unicode arrow as icon'],
  ['high', 'emoji', /\p{Extended_Pictographic}/u, 'Emoji'],
  ['med', 'section-number', /(^|\s)0[1-9]\s*[\/—–-]/, 'Section number 01/02 (only for real sequences)'],
  ['low', 'hype-word', /\b(seamless|robust|powerful|unlock|supercharge|revolutioni[sz]e|cutting-edge|effortless)\b/i, 'Hype word'],
];
for (const [sev, id, re, why] of textRules) { const m = text.match(re); if (m) findings.push({ sev, id, why, at: m[0].slice(0, 80) }); }

const fadeUps = (src.match(/translateY\(\s*\d+px\s*\)/g) || []).length;
const observers = (src.match(/IntersectionObserver/g) || []).length;
if (fadeUps >= 6 && observers) findings.push({ sev: 'high', id: 'fade-up-everywhere', why: `${fadeUps} translateY offsets + IntersectionObserver: likely fade-and-slide-up on every block` });
const tilt = /rotate[XY]\([^)]*\)[\s\S]{0,200}mousemove|mousemove[\s\S]{0,400}rotate[XY]/i.test(src);
if (tilt) findings.push({ sev: 'high', id: 'tilt-hover', why: 'Pointer-driven 3D tilt' });

console.log(JSON.stringify({ file, high: findings.filter(f => f.sev === 'high').length, findings }, null, 1));
process.exit(findings.some(f => f.sev === 'high') ? 1 : 0);
