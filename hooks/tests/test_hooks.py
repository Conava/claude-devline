"""Checks for the hook wiring, the voice injection and path resolution in validate-bash.sh."""
import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "hooks" / "scripts"
# Claude Code turns additionalContext above about 10,000 characters into a preview plus a file.
LIMIT = 9000


def run(script, payload, *args, env=None, cwd=None):
    out = subprocess.run(["bash", str(SCRIPTS / script), *args], input=json.dumps(payload),
                         capture_output=True, text=True, env=env, cwd=cwd, check=True)
    return out.stdout


class WiringTests(unittest.TestCase):
    def test_commands_use_plugin_root_and_exist(self):
        hooks = json.loads((ROOT / "hooks" / "hooks.json").read_text())["hooks"]
        commands = [h["command"] for groups in hooks.values() for g in groups for h in g["hooks"]]
        self.assertTrue(commands)
        for c in commands:
            with self.subTest(command=c):
                m = re.fullmatch(r"bash \$\{CLAUDE_PLUGIN_ROOT\}/(hooks/scripts/[\w.-]+)( \w+)?", c)
                self.assertTrue(m, "hook command must run a script under ${CLAUDE_PLUGIN_ROOT}")
                self.assertTrue((ROOT / m.group(1)).is_file())


class InjectionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.config = Path(self.tmp.name) / "config"
        self.env = {**os.environ, "CLAUDE_CONFIG_DIR": str(self.config), "HOME": self.tmp.name}

    def tearDown(self):
        self.tmp.cleanup()

    def inject(self, mode, event="SessionStart", cwd=None):
        out = run("inject-voice.sh", {"hook_event_name": event, "cwd": cwd or self.tmp.name},
                  mode, env=self.env, cwd="/")
        return json.loads(out)["hookSpecificOutput"] if out.strip() else None

    def test_core_outputs_fit_and_render(self):
        for mode in ("conduct", "voice"):
            with self.subTest(mode=mode):
                out = self.inject(mode, event="SubagentStart")
                ctx = out["additionalContext"]
                print(f"\n{mode}: {len(ctx)} chars", end="")
                self.assertEqual(out["hookEventName"], "SubagentStart")
                self.assertLess(len(ctx), LIMIT)
                self.assertNotIn("${CLAUDE_PLUGIN_ROOT}", ctx)
        self.assertIn(str(ROOT / "skills/voice/scripts/check-tells.sh"), self.inject("voice")["additionalContext"])

    def test_personal_absent_by_default(self):
        self.assertIsNone(self.inject("personal"))

    def test_personal_default_dir(self):
        voice = self.config / "devline" / "voice"
        (voice / "contexts").mkdir(parents=True)
        (voice / "voice.md").write_text("Keep it short.\n")
        (voice / "contexts" / "pr.md").write_text("x\n")
        ctx = self.inject("personal")["additionalContext"]
        self.assertIn("Keep it short.", ctx)
        self.assertIn(str(voice / "contexts" / "pr.md"), ctx)
        self.assertIn("Never apply it to fiction or scientific writing", ctx)

    def test_personal_voice_dir_key_and_size_fallback(self):
        other = Path(self.tmp.name) / "elsewhere"
        other.mkdir()
        (other / "voice.md").write_text("word " * 4000)
        (self.config / "devline").mkdir(parents=True)
        (self.config / "devline" / "config.md").write_text("---\nvoice_dir: ~/elsewhere\n---\n# notes\n")
        ctx = self.inject("personal")["additionalContext"]
        self.assertIn(str(other), ctx)
        self.assertIn("too long to inject", ctx)
        self.assertLess(len(ctx), LIMIT)

    def test_repo_voice_dir_overrides_user(self):
        repo = Path(self.tmp.name) / "repo"
        (repo / ".claude").mkdir(parents=True)
        (repo / "voice").mkdir()
        (repo / "voice" / "voice.md").write_text("Repo layer.\n")
        (repo / ".claude" / "devline.md").write_text(f'---\nvoice_dir: "{repo / "voice"}"\n---\n')
        self.assertIn("Repo layer.", self.inject("personal", cwd=str(repo))["additionalContext"])


class ResolveTests(unittest.TestCase):
    """validate-bash.sh scans a script before it runs; a leading cd decides which file that is."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.a = Path(self.tmp.name) / "a"
        self.b = Path(self.tmp.name) / "b"
        for d, body in ((self.a, "echo hi"), (self.b, "docker run --privileged alpine sh")):
            d.mkdir()
            (d / "x.sh").write_text(f"#!/bin/bash\n{body}\n")

    def tearDown(self):
        self.tmp.cleanup()

    def check(self, command):
        return run("validate-bash.sh", {"tool_name": "Bash", "cwd": str(self.a),
                                        "permission_mode": "bypassPermissions",
                                        "tool_input": {"command": command}})

    def test_leading_cd_moves_resolution(self):
        self.assertEqual(self.check("bash x.sh"), "")
        self.assertIn('"ask"', self.check(f"cd {self.b} && bash x.sh"))
        self.assertIn('"ask"', self.check("cd ../b; bash x.sh"))
        self.assertEqual(self.check(f"cd {self.b} && bash {self.a}/x.sh"), "")

    def test_pipeline_can_remove_its_own_work(self):
        repo = Path(self.tmp.name) / "repo"
        for d in (repo / ".git", repo / ".devline" / "design" / "s1" / ".git",
                  Path(self.tmp.name) / "repo.worktrees" / "wt" / ".git"):
            d.mkdir(parents=True)
        whole = f"rm -rf {repo}"
        self.assertIn('"ask"', self.check(whole))  # a real repo still asks
        for cmd in (f"rm -rf {repo}/.devline/design/s1", f"rm -rf {self.tmp.name}/repo.worktrees/wt",
                    f"cd {repo} && rm -f *.png", f"rm -f {repo}/d-*.png",
                    f"python3 - <<'EOF'\nimport os\nos.system('x')  # rm {repo}\nEOF"):
            self.assertEqual(self.check(cmd), "", cmd)
        self.assertIn('"ask"', self.check(f"cd {repo} && rm -rf *"))  # bare * empties the repo

    def test_password_store_rule_needs_command_position(self):
        verb = "pa" + "ss"
        for cmd in (f'git commit -m "first {verb} at it"', f'echo "partial {verb} not done" >> notes.md'):
            self.assertEqual(self.check(cmd), "", cmd)
        for cmd in (f"{verb} show email/work", f"{verb} email/work", f"ls; sudo {verb} show email/work",
                    f"echo $({verb} email/work)"):
            payload = {"tool_name": "Bash", "cwd": str(self.a), "permission_mode": "bypassPermissions",
                       "tool_input": {"command": cmd}}
            out = subprocess.run(["bash", str(SCRIPTS / "validate-bash.sh")], input=json.dumps(payload),
                                 capture_output=True, text=True)
            self.assertEqual(out.returncode, 2, cmd)


if __name__ == "__main__":
    unittest.main()
