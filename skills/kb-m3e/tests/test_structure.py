"""Structure checks for the kb-m3e knowledge base."""
import re
import unittest
from pathlib import Path

KB = Path(__file__).resolve().parents[1]
FILES = [KB / "SKILL.md", *sorted((KB / "references").glob("*.md"))]
EXPECTED = {"motion.md", "shape.md", "color.md", "type.md", "components.md", "layout.md", "checklist.md"}
# Private strings that must never reach the public plugin.
FORBIDDEN = re.compile(r"dux|marlon|/home/|harrow", re.I)
URL = re.compile(r"https?://\S+")


def read(path):
    return path.read_text(encoding="utf-8")


class Structure(unittest.TestCase):
    def test_expected_references_exist_and_are_routed(self):
        names = {f.name for f in (KB / "references").glob("*.md")}
        self.assertEqual(names, EXPECTED)
        router = read(KB / "SKILL.md")
        for n in EXPECTED:
            self.assertIn(f"references/{n}", router, f"{n} not routed by SKILL.md")

    def test_frontmatter(self):
        m = re.match(r"---\n(.*?)\n---\n", read(KB / "SKILL.md"), re.S)
        self.assertTrue(m, "no frontmatter")
        fm = dict(line.split(":", 1) for line in m.group(1).splitlines() if ":" in line)
        self.assertEqual(fm["name"].strip(), "kb-m3e")
        self.assertTrue(fm["description"].strip())
        self.assertEqual(fm["user-invocable"].strip(), "false")
        self.assertEqual(fm["disable-model-invocation"].strip(), "false")

    def test_every_file_has_sources_with_url(self):
        for f in FILES:
            with self.subTest(file=f.name):
                text = read(f)
                self.assertIn("\n## Sources\n", text)
                self.assertRegex(text.split("\n## Sources\n", 1)[1], URL)

    def test_no_private_strings(self):
        for f in [*FILES, Path(__file__)]:
            text = read(f)
            if f == Path(__file__):
                text = text.replace(FORBIDDEN.pattern, "")
            with self.subTest(file=f.name):
                hit = FORBIDDEN.search(text)
                self.assertIsNone(hit, f"forbidden string {hit and hit.group(0)!r}")

    def test_every_component_has_motion(self):
        text = read(KB / "references" / "components.md").split("\n## Sources\n", 1)[0]
        entries = re.split(r"\n### ", text)[1:]
        self.assertGreaterEqual(len(entries), 20)
        for e in entries:
            name = e.splitlines()[0]
            with self.subTest(component=name):
                self.assertRegex(e, r"(?m)^- Motion: \S", "no Motion line")

    def test_room_for_choice_lines_say_what(self):
        for f in FILES:
            for line in read(f).splitlines():
                if "Room for choice:" in line:
                    with self.subTest(file=f.name, line=line[:60]):
                        self.assertGreater(len(line.split("Room for choice:", 1)[1].strip()), 10)

    def test_files_stay_readable(self):
        for f in FILES:
            limit = 700 if f.name == "components.md" else 400
            with self.subTest(file=f.name):
                self.assertLess(len(read(f).splitlines()), limit)


if __name__ == "__main__":
    unittest.main()
