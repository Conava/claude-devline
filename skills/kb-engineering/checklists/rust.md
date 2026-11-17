# Rust checklist

Selected when the project has a `Cargo.toml`; services and CLIs also read `backend.md`. Async items assume tokio, the most common runtime; for another runtime, find its equivalent of each tokio call before applying them. Generic timeout, retry and error rules live in `reliability.md`, test method in `testing.md`, measurement method in `performance.md`; this file holds what is specific to Rust.

## Panics and errors

- **Return `Result` by default; panic only when an invariant is broken.** Panicking decides for the caller that the failure is unrecoverable; malformed input, a full disk or a rate-limited upstream are expected failures (Rust Book, ch. 9.3). Check: grep `\.unwrap()`, `\.expect(`, `panic!`, `todo!`, `unimplemented!` and `dbg!` outside tests and examples; where the project has adopted them, clippy's restriction lints `unwrap_used`, `expect_used`, `panic`, `todo` and `dbg_macro` are on in `[lints.clippy]`, with `allow-unwrap-in-tests` and `allow-expect-in-tests` in `clippy.toml`.
- **Make each `expect` state the invariant that makes it safe.** `expect("hardcoded address should be valid")` tells the next reader what to recheck when the input stops being hardcoded. Check: every `expect` in non-test code names why `Err` or `None` cannot happen, and none of them sits on data from a user, file, network or environment.
- **Find the hidden panics.** Indexing and slicing out of range, slicing a `str` off a character boundary, integer division by zero, a second `RefCell::borrow_mut` and overflow in debug builds all panic without an `unwrap` in sight. Check: indexes derived from input use `.get()`; string slicing on input has a test with multibyte UTF-8; panic-free crates enable `indexing_slicing` and `string_slice` (restriction).
- **Encode checked invariants in types instead of rechecking them.** A constructor that validates once and a private field mean every holder of the type can rely on the value; taking `T` instead of `Option<T>` removes a whole case (Rust Book, ch. 9.3; C-VALIDATE). Check: values validated at the boundary are wrapped in a newtype with a fallible constructor (`TryFrom` or `new -> Result`) and private fields; inner functions take the newtype, not the raw value.
- **Give libraries their own error types and applications context.** Callers of a library need to match on what went wrong; an application needs to know where. Check: library crates derive `std::error::Error` with `thiserror` (which does not appear in the public API) and do not return `anyhow::Error` from public functions; binaries use `anyhow::Result` and add `.context(..)` or `.with_context(..)` at each I/O boundary; error types are meaningful and well-behaved (API guideline C-GOOD-ERR).
- **Document errors, panics and safety on public items (C-FAILURE).** Callers cannot avoid a panic nobody wrote down. Check: public `unsafe fn` has a `# Safety` section (`missing_safety_doc`, on by default); where the project uses pedantic, `missing_errors_doc` and `missing_panics_doc` are clean.
- **Handle mutex poisoning on purpose.** After a thread panics while holding a `std::sync::Mutex`, `lock()` returns `Err(PoisonError)`; `into_inner` recovers the guard. Check: each `lock().unwrap()` is a deliberate "propagate the panic" choice, or the code recovers with `into_inner` and repairs the state; `unsafe` code never relies on poisoning for soundness.
- **Check what `read` and `write` actually processed.** They may handle only part of the buffer. Check: `read_exact` and `write_all` where the whole buffer matters; clippy `unused_io_amount` (correctness, deny by default) is clean.

## Integers and casts

- **Decide what overflow means for every input-derived calculation.** Arithmetic overflow panics in debug builds and wraps in release builds (the default release profile has no overflow checks), so tests pass and production silently wraps. Check: lengths, offsets, money and counters from outside use `checked_*` (returning an error), `saturating_*` or `wrapping_*`, or `Wrapping` and `Saturating` types; crates where wrapping is a security bug set `overflow-checks = true` in `[profile.release]`; `arithmetic_side_effects` (restriction) for code that must never overflow.
- **Use `try_from` for narrowing conversions, not `as`.** `as` truncates larger integers, reinterprets sign, saturates floats and turns `NaN` into `0`, all without an error. Check: `u32::try_from(x)` and friends with the error handled; clippy `cast_possible_truncation`, `cast_sign_loss` and `cast_possible_wrap` (pedantic) are clean on changed files; a test feeds the maximum, a negative value and `NaN` where floats are cast.

