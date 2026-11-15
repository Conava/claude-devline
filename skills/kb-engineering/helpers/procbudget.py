#!/usr/bin/env python3
# Usage: procbudget.py [--duration S] [--mem-max MB] [--growth-max MB] [--cpu-max PCT] [--vram-max MB] (--pid PID | -- CMD [ARGS...])
# SPDX-License-Identifier: MIT
"""Sample a process tree's memory (PSS), growth, CPU and VRAM and fail when a budget is breached. Linux, stdlib only.

Exit codes:
  0  all set budgets met
  1  a budget was breached, or the target died before the window ended
  2  usage error, PID missing at start, or not Linux
  3  no breach, but a budget that was set could not be measured
"""
import argparse
import json
import os
import re
import signal
import subprocess
import sys
import time

METRICS = ("mem_peak_mb", "mem_growth_mb", "cpu_pct", "vram_peak_mb")
BUDGET_FLAGS = {"mem_peak_mb": "mem_max", "mem_growth_mb": "growth_max", "cpu_pct": "cpu_max", "vram_peak_mb": "vram_max"}
UNITS = {"": 1, "B": 1, "KIB": 1024, "MIB": 1024**2, "GIB": 1024**3}


def proc_root():
    # PROCBUDGET_PROC lets tests point at a fake tree
    return os.environ.get("PROCBUDGET_PROC", "/proc")


