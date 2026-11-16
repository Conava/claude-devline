"""Structure checks for the kb-engineering router, its checklists and verify-setup."""
import re
import unittest
from pathlib import Path

SKILLS = Path(__file__).resolve().parents[2]
KB = SKILLS / "kb-engineering"
ROUTER = KB / "SKILL.md"
VERIFY_SETUP = SKILLS / "verify-setup" / "SKILL.md"
SETUP_MD = KB / "references" / "setup.md"

# Checklists are curated, not padded: short ones are fine, this only guards against stubs.
MIN_CHECKLIST_LINES = 80
# Unlicensed vendor docs and ideas-only sources state their status instead of a licence name.
LICENCE = re.compile(
    r"\b(vendor|(ideas|facts|numbers) only|(usage described|tool use) only|MIT|Apache|CC-BY\S*|GPL\S*|GFDL|EPL\S*|BSD|ISC|licen[cs]e\w*|copyright\w*|redistributable)\b",
    re.I,
)
RECIPE_HEADINGS = ["Fast path", "Full sweep", "Environment", "What working looks like", "Known noise"]


def read(path):
    return path.read_text(encoding="utf-8")


def frontmatter(path):
    m = re.match(r"---\n(.*?)\n---\n", read(path), re.S)
    assert m, f"{path}: no frontmatter block"
    return dict(line.split(":", 1) for line in m.group(1).splitlines() if ":" in line)


def routed_checklists():
    names = set(re.findall(r"`([\w-]+\.md)`", read(ROUTER).split("## Always-on rules")[0]))
    return sorted(names)


def checklist_files():
    return sorted((KB / "checklists").glob("*.md"))


class RouterTests(unittest.TestCase):
    def test_every_routed_checklist_exists(self):
        names = routed_checklists()
        self.assertTrue(names, "no checklist names found in SKILL.md tables")
        for n in names:
            self.assertTrue((KB / "checklists" / n).is_file(), f"missing checklist {n}")

    def test_every_checklist_is_routed(self):
        routed = set(routed_checklists())
        for f in checklist_files():
            self.assertIn(f.name, routed, f"{f.name} is not routed by SKILL.md")

    def test_router_under_150_lines(self):
        self.assertLess(len(read(ROUTER).splitlines()), 150)

    def test_frontmatter_parses(self):
        for path, keys in ((ROUTER, ("name", "description")), (VERIFY_SETUP, ("name", "description", "user-invocable"))):
            fm = frontmatter(path)
            for k in keys:
                self.assertTrue(fm.get(k, "").strip(), f"{path.parent.name}: frontmatter key {k!r} missing")


class ChecklistTests(unittest.TestCase):
    def test_sections_and_sources(self):
        files = checklist_files()
        self.assertTrue(files)
        for f in files:
            text = read(f)
            lines = text.splitlines()
            with self.subTest(checklist=f.name):
                self.assertGreaterEqual(len(lines), MIN_CHECKLIST_LINES, "too short")
                self.assertRegex(lines[0], r"^# .+ checklist$")
                self.assertIn("\n## Verify it\n", text)
                self.assertIn("\n## Sources\n", text)
                sources = text.split("\n## Sources\n", 1)[1]
                items = [l for l in sources.splitlines() if l.startswith("- ")]
                self.assertTrue(items, "Sources is empty")
                for l in items:
                    self.assertRegex(l, LICENCE, f"no licence named: {l[:80]}")


class VerifySetupTests(unittest.TestCase):
    def test_paths_into_kb_engineering_exist(self):
        refs = re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}/(skills/kb-engineering/[^\s`]+)", read(VERIFY_SETUP))
        self.assertTrue(refs)
        for ref in refs:
            ref = ref.replace("<file>", "backend")  # placeholder for any checklist
            self.assertTrue((SKILLS.parent / ref).exists(), f"verify-setup points at missing {ref}")

    def test_recipe_template_has_five_headings(self):
        template = read(SETUP_MD).split("```markdown", 1)[1].split("```", 1)[0]
        for h in RECIPE_HEADINGS:
            self.assertIn(f"\n## {h}\n", template, f"template lacks '## {h}'")


class AgentTests(unittest.TestCase):
    def test_plugin_paths_in_agents_exist(self):
        for agent in sorted((SKILLS.parent / "agents").glob("*.md")):
            for ref in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}/(skills/[^\s`)\"']+)", read(agent)):
                ref = ref.rstrip(".,;:")
                with self.subTest(agent=agent.name, ref=ref):
                    self.assertTrue((SKILLS.parent / ref).exists(), f"{agent.name} points at missing {ref}")


if __name__ == "__main__":
    unittest.main()
