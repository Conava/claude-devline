# Desktop apps checklist

Selected for desktop GUI apps: Qt/QML, GTK, Electron, Tauri, Flutter desktop. Desktop is where an agent most easily damages the user's session (restarts the shell, writes real config, plays real audio) and where offscreen test modes hide real rendering and input problems. The approach here is a real run in a nested compositor that is invisible on the user's desktop, with measured frames, idle CPU and VRAM. Electron and Tauri security flags are in security.md's desktop group and not repeated here. Linux is assumed; adapt the session pieces on other platforms.

## Never the live session

- **Do not restart, reload or signal the user's shell, compositor, panel or session services.** The user is working in them. Check: grep scripts for `systemctl --user restart`, `kquitapp`, `killall`, `pkill`, `swaymsg reload`; none runs against the real session.
- **Do not install, uninstall or enable anything.** Installs change the user's machine and cannot be undone by a test run. Check: no `pacman`, `apt`, `dnf`, `flatpak install`, `pip install --user`, `make install` in the run path; name missing tools for the user instead.
- **Never read or write the real config, data, cache or keyring.** A test that migrates real settings or overwrites a library destroys user data. Check: the run sets private `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`; after the run, the real dirs are unchanged.
- **Do not use the app's own quit command or a running instance.** A second launch may hand off to the user's running instance (single instance) and a quit command may close their window. Check: the sandbox has its own runtime dir and bus so the instance lookup cannot find the user's; the app is stopped by PID.
- **Take PIDs only from `$!` of processes you started.** Name matching hits the user's processes. Check: no `pgrep -f`, `pkill`, `killall` on app or compositor names.

## Sandboxed GUI runs

- **Run under a nested or headless compositor.** The window then never appears on the user's screen, and real shaders, masks and input timing run. Options: `weston --backend=headless`, `sway` with `WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1`, `kwin_wayland --virtual`, `cage` (kiosk) with `WLR_BACKENDS=headless`, `Xvfb` or `xvfb-run` for X11 apps. Check: the script names which one it uses and sets a size explicitly (for example 1280x800).
- **Give the run a private runtime dir and session bus.** Sockets and the bus are how an app finds other instances and services. Check: `XDG_RUNTIME_DIR` is a fresh `0700` directory with a short path (a Unix socket path is limited to about 100 characters), and the app runs under `dbus-run-session`.
- **Provide a fresh keyring when the app stores secrets.** Otherwise the app prompts, fails, or reaches the user's real keyring. Check: a throwaway keyring daemon on the private bus, unlocked with a throwaway password piped on stdin (`gnome-keyring-daemon --unlock` or the project's equivalent), and secret-handling paths are exercised.
- **Silence audio without touching the user's devices.** Real speakers mid-test are a bug report. Check: a null sink or a private PipeWire/PulseAudio instance in the private runtime dir, or the app's own dummy audio backend (`SDL_AUDIODRIVER=dummy`); never the user's default sink.
- **Generate fixtures, never copy the user's library.** User media and documents are private and change. Check: fixtures are generated under the temp dir by the harness (small files, plus an edge-case set: empty, huge names, odd encodings, right-to-left names).
- **Stop in order: app first, then compositor, then the bus.** A nested compositor can spin at full CPU when its host disappears, and an app can hang waiting for it. Check: `trap` cleanup sends SIGTERM to the recorded PIDs, waits a grace period, then SIGKILL, in that order; after the run no recorded PID is alive.
- **Use a GPU-backed renderer when the run measures frames or VRAM.** Software renderers (pixman, llvmpipe) give different frame times and no VRAM. Check: the script states the renderer used; budgets are recorded under that same renderer.

## Driving and looking