def read(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:  # process vanished or not readable
        return None


def parse_stat(text):
    """Return (state, ppid, cpu_ticks) from /proc/PID/stat; comm may contain spaces and parens."""
    f = text.rpartition(")")[2].split()
    return f[0], int(f[1]), int(f[11]) + int(f[12])


def scan():
    """Map pid -> (state, ppid, ticks) for every process."""
    root, out = proc_root(), {}
    try:
        names = os.listdir(root)
    except OSError:
        return out
    for n in names:
        if n.isdigit():
            t = read(f"{root}/{n}/stat")
            if t:
                try:
                    out[int(n)] = parse_stat(t)
                except (ValueError, IndexError):
                    pass
    return out


def tree(root_pid, procs):
    """Live (non-zombie) pids of root_pid and its descendants."""
    kids = {}
    for pid, (_, ppid, _) in procs.items():
        kids.setdefault(ppid, []).append(pid)
    seen, todo = [], [root_pid]
    while todo:
        p = todo.pop()
        if p in procs and p not in seen:
            seen.append(p)
            todo.extend(kids.get(p, []))
    return [p for p in seen if procs[p][0] not in ("Z", "X")]


def mem_mb(pids):
    """Tree memory in MB and its source: 'pss' if every process had smaps_rollup, else 'rss'."""
    root, total_kb, source = proc_root(), 0, "pss"
    for p in pids:
        m = re.search(r"^Pss:\s+(\d+) kB", read(f"{root}/{p}/smaps_rollup") or "", re.M)
        if not m:
            m, source = re.search(r"^VmRSS:\s+(\d+) kB", read(f"{root}/{p}/status") or "", re.M), "rss"
        if m:
            total_kb += int(m.group(1))
    return total_kb / 1024, source


def _bytes(value):
    m = re.match(r"\s*(\d+)\s*([A-Za-z]*)", value)
    return int(m.group(1)) * UNITS.get(m.group(2).upper(), 1) if m else 0


def _fd_vram_bytes(keys):
    """Pick one VRAM figure per fd: drm-total-vram*, else drm-resident-vram*, else deprecated drm-memory-vram."""
    for prefix in ("drm-total-vram", "drm-resident-vram", "drm-memory-vram"):
        vals = [_bytes(v) for k, v in keys.items() if k.startswith(prefix)]
        if vals:
            return sum(vals)
    return 0


def drm_vram_mib(pids):
    """Sum VRAM over DRM fdinfo of pids, each drm-client-id once. None if no DRM client fd was seen."""
    root, clients = proc_root(), {}
    for p in pids:
        d = f"{root}/{p}/fdinfo"
        try:
            fds = os.listdir(d)
        except OSError:
            continue
        for fd in fds:
            keys = dict(l.split(":", 1) for l in (read(f"{d}/{fd}") or "").splitlines() if ":" in l)
            keys = {k.strip(): v.strip() for k, v in keys.items()}
            if "drm-client-id" in keys:
                ident = (keys.get("drm-pdev", ""), keys["drm-client-id"])
                clients[ident] = max(clients.get(ident, 0), _fd_vram_bytes(keys))
    return sum(clients.values()) / 1024**2 if clients else None


def nvidia_vram_mib(pids):
    """VRAM of pids per nvidia-smi, or None if it is missing, fails, or lists none of them."""
    try:
        r = subprocess.run(
            ["nvidia-smi", "--query-compute-apps=pid,used_memory", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if r.returncode:
        return None
    total, found = 0.0, False
    for line in r.stdout.splitlines():
        parts = [x.strip() for x in line.split(",")]
        if len(parts) == 2 and parts[0].isdigit() and parts[0] in map(str, pids):
            try:
                total, found = total + float(parts[1]), True
            except ValueError:
                pass
    return total if found else None


def vram_mib(pids):
    v = drm_vram_mib(pids)
    return v if v is not None else nvidia_vram_mib(pids)


def stop_group(pgid):
    """SIGTERM the group, wait up to 3 s, then SIGKILL."""
    try:
        os.killpg(pgid, signal.SIGTERM)
    except ProcessLookupError:
        return
    end = time.time() + 3
    while time.time() < end:
        try:
            os.killpg(pgid, 0)
        except ProcessLookupError:
            return
        time.sleep(0.05)
    try:
        os.killpg(pgid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def sample_loop(root_pid, popen, a):
    """Return (samples, died_message). A sample is (t, mem_mb, source, cumulative_cpu_ticks, vram_mib)."""
    start, samples, ticks_seen, died = time.monotonic(), [], {}, None
    sources = set()
    while True:
        t = time.monotonic() - start
        if popen is not None and popen.poll() is not None:
            died = f"target exited with code {popen.returncode} after {t:.1f}s"
            break
        procs = scan()
        pids = tree(root_pid, procs)
        if not pids:
            died = f"target exited after {t:.1f}s"
            break
        for p in pids:  # keep ticks of processes that exit later
            ticks_seen[p] = max(ticks_seen.get(p, 0), procs[p][2])
        m, src = mem_mb(pids)
        sources.add(src)
        samples.append((t, m, sum(ticks_seen.values()), vram_mib(pids)))
        if t + a.interval > a.duration:
            break
        time.sleep(a.interval)
    return samples, died, ("rss" if "rss" in sources else "pss")


def compute(samples, source, a):
    post = [s for s in samples if s[0] >= a.warmup]
    clk = os.sysconf("SC_CLK_TCK")
    vals = {
        "mem_peak_mb": max((s[1] for s in samples), default=None),
        "mem_growth_mb": post[-1][1] - post[0][1] if len(post) >= 2 else None,
        "cpu_pct": None,
        "vram_peak_mb": max((s[3] for s in samples if s[3] is not None), default=None),
    }
    if len(post) >= 2 and post[-1][0] > post[0][0]:
        vals["cpu_pct"] = (post[-1][2] - post[0][2]) / clk / (post[-1][0] - post[0][0]) * 100
    return vals


def verdicts(vals, a):
    out = {}
    for name in METRICS:
        budget, v = getattr(a, BUDGET_FLAGS[name]), vals[name]
        status = "unmeasured" if v is None else "FAIL" if budget is not None and v > budget else "ok"
        out[name] = {"value": v, "budget": budget, "status": status}
    return out


def parse_args(argv):
    p = argparse.ArgumentParser(
        prog="procbudget.py",
        description="Sample a process tree (target and live descendants) and check resource budgets. "
        "With -- CMD the command runs in a new session and its process group is stopped afterwards.",
        epilog="exit codes: 0 budgets met; 1 budget breached or target died early; "
        "2 usage error, PID missing, or not Linux; 3 no breach but a set budget was unmeasured",
    )
    p.add_argument("--duration", type=float, default=10, help="sampling window in seconds (default 10)")
    p.add_argument("--interval", type=float, default=0.5, help="seconds between samples (default 0.5)")
    p.add_argument("--warmup", type=float, default=0, help="seconds ignored for growth and CPU (default 0)")
    p.add_argument("--mem-max", type=float, metavar="MB", help="peak tree PSS (RSS fallback)")
    p.add_argument("--growth-max", type=float, metavar="MB", help="last sample minus first post-warmup sample")
    p.add_argument("--cpu-max", type=float, metavar="PCT", help="tree CPU as percent of one core")
    p.add_argument("--vram-max", type=float, metavar="MB", help="peak tree VRAM (DRM fdinfo, else nvidia-smi)")
    p.add_argument("--json", metavar="FILE", help="also write metrics and verdicts as JSON")
    p.add_argument("--pid", type=int, help="sample an existing process instead of starting CMD")
    cmd = []
    if "--" in argv:
        i = argv.index("--")
        argv, cmd = argv[:i], argv[i + 1:]
    a = p.parse_args(argv)
    a.cmd = cmd
    if bool(a.pid) == bool(cmd):
        p.error("give exactly one of --pid PID or -- CMD [ARGS...]")
    if a.duration <= 0 or a.interval <= 0 or a.warmup < 0 or a.interval > a.duration or a.warmup >= a.duration:
        p.error("need duration > 0, 0 < interval <= duration, 0 <= warmup < duration")
    for flag in BUDGET_FLAGS.values():
        if getattr(a, flag) is not None and getattr(a, flag) <= 0:
            p.error(f"--{flag.replace('_', '-')} must be positive")
    return a


def main(argv):
    a = parse_args(argv)
    if not sys.platform.startswith("linux"):
        print("procbudget: Linux only", file=sys.stderr)
        return 2
    popen = None
    if a.pid:
        if a.pid not in scan():
            print(f"procbudget: no such process {a.pid}", file=sys.stderr)
            return 2
        root_pid = a.pid
    else:
        try:
            popen = subprocess.Popen(a.cmd, start_new_session=True)
        except OSError as e:
            print(f"procbudget: cannot start {a.cmd[0]}: {e}", file=sys.stderr)
            return 2
        root_pid = popen.pid
    try:
        samples, died, source = sample_loop(root_pid, popen, a)
    finally:
        if popen is not None:
            stop_group(popen.pid)
            popen.wait()
    res = verdicts(compute(samples, source, a), a)
    for name, r in res.items():
        budget = f" budget {r['budget']:g}" if r["budget"] is not None else ""
        value = "n/a" if r["value"] is None else f"{r['value']:.1f}"
        print(f"{name} {value}{budget} {r['status']}")
        if name == "mem_peak_mb":
            print(f"mem_source {source}")
    if died:
        print(f"procbudget: {died}")
    breached = died or any(r["status"] == "FAIL" for r in res.values())
    unmeasured = any(r["status"] == "unmeasured" and r["budget"] is not None for r in res.values())
    code = 1 if breached else 3 if unmeasured else 0
    if a.json:
        doc = {"metrics": {**res, "mem_source": source}, "target_died": died, "exit_code": code}
        with open(a.json, "w") as f:
            json.dump(doc, f, indent=2)
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
