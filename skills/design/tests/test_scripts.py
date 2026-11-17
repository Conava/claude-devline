"""Self-tests for the design scripts: gallery.py, slop-scan.mjs and (if Playwright is installed) capture.mjs."""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
NODE = shutil.which("node")
PLAYWRIGHT = Path.home() / ".cache/devline/capture/node_modules/playwright-core"


class GalleryTests(unittest.TestCase):
    def test_builds_index_with_copied_assets(self):
        with tempfile.TemporaryDirectory() as d:
            work = Path(d)
            (work / "sketches").mkdir()
            (work / "sketches/s1.html").write_text("<p>one</p>")
            (work / "sketches/s1.story.md").write_text("frame 1: a <dot> becomes a line")
            (work / "sketches/s2.html").write_text("<p>two</p>")
            cap = work / "captures/s1"
            cap.mkdir(parents=True)
            for f in ("desktop.png", "narrow.png", "demo-0.png", "demo-1.png", "recording.webm", "phone-0.png", "phone-5.png"):
                (cap / f).write_bytes(b"x")
            r = subprocess.run([sys.executable, "-I", str(SCRIPTS / "gallery.py"), str(work), "sketches", "captures", "Sketches"],
                               capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            index = (work / "gallery/index.html").read_text()
            for s in ("<title>Sketches</title>", 'href="sketches/s1.html"', "captures/s1/desktop.png",
                      "captures/s1/narrow.png", "captures/s1/demo-1.png", "captures/s1/phone-5.png", "captures/s1/recording.webm",
                      "a &lt;dot&gt; becomes a line", "open live", "No captures."):
                self.assertIn(s, index)
            for f in ("sketches/s1.html", "captures/s1/desktop.png", "captures/s1/recording.webm"):
                self.assertTrue((work / "gallery" / f).is_file(), f)

    def test_only_shows_kept_sketches_in_cull_order(self):
        with tempfile.TemporaryDirectory() as d:
            work = Path(d)
            (work / "sketches").mkdir()
            for k in (1, 2, 3, 10):
                (work / f"sketches/s{k}.html").write_text("<p>x</p>")
            (work / "cull.md").write_text("# Cull\n\ns10 | 8 | keep | strong | the ring\n"
                                          "s2 | 4 | drop | generic\n| s3 | 7 | keep | ok | the fold |\n")
            r = subprocess.run([sys.executable, "-I", str(SCRIPTS / "gallery.py"), str(work), "sketches", "captures",
                                "Sketches", "--only", str(work / "cull.md")], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            index = (work / "gallery/index.html").read_text()
            self.assertNotIn("s1.html", index)
            self.assertNotIn("s2.html", index)
            self.assertLess(index.index("s10.html"), index.index("s3.html"))

    def test_no_items_fails(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "final").mkdir()
            r = subprocess.run([sys.executable, "-I", str(SCRIPTS / "gallery.py"), d, "final", "captures", "Final"],
                               capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0)


@unittest.skipUnless(NODE, "node not installed")
class SlopScanTests(unittest.TestCase):
    def scan(self, html):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "page.html"
            f.write_text(html)
            r = subprocess.run([NODE, str(SCRIPTS / "slop-scan.mjs"), str(f)], capture_output=True, text=True)
            return r.returncode, json.loads(r.stdout)

    def test_gradient_text_is_high(self):
        code, out = self.scan("<style>h1{background:linear-gradient(red,blue);-webkit-background-clip:text}</style><h1>Hi</h1>")
        self.assertEqual(code, 1)
        self.assertIn("gradient-text", [f["id"] for f in out["findings"]])

    def test_clean_page_passes(self):
        code, out = self.scan("<style>body{font-family:Literata,serif;color:#222}</style><h1>Opening hours</h1><p>Tuesday to Sunday.</p>")
        self.assertEqual(code, 0, out)
        self.assertEqual(out["high"], 0)

    def test_reflex_font_is_medium(self):
        code, out = self.scan("<style>body{font-family:Inter,sans-serif}</style><p>Text</p>")
        self.assertEqual(code, 0)
        self.assertEqual([f["sev"] for f in out["findings"] if f["id"] == "reflex-font"], ["med"])


PAGE = """<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>t</title>
<button id="b" onclick="document.getElementById('o').textContent='opened'">Open</button>
<p id="o">closed</p><input id="i"><div style="height:4000px;background:linear-gradient(#fff,#000)"></div>"""


@unittest.skipUnless(NODE and PLAYWRIGHT.is_dir(), "playwright-core not installed in ~/.cache/devline/capture")
class CaptureTests(unittest.TestCase):
    def run_capture(self, d, *args):
        page = Path(d) / "page.html"
        page.write_text(PAGE)
        out = Path(d) / "out"
        r = subprocess.run([NODE, str(SCRIPTS / "capture.mjs"), str(page), str(out), *args],
                           capture_output=True, text=True, timeout=180)
        self.assertEqual(r.returncode, 0, r.stderr)
        return out

    def test_demo_script(self):
        with tempfile.TemporaryDirectory() as d:
            demo = Path(d) / "demo.json"
            demo.write_text(json.dumps([{"click": "text=Open"}, {"type": ["#i", "hi"]}, {"press": "Tab"}, {"wait": 100}]))
            out = self.run_capture(d, "--narrow", "420", "--video", "script", "--demo", str(demo))
            for f in ("desktop.png", "narrow.png", "reduced.png", "demo-0.png", "demo-3.png", "recording.webm"):
                self.assertTrue((out / f).is_file(), f)
            self.assertEqual(json.loads((out / "errors.json").read_text()), [])

    def test_phone_sheet_and_video(self):
        with tempfile.TemporaryDirectory() as d:
            out = self.run_capture(d, "--phone-sheet", "--video", "scroll", "--phone-video")
            for f in ("phone.png", "phone-0.png", "phone-5.png", "recording.webm", "phone-recording.webm"):
                self.assertTrue((out / f).is_file(), f)
            self.assertNotEqual((out / "phone-0.png").read_bytes(), (out / "phone-5.png").read_bytes(), "touch scroll did not move")
            self.assertEqual(json.loads((out / "errors.json").read_text()), [])

    def test_stills_only(self):
        with tempfile.TemporaryDirectory() as d:
            out = self.run_capture(d, "--stills-only")
            self.assertTrue((out / "desktop.png").is_file())
            self.assertTrue((out / "phone.png").is_file())
            self.assertFalse((out / "reduced.png").exists())
            self.assertFalse((out / "phone-0.png").exists())


if __name__ == "__main__":
    unittest.main()