- **Prefer a test-only automation hook for driving.** A hook (a debug IPC command, an object-name lookup, an environment-enabled test server) is stable, and an unhooked UI forces coordinates. Check: the hook is compiled or enabled only by an explicit environment variable and is off in release builds.
- **Use real virtual pointer and keyboard input for anything about feel.** Synthetic toolkit events skip the input pipeline, and miss throttling, focus and cursor-shape bugs. Check: scenarios that cover hover, drag, scroll or typing send input through the compositor (a virtual pointer/keyboard client such as `wtype`, `ydotool`, or `wlrctl` where the compositor allows it), not only direct widget calls.
- **Use a vision driver when there is no hook.** Midscene-style drivers take a screenshot and act on what they see, which works without toolkit access but is slower and less exact. Check: used only as a fallback, with the assertion also checked in a screenshot the agent reads.
- **Drive Electron over CDP and Tauri over WebDriver.** The webview is a real browser engine and these are the supported ways in. Check: Electron is launched with Playwright's `_electron.launch()` or `--remote-debugging-port` plus `agent-browser`; Tauri through `tauri-driver` (WebDriver) with the platform's webview driver installed.
- **Read the screenshots.** A clean exit says nothing about how it looks: wrong colors, clipping and empty states pass every assertion. Check: capture after each scenario step (`grim -g` for a region, or the compositor's screenshot tool), open each image, and state what it shows in the evidence.
- **Use offscreen platform plugins only for logic.** `QT_QPA_PLATFORM=offscreen` and similar modes skip real shaders, masks and input timing, so passing there proves little about rendering. Check: offscreen runs are labelled as logic tests; rendering claims come from the nested-compositor run.

## Frames, idle, memory, VRAM

Starting values are examples; the project owns its budgets and records them from a measured baseline (see performance.md).

- **Probe frame presentation during motion and budget the gap.** Dropped frames are felt before they are measured by averages. Check: a probe records timestamps of presented frames while a scenario scrolls or animates; the longest gap is asserted below the budget (80 ms is a reasonable starting value); percentiles are reported, not the mean.
- **Time action to visible with a delayed upstream.** Optimistic updates must show up before the network answers. Check: a fake with a control file delays replies by 800 ms; the visible change must appear within the budget (400 ms is a starting value) with the delay active.
- **Measure idle CPU with the window hidden or unfocused.** Polling timers and running animations burn battery. Check: sample the process tree for 30 s after the scenario; CPU stays near zero (a few percent of one core at most); timers and animations stop when the window is not visible.
- **Measure memory growth after repeated navigation.** Leaks show up as growth, not as a peak. Check: repeat an open, close or navigate cycle N times (for example 20), compare PSS after warm-up with PSS at the end, and assert growth under the budget. Use PSS, since RSS double-counts shared pages across processes.
- **Measure VRAM through fdinfo.** GPU memory is not in RSS and leaks there crash other apps. Check: sum `drm-total-vram*` (or `drm-resident-vram*`) from `/proc/PID/fdinfo/*`, counting each `drm-client-id` once; textures and offscreen buffers are released when views are hidden; hiding all windows drops the number.
- **Qt Quick: read the scene graph's own diagnostics.** `QSG_RENDER_TIMING=1` prints per-frame sync, render and swap times and `QSG_INFO=1` prints the backend and atlas details. Check: no frame spends tens of milliseconds in sync (usually a heavy binding or item creation on the GUI thread); the render loop is the one you expect (`QSG_RENDER_LOOP`).
- **Qt Quick: keep atlases, batching and threading intact.** Images and clipping that break batching multiply draw calls, and scene graph objects touched off the render thread crash or glitch. Check: scene graph nodes are created and modified only in `updatePaintNode` on the render thread; many small images use atlas-friendly sizes; `clip: true` and opacity layers are used deliberately.
- **Run timing-sensitive scenarios alone.** Parallel runs distort frame and latency numbers. Check: the run records the load average, and budget scenarios do not share the machine with other agents' runs.

## Toolkit checks

- **Treat toolkit lint warnings as errors.** QML and GTK warnings are usually real bugs (unresolved bindings, missing properties) that only fail at runtime. Check: `qmllint` with warnings failing the build (fail on any qmllint output, or use its max-warnings option where the installed version has one); GTK tests run with `G_DEBUG=fatal-warnings`; Electron runs with `--enable-logging=stderr`.
- **Scan every log the run wrote.** The app log, the UI or toolkit log (QML warnings, GTK criticals, renderer console), the compositor log and the bus log each reveal different failures. Check: all are captured to files in the run directory and scanned for `error`, `warning`, `critical`, `fatal`, `segfault`, `Cannot`; the scan fails the run except for allowlisted lines that each carry a reason.
- **Check for crashes you did not drive into.** A crash during shutdown still loses data. Check: exit codes of every recorded PID are read, and an abnormal exit or a core file fails the run.

## App behavior

- **Allow a single instance and hand off cleanly.** A second launch that starts a second database or settings writer corrupts state. Check: launching twice in the sandbox focuses or messages the first and exits; the lock is released after a crash (`SIGKILL` the first, the second starts).
- **Put a timeout on every IPC call to other processes.** A hung backend or portal must not freeze the UI. Check: calls to helper processes, D-Bus services and portals have timeouts and run off the UI thread; a stopped helper (`SIGSTOP`) leaves the UI responsive.
- **Recover from a crash with state restored.** Users lose work and position when a backend dies. Check: kill the backend or helper process mid-use; the supervisor restarts it with bounded retries, and the visible state (position, selection, unsaved edits) comes back.
- **Migrate settings and keep unknown keys.** An update that cannot read old settings resets the user's setup, and one that drops unknown keys breaks the older version on rollback. Check: a fixture from the previous settings version loads and migrates; the write-back keeps keys it does not know.
- **Use portals and desktop entries correctly.** Sandboxed packages cannot use direct file or screen access. Check: file pickers, screenshots and notifications go through XDG portals where the app ships as Flatpak or Snap; the `.desktop` file validates (`desktop-file-validate`) and its `StartupWMClass` matches the window's app id.
- **Expose accessibility roles and names.** Unnamed controls are invisible to screen readers and to name-based drivers. Check: interactive items carry a role and accessible name (`Accessible.name` in QML, labels in GTK, ARIA in webviews); keyboard-only navigation reaches every control with a visible focus.
- **Mirror the layout for right-to-left languages.** Layouts hardcoded left-to-right break in Arabic and Hebrew. Check: one scenario runs with `LANG=ar` or the toolkit's RTL switch and a screenshot is read.
- **Do not let controls resize with state.** Buttons that grow when a label changes move targets under the cursor. Check: widths of toggles, play/pause-style buttons and counters are fixed or reserve space for the longest state; a screenshot comparison before and after toggling shows the same geometry.
- **Honor the reduce-motion setting.** Motion-sensitive users set it system-wide. Check: with the setting on (`prefers-reduced-motion` in webviews, the toolkit's or portal's animation setting elsewhere) animations are skipped or shortened, and a scenario confirms it.

## Verify it

A starting outline for a nested-compositor run. Adapt every placeholder per project; run it from a script the project keeps, not from a pasted one-liner.

```bash
set -u
RUN="$(mktemp -d /tmp/gui-run.XXXXXX)"; export XDG_RUNTIME_DIR="$RUN/rt"; mkdir -m 700 "$XDG_RUNTIME_DIR"
export HOME="$RUN/home" XDG_CONFIG_HOME="$RUN/home/cfg" XDG_DATA_HOME="$RUN/home/data" XDG_STATE_HOME="$RUN/home/state" XDG_CACHE_HOME="$RUN/home/cache"
mkdir -p "$HOME"; PIDS=()
trap 'for p in "${PIDS[@]}"; do kill "$p" 2>/dev/null; done; sleep 2; for p in "${PIDS[@]}"; do kill -9 "$p" 2>/dev/null; done; rm -rf "$RUN"' EXIT
WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 sway -c /dev/null >"$RUN/compositor.log" 2>&1 & PIDS+=($!)
until compgen -G "$XDG_RUNTIME_DIR/wayland-*" >/dev/null; do sleep 0.2; done
export WAYLAND_DISPLAY="$(basename "$(ls "$XDG_RUNTIME_DIR"/wayland-? | head -1)")"
timeout 120 dbus-run-session -- ./build/app --test-hook >"$RUN/app.log" 2>&1 & PIDS=("$!" "${PIDS[@]}")  # app first in the stop order
sleep 5; grim "$RUN/start.png"            # then read the image
grep -Ei 'error|warn|critical|fatal' "$RUN"/*.log && echo "log scan FAILED"
```

- Stop order and cleanup: the `trap` above kills the app PID first, then the compositor; a real script should wait for exit and record exit codes. Keep `$RUN` on failure for inspection.
- Frame-gap probe for Qt Quick: connect to `QQuickWindow::frameSwapped` in a test-only hook, record `QElapsedTimer` timestamps into an array while a scenario animates, and print the maximum gap and the 99th percentile at the end. For web content, use `requestAnimationFrame` deltas in a Playwright or CDP session.
- Idle CPU: `PID=<app pid>; a=$(awk '{print $14+$15}' /proc/$PID/stat); sleep 30; b=$(awk '{print $14+$15}' /proc/$PID/stat); echo "$(( (b-a) / $(getconf CLK_TCK) )) CPU-seconds in 30 s"` (add children for multi-process apps).
- Tree PSS: `awk '/^Pss:/ {s+=$2} END {print s/1024 " MB"}' /proc/$PID/smaps_rollup` for each process in the tree and sum.
- VRAM: `cat /proc/$PID/fdinfo/* | grep -E 'drm-client-id|drm-total-vram|drm-resident-vram'` and sum per unique client id; or `nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits`; or `nvtop` interactively.
- The opt-in helper measures memory, growth, idle CPU and VRAM in one command and fails on a budget: `python3 -I ${CLAUDE_SKILL_DIR}/helpers/procbudget.py --duration 30 --warmup 5 --mem-max 600 --growth-max 20 --cpu-max 5 --vram-max 800 --pid $APP_PID` (copy into the project only if the user agrees).
- Capture: `grim out.png` (wlroots compositors, including sway and cage), `grim -g "x,y wxh" out.png` for a region; `spectacle -b -n -o out.png` under KWin; `import -window root out.png` under Xvfb; Playwright's `page.screenshot()` for Electron.
- Toolkit checks: `qmllint qml/*.qml` (nonzero exit or any output fails), `G_DEBUG=fatal-warnings ./app-tests`, `desktop-file-validate app.desktop`.
- Electron: `npx playwright test` with `_electron.launch({ args: ['.'], env: { ...process.env, HOME: sandboxHome } })`, then `electronApp.firstWindow()` and `page.screenshot()`. Tauri: start `tauri-driver`, then drive with any WebDriver client.

## Sources

- Qt documentation: Qt Quick performance considerations, scene graph, QML profiler, qmllint. GFDL, paraphrased.
- Linux kernel documentation: DRM client usage stats (fdinfo keys). GPL, facts only.
- wlroots and sway documentation (`WLR_BACKENDS`, headless backend), Weston and KWin manuals. MIT or GPL tool documentation, facts only, paraphrased.
- Electron security tutorial and testing docs. MIT, adapted.
- Tauri documentation (WebDriver, security). Apache-2.0 and MIT, adapted.
- Playwright documentation (Electron support, screenshots). Apache-2.0, adapted.
- vercel-labs/agent-browser (Electron over CDP). Apache-2.0, adapted.
- web-infra-dev/midscene (vision-driven desktop automation). MIT, adapted.
- addyosmani/agent-skills (performance, browser isolation, observability). MIT, adapted.
- Syllo/nvtop. GPL-3, tool use only.
- Freedesktop specifications (desktop entries, portals). Freely redistributable specifications, paraphrased.
