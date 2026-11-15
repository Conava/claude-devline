"""Tests for helpers/procbudget.py: real child processes, plus a fake /proc tree for fdinfo parsing."""
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parent.parent / "helpers" / "procbudget.py"
sys.path.insert(0, str(HELPER.parent))

PY = sys.executable
FAST = ["--duration", "1", "--interval", "0.1"]

# 60 MB held by the interpreter (bytes * n touches every page, so it is resident)
HOLD = "import time; x = b'x' * ({mb} * 1024 * 1024); time.sleep(30)"
SLEEP = "import time; time.sleep(30)"


def run(*args, timeout=60):
    return subprocess.run([PY, "-I", str(HELPER), *args], capture_output=True, text=True, timeout=timeout)


def child(code):
    return ["--", PY, "-c", code]


def alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    try:
        return Path(f"/proc/{pid}/stat").read_text().rpartition(")")[2].split()[0] != "Z"
    except OSError:
        return False


class Budgets(unittest.TestCase):
    def test_memory_budget(self):
        r = run(*FAST, "--mem-max", "20", *child(HOLD.format(mb=80)))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("FAIL", r.stdout)
        r = run(*FAST, "--mem-max", "500", *child(HOLD.format(mb=80)))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_descendants_count(self):
        code = (
            "import subprocess, sys, time\n"
            f"subprocess.Popen([sys.executable, '-c', {HOLD.format(mb=60)!r}])\n"
            "time.sleep(30)"
        )
        r = run(*FAST, "--mem-max", "30", *child(code))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)

    def test_growth(self):
        grow = "import time\nl = []\nfor _ in range(40):\n l.append(b'x' * 5 * 1024 * 1024)\n time.sleep(0.1)\ntime.sleep(30)"
        r = run(*FAST, "--warmup", "0.5", "--growth-max", "5", *child(grow))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        steady = HOLD.format(mb=20)
        r = run(*FAST, "--warmup", "0.5", "--growth-max", "5", *child(steady))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_cpu(self):
        r = run(*FAST, "--cpu-max", "50", *child("while True: pass"))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        r = run(*FAST, "--cpu-max", "5", *child(SLEEP))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_early_exit_names_code(self):
        r = run("--mem-max", "500", *child("import time, sys; time.sleep(0.3); sys.exit(7)"))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("7", r.stdout + r.stderr)

    def test_unmeasurable_vram_exits_3(self):
        r = run(*FAST, "--vram-max", "100", *child(SLEEP))
        self.assertEqual(r.returncode, 3, r.stdout + r.stderr)
        self.assertIn("unmeasured", r.stdout)

    def test_breach_beats_unmeasured(self):
        r = run(*FAST, "--mem-max", "1", "--vram-max", "100", *child(SLEEP))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)


class Usage(unittest.TestCase):
    def test_usage_errors_exit_2(self):
        for args in (
            [*FAST, "--mem-max", "0", *child(SLEEP)],
            ["--duration", "1", "--interval", "2", *child(SLEEP)],
            [*FAST],
            [*FAST, "--pid", "999999999"],
            [*FAST, "--", "/nonexistent/definitely-not-here"],
        ):
            r = run(*args)
            self.assertEqual(r.returncode, 2, (args, r.stdout, r.stderr))


