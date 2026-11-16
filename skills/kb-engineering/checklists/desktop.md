# Desktop apps checklist

Selected for desktop GUI apps: Qt/QML, GTK, Electron, Tauri, Flutter desktop. Desktop is where an agent most easily damages the user's session (restarts the shell, writes real config, plays real audio) and where offscreen test modes hide real rendering and input problems. The approach here is a real run in a nested compositor that is invisible on the user's desktop, with measured frames, idle CPU and VRAM. Electron and Tauri security flags are in security.md's desktop group and not repeated here. Linux is assumed; adapt the session pieces on other platforms.

## Never the live session

- **Do not restart, reload or signal the user's shell, compositor, panel or session services.** The user is working in them. Check: grep scripts for `systemctl --user restart`, `kquitapp`, `killall`, `pkill`, `swaymsg reload` and `--replace` (KWin and other shells use it to take over the running session); none runs against the real session.
- **Do not install, uninstall or enable anything.** Installs change the user's machine and cannot be undone by a test run. Check: no `pacman`, `apt`, `dnf`, `flatpak install`, `pip install --user`, `make install` in the run path; name missing tools for the user instead.
- **Never read or write the real config, data, cache or keyring.** A test that migrates real settings or overwrites a library destroys user data. Check: the run sets private `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`; after the run, the real dirs are unchanged.
- **Do not use the app's own quit command or a running instance.** A second launch may hand off to the user's running instance (single instance) and a quit command may close their window. Check: the sandbox has its own runtime dir and bus so the instance lookup cannot find the user's; the app is stopped by PID.
- **Take PIDs only from `$!` of processes you started.** Name matching hits the user's processes. Check: no `pgrep -f`, `pkill`, `killall` on app or compositor names.

## Sandboxed GUI runs

- **Run under a nested or headless compositor.** The window then never appears on the user's screen, and real shaders, masks and input timing run. Options (flags checked against each tool's docs or `--help`): `weston -B headless --width=1280 --height=800` (`--refresh-rate=0` repaints only on capture); `sway` or `cage` (both wlroots) with `WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1` and `WLR_HEADLESS_OUTPUTS=1`; `kwin_wayland --virtual --width 1280 --height 800 --socket <name>`; `Xvfb :99 -screen 0 1280x800x24` or `xvfb-run -a` for X11 apps. Check: the script names which one it uses, sets a size explicitly and never passes `--replace`.
- **Give the run a private runtime dir and session bus.** Sockets and the bus are how an app finds other instances and services. Check: `XDG_RUNTIME_DIR` is a fresh `0700` directory with a short path (a Unix socket path is limited to about 100 characters), and the app runs under `dbus-run-session`.
- **Provide a fresh keyring when the app stores secrets.** Otherwise the app prompts, fails, or reaches the user's real keyring. Check: a throwaway keyring daemon on the private bus, unlocked with a throwaway password piped on stdin (`gnome-keyring-daemon --unlock` or the project's equivalent), and secret-handling paths are exercised.
- **Silence audio without touching the user's devices.** Real speakers mid-test are a bug report. Check: a null sink or a private PipeWire/PulseAudio instance in the private runtime dir, or the app's own dummy audio backend (`SDL_AUDIODRIVER=dummy`); never the user's default sink.
- **Generate fixtures, never copy the user's library.** User media and documents are private and change. Check: fixtures are generated under the temp dir by the harness (small files, plus an edge-case set: empty, huge names, odd encodings, right-to-left names).
- **Stop in order: app first, then compositor, then the bus.** A nested compositor can spin at full CPU when its host disappears, and an app can hang waiting for it. Check: `trap` cleanup sends SIGTERM to the recorded PIDs, waits a grace period, then SIGKILL, in that order; after the run no recorded PID is alive.
- **Use a GPU-backed renderer when the run measures frames or VRAM.** Software renderers (pixman, llvmpipe) give different frame times and no VRAM. Check: the script states the renderer used (`WLR_RENDERER`, weston `--renderer=gl|pixman`, `GSK_RENDERER` for GTK 4); budgets are recorded under that same renderer.

## Driving and looking