## Async (tokio)

- **Keep blocking work off the runtime's worker threads.** One blocking call stalls every task on that worker; a rule of thumb is no more than 10 to 100 microseconds between `.await` points. Check: grep async code for `std::fs`, `std::thread::sleep`, `std::net`, `reqwest::blocking` and synchronous database clients; short blocking I/O goes through `tokio::task::spawn_blocking`, CPU-heavy work through `rayon` (result returned over a `oneshot` channel), and endless loops through a dedicated `std::thread`; `tokio-console` shows no task with long polls (Verify it).
- **Remember that `spawn_blocking` cannot be cancelled and shutdown waits for it.** `abort` does nothing once a blocking task started, and runtime shutdown waits indefinitely unless `shutdown_timeout` is used. Check: blocking tasks are bounded in time or check a stop flag; long-running services shut the runtime down with a timeout.
- **Do not hold a `std::sync::Mutex` or `RefCell` guard across `.await`.** It deadlocks or blocks the worker, and the `std` guard is not `Send`, so the future cannot move between threads. Check: clippy `await_holding_lock` and `await_holding_refcell_ref` (suspicious, warn by default) are clean; guards are dropped in an inner scope or with `drop(guard)` before the await. Prefer the `std` mutex for plain data; use `tokio::sync::Mutex` only when the guard must cross an await, such as for an I/O resource, or give the resource its own task and send it messages.
- **Make every future in a `select!` loop cancellation-safe.** `select!` drops the losing branches at their current await point. `read_exact`, `read_to_end`, `read_to_string` and `write_all` can lose data; `Mutex::lock`, `RwLock` locks, `Semaphore::acquire` and `Notify::notified` lose their place in the queue; `mpsc` and `broadcast` `recv`, `TcpListener::accept` and `Stream::next` are safe. Check: unsafe operations are started once outside the loop, pinned with `tokio::pin!`, and polled by `&mut` reference; a test cancels the operation mid-way (with `tokio::time::timeout`) and asserts nothing was lost or sent twice.
- **Give every spawned task an owner.** Dropping a `JoinHandle` detaches the task: it keeps running and its result, including a panic returned as `JoinError`, is lost. `abort` only takes effect at the task's next await. Check: tasks live in a `JoinSet` (aborted on drop, `shutdown()` aborts and waits) or their handles are awaited and the `JoinError` checked; shutdown cancels a `tokio_util::sync::CancellationToken` (children via `child_token`) and then awaits the tasks.
- **Box very large futures.** An `async fn` holding big arrays or deep state produces a large future that can overflow the stack when polled. Check: clippy `large_futures` (pedantic) on async-heavy crates; large futures are moved to the heap with `Box::pin` before being awaited or spawned.
- **Put a timeout on every external await.** `reqwest::ClientBuilder` sets no total, connect or read timeout by default, and a future can wait forever. Check: `Client::builder().timeout(..)` and `.connect_timeout(..)`, plus `tokio::time::timeout` around other network, IPC and lock waits (budgets from `reliability.md`).

## Send, Sync and Drop

- **Write `unsafe impl Send` or `Sync` only with a written proof.** These traits are derived automatically when every field qualifies; a wrong manual impl is undefined behaviour that other unsafe code will trust (Rustonomicon). Raw pointers, `UnsafeCell` and `Rc` are neither. Check: every `unsafe impl Send` or `Sync` has a `// SAFETY:` comment, bounds such as `where T: Send`, and a loom or Miri test of the concurrent use.
- **Keep public types `Send` and `Sync` where possible, and pin that down (C-SEND-SYNC).** An `Rc` or raw pointer added to a field silently removes both traits and breaks every downstream user who shares the type across threads. Check: a compile-time assertion such as `#[allow(dead_code)] fn assert_send_sync() { fn is<T: Send + Sync>() {} is::<MyType>(); }` for public types meant to be shared.
- **Do not "fix" a `!Send` future by switching mutex types blindly.** A spawn error about `Send` usually means a guard, `Rc` or `RefCell` lives across an await. Check: the fix narrows the guard's scope first; a type change comes with the reason; clippy `future_not_send` (nursery) helps on library code that must be spawnable.
- **Bind guards to a name; `let _ = ...` drops at once.** `let _ = mutex.lock()` releases the lock in the same statement, and `let _ = some_future` never runs the future. Check: guards use `let _guard = ...`; rustc's and clippy's `let_underscore_lock` and clippy `let_underscore_future` are clean.
- **Rely on drop order only where it is written down.** Locals drop in reverse declaration order and struct fields in declaration order; edition 2024 drops `if let` temporaries before the `else` block and tail-expression temporaries right after the tail expression. Check: a guard or handle that must outlive another is declared earlier (or placed later in the struct), with a comment; after an edition migration, rerun the tests around lock guards in `if let` and block tail expressions.
- **Keep `Drop` infallible and non-blocking, and offer an explicit close.** Errors in `drop` have nowhere to go (C-DTOR-FAIL, C-DTOR-BLOCK). Check: types wrapping files, connections or buffers expose `close`, `flush` or `finish` returning `Result`; `drop` only logs; tests call the explicit method.

