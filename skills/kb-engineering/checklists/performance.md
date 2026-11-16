# Performance checklist

Selected for hot paths, rendering or animation, data volume, startup, long-running processes and new dependencies: anything where time, CPU, memory or GPU memory can regress.

Item format: rule, why, then `Check:` for the concrete step. The numbers here are starting points; the project owns its budgets.

## Method

- **Measure first, fix the measured bottleneck, and start from a profile.** Guessing optimizes the wrong thing and adds complexity for nothing; models handed a line-level time and memory profile optimize far better than models asked to "make it faster" (EffiLearner, NeurIPS 2024). Check: a profile, flame graph or benchmark that shows where the time or memory goes is in the evidence before the change (`py-spy record`, `perf record -g`, async-profiler, `go tool pprof`, the DevTools performance panel).
- **Keep or revert on numbers, and log every attempt.** A tried and abandoned idea gets retried by the next agent unless it is recorded. Check: before and after figures sit in the report; a change with no measurable gain is reverted; the full test suite ran green after each kept optimisation, and one that changes any test result is reverted, not "fixed" in the test (no optimisation method in ECCO, EMNLP 2024, gained speed without some loss of correctness).
- **Correct is not efficient: run new loops at realistic input sizes.** Generated code that passes its tests is often several times slower than a reference solution, with much worse worst cases (EffiBench, NeurIPS 2024), and tiny fixtures hide it. Check: a test or benchmark runs each new loop over a collection at production-like size (or 10x the fixture) with a time bound; nested loops over the same collection, linear lookups inside loops (`list.contains`, `indexOf`, `in list`) and per-item queries or execs are replaced by a map, a set or one batched call, or justified.
- **Compare with an interleaved A/B, not two sequential runs.** Machine load drifts, and the second run often wins or loses on that alone. Check: alternate base and change (ABAB), at least five runs each, record the load average (`cat /proc/loadavg`) with each run, keep only differences beyond the spread. This also applies to a claim that a slowdown predates the change: show it with the A/B, not from memory.
- **Run timing-sensitive checks alone.** Parallel jobs on the same machine make frame and latency numbers meaningless. Check: no other build, test or agent run is active; the load average is low when you start.
- **Warm up before measuring.** JIT, caches, connection pools and lazy initialization dominate the first iterations. Check: discard a warm-up phase; report steady state and, separately, cold start.
- **Report percentiles, not means.** A mean hides the slow tail users feel. Check: p50, p95 and p99 (and the max for frame gaps); the sample count is large enough that p99 means something.
- **Use the USE method for "why is it slow".** For each resource (CPU, memory, disk, network, GPU, locks, pools) check utilization, saturation and errors before theorizing. Check: the report names the saturated resource.
- **Benchmark what users run.** A micro-benchmark of a function tells little about the program. Check: the measurement drives the real entry point with realistic data volume; micro-benchmarks only back a measured hot spot; the harness loads the same theme, plugins and platform integration the user has (an icon lookup can cost microseconds in a bare harness and milliseconds with the real platform theme), and input latency is measured with real input events.

## Budgets

A budget is a number that fails a build. Record it from a measured baseline with headroom, then enforce it where the table says. Starting values are common defaults, not rules; the project owns the number, and changing one is a deliberate edit with a reason.