- **Prefer a test-only automation hook for driving.** A hook (a debug IPC command, an object-name lookup, an environment-enabled test server) is stable, and an unhooked UI forces coordinates. Check: the hook is compiled or enabled only by an explicit environment variable and is off in release builds.
- **Use real virtual pointer and keyboard input for anything about feel.** Synthetic toolkit events skip the input pipeline, and miss throttling, focus and cursor-shape bugs. Check: scenarios that cover hover, drag, scroll or typing send input through the compositor (a virtual pointer/keyboard client such as `wtype`, `ydotool`, or `wlrctl` where the compositor allows it), not only direct widget calls.
- **Use a vision driver when there is no hook.** Midscene-style drivers take a screenshot and act on what they see, which works without toolkit access but is slower and less exact. Check: used only as a fallback, with the assertion also checked in a screenshot the agent reads.
- **Drive Electron over CDP and Tauri over WebDriver.** The webview is a real browser engine and these are the supported ways in. Check: Electron is launched with Playwright's `_electron.launch()` or `--remote-debugging-port` plus `agent-browser`; Tauri through `tauri-driver` (WebDriver) with the platform's webview driver installed.
- **Read the screenshots.** A clean exit says nothing about how it looks: wrong colors, clipping and empty states pass every assertion. Check: capture after each scenario step (`grim -g` for a region, or the compositor's screenshot tool), open each image, and state what it shows in the evidence.
- **Use offscreen platform plugins only for logic.** `QT_QPA_PLATFORM=offscreen` and similar modes skip real shaders, masks and input timing, so passing there proves little about rendering. Check: offscreen runs (Qt Quick Test with `-platform offscreen -input tests/`, which otherwise opens a real window) are labelled as logic tests; rendering claims come from the nested-compositor run.
- **Check every moved or new container by eye in a real run.** A content-sized item inside a container that assigns widths (a layout, a form row, a host panel) can render at 0x0 and vanish, and code review does not catch it. Check: such items get an explicit width or fill; a screenshot of every moved container is read in the nested-compositor run.

## Frames, idle, memory, VRAM

Starting values are examples; the project owns its budgets and records them from a measured baseline (see performance.md).

- **Probe frame presentation during motion and budget the gap.** Dropped frames are felt before they are measured by averages. Check: a probe records timestamps of presented frames while a scenario scrolls or animates; the longest gap is asserted below the budget (80 ms is a reasonable starting value); percentiles are reported, not the mean.
- **Time action to visible with a delayed upstream.** Optimistic updates must show up before the network answers. Check: a fake with a control file delays replies by 800 ms; the visible change must appear within the budget (400 ms is a starting value) with the delay active.
- **Measure idle CPU with the window hidden or unfocused.** Polling timers and running animations burn battery. Check: sample the process tree for 30 s after the scenario; CPU stays near zero (a few percent of one core at most); timers and animations stop when the window is not visible.
- **Measure memory growth after repeated navigation.** Leaks show up as growth, not as a peak. Check: repeat an open, close or navigate cycle N times (for example 20), compare PSS after warm-up with PSS at the end, and assert growth under the budget. Use PSS, since RSS double-counts shared pages across processes.
- **Measure VRAM through fdinfo.** GPU memory is not in RSS and leaks there crash other apps. Check: sum `drm-total-vram*` (or `drm-resident-vram*`) from `/proc/PID/fdinfo/*`, counting each `drm-client-id` once; textures and offscreen buffers are released when views are hidden; hiding all windows drops the number.
- **Qt Quick: read the scene graph's own diagnostics.** `QSG_RENDER_TIMING=1` prints per-frame timing parameters, `QSG_INFO=1` (legacy switch for the `qt.scenegraph.general` category) prints the backend, and `QSG_RENDERER_DEBUG=render` reports batching. Check: no frame spends tens of milliseconds in sync (usually a heavy binding or item creation on the GUI thread); the render loop is the one you expect (`QSG_RENDER_LOOP=basic|threaded`); a `QSG_VISUALIZE=overdraw` (or `batches`, `clip`, `changes`) screenshot of the changed view is read.
- **Qt Quick: keep the GUI thread inside its frame budget.** At 60 fps a frame has about 16 ms, GPU upload included. Check: QML Profiler (`qmlprofiler` or Qt Creator) on the scenario shows no binding or handler over a few milliseconds; heavy work runs in a worker thread; C++ called from QML never spins a nested event loop (`grep -rn 'processEvents\|QEventLoop'`); large components load through `Loader { asynchronous: true }`; images set `sourceSize` to the displayed size and `asynchronous: true`; delegates are lean, never `clip: true`, and views reuse items.
- **Qt Quick: keep atlases, batching and threading intact.** Images and clipping that break batching multiply draw calls, and scene graph objects touched off the render thread crash or glitch. Check: scene graph nodes are created and modified only in `updatePaintNode` on the render thread; many small images use atlas-friendly sizes; `clip: true` and opacity layers are used deliberately.
- **Run timing-sensitive scenarios alone.** Parallel runs distort frame and latency numbers. Check: the run records the load average, and budget scenarios do not share the machine with other agents' runs.

## Toolkit checks

- **Treat toolkit lint warnings as errors, with a linter that can see your imports.** An unresolved QML type or an assignment to a missing property in an eagerly loaded file can kill the whole UI with nothing in the log, and plain `qmllint` without the import paths, or with warnings suppressed, passes everything. Check: `qmllint -I <each import dir> --max-warnings 0 --json - <files>` (or the CMake `all_qmllint` target); first probe it with a made-up property in a scratch copy to prove it reports; compare against the base branch so only new warnings count; GTK and GLib tests run with `G_DEBUG=fatal-criticals` (`fatal-warnings` where the project accepts it); Electron runs with `--enable-logging=stderr`.
- **Add a live health check that proves the UI actually loaded.** A silent load failure leaves a process that runs but serves nothing. Check: after start, the harness asks the app something only a fully loaded UI can answer (count of registered IPC targets, a test-hook ping, the main window's object name) and fails the run otherwise.
- **Disable the QML disk cache in test runs.** Stale compiled caches after files change under the same path (a submodule bump, a branch switch) cause phantom `TypeError`s. Check: test and harness scripts export `QML_DISABLE_DISK_CACHE=1`, or point `QML_DISK_CACHE_PATH` into the run directory.
- **Scan every log the run wrote.** The app log, the UI or toolkit log (QML warnings, GTK criticals, renderer console), the compositor log and the bus log each reveal different failures. Check: all are captured to files in the run directory and scanned for `error`, `warning`, `critical`, `fatal`, `segfault`, `Cannot`; the scan fails the run except for allowlisted lines that each carry a reason.
- **Check for crashes you did not drive into.** A crash during shutdown still loses data. Check: exit codes of every recorded PID are read, and an abnormal exit or a core file fails the run.

## Structure

- **Keep code loading on the baseline runtime.** When the UI must also run on the upstream toolkit or an older supported version, a fork-only or newer property used in a binding breaks it. Check: version- or fork-only features sit behind guarded assignments or feature checks, never in bindings; one CI or harness run on the baseline runtime loads with no warnings.
- **Services never import UI, and run only while something watches.** Services that import UI modules create cycles and keep timers alive with no viewer. Check: `grep -rn` finds no imports of UI module dirs inside service code; timers, watchers and subscriptions start on the first reference and stop on the last; the idle CPU check above runs with every view closed.
- **Fix a shared component at its source, never in a local copy.** Patched copies of shared widgets drift, and edits through a symlink into a submodule land in the wrong repository. Check: `git -C <submodule> status` is clean in the app change; the fix is its own change in the shared library, then the submodule is bumped; a missing widget is built in the library's style so it can move upstream unchanged.
- **Give a per-backend control its equivalent on every backend, or hide it.** A setting that silently does nothing on one backend reads as a bug. Check: list each backend-specific control and, per backend, the equivalent or the condition that hides it; a scenario per backend opens the settings page and a screenshot is read.

## UI state and input

- **Bind per-item components to typed properties instead of `Connections` on change signals.** In delegates and per-screen items, `Connections { onFooChanged }` is a common review finding; a bound handler fires once at creation when the initial value differs from the default and never on a same-value write. Check: handlers sit on a same-file source or a typed readonly property (never `var`); only idempotent bodies are converted; `Connections` remain for plain signals and singletons; `qmllint` reports no unqualified access.
- **Re-sync controls with state after a reset.** Dropdowns and chip groups that set their own current value on a pick silently drop a plain binding, so a reopened dialog shows the last pick over reset fields. Check: resettable controls use an explicit `Binding` element (or a wrapper that does); a scenario picks, cancels, reopens and asserts the reset value.
- **Ignore programmatic fills in edit handlers.** A text field's edit signal can fire when code fills it, so opening a record marks it changed. Check: handlers that write state return early when the text equals the current value, or listen to user-interaction signals (`textEdited`, a slider's `moved`) rather than `textChanged`/`valueChanged`; a test opens a record and asserts it is not dirty.
- **Recheck row-pointing state on every list rebuild.** A selection index follows whatever slides into its slot, a detail pane keeps a removed row, a filter hides the current item. Check: delegates hold no state (it lives in the model); the shared rebuild function remaps selection by key, closes panes whose row left and keeps the current item visible; a test removes, moves and filters rows and asserts the selection.
- **Do not rely on delivery order between handlers.** Two handlers hearing one event, or a change handler running before sibling bindings update, fire in an unspecified order. Check: decisions that read another handler's state run deferred (`Qt.callLater`, an idle callback or an existing grace timer); a test drives the event and asserts the final state.
- **Keep unsaved edits when a page reloads on return.** Coming back from a sub-page, or reopening, refreshes the form and wipes typing. Check: only untouched fields refresh; kept edits are marked and can be discarded; a scenario edits, navigates away and back, and asserts the edit.
- **Say why an action is disabled or refused, in visible text.** A disabled Qt control shows no tooltip, and a silent no-op reads as a bug. Check: every disabled control or refused action has a visible reason (inline text, or an enabled control that shows a message on use); a screenshot of the disabled state is read.
- **Replace every path a removed control covered.** Changing what a click does, or cutting an editor section, can leave an action or a field unreachable. Check: the change lists what the removed control, gesture or section did and where each now lives; new handlers on shared surfaces pass through input they do not use.
- **Route keys deliberately when a popup takes focus.** An overlay that grabs the keyboard stops the window's shortcuts, which may or may not be intended. Check: overlays that take focus declare which shortcuts they override; one scenario per overlay presses a window shortcut and asserts the expected target.

## Windows and layout

- **Keep content inside its window.** Popups, sheets and detail panes that outgrow the parent window are cut off on small screens. Check: sizes are clamped to the parent and content scrolls; a scenario at a small window size (for example 800x600) takes a screenshot that is read.
- **Put things that must move together on one surface, and give borrowed painting a fallback.** Two Wayland surfaces cannot commit on the same frame, so a shape split across windows drifts however it is tuned, and a background painted by another window is missing whenever that window cannot paint. Check: co-moving visuals live in one window; every state where the painting window cannot paint is listed and falls back to local chrome; screenshots during the motion are read.
- **Size windows for the common state, not the rare one.** A surface sized for a rare expanded state pays for it all day in memory and compositing, and resizes show squeezed buffers for a frame. Check: grow for the rare state, hold the action until a frame at the new size is presented (with a time limit), shrink only when no frame is in flight; the VRAM check runs in the common state.

## App behavior

- **Allow a single instance and hand off cleanly.** A second launch that starts a second database or settings writer corrupts state. Check: launching twice in the sandbox focuses or messages the first and exits; the lock is released after a crash (`SIGKILL` the first, the second starts).
- **Put a timeout on every IPC call to other processes.** A hung backend or portal must not freeze the UI. Check: calls to helper processes, D-Bus services and portals have timeouts and run off the UI thread; a stopped helper (`SIGSTOP`) leaves the UI responsive.
- **Recover from a crash with state restored.** Users lose work and position when a backend dies. Check: kill the backend or helper process mid-use; the supervisor restarts it with bounded retries, and the visible state (position, selection, unsaved edits) comes back.
- **Migrate settings and keep unknown keys.** An update that cannot read old settings resets the user's setup, and one that drops unknown keys breaks the older version on rollback. Check: a fixture from the previous settings version loads and migrates; the write-back keeps keys it does not know.
- **Use portals and desktop entries correctly.** Sandboxed packages cannot use direct file or screen access. Check: file pickers, screenshots and notifications go through XDG portals where the app ships as Flatpak or Snap; the `.desktop` file validates (`desktop-file-validate`), its `StartupWMClass` matches the window's app id, and `DBusActivatable`, `SingleMainWindow` and `StartupNotify` are set only when true for the app.
- **Route every user-facing string through the translation function, and reuse existing terms.** Each new string costs one translation per language, and near-duplicates of existing terms multiply that. Check: strings use `qsTr`/`tr` (or `_()`/gettext) with translator context (`//:` comments in Qt, disambiguation arguments for short words); placeholders use `%1` and `.arg()`, never concatenation; plurals use the `%n` form; numbers and dates go through the locale; the catalog is searched before adding a term (reuse only when the meaning and part of speech match); machine-read output (IPC replies, CLI) stays untranslated; synced catalogs are never edited by hand; `lupdate` or `xgettext` runs clean.
- **Electron: deny permission requests by default and turn off unneeded fuses.** Electron approves every permission request unless a handler says otherwise, and fuses such as `runAsNode` let anyone run the binary as plain Node. Check: `session.setPermissionRequestHandler` (and `setPermissionCheckHandler`) allowlist by origin and permission; `npx @electron/fuses read --app <packaged app>` shows `RunAsNode` and `EnableNodeCliInspectArguments` off. Other Electron and Tauri hardening is in security.md.
- **Expose accessibility roles and names.** Unnamed controls are invisible to screen readers and to name-based drivers. Check: interactive items carry a role and accessible name (`Accessible.name` in QML, labels in GTK, ARIA in webviews); GTK 4 test runs use `GTK_A11Y=test`; keyboard-only navigation reaches every control with a visible focus; when a form is replaced or extracted into a component, its initial focus, tab order, Enter to submit or advance and the submit signal to the host survive, and a scenario drives it keyboard-only.
- **Mirror the layout for right-to-left languages.** Layouts hardcoded left-to-right break in Arabic and Hebrew. Check: one scenario runs with `LANG=ar` or the toolkit's RTL switch (`GTK_DEBUG=invert-text-dir` for GTK 4) and a screenshot is read.
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
- Toolkit checks: `qmllint -I qml --max-warnings 0 qml/*.qml` (nonzero exit fails), `QML_DISABLE_DISK_CACHE=1 ./tst_app -platform offscreen -input tests/` for Qt Quick Test logic, `G_DEBUG=fatal-criticals GTK_A11Y=test ./app-tests`, `desktop-file-validate app.desktop`.
- Other compositors in the outline above: replace the sway line with `weston -B headless --width=1280 --height=800 --socket=wl-test` or `kwin_wayland --virtual --width 1280 --height 800 --socket wl-test` and set `WAYLAND_DISPLAY=wl-test`.
- Electron: `npx playwright test` with `_electron.launch({ args: ['.'], env: { ...process.env, HOME: sandboxHome } })`, then `electronApp.firstWindow()` and `page.screenshot()`. Tauri: start `tauri-driver`, then drive with any WebDriver client.

## Sources

- Qt documentation: Qt Quick performance considerations, best practices, scene graph and default renderer, QML disk cache, Qt Quick Test, writing source code for translation, qmllint. GFDL, paraphrased.
- GTK 4 and GLib "Running and debugging" docs (`GTK_DEBUG`, `GTK_A11Y`, `GSK_RENDERER`, `G_DEBUG`). LGPL project docs, facts only.
- Electron fuses documentation and the Electron security checklist (permission handler). MIT, adapted.
- Linux kernel documentation: DRM client usage stats (fdinfo keys). GPL, facts only.
- wlroots environment variable docs (`WLR_BACKENDS`, `WLR_LIBINPUT_NO_DEVICES`, `WLR_HEADLESS_OUTPUTS`, `WLR_RENDERER`), weston(1) man page and "Running Weston" docs, and `kwin_wayland --help` (KWin 6). MIT or GPL tool documentation, facts only, paraphrased.
- Electron security tutorial and testing docs. MIT, adapted.
- Tauri documentation (WebDriver, security). Apache-2.0 and MIT, adapted.
- Playwright documentation (Electron support, screenshots). Apache-2.0, adapted.
- vercel-labs/agent-browser (Electron over CDP). Apache-2.0, adapted.
- web-infra-dev/midscene (vision-driven desktop automation). MIT, adapted.
- addyosmani/agent-skills (performance, browser isolation, observability). MIT, adapted.
- Syllo/nvtop. GPL-3, tool use only.
- Freedesktop specifications (Desktop Entry recognized keys, portals). Freely redistributable specifications, paraphrased.
