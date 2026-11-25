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
