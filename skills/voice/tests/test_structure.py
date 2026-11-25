"""Structure checks for the voice core, the writing layers and the tells checker."""
import hashlib
import importlib.util
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
VOICE = ROOT / "skills" / "voice"
WRITING = ROOT / "skills" / "writing"
LAYERS = WRITING / "layers"
CHECK = VOICE / "scripts" / "check-tells.sh"

_spec = importlib.util.spec_from_file_location("design_structure", ROOT / "skills/design/tests/test_structure.py")
_design = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_design)
PRIVATE = _design.PRIVATE


class LayerTests(unittest.TestCase):
    def test_routed_layers_match_files(self):
        routed = set(re.findall(r"`layers/([\w-]+\.md)`", (WRITING / "SKILL.md").read_text()))
        files = {f.name for f in LAYERS.glob("*.md")}
        self.assertTrue(routed)
        self.assertEqual(routed, files)

    def test_core_files_exist(self):
        for name in ("conduct.md", "voice.md", "code-comments.md"):
            self.assertTrue((VOICE / "core" / name).is_file(), name)


class PublicRepoTests(unittest.TestCase):
    def test_no_private_strings(self):
        files = [f for d in (VOICE, LAYERS) for f in d.rglob("*")
                 if f.is_file() and "__pycache__" not in f.parts]
        files += [WRITING / "SKILL.md", ROOT / "hooks" / "scripts" / "inject-voice.sh"]
        for f in files:
            text = f.read_text(encoding="utf-8").lower()
            with self.subTest(file=str(f.relative_to(ROOT))):
                self.assertNotIn("/".join(("", "home", "")), text)
                hits = {w for w in re.split(r"[^a-z0-9]+", text) if hashlib.sha256(w.encode()).hexdigest() in PRIVATE}
                self.assertFalse(hits, "private word found")


class CheckTellsTests(unittest.TestCase):
    def check(self, text, *flags):
        return subprocess.run(["bash", str(CHECK), *flags, "-"], input=text, capture_output=True, text=True)

    def test_hard_hit_fails_and_warn_passes(self):
        self.assertEqual(self.check("It works — mostly.\n").returncode, 1)
        out = self.check("The cause was the config file: it was stale.\n")
        self.assertEqual(out.returncode, 0)
        self.assertIn("warn: colon reveal", out.stdout)

    def test_fiction_flag_adds_story_checks(self):
        text = "She checked the gauge again. This one she didn't know.\n"
        self.assertNotIn("withheld knowledge", self.check(text).stdout)
        self.assertIn("withheld knowledge", self.check(text, "--fiction").stdout)


if __name__ == "__main__":
    unittest.main()