| Metric | How to measure | Starting value | Enforce |
|---|---|---|---|
| Largest Contentful Paint (web) | Lighthouse CI, Chrome DevTools MCP trace | 2.5 s or less at p75 | Lighthouse CI assertion |
| Interaction to Next Paint (web) | Playwright with `web-vitals`, DevTools trace | 200 ms or less at p75 | Lighthouse CI or e2e assertion |
| Cumulative Layout Shift (web) | Lighthouse CI | 0.1 or less | Lighthouse CI assertion |
| JS per route | `size-limit` on the built bundle | the baseline plus about 10 percent | CI step that fails the PR |
| Service latency | `oha`, `hey`, `wrk`, `k6` against the built binary | p95 and p99 from the baseline, under the caller's timeout | load step in the verify recipe |
| Frame gap during motion (desktop, animation) | frame-presentation timestamps while scrolling or animating | 80 ms largest gap (a starting value from one project; 60 fps needs 16.7 ms per frame) | scenario with a hard limit |
| Action to visible | timestamp from input to the changed pixels with a delayed fake upstream | 400 ms with an upstream delayed by 800 ms (optimistic update) | scenario with a hard limit |
| Peak memory | tree PSS sampled over a scenario | baseline plus headroom | resource sampler budget |
| Memory growth | PSS after N repetitions of one action, minus PSS after the first | near zero; allow only measured noise | resource sampler budget |
| Idle CPU | CPU percent over a window with the app idle or hidden | well under 1 percent of a core | resource sampler budget |
| VRAM | DRM fdinfo or `nvidia-smi` for the process tree | baseline plus headroom | resource sampler budget |
| Startup time | process start to first usable frame or ready endpoint | baseline plus headroom | startup scenario |

- **Take budgets from a measured baseline, not from this table.** A number from a different app is either never reached or never tight. Check: the project's budget file has the measured value, the date and the machine class.
- **Make budget breaches fail the run.** A printed number nobody reads is not a budget. Check: the command exits non-zero on breach; CI and the local fast path call the same command.
- **Do not widen a budget to make a change pass.** A silently raised limit is a regression with paperwork. Check: the diff shows budget files; any increase has a stated reason and measured figures.

## CPU and idle

- **A new feature costs nothing for users who never use it.** In a long-running process, a service that creates folders, watchers, timers or scans at startup taxes everyone. Check: start with the feature unused or its optional dependency absent; no new threads, timers, watchers, processes or UI appear (`ls /proc/$PID/task | wc -l`, `ls -l /proc/$PID/fd | wc -l` against the base build) and idle CPU is unchanged.
- **Idle means near zero CPU.** Polling loops and busy timers burn battery and starve other processes. Check: sample CPU for 10 s with the app idle and hidden; the figure is under the budget.
- **Prefer events over polling.** File watchers, sockets, signals and condition variables replace sleep loops. Check: grep for `sleep(`, `setInterval`, `time.After` in loops, `QTimer` with short intervals, and justify each.
- **Stop timers and animations when invisible; hidden is not stopped.** Hidden windows and background tabs should not render, but an item's own visibility often stays true when its window hides, list views keep their delegates, and global bindings outlive their window. Check: minimize or hide the window, confirm CPU and GPU engine time drop (`drm-engine-*` stops growing); gate the model or binding, not only the visibility; on the web, check `visibilitychange` and `IntersectionObserver` handling.
- **A probe never starts anything.** Feature detection that activates a D-Bus service, launches a display server (running an X11 tool brings up Xwayland) or spins up a daemon costs more than the feature. Check: D-Bus calls pass the no-autostart flag (`busctl --auto-start=no`, `G_DBUS_CALL_FLAGS_NO_AUTO_START`) unless starting the service is the point; signal subscriptions filter on your own object path; `ps` before and after a probe shows no new processes.
- **Touch a device that can sleep only when the caller names it; reading counts as touching.** Polling a sensor or status file on a discrete GPU or a disk marks it busy and keeps it awake. Check: omitted means none in every module and indirect reader; opening a page is not naming a device; with the device idle, `cat /sys/bus/pci/devices/<addr>/power/runtime_status` stays `suspended` while the app runs; when one reader is fixed, grep every other reader of the same device.
- **Pick a metric's source by cost first.** Summing a per-process scan for a system-wide number, or one exec per device, costs far more than one system counter or one call with all ids. Check: system-wide numbers come from system-wide counters (`/proc/stat`, `/proc/meminfo`); external commands take the whole id list in one call.
- **A watcher or model without its target is not idle.** A folder model with no folder set may list the working directory; a watcher on a missing path may poll. Check: create watchers and models only once their target exists, and destroy them when it goes.
- **Bound background work.** Unlimited workers and unbounded batches saturate the machine. Check: concurrency has a cap; work yields; a spike does not queue forever (see reliability.md for queues).
- **Do not do work for nothing.** Recomputing unchanged derived data on every tick or event wastes CPU. Check: updates are driven by change, with memoization or invalidation, not by a timer.

