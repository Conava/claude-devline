# Python checklist

Selected for Python projects (`pyproject.toml`, `requirements*.txt`, `setup.py`) and for stdlib-only Python services and CLIs without a manifest. Read it together with `backend.md` for a server or CLI and `desktop.md` for a Qt or GTK GUI. Many checks name ruff, mypy or pyright rules: run what the project has configured, and in a stdlib-only project use the stdlib fallbacks in Verify it instead of adding tools uninvited.

## Types and static checks

- **Run the project's type checker as its own gate, over the tests too.** Python runs code with wrong types until the line executes. Check: `mypy` or `pyright` (whichever the project configures) exits 0 on the package and its tests; without one, suggest it rather than adding it in an unrelated change.
- **Know that mypy skips the bodies of unannotated functions by default.** An untyped `def` is not checked at all, so a green mypy run can cover little. Check: the config sets `strict = true` (and turns individual options off, per module if needed) or at least `check_untyped_defs = true`; new and changed functions carry annotations.
- **Know pyright's default mode and set the target version.** Pyright's default `typeCheckingMode` is `standard`, `strict` adds unknown-type and missing-annotation checks, and without `pythonVersion` it checks against whatever interpreter is installed, not the oldest version you support. Check: `[tool.pyright]` (or `pyrightconfig.json`, which takes precedence) sets `pythonVersion` to the `requires-python` minimum; mypy sets `python_version` the same way.
- **Make suppressions expire.** A `# type: ignore` outlives the bug it hid. Check: mypy `warn_unused_ignores = true` (part of strict) or pyright `reportUnnecessaryTypeIgnoreComment` (off by default in every mode); suppressions carry an error code, `# type: ignore[arg-type]`.
- **Treat `Any` and `cast` as unchecked claims.** `json.loads`, `request.json()`, `os.environ` and untyped libraries return values the checker cannot see into. Check: data from a trust boundary is parsed into a typed model (dataclass with validation, pydantic, attrs or the project's equivalent) before use; no new `cast()` on external data.
- **Model closed sets with `Literal`, `Enum` or a union of dataclasses, and make matches exhaustive.** A new member should fail type checking where it is not handled. Check: `match` or `if` chains over a union end in `typing.assert_never(value)` (3.11+); mypy or pyright reports the missing case when a member is added.
- **Look up new APIs in the installed version, and treat deprecation warnings as errors in tests.** Models reach for deprecated or invented signatures, more often when the surrounding code is old (`agent-process.md`, "Check every API against the installed or released version"). Check: the version comes from the lockfile; tests run with `-W error::DeprecationWarning` or pytest `filterwarnings = ["error::DeprecationWarning"]` scoped to your own package.

## Language traps

- **Never use a mutable default argument.** Defaults are evaluated once at definition time, so a `[]` or `{}` default is shared by every call that mutates it. Check: ruff `B006` (mutable-argument-default) and `B008` (function call in default) are clean; the fix is a `None` default and creating the object inside.
- **Bind loop variables explicitly in closures.** A lambda or nested function looks the variable up when it runs, so every callback created in a loop sees the last value. Check: ruff `B023` (function-uses-loop-variable) is clean; capture with a default argument (`lambda n=x: ...`) or `functools.partial`.
- **Pass `strict=True` to `zip` when lengths must match.** `zip` stops at the shortest input and drops data silently. Check: ruff `B905` is clean, or the length mismatch is intended and commented.
- **Use timezone-aware datetimes.** Naive `datetime.now()` and `utcnow()` mix local and UTC times without error. Check: ruff `DTZ005` and the other `DTZ` rules are clean; stored and compared timestamps carry `tzinfo=UTC`; tests pin the clock (`testing.md`, "Pin the clock in time-dependent tests").

## Errors and resources

- **Chain exceptions when you translate them.** `raise NewError(...) from err` records the cause; a bare raise inside `except` reads as a second failure while handling the first, and `from None` hides the cause on purpose. Check: ruff `B904` (raise-without-from-inside-except) is clean; context goes in the message or `err.add_note(...)` (3.11+), once (`reliability.md`, "Wrap errors once with context").
- **Never catch broadly and carry on.** `except Exception:` with a `pass` or a log line hides programmer errors, and a bare `except:` also catches `KeyboardInterrupt` and `SystemExit`. Check: ruff `BLE001` (blind-except) and `E722` are clean, or each broad catch logs with `logger.exception` and re-raises or sits at a top-level boundary (`reliability.md`, "Never swallow an error").
- **Release every resource with a context manager.** Files, sockets, locks, sessions and temp directories leak on the exception path without one. Check: `with` (or `contextlib.ExitStack` for a variable number) around each; `requests.Session` and `httpx.Client` are used as context managers or closed at shutdown; `python3 -X dev` or `-W default` shows no `ResourceWarning` in the test run.
- **Handle several concurrent failures with exception groups.** `TaskGroup` raises an `ExceptionGroup`, which a plain `except ValueError` does not catch. Check: code around a `TaskGroup` uses `except*` (3.11+) for the types it handles.

## Async

- **Keep a reference to every task, or use a `TaskGroup`.** The event loop holds tasks only weakly, so an unreferenced task can be garbage collected mid-run, and an exception nobody retrieves surfaces only as "Task exception was never retrieved" at collection time. Check: ruff `RUF006` (asyncio-dangling-task) is clean; concurrent work runs in `async with asyncio.TaskGroup()` (3.11+); long-lived background tasks live in a set with `add_done_callback(tasks.discard)`.
- **Prefer `TaskGroup` over `gather` for work that must succeed together.** With `gather`'s default `return_exceptions=False`, the first exception propagates while the other awaitables keep running; `TaskGroup` cancels the rest. Check: `gather` remains only where partial results are wanted, with `return_exceptions=True` and each result inspected.
- **Put a timeout on every external await.** Check: `async with asyncio.timeout(s):` (3.11+) or `asyncio.wait_for`; the resulting `TimeoutError` is caught outside the `async with` block, not inside it.
- **Re-raise `CancelledError`.** It is a `BaseException` because timeouts and `TaskGroup` rely on cancellation; swallowing it breaks both. Check: cleanup uses `try/finally`; any `except asyncio.CancelledError` ends in `raise`.
- **Keep blocking calls out of coroutines.** One `time.sleep`, `open().read()`, `requests` call or sync database driver stalls every task on the loop. Check: ruff `ASYNC210` (blocking HTTP), `ASYNC230` (blocking `open`) and `ASYNC251` (`time.sleep`) are clean; blocking work goes through `asyncio.to_thread` or `loop.run_in_executor`; asyncio debug mode (`PYTHONASYNCIODEBUG=1` or `-X dev`) logs callbacks slower than 100 ms and coroutines that were never awaited.
- **Touch asyncio objects only from the loop's thread.** Almost none of them are thread-safe. Check: other threads use `loop.call_soon_threadsafe` or `asyncio.run_coroutine_threadsafe`; debug mode raises on wrong-thread calls.

## Processes, HTTP and I/O

- **Run subprocesses with an argument list, a timeout and an explicit `check`.** A shell string built from data is injection, an untimed child hangs the caller, and `subprocess.run` ignores a failing exit code unless told. Check: `subprocess.run([...], timeout=..., check=True)` (ruff `S602`, `S604` and `PLW1510` clean); `run()` kills and reaps the child on timeout, but `Popen.communicate(timeout=)` does not, so that path calls `proc.kill()` then `communicate()` again (`security.md` Process execution).
- **Pass an explicit timeout to every `requests` call.** `requests` has no default timeout and can hang forever. Check: ruff `S113` (request-without-timeout) is clean; use a `(connect, read)` tuple.
- **Know what a `requests` timeout does not bound.** The read timeout is the gap between bytes, not the total, and the connect timeout applies per resolved address, so a host with IPv4 and IPv6 doubles it. Check: total-time limits on slow streams are enforced separately (a deadline checked while iterating, or a worker timeout); `stream=True` responses are used in a `with` block so the connection goes back to the pool.
- **Set `httpx` timeouts to the downstream's budget.** `httpx` defaults to 5 seconds of inactivity per phase (connect, read, write, pool) and `timeout=None` disables them. Check: clients set `httpx.Timeout(...)` from measured latency (`reliability.md`, "Derive timeouts from the downstream's measured latency"); no `timeout=None` on external calls.
- **Retry in one layer, and never retry a non-idempotent POST blindly.** `urllib3.Retry` mounted on a session retries whatever `allowed_methods` lists. Check: `reliability.md` Retries and overload; `allowed_methods` excludes POST unless the request carries an idempotency key.

## Security lint

- **Run ruff's `S` (flake8-bandit) rules on changed code.** They map the general rules in `security.md` to Python calls. Check: these stay clean or carry a reasoned `# noqa: Sxxx`: `S301` (`pickle` on untrusted data), `S506` (`yaml.load` without `SafeLoader`), `S307` (`eval`), `S102` (`exec`), `S608` (SQL built from strings), `S324` (MD5 or SHA-1 for security), `S311` (`random` for secrets, use `secrets`), `S108` (hard-coded `/tmp` paths, use `tempfile`), `S105` (hard-coded passwords), `S501` (`verify=False`).
- **Do not let `assert` guard anything.** `python -O` removes asserts, so an assert used for validation or authorization vanishes in optimized runs. Check: ruff `S101` on non-test code; invariants that matter raise explicit exceptions.
- **Know which ruff rules actually ran.** Before ruff 0.16 the default set was only `E4`, `E7`, `E9` and `F`; 0.16 enables about 400 rules by default, including `B006`, `B023`, `BLE001`, `E722`, `PLW1510` and the `ASYNC` blocking-call rules, but still none of `S113`, `S301`, `S506`, `S602`, `S608`, `B904`, `B905`, `DTZ005` or `RUF006`, and a project with its own `select` gets only what it lists. Check: read the locked ruff version and `[tool.ruff.lint] select` before claiming a rule passed; to check a rule the project has not enabled, run it once with `ruff check --select <codes> <files>` and report findings rather than changing the config.

## Tests

- **Write fixtures with one state change each, torn down after `yield`.** If a fixture raises before its `yield`, its own teardown does not run, so a fixture that does several setup steps leaks the earlier ones. Check: each fixture creates one thing and cleans it up after `yield`; tests use `tmp_path` and `monkeypatch` instead of real paths and environment edits (`testing.md`, Run the real app without touching the user's environment).
- **Shuffle test order only with a plugin the project already has.** `pytest-randomly` shuffles by module, class and function, reseeds `random` per test and prints the seed. Check: if installed, record the printed seed and reproduce with `--randomly-seed=<n>`; if not, suggest it rather than adding it; `-p no:randomly` disables it for a single diagnosis run.
- **Use Hypothesis for parsers, serializers and invariants, and pin what it finds.** It shrinks a failing input to a small one and replays saved failures from the `.hypothesis` directory, but database entries can be invalidated by upgrades. Check: every failure Hypothesis found is pinned with `@example(...)`; `.hypothesis/` is in `.gitignore`; `@reproduce_failure` blobs are removed before commit because they are not stable across versions (`testing.md`, Beyond examples).
- **Run tests with warnings visible.** Check: `python3 -X dev -m pytest` shows `ResourceWarning` and asyncio debug output; the log scan covers pytest's captured warnings summary.

## Packaging, dependencies and versions

- **Support the Python versions that are still maintained, and say so in one place.** Each release gets about 2 years of bugfixes and security fixes to 5 years (PEP 602); in November 2026 the maintained lines are 3.11 to 3.15, and 3.10 reached end of life in October 2026. Check: `requires-python` in `pyproject.toml` states the minimum without an upper bound; the CI matrix runs the minimum and the newest; the type checker targets the minimum (Types and static checks); new syntax (`except*`, `TaskGroup`, `typing.assert_never`) is not used below the minimum.
- **Lock dependencies and install from the lock.** Check: the project's lock is committed and current (`uv lock --check`, then `uv sync --locked`; or `pip-compile` from pip-tools with `pip install -r requirements.txt`); CI never resolves fresh (`security.md`, "Commit the lockfile and install from it").
- **Look every new package up on PyPI before adding it.** Check: `pip index versions <name>` or pypi.org/project/<name> matches the intended project, its repository link and age (`security.md`, "Look up every new package name on the registry before adding it"); import name and distribution name are checked separately, since they often differ.
- **Keep development tools out of runtime dependencies.** Check: test and lint tools sit in `[dependency-groups]` (PEP 735) or the project's dev extra, not in `[project] dependencies`; the licence is an SPDX expression in `license` (PEP 639) when the metadata is touched.
- **Audit dependencies after every change.** Check: `pip-audit` (current environment), `pip-audit -r requirements.txt` or `pip-audit .` for a `pyproject.toml` project exits 0; it exits 1 on a known vulnerability.

## Logging

- **Name loggers by module and leave configuration to the application.** Check: modules use `logger = logging.getLogger(__name__)`; library code adds at most a `NullHandler` and never calls `basicConfig` or logs to the root logger; the application configures handlers once at startup, structured per `reliability.md` Logging and observability.
- **Pass log arguments separately instead of formatting them first.** An f-string is built even when the level is off. Check: `logger.debug("user %s from %s", user, addr)`; expensive values are guarded with `logger.isEnabledFor(logging.DEBUG)`; `logger.exception(...)` is called only inside an `except` block, where it adds the traceback.

## Verify it

Project with tools configured (use the project's runner, for example `uv run`):

```bash
uv sync --locked                     # or: pip install -r requirements.txt in a fresh venv
ruff check . && ruff format --check .
mypy .                               # or: pyright
python3 -X dev -W error::DeprecationWarning -m pytest -q
pip-audit .                          # or: pip-audit -r requirements.txt
```

Stdlib-only project (nothing to install):

```bash
python3 -X dev -W error -m unittest discover -v     # -X dev: asyncio debug, ResourceWarning
python3 -m py_compile path/to/changed.py            # writes __pycache__/; keep it in .gitignore
grep -rnE 'shell=True|requests\.(get|post|put|delete|request)\(' --include='*.py' . | grep -v 'timeout='
```

One-off rule check without changing the config: `ruff check --select B904,B905,S,DTZ,RUF006 <changed files>` (via `uvx ruff` when ruff is not installed and the owner agrees to fetch it).

Real run: start the service under the sandbox from `backend.md` Verify it with `PYTHONASYNCIODEBUG=1 PYTHONUNBUFFERED=1`, then scan the log for `Traceback`, `ResourceWarning`, `DeprecationWarning`, `was never awaited` and `Task exception was never retrieved`.

## Sources

- Python documentation (PSF licence, adapted): asyncio tasks (weak task references, `TaskGroup`, `timeout`, `gather`, `CancelledError`) and "Developing with asyncio" (debug mode, slow callbacks, thread safety); `subprocess` (argument lists, `shell=True`, `run` versus `communicate` timeouts, `check`); errors tutorial (chaining, `add_note`, exception groups); programming FAQ (mutable defaults, late-binding closures); logging HOWTO.
- PEP 602 and the Python developer's guide version table (PSF licence and public domain, facts only): release cadence, support windows and end-of-life dates, rechecked 2026-11.
- Python Packaging User Guide, "Writing your pyproject.toml" (CC-BY-SA-3.0, paraphrased): `requires-python` upper bounds, dependency groups, SPDX licence expressions.
- mypy documentation (MIT, adapted): strict configuration, `check_untyped_defs`, `warn_unused_ignores`, per-module options; pyright configuration docs (MIT, adapted): type-checking modes, `pythonVersion`, `reportUnnecessaryTypeIgnoreComment`.
- ruff rules reference (MIT, adapted): rule codes and names for bugbear, bandit, async, datetime, blind except, `RUF006`, `PLW1510`, and the default rule selection; Astral's ruff v0.16.0 release notes (vendor blog, facts only): the expanded default set.
- pytest documentation (MIT, adapted): yield fixtures, teardown order, safe teardowns; pytest-randomly (MIT, adapted): shuffling, reseeding, seed options; Hypothesis documentation (MPL-2.0, paraphrased): shrinking, example database, `@example`, `@reproduce_failure`.
- requests documentation (Apache-2.0, adapted): no default timeout, read-timeout semantics, per-address connect timeout, streaming and sessions; httpx documentation (BSD-3-Clause, adapted): default and per-phase timeouts.
- pip-audit (Apache-2.0, adapted) and uv documentation (Apache-2.0/MIT, adapted): audit modes and exit codes, `uv lock --check` and `--locked`.
- Scientific findings on LLM-written code, facts only: Spracklen et al., package hallucinations (USENIX Security 2025); Wang et al., deprecated API usage (ICSE 2025).