## Unsafe code

- **Forbid `unsafe` where it is not needed, and justify each block where it is.** Every unsafe block is a promise the compiler cannot check. Check: crates without unsafe set `[lints.rust] unsafe_code = "forbid"`; elsewhere each block has a `// SAFETY:` comment on the lines before it (`undocumented_unsafe_blocks`, restriction) and does one unsafe operation (`multiple_unsafe_ops_per_block`).
- **Put unsafe operations inside `unsafe {}` even within an `unsafe fn`.** From edition 2024 `unsafe_op_in_unsafe_fn` warns, because `unsafe fn` now only means callers have obligations. Check: no `unsafe_op_in_unsafe_fn` warnings; `extern` blocks are `unsafe extern` and attributes such as `no_mangle` are written `#[unsafe(no_mangle)]` on edition 2024.
- **Never make soundness depend on a destructor running.** `std::mem::forget` is safe, so any value may be leaked without its `Drop`. Check: unsafe code that hands out references or guards stays sound if the guard is forgotten; clippy `mem_forget` flags deliberate uses.
- **Run Miri over every test that reaches changed unsafe code.** It catches out-of-bounds access, use-after-free, uninitialised reads, invalid values, misalignment, data races, aliasing violations and leaks, but only on paths that run, and it cannot run most FFI or networking. Check: `cargo +nightly miri test` on the affected crate or tests is clean; `MIRIFLAGS="-Zmiri-many-seeds"` for code with threads; a clean Miri run is evidence, not a proof of soundness.
- **Model-check atomics and lock-free code with loom.** Ordinary tests and Miri explore few interleavings. Check: loom tests use `loom::model` with `loom::sync` and `loom::thread` types behind `cfg(loom)` and run under `RUSTFLAGS="--cfg loom" cargo test --release`; note that loom treats `SeqCst` accesses as `AcqRel` and skips some C11 behaviours such as load buffering. Sanitizers: `testing.md`.

## Dependencies, features and lints

- **Check every new API against the locked crate version and the MSRV.** Models reach for deprecated or newer signatures (`agent-process.md`). Check: the version comes from `Cargo.lock` and its docs.rs page; `rust-version` in `Cargo.toml` is respected (clippy `incompatible_msrv`, suspicious, warn by default); no new `deprecated` warnings in changed lines.
- **Keep features additive and test the combinations.** Cargo unifies features across the dependency graph, so a feature that removes behaviour breaks some other crate's build. Check: no mutually exclusive features (or a `compile_error!` when both are on); CI builds and tests with default features, `--no-default-features` and `--all-features`; `cargo tree -e features -i <crate>` explains why a feature is on.
- **Audit dependencies for advisories, licences, bans and sources.** Check: `cargo deny check` (advisories including unmaintained and yanked crates, licences, banned and duplicate crates, allowed sources) or `cargo audit` against `Cargo.lock`; run `cargo audit` only on trusted checkouts, since a missing lockfile is generated by running project code; `cargo audit bin` on release binaries built with `cargo auditable`. Supply-chain policy: `security.md`.
- **Configure lints in `[lints]` (Cargo 1.74), and give every `allow` a reason.** Scattered `#![allow]` attributes hide findings, and an `allow` added to get green is a loosened check (`testing.md`). Check: lint levels live in `[lints.rust]` and `[lints.clippy]`; new `#[allow(..)]` uses `reason = ".."` (`allow_attributes_without_reason`, restriction); new `#[ignore]` on a test is reported as a loosened test; do not enable the whole `restriction` group, pick lints one by one.
- **Gate on clippy with warnings denied.** Check: on Cargo 1.97+ `CARGO_BUILD_WARNINGS=deny cargo clippy --all-targets --all-features` (keeps the build cache); on older Cargo `cargo clippy --all-targets --all-features -- -D warnings`; `pedantic` only where the project already adopted it.

