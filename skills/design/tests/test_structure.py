"""Structure checks for the design skill and the designer agent."""
import re
import unittest
from pathlib import Path

DESIGN = Path(__file__).resolve().parents[1]
ROOT = DESIGN.parents[1]
SKILL = DESIGN / "SKILL.md"
AGENT = ROOT / "agents" / "designer.md"
REFS = DESIGN / "references"
CREDITS = DESIGN / "CREDITS.md"

PRIVATE = re.compile(r"\bdux|marlon|harrow|/home/|kranz|bpmn", re.I)
PATH = re.compile(r"\b(?:references|scripts)/[\w./-]*[\w/]")


def read(path):
    return path.read_text(encoding="utf-8")


class ReferencedFilesTests(unittest.TestCase):
    def test_named_paths_exist(self):
        for doc in (SKILL, AGENT):
            # kb-m3e ships separately; strict mode checks for it at run time.
            text = read(doc).replace("kb-m3e/references", "")
            paths = set(PATH.findall(text))
            self.assertTrue(paths, f"{doc.name}: no references/ or scripts/ paths found")
            for p in paths:
                with self.subTest(doc=doc.name, path=p):
                    self.assertTrue((DESIGN / p).exists(), f"missing {p}")

    def test_agent_reference_names_exist(self):
        refs_line = next(l for l in read(AGENT).splitlines() if l.startswith("References"))
        names = re.findall(r"`([\w-]+\.md|[\w-]+/)`", refs_line)
        self.assertGreaterEqual(len(names), 9)
        for n in names:
            self.assertTrue((REFS / n).exists(), f"agent names missing reference {n}")

    def test_frontmatter(self):
        for doc in (SKILL, AGENT):
            m = re.match(r"---\n(.*?)\n---\n", read(doc), re.S)
            self.assertTrue(m, f"{doc.name}: no frontmatter")
            self.assertRegex(m.group(1), r"(?m)^name: \S")
            self.assertRegex(m.group(1), r"(?m)^description: \S")


class PublicRepoTests(unittest.TestCase):
    def test_no_private_strings(self):
        files = [AGENT] + [f for f in DESIGN.rglob("*") if f.is_file() and not {"__pycache__", "tests"} & set(f.relative_to(DESIGN).parts)]
        for f in files:
            with self.subTest(file=str(f.relative_to(ROOT))):
                m = PRIVATE.search(read(f))
                self.assertIsNone(m, m and m.group(0))


class AttributionTests(unittest.TestCase):
    def test_every_reference_is_attributed(self):
        credits = read(CREDITS)
        for f in sorted(REFS.glob("*.md")):
            with self.subTest(ref=f.name):
                self.assertTrue(re.search(r"(?m)^Sources: ", read(f)) or f.stem in credits,
                                "no Sources line and not covered by CREDITS.md")

    def test_web_copies_carry_attribution_and_licence(self):
        self.assertTrue((REFS / "LICENSE-APACHE").is_file())
        self.assertIn("Apache License", read(REFS / "LICENSE-APACHE"))
        web = sorted((REFS / "web").glob("*.md"))
        self.assertTrue(web)
        for f in web:
            with self.subTest(ref=f.name):
                first = read(f).splitlines()[0]
                self.assertRegex(first, r"^<!-- Source: https://github\.com/GoogleChrome/modern-web-guidance .*Apache-2\.0.*Copied unchanged\. -->$")

    def test_credits_link_every_source(self):
        credits = read(CREDITS)
        for repo in ("pbakaus/impeccable", "anthropics/skills", "heydamir/unslop", "emilkowalski/skills",
                     "greensock/gsap-skills", "CloudAI-X/threejs-skills", "vercel-labs/web-interface-guidelines",
                     "GoogleChrome/modern-web-guidance", "LemonFace0309/charles-skills"):
            self.assertIn(f"https://github.com/{repo}", credits)


if __name__ == "__main__":
    unittest.main()
