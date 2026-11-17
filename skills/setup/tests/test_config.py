"""Structure checks for the layered devline config."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REF = ROOT / "skills/setup/references/config.md"
REF_PATH = "${CLAUDE_PLUGIN_ROOT}/skills/setup/references/config.md"
LEGACY = "devline" + ".local"  # split so this file doesn't match itself
DESIGN_KEYS = {"design_model", "sketch_model", "mockup_model", "design_sketches", "design_pick", "design_mode"}


def read(path):
    return path.read_text(encoding="utf-8")


def key_table():
    """{key: owner} from the Keys table of the reference."""
    keys = read(REF).split("\n## Keys\n", 1)[1]
    return dict(re.findall(r"(?m)^\| `([a-z_]+)` \| [^|]+ \| ([^|]+?) \|", keys))


def owner_file(owner):
    return ROOT / owner if "/" in owner else ROOT / "skills" / owner / "SKILL.md"


def defaults_section(text):
    m = re.search(r"(?m)^(#+) Defaults\s*$", text)
    if not m:
        return None
    rest = text[m.end():]
    end = re.search(rf"(?m)^#{{1,{len(m.group(1))}}} ", rest)
    return rest[: end.start()] if end else rest


class Config(unittest.TestCase):
    def test_table_has_the_keys_in_use(self):
        keys = key_table()
        self.assertGreaterEqual(len(keys), 20)
        self.assertLessEqual(DESIGN_KEYS, set(keys))

    def test_every_key_is_defined_by_its_owner(self):
        for key, owner in key_table().items():
            with self.subTest(key=key, owner=owner):
                path = owner_file(owner)
                self.assertTrue(path.is_file(), f"owner {owner} not found")
                text = read(path)
                if path.name == "SKILL.md":
                    text = defaults_section(text)
                    self.assertIsNotNone(text, f"{owner} has no Defaults section")
                self.assertIn(f"`{key}`", text)

    def test_owners_point_to_the_reference(self):
        for owner in set(key_table().values()):
            with self.subTest(owner=owner):
                self.assertIn(REF_PATH, read(owner_file(owner)))

    def test_legacy_name_only_in_the_migration_note(self):
        skip = {".git", "__pycache__", ".devline"}
        for path in ROOT.rglob("*"):
            if not path.is_file() or skip & set(path.relative_to(ROOT).parts) or path == REF:
                continue
            try:
                text = read(path)
            except UnicodeDecodeError:
                continue
            with self.subTest(file=str(path.relative_to(ROOT))):
                self.assertNotIn(LEGACY, text)


if __name__ == "__main__":
    unittest.main()