## Tests and fuzzing

- **Run the whole suite, doc tests included.** Check: `cargo test --all-targets` plus `cargo test --doc` (doc tests are not part of `--all-targets`); shuffled order needs nightly libtest (`testing.md`).
- **Fuzz parsers, decoders and anything handling hostile bytes.** Check: `cargo fuzz run <target> -- -max_total_time=300` on touched parsers (nightly, libFuzzer); structured inputs derive `arbitrary::Arbitrary`; crashes land in `fuzz/artifacts/<target>/`, are minimised with `cargo fuzz tmin` and become a regular unit test committed with the fix.
- **Kill surviving mutants in changed code.** Check: `cargo mutants --in-diff` as in `testing.md`; missed mutants in changed lines are killed or explained.

## Verify it

```bash
CARGO_BUILD_WARNINGS=deny cargo clippy --all-targets --all-features   # Cargo < 1.97: cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets && cargo test --doc
cargo test --no-default-features && cargo test --all-features
cargo deny check                    # or: cargo audit
cargo build --release
```

- Unsafe changed: `rustup +nightly component add miri && cargo +nightly miri test`; with threads, `MIRIFLAGS="-Zmiri-many-seeds" cargo +nightly miri test`.
- Atomics or lock-free code changed: `RUSTFLAGS="--cfg loom" cargo test --release --lib`.
- Fuzz: `cargo +nightly fuzz run <target> -- -max_total_time=300`; replay with `cargo +nightly fuzz run <target> fuzz/artifacts/<target>/<file>`.
- Stuck or slow tasks: build with `console-subscriber` and `RUSTFLAGS="--cfg tokio_unstable"`, run the flow, and read `tokio-console` for tasks with long poll times or that never complete.
- Prove the gate can fail: hold a `std` mutex guard across an `.await` in a scratch copy and watch clippy go red (`agent-process.md`).

## Sources

- The Rust Programming Language (Rust Book), The Rust Reference, The Rustonomicon, the Rust Edition Guide and the Cargo Book, rust-lang (MIT OR Apache-2.0): adapted (panic versus `Result`, overflow and `as` cast semantics, drop order and edition 2024 temporaries, `Send` and `Sync`, `unsafe_op_in_unsafe_fn`, additive features, `[lints]` table).
- Rust API Guidelines, rust-lang (MIT OR Apache-2.0): adapted (C-GOOD-ERR, C-FAILURE, C-DTOR-FAIL, C-DTOR-BLOCK).
- Rust standard library documentation, `std::sync::Mutex` (MIT OR Apache-2.0): adapted (poisoning, re-locking, guard scope).
- rust-lang/rust-clippy README and lint list (MIT OR Apache-2.0): adapted (lint groups and default levels, `CARGO_BUILD_WARNINGS`, lint names and test allowances).
- tokio and tokio-util documentation (MIT): adapted (cancellation safety lists, `spawn_blocking` limits, mutex choice, `JoinHandle`, `JoinSet`, `CancellationToken`).
- Alice Ryhl, "Async: What is blocking?" (blog, no licence stated; ideas and numbers only): 10 to 100 microseconds between awaits, choice between `spawn_blocking`, rayon and a thread.
- reqwest `ClientBuilder` documentation (vendor docs, facts only): no default total, connect or read timeout.
- dtolnay/thiserror and dtolnay/anyhow (MIT OR Apache-2.0): adapted (library versus application error handling).
- rust-lang/miri (MIT OR Apache-2.0), tokio-rs/loom (MIT): adapted (what each detects, flags, limitations).
- EmbarkStudios/cargo-deny and rustsec/cargo-audit (MIT OR Apache-2.0), rust-fuzz/cargo-fuzz (MIT OR Apache-2.0), sourcefrog/cargo-mutants (MIT): tool use only, commands and behaviour.
- Wang et al., "How and Why LLMs Use Deprecated APIs in Code Completion?", ICSE 2025 (paper, facts only): deprecated and version-mismatched API use.