## RAM and leaks

- **Measure PSS, not RSS, for multi-process apps.** RSS counts shared pages once per process, so a browser or worker tree looks far larger than it is. Check: sum `Pss` from `/proc/PID/smaps_rollup` over the tree; fall back to RSS only where smaps is unreadable and say so.
- **Check growth after N repetitions of an action.** A leak shows as memory that does not return after open/close, navigate/back or load/unload repeated 10 to 50 times. Check: baseline, repeat, return to the start state, compare; a steady rise is a leak.
- **Bound every cache and give it eviction.** A cache without a limit is a leak with a good name, and a cache that replaced a live binding stops following the source. Check: each cache has a max size or TTL and a test or note on what happens when full; it is emptied when the source releases the data, and keyed or reset on every input the original lookup read (theme, settings, locale).
- **Remove listeners, timers and subscriptions on teardown.** Retained callbacks keep whole object graphs alive. Check: each `add`/`subscribe`/`connect` has its matching removal on the teardown path.
- **Do not hold large data longer than needed.** Streaming beats loading whole files, result sets or images. Check: no unbounded `readAll`, `fetchall`, `collect` on input of unknown size.
- **Use the runtime's own leak tools; do not read raw dumps.**
  - Browser JS: memlab scenarios, or DevTools MCP heap snapshots compared before and after (use the tool's diff, never read the raw snapshot file).
  - JVM: JDK Flight Recorder with `jdk.OldObjectSample`, heap dump on OOM, `jcmd GC.heap_dump`, then a heap analyzer.
  - Go: `pprof` heap profiles (`go tool pprof -base`), `goleak` in tests for goroutine leaks.
  - Native: heaptrack, valgrind massif, LeakSanitizer (`-fsanitize=address`).
  - Rust async: `tokio-console` for stuck or leaked tasks; sanitizers on nightly.
  - Python: `tracemalloc` snapshots compared before and after.
  Check: the report names the tool and the retained object type or allocation site.

## VRAM

- **Measure VRAM per process on Linux through DRM fdinfo.** Each open DRM file descriptor shows its memory in `/proc/PID/fdinfo/FD`: `drm-total-<region>` is all buffers the client requested, `drm-resident-<region>` is what is actually backed, and `drm-shared-<region>` marks buffers shared with another file. The region name is driver specific (`vram`, `gtt`, `system`; `memory` is reserved for system memory). Values may carry a `KiB` or `MiB` suffix and default to bytes. Check: parse the keys, honor the unit, prefer `drm-total-vram*`, then `drm-resident-vram*`.
- **Count each DRM client once.** The same client id can appear on several descriptors (duplicated or inherited fds), and summing all of them overcounts. Check: dedupe on `drm-client-id` (together with `drm-pdev` where ids are per device).
- **Treat `drm-memory-<region>` as deprecated.** The kernel docs say only amdgpu prints it, as an alias for `drm-resident-<region>`. Check: do not rely on it where `drm-total` or `drm-resident` exists.
- **Use the right tool for the vendor.** `nvtop` shows per-process GPU memory and engine use across AMD, Intel and NVIDIA interactively; for scripted checks on NVIDIA use `nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits` (it lists compute processes; graphics-only processes may be missing, so state "unmeasured" rather than zero). Check: a missing reading is reported as unmeasured, never as 0.
- **Release textures and offscreen buffers when hidden.** Layers, effects and render targets kept for an invisible window hold VRAM for nothing. Check: hide the window or leave the view, sample VRAM, expect it to drop toward the baseline.
- **Pack small images into atlases and size textures to what is drawn.** Many small textures cost draw calls and memory, and oversize sources waste both. Check: image sources are scaled to display size times device pixel ratio; the toolkit's atlas diagnostics (Qt `QSG_INFO`, `QSG_RENDER_TIMING`) show batching.
- **Cap device pixel ratio and dispose WebGL objects.** A 3x canvas costs nine times the pixels, and undisposed textures, buffers and contexts never come back. Check: the canvas ratio is clamped (commonly 2); `dispose()` or `deleteTexture` runs on teardown; the VRAM or the `WebGL` memory figure returns after repeated navigation.

## Backend hot paths

- **Eliminate N+1 queries.** One query per row turns a page into hundreds of round trips. Check: log or count statements per request in a test with a list of 50 items; the count does not grow with the list.
- **Size connection pools deliberately.** Small pools usually beat large ones; a start is about cores times two plus effective disk spindles for the database, and instances times pool size must stay under the database's limit. Check: the pool size and the arithmetic are written in config or the PR; a pool-exhaustion log or leak threshold is enabled.
- **Run EXPLAIN before adding an index.** An index the planner ignores only slows writes. Check: attach the plan before and after for the query that motivated it, on realistic data volume.
- **Paginate every list endpoint with a stable order and a maximum page size.** Unbounded fetches are the common slow-and-out-of-memory path. Check: a request without a limit still returns a bounded page.
- **Include every varying input in a cache key.** A key missing the user, locale or filter serves the wrong data (and is a security bug). Check: list the inputs that change the response, compare with the key.
- **Protect against cache stampedes.** A popular key that expires sends every caller to the database at once. Check: single-flight or request coalescing, soft TTL with refresh, or jittered expiry exists for hot keys.
- **Keep slow work off the request path.** Reports, emails and fan-out belong in a queue with a bound. Check: the handler's p95 under load stays within budget with the slow dependency delayed.
- **Split latency into p50, p95 and p99 and report the degraded mode.** A fast median hides a stalled tail. Check: the load test output has the percentiles and, with a delayed upstream, the degraded response time.

## Frontend

- **Split bundles by route and load heavy code on demand.** One big bundle delays every page. Check: `size-limit` or the bundler's analyzer shows per-route size; a new dependency's cost is stated.
- **Give images dimensions and prioritize the main one.** Missing `width`/`height` causes layout shift, and a lazy-loaded hero image delays LCP. Check: `<img>` has dimensions; the LCP image has `fetchpriority="high"` and is not lazy; others are `loading="lazy"`.
- **Find and break up long tasks.** Main-thread tasks over 50 ms delay input and hurt INP. Check: a performance trace lists long tasks during the interaction; heavy work moves to a worker or is chunked.
- **Mind fonts and third-party scripts.** They block rendering and add weight. Check: fonts use `font-display` and are subset; third-party scripts are deferred.
- **Browser specifics live in web.md.** Check: for CWV, heap growth after repeated navigation and browser verification, use web.md and do not duplicate it here.

## Verify it

Linux one-liners, in a sandbox and against a process you started yourself (`$!`, never `pgrep -f`). Replace `$PID`; descendants are found by parent pid.

```bash
# Tree PSS in MiB (needs /proc/PID/smaps_rollup access; same user)
ptree() { local p; for p in "$@"; do echo "$p"; ptree $(pgrep -P "$p"); done; }
for p in $(ptree "$PID"); do awk '/^Pss:/ {s+=$2} END {print s+0}' "/proc/$p/smaps_rollup" 2>/dev/null; done | awk '{s+=$1} END {printf "PSS %.1f MiB\n", s/1024}'

# CPU percent of one core over 10 s (utime+stime are fields 14 and 15, in clock ticks)
t() { awk '{print $14+$15}' "/proc/$1/stat"; }
a=$(t "$PID"); sleep 10; b=$(t "$PID"); echo "CPU $(( (b-a) * 100 / (10 * $(getconf CLK_TCK)) )) %"

# VRAM through DRM fdinfo, each client once (KiB; read the units the driver printed)
for f in /proc/$PID/fdinfo/*; do awk '/^drm-client-id:/{id=$2} /^drm-total-vram/{print id, $2, $3}' "$f" 2>/dev/null; done | sort -u -k1,1 | awk '{s+=$2} END {print "VRAM", s, "KiB (check the unit column)"}'
```

These are starting points: the single-process `tree` helper above ignores processes started after the call, and the VRAM line assumes the `vram` region name and a KiB unit. For repeatable results use the opt-in helper, which handles units, client ids, the `drm-resident` fallback, descendants and `nvidia-smi`:

```bash
python3 -I "${CLAUDE_SKILL_DIR}/helpers/procbudget.py" --duration 30 --warmup 5 --mem-max 400 --growth-max 20 --cpu-max 2 --vram-max 300 -- ./build/app --headless
```

Exit 0 means every budget held, 1 a breach or a dead target, 2 a usage error, 3 a set budget that could not be measured. Copy it into a project only when the user agrees.

Benchmarks and budgets by toolchain:

- Go: `go test -bench . -count 10 -run '^$' ./pkg > old.txt`, change, repeat into `new.txt`, `benchstat old.txt new.txt`; heap profile with `go test -memprofile mem.out`.
- JVM: JMH for micro-benchmarks only (`./gradlew jmh` with the JMH plugin); for a running service use JFR: `java -XX:StartFlightRecording=filename=rec.jfr,settings=profile ...` and `jfr print --events jdk.GCPhasePause rec.jfr`; async-profiler for CPU and allocation flame graphs.
- CLIs: `hyperfine --warmup 3 --runs 20 './old' './new'`; hyperfine alternates nothing by itself, so run the pair twice in swapped order and record `cat /proc/loadavg`.
- Services: `oha -z 30s -c 50 http://127.0.0.1:$PORT/path` (or `hey`, `wrk`, `k6`), with the upstream delayed by its control file or toxiproxy.
- Bundles: `npx size-limit` with this in `package.json`:

```json
"size-limit": [{ "path": "dist/assets/index-*.js", "limit": "170 kB" }]
```

- Web vitals: `npx @lhci/cli autorun` with `lighthouserc.json`:

```json
{ "ci": { "assert": { "assertions": {
  "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
  "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
  "total-blocking-time": ["error", { "maxNumericValue": 200 }]
} } } }
```

  INP needs real interaction, so measure it in a Playwright scenario with the `web-vitals` library; Lighthouse reports Total Blocking Time as its lab proxy.
- Query plans: `EXPLAIN (ANALYZE, BUFFERS) <query>` on PostgreSQL, `EXPLAIN ANALYZE` on MySQL 8, `EXPLAIN QUERY PLAN` on SQLite.

## Sources

- addyosmani/agent-skills, performance-optimization and its performance checklist: MIT, adapted.
- ChromeDevTools/chrome-devtools-mcp, memory-leak-debugging skill and performance traces: Apache-2.0, adapted.
- Linux kernel documentation, "DRM client usage stats": GPL documentation, facts only (key names, units, client-id rule).
- HikariCP wiki, "About Pool Sizing": Apache-2.0, adapted.
- GoogleChrome/lighthouse-ci and ai/size-limit: Apache-2.0 and MIT, usage adapted.
- Core Web Vitals thresholds (web.dev): vendor documentation, numbers only.
- meta/memlab: MIT, usage adapted.
- Qt Quick performance considerations and scene graph documentation: GFDL, paraphrased.
- Brendan Gregg, the USE method: author copyright, paraphrased, facts only.
- dgryski/go-perfbook (measurement and benchstat): CC-BY-SA, paraphrased.
- thedaviddias/Front-End-Performance-Checklist: MIT, adapted.
- affaan-m/ECC, benchmark-methodology and latency-critical-systems: MIT, adapted.
- Syllo/nvtop, KDE/heaptrack, async-profiler, JDK Flight Recorder: tools, usage described only.
- Scientific findings on LLM-written code, facts only: Huang et al., EffiBench (NeurIPS 2024 D&B); Waghjale et al., ECCO (EMNLP 2024); Huang et al., EffiLearner (NeurIPS 2024).
- Lessons from real agent mistakes in the maintainer's own long-running desktop projects (cost for non-users, probes, sleeping devices): original text under the project licence.
