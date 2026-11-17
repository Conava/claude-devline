"""Cross-file links of the devline pipeline: stage names, presets, focus values, handoff parts."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEVLINE = ROOT / "skills/devline"
STAGES = DEVLINE / "references/stages.md"
PRESETS = {"quick", "implement", "full"}


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def section(text, heading):
    """Body of the H2 `heading` up to the next H2."""
    m = re.search(rf"(?m)^## {re.escape(heading)}.*$", text)
    assert m, f"no '## {heading}' section"
    rest = text[m.end():]
    end = re.search(r"(?m)^## ", rest)
    return rest[: end.start()] if end else rest


def stage_table():
    """{stage: pulled-in-by} from the Stages table."""
    rows = re.findall(r"(?m)^\| `([^`]+)` \|(.*)\|\s*$", section(read(STAGES), "Stages"))
    return {name: cells.split("|")[-1].strip() for name, cells in rows}


def presets():
    """{preset: [stage, ...]} from lines like '- **quick**: `a`, `b`'."""
    lines = re.findall(r"(?m)^- \*\*(\w+)\*\*:(.*)$", section(read(STAGES), "Presets"))
    return {name: re.findall(r"`([^`]+)`", rest) for name, rest in lines}


def focus_values(text):
    return set(re.findall(r"focus: ?([a-z-]+)", text))


def frontmatter(rel):
    m = re.match(r"---\n(.*?)\n---\n", read(rel), re.S)
    assert m, f"{rel}: no frontmatter"
    return {k.strip(): v.strip() for k, v in (l.split(":", 1) for l in m.group(1).splitlines() if ":" in l)}


class Stages(unittest.TestCase):
    def test_every_stage_has_a_trigger(self):
        table = stage_table()
        self.assertGreaterEqual(len(table), 10)
        for name, trigger in table.items():
            with self.subTest(stage=name):
                self.assertTrue(trigger, f"{name} has no 'Pulled in by'")

    def test_presets_name_only_table_stages(self):
        table, found = stage_table(), presets()
        self.assertLessEqual(PRESETS, set(found))
        for name, stages in found.items():
            with self.subTest(preset=name):
                self.assertTrue(stages)
                self.assertLessEqual(set(stages), set(table))

    def test_commands_name_an_existing_preset(self):
        for skill, preset in (("quick", "quick"), ("implement", "implement")):
            with self.subTest(skill=skill):
                text = read(f"skills/{skill}/SKILL.md")
                self.assertIn("stages.md", text)
                self.assertRegex(text, rf"preset `?{preset}`?|`{preset}` preset")
        self.assertNotIn("hand off to the full", read("skills/quick/SKILL.md"))

    def test_reviewer_focus_matches_stage_menu(self):
        reviewer = re.findall(r"(?m)^- `([a-z-]+)`:", section(read("agents/reviewer.md"), "Focus"))
        self.assertEqual(set(reviewer), focus_values(read("skills/devline/references/stages.md")))
        self.assertEqual(len(reviewer), 4)


class Handoff(unittest.TestCase):
    def test_frontmatter_is_explicit_only(self):
        fm = frontmatter("skills/handoff/SKILL.md")
        self.assertEqual(fm.get("name"), "handoff")
        self.assertEqual(fm.get("disable-model-invocation"), "true")

    def test_carries_every_precompact_part(self):
        # a title is the first words of each numbered line, before its colon
        lines = re.findall(r"(?m)^\d\. ([^:\n]+)", read("hooks/scripts/pre-compact.sh"))
        titles = [" ".join(line.rstrip(".").split()[:5]) for line in lines]
        self.assertEqual(len(titles), 7)
        skill = read("skills/handoff/SKILL.md")
        for title in titles:
            with self.subTest(title=title):
                self.assertIn(title, skill)


class Agents(unittest.TestCase):
    def test_plan_opens_with_summary_for_approval(self):
        text = read("agents/references/plan-format.md")
        self.assertEqual(re.findall(r"(?m)^## .*$", text)[0], "## Summary for approval")
        self.assertIn("**Reach:**", text)
        self.assertIn("Summary for approval", read("agents/planner.md").split("### 7.")[1].split("\n### ")[0])

    def test_implementer_reports_red_run_and_integration_notes(self):
        text = read("agents/implementer.md")
        for needle in ("- Red:", "### Integration notes", "Committed:"):
            with self.subTest(needle=needle):
                self.assertIn(needle, text)

    def test_brainstorm_credits_its_source(self):
        self.assertIn("MIT", section(read("skills/brainstorm/SKILL.md"), "Credits"))


class Orchestrator(unittest.TestCase):
    def test_referenced_files_exist(self):
        text = read("skills/devline/SKILL.md")
        refs = set(re.findall(r"(\$\{CLAUDE_PLUGIN_ROOT\}/[\w/-]+/)?references/([\w-]+\.md)", text))
        self.assertIn(("", "stages.md"), refs)
        for prefix, name in refs:
            with self.subTest(ref=prefix + name):
                if prefix:
                    self.assertTrue((ROOT / prefix.split("}/", 1)[1] / "references" / name).is_file())
                else:
                    # bare paths are devline's own, or another skill's when the text names that skill
                    self.assertTrue(any(ROOT.glob(f"skills/*/references/{name}")))

    def test_defaults_list_stage_menu(self):
        self.assertIn("`stage_menu`", section(read("skills/devline/SKILL.md"), "Defaults"))
        self.assertNotRegex(read("skills/devline/SKILL.md"), r"(?m)^#+ Fast Lane")

    def test_protocol_sections(self):
        text = read("skills/devline/references/implementation-protocol.md")
        for heading in ("Agent Briefs", "Merged-Tree Gates", "Orchestrator Discipline"):
            with self.subTest(heading=heading):
                self.assertRegex(text, rf"(?m)^## {heading}\s*$")
        self.assertNotIn('Run tests to "verify" a merge', text)

    def test_state_schema_has_stages(self):
        text = read("skills/devline/references/recovery.md")
        self.assertIn("## Stages", text)
        self.assertRegex(text, r"(?m)^\| # \| Status \|.*\bAgent\b.*\bWorktree\b")


if __name__ == "__main__":
    unittest.main()
