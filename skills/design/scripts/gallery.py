#!/usr/bin/env python3
"""Build <workdir>/gallery/index.html: one card per <items-subdir>/*.html.

Usage: python3 -I gallery.py <workdir> <items-subdir> <captures-subdir> "<title>" [--only <file>]
--only shows just the listed items, in file order: lines that are a bare stem ("s3"), or cull.md
lines "s3 | 8 | keep | ..." (drop lines are ignored).
Captures for item X are read from <captures-subdir>/X/ (capture.mjs output; phone-<i>.png show as a strip). Items and captures
are copied into the gallery, so `python3 -m http.server` in the gallery dir serves everything.
"""
import html
import re
import shutil
import sys
from pathlib import Path

CSS = """
:root{color-scheme:light dark;--bg:#f4f4f2;--card:#fff;--ink:#1c1c1a;--mute:#6b6b66;--line:#d9d9d4}
@media (prefers-color-scheme:dark){:root{--bg:#161615;--card:#1f1f1d;--ink:#ecece8;--mute:#9a9a94;--line:#33332f}}
*{box-sizing:border-box}
body{margin:0;padding:24px 16px;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,sans-serif}
main{max-width:1280px;margin:0 auto}
h1{font-size:22px;margin:0 0 20px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,560px),1fr));gap:16px}
.card{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:12px;min-width:0}
.card h2{font-size:16px;margin:0 0 10px;display:flex;justify-content:space-between;gap:12px}
.card h2 a{font-size:14px;font-weight:400}
a{color:inherit}
.shots{display:grid;grid-template-columns:3fr 1fr;gap:8px;align-items:start}
img,video{display:block;width:100%;border:1px solid var(--line);border-radius:4px}
video{margin-top:8px}
.demo{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:6px;margin-top:8px}
.strip{display:grid;grid-template-columns:repeat(6,1fr);gap:6px;margin-top:8px}
.demo figure{margin:0}.demo figcaption{font-size:12px;color:var(--mute)}
pre{white-space:pre-wrap;font:13px/1.5 system-ui,sans-serif;color:var(--mute);margin:10px 0 0}
.none{color:var(--mute);font-size:13px}
"""


def natural(p):
    return [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", p.stem)]


def img(rel, alt, cls=""):
    r = html.escape(rel)
    return f'<a href="{r}" target="_blank"><img loading="lazy" src="{r}" alt="{html.escape(alt)}"{cls}></a>'


def card(item, items_sub, cap_sub, cap):
    name = item.stem
    live = f"{items_sub}/{item.name}"
    parts = [f'<article class="card"><h2>{html.escape(name)} <a href="{html.escape(live)}" target="_blank">open live</a></h2>']
    if cap.is_dir():
        base = f"{cap_sub}/{name}"
        small = next((f for f in ("phone.png", "narrow.png") if (cap / f).exists()), None)
        if (cap / "desktop.png").exists():
            parts.append('<div class="shots">' + img(f"{base}/desktop.png", f"{name}, desktop"))
            if small:
                parts.append(img(f"{base}/{small}", f"{name}, {small[:-4]}"))
            parts.append("</div>")
        phones = sorted(cap.glob("phone-[0-9]*.png"), key=natural)
        if phones:
            parts.append('<div class="strip">' + "".join(
                img(f"{base}/{f.name}", f"{name}, phone scroll {f.stem[6:]}") for f in phones) + "</div>")
        if (cap / "recording.webm").exists():
            parts.append(f'<video controls preload="none" src="{html.escape(base)}/recording.webm"></video>')
        demos = sorted(cap.glob("demo-*.png"), key=natural)
        if demos:
            parts.append('<div class="demo">' + "".join(
                f'<figure>{img(f"{base}/{d.name}", f"{name}, demo step {d.stem[5:]}")}<figcaption>step {d.stem[5:]}</figcaption></figure>'
                for d in demos) + "</div>")
    else:
        parts.append('<p class="none">No captures.</p>')
    story = item.with_name(name + ".story.md")
    if story.exists():
        parts.append(f"<pre>{html.escape(story.read_text(encoding='utf-8'))}</pre>")
    parts.append("</article>")
    return "".join(parts)


def only_stems(path):
    stems = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        m = re.match(r"\s*[-*|]?\s*`?([\w-]+)`?\s*(?:$|\|\s*[\d.]+\s*\|\s*keep\b)", line, re.I)
        if m:
            stems.append(m.group(1))
    return stems


def build(workdir, items_sub, cap_sub, title, only=None):
    work = Path(workdir).resolve()
    items_dir, caps_dir, gal = work / items_sub, work / cap_sub, work / "gallery"
    items = sorted(items_dir.glob("*.html"), key=natural)
    if only is not None:
        by_stem = {i.stem: i for i in items}
        items = [by_stem[s] for s in dict.fromkeys(only_stems(only)) if s in by_stem]
    if not items:
        sys.exit(f"no *.html in {items_dir}")
    gal.mkdir(exist_ok=True)
    for src, dest in ((items_dir, gal / items_sub), (caps_dir, gal / cap_sub)):
        shutil.rmtree(dest, ignore_errors=True)
        if src.is_dir():
            shutil.copytree(src, dest, ignore=shutil.ignore_patterns(".*"))
    cards = "".join(card(i, items_sub, cap_sub, caps_dir / i.stem) for i in items)
    t = html.escape(title)
    out = gal / "index.html"
    out.write_text(
        f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
        f"<title>{t}</title><style>{CSS}</style><main><h1>{t}</h1><div class=\"grid\">{cards}</div></main></html>\n",
        encoding="utf-8")
    return out


if __name__ == "__main__":
    args = sys.argv[1:]
    only = None
    if len(args) == 6 and args[4] == "--only":
        only = args.pop()
        args.pop()
    if len(args) != 4:
        sys.exit(__doc__)
    print("gallery:", build(*args, only=only))