class Lifecycle(unittest.TestCase):
    def test_no_process_survives(self):
        with tempfile.TemporaryDirectory() as d:
            pf = Path(d, "pids")
            sh = f"sleep 300 & echo $$ $! > {pf}; sleep 300"
            r = run("--duration", "1", "--interval", "0.2", "--", "sh", "-c", sh)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            pids = [int(p) for p in pf.read_text().split()]
            self.assertEqual(len(pids), 2)
            time.sleep(0.2)
            self.assertEqual([p for p in pids if alive(p)], [])

    def test_sigterm_to_procbudget_stops_target(self):
        with tempfile.TemporaryDirectory() as d:
            pf = Path(d, "pid")
            p = subprocess.Popen([PY, "-I", str(HELPER), "--duration", "60", "--", "sh", "-c", f"echo $$ > {pf}; exec sleep 300"])
            try:
                end = time.time() + 10
                while not (pf.exists() and pf.read_text().strip()) and time.time() < end:
                    time.sleep(0.05)
                pid = int(pf.read_text())
                p.terminate()
                p.wait(timeout=10)
                time.sleep(0.2)
                self.assertFalse(alive(pid), "target survived SIGTERM to procbudget")
            finally:
                p.kill()
                p.wait()
                if pf.exists() and alive(int(pf.read_text())):
                    os.kill(int(pf.read_text()), 9)

    def _double_signal_stops_target(self, sig):
        with tempfile.TemporaryDirectory() as d:
            pf = Path(d, "pid")
            script = f"echo $$ > {pf}; trap '' TERM; while :; do sleep 0.1; done"
            p = subprocess.Popen([PY, "-I", str(HELPER), "--duration", "60", "--", "sh", "-c", script])
            try:
                end = time.time() + 10
                while not (pf.exists() and pf.read_text().strip()) and time.time() < end:
                    time.sleep(0.05)
                pid = int(pf.read_text())
                p.send_signal(sig)
                time.sleep(0.5)
                p.send_signal(sig)
                p.wait(timeout=15)
                time.sleep(0.2)
                self.assertFalse(alive(pid), f"target leaked after double {sig.name}")
            finally:
                p.kill()
                p.wait()
                if pf.exists() and alive(int(pf.read_text())):
                    os.kill(int(pf.read_text()), 9)

    def test_double_sigterm_to_procbudget_stops_target(self):
        self._double_signal_stops_target(signal.SIGTERM)

    def test_double_sigint_to_procbudget_stops_target(self):
        self._double_signal_stops_target(signal.SIGINT)

    def test_json_has_all_keys(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d, "r.json")
            r = run(*FAST, "--mem-max", "500", "--json", str(out), *child(SLEEP))
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            data = json.loads(out.read_text())
            for key in ("mem_peak_mb", "mem_source", "mem_growth_mb", "cpu_pct", "vram_peak_mb"):
                self.assertIn(key, data["metrics"])
            self.assertEqual(data["metrics"]["mem_peak_mb"]["status"], "ok")
            self.assertEqual(data["metrics"]["mem_peak_mb"]["budget"], 500.0)
            self.assertEqual(data["exit_code"], 0)

    def test_pid_mode_leaves_target_running(self):
        p = subprocess.Popen([PY, "-c", SLEEP])
        try:
            r = run(*FAST, "--mem-max", "500", "--pid", str(p.pid))
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            self.assertIsNone(p.poll())
        finally:
            p.kill()
            p.wait()


class FdinfoParsing(unittest.TestCase):
    def test_shared_client_counted_once_and_total_preferred(self):
        import procbudget

        def fd(root, n, text):
            Path(root, "100", "fdinfo").mkdir(parents=True, exist_ok=True)
            Path(root, "100", "fdinfo", str(n)).write_text(text)

        with tempfile.TemporaryDirectory() as root:
            # two fds of client 7 (dup'd), one fd of client 9
            fd(root, 3, "drm-client-id:\t7\ndrm-total-vram0:\t2048 KiB\ndrm-resident-vram0:\t1 KiB\ndrm-memory-vram:\t1 KiB\n")
            fd(root, 4, "drm-client-id:\t7\ndrm-total-vram0:\t2048 KiB\n")
            fd(root, 5, "drm-client-id:\t9\ndrm-total-vram0:\t3 MiB\ndrm-total-gtt:\t99 MiB\n")
            fd(root, 6, "pos:\t0\nflags:\t02\n")  # not a DRM fd
            # deprecated key only, third client
            fd(root, 7, "drm-client-id:\t11\ndrm-memory-vram:\t1024 KiB\n")
            os.environ["PROCBUDGET_PROC"] = root
            try:
                self.assertAlmostEqual(procbudget.drm_vram_mib([100]), 2 + 3 + 1)
                self.assertIsNone(procbudget.drm_vram_mib([4242]))
            finally:
                del os.environ["PROCBUDGET_PROC"]


if __name__ == "__main__":
    unittest.main()
