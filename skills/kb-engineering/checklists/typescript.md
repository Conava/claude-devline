# TypeScript and JavaScript checklist

Selected for TypeScript projects (`tsconfig.json`, `.ts` or `.tsx` files) on Node or in the browser, and for plain JavaScript projects with a `package.json`. Read it together with `backend.md` for a server or CLI, `web.md` for a browser frontend and `desktop.md` for Electron. Plain JavaScript: the Promises, Trust boundaries, Node runtime, Modules and Dependencies groups apply as written; the Compiler group applies only once the project type-checks its JavaScript (`checkJs` or `// @ts-check`), which you suggest rather than add uninvited.

## Compiler as a gate

- **Run `tsc --noEmit` as its own gate, on a config that includes the tests.** Bundlers (Vite, esbuild, swc) and Node's type stripping drop types without checking them, so a build can be green with type errors; and with tests excluded from the checked project, stale fixtures using an old field shape compile silently while the component they test is broken. Check: `npx tsc --noEmit -p <config>` exits 0 and the config's `include` covers test files (or a separate `tsconfig.test.json` is checked too); with project references, `npx tsc -b`.
- **Keep `strict` on and know what it does not cover.** `strict` turns on the strict family (`strictNullChecks`, `noImplicitAny`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitThis`, `useUnknownInCatchVariables`, `alwaysStrict`, `strictBuiltinIteratorReturn`), but not `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, `noFallthroughCasesInSwitch` or `noPropertyAccessFromIndexSignature`. Check: read `tsconfig.json` (and every config it `extends`); never turn a strict flag off to make a change compile.
- **Turn on `noUncheckedIndexedAccess` for new projects, and handle `undefined` where it already is.** Without it, `record[key]` and `arr[i]` are typed as present even when missing, which is where most runtime `undefined` errors come from. Check: the flag is set, or for an existing project lookups on records, maps from parsed input and array indexes are narrowed before use; suggest the flag to the owner rather than flipping it in an unrelated change.
- **Respect `exactOptionalPropertyTypes` and `noImplicitOverride` where they are set.** The first makes "absent" and "present but `undefined`" different types, which matters for PATCH bodies and spread merges; the second requires `override` so a renamed base method cannot leave a subclass method silently orphaned. Check: no `as` cast added to get around either flag; overriding members carry `override`.
- **Treat `any`, `as`, `!` and `@ts-ignore` as unchecked claims.** Each one tells the compiler to stop checking, and `JSON.parse`, `response.json()` and untyped libraries return `any` that spreads through the code. Check: no new explicit `any` (`@typescript-eslint/no-explicit-any`); the `no-unsafe-assignment`, `no-unsafe-argument`, `no-unsafe-call`, `no-unsafe-member-access` and `no-unsafe-return` rules are clean on changed files; `@ts-expect-error` with a reason instead of `@ts-ignore`; `unknown` plus a schema (Trust boundaries) instead of a cast.
- **Use `satisfies` to check a literal against a type without widening it.** An annotation replaces the inferred type with the declared one and loses the specific keys and value types; `satisfies` (TypeScript 4.9+) checks the same thing and keeps them. Check: config objects, route tables and lookup maps use `satisfies Record<K, V>` where callers need the narrow types; no `as const as T` chains.
- **Model states as discriminated unions and make switches exhaustive.** A union with a literal `kind` field lets the compiler narrow each branch, and a `default` branch that assigns the value to `never` fails to compile when a new member is added. Check: switches over a union end in `default: { const unreachable: never = value; throw new Error(...) }` or the project enables `@typescript-eslint/switch-exhaustiveness-check`; no boolean flag pairs (`isLoading`, `isError`) that can both be true.
- **Look up new APIs in the installed version's types, and keep deprecation warnings at zero.** Models reach for deprecated or invented signatures, more often when the surrounding code is old (`agent-process.md`, "Check every API against the installed or released version"). Check: the version comes from the lockfile; `@typescript-eslint/no-deprecated` (or the editor's strikethrough) shows nothing new in changed lines.

## Promises and async

- **Never leave a promise floating.** An un-awaited promise loses its rejection and its ordering, and passes locally while flaking in CI; `void promise` silences the lint but still leaves the rejection unhandled. Check: `@typescript-eslint/no-floating-promises` (in `recommended-type-checked`, needs type information) is on for app and test code; each intentional fire-and-forget has a `.catch` that reports; arrays of promises go through `Promise.all` or `Promise.allSettled`.
- **Do not pass async functions where a `void` callback is expected.** `forEach`, `addEventListener` and most event emitters ignore the returned promise, so rejections go nowhere and iterations overlap. Check: `@typescript-eslint/no-misused-promises` is clean (it also catches `if (promise)` and spreading a promise); loops that await use `for...of` or `Promise.all`.
- **Pick `Promise.all` or `Promise.allSettled` on purpose.** `all` rejects on the first failure while the other operations keep running; `allSettled` never rejects, so failures must be read out of the results. Check: after `allSettled`, the code inspects each `status === 'rejected'`; concurrency over large lists is bounded (`reliability.md`, "Bound every queue and buffer").
- **Make conditions boolean on purpose.** Truthiness treats `0`, `NaN` and `""` like `null`, so a count of zero or an empty name takes the "missing" branch. Check: comparisons are explicit (`!== undefined`, `.length > 0`); where the project uses typed linting, suggest `@typescript-eslint/strict-boolean-expressions`, which no stable shared config enables.
- **Narrow `catch (e)` before using it.** Under `strict`, `e` is `unknown` (`useUnknownInCatchVariables`) because anything can be thrown. Check: handlers use `e instanceof Error` or a type guard before reading `.message`; throws use `Error` subclasses, and `new Error(msg, { cause: e })` keeps the original when wrapping (`reliability.md`, "Wrap errors once with context").

## Trust boundaries and runtime validation

- **Validate data at every trust boundary with a runtime schema; types vanish at runtime.** A TypeScript type on `await res.json()`, `JSON.parse`, `process.env`, `localStorage`, `postMessage`, a message queue or a config file is a promise nobody checks. Check: each boundary parses `unknown` through the project's schema library (zod, valibot, arktype or similar; add one only with the owner's agreement) and derives the static type from the schema (`z.infer`); a test sends a wrong-typed payload and expects the error path. The general input rules are in `backend.md` API and `reliability.md` Hostile input.
- **Know your schema library's defaults for unknown keys and coercion.** In zod, `z.object` strips unknown keys silently, `z.strictObject` rejects them and `z.looseObject` passes them through; `z.coerce.string()` turns `null` into `"null"`. Check: request bodies that must not carry extra fields use the strict variant; coercion is used only where the input is known to be a string (query parameters, environment variables); `safeParse` results are branched on `success`, not cast.
- **Parse configuration once at startup and fail fast.** Scattered `process.env.X!` reads fail at the first request. Check: one module parses the environment through a schema at boot and exports the typed result; starting with a missing variable exits non-zero naming it (`backend.md`, Config and lifecycle).

## Node runtime

- **Let unhandled rejections crash the process, under a supervisor.** Since Node 15 the default `--unhandled-rejections` mode is `throw`, and continuing in an unknown state corrupts data. Check: no `process.on('unhandledRejection', () => {})` that swallows; a process manager, container restart policy or systemd restarts with backoff; programmer errors (`TypeError`, `ReferenceError`) are not handled as operational ones (`reliability.md` Errors).
- **Pass a timeout signal to `fetch` and every cancellable call.** `fetch` has no overall timeout, and undici's header and body timeouts are 300 seconds each. Check: every `fetch(` passes `signal: AbortSignal.timeout(ms)` (Node 17.3+), combined with a caller's signal through `AbortSignal.any` (Node 20.3+); a timed-out call rejects with a `TimeoutError`, an aborted one with an `AbortError`, and the handler tells them apart.
- **Set the HTTP server timeouts deliberately.** `server.requestTimeout` defaults to 300 s (since Node 18), `headersTimeout` to 60 s, and `server.timeout` to 0, which is none. Check: the values are set for the service's latency budget and `keepAliveTimeout` is above the load balancer's idle timeout.
- **Close the server and drain on SIGTERM.** Without `server.close()` and in-flight tracking, a deploy drops requests. Check: the `SIGTERM` handler stops accepting, awaits in-flight work within a deadline and exits (`backend.md`, "Handle SIGTERM").
- **Keep the event loop free.** Synchronous `fs`, `zlib`, `crypto` (`pbkdf2Sync`, `randomFillSync`) and `child_process` (`execSync`, `spawnSync`) calls, `JSON.parse` of large input (about 1.3 s for 50 MB in the Node guide's benchmark) and regexes with nested quantifiers on attacker input (ReDoS) stall every request. Check: no `*Sync` calls on request paths; input size is capped before parsing; new regexes on external input avoid nested quantifiers and overlapping alternation; event-loop delay under load is measured with `perf_hooks.monitorEventLoopDelay()`; CPU work moves to `worker_threads`.
- **Respect stream backpressure and connect streams with `pipeline`.** Ignoring `write()` returning `false` queues data in memory: the Node guide measured 1.52 GB instead of 88 MB for the same gzip job. `.pipe()` attaches no error handlers and leaves the other streams open when one fails. Check: writers wait for `'drain'` after `false`; streams are joined with `await pipeline(...)` from `node:stream/promises`, inside a `try`.
- **Watch for deprecation warnings at runtime.** Node prints them once and moves on. Check: test runs use `--trace-deprecation` or `--throw-deprecation`, and the log scan (`testing.md`, Logs are part of the result) finds no `DeprecationWarning`.

## Modules and running TypeScript

- **Know how each file is loaded.** `.mjs`/`.mts` are always ESM, `.cjs`/`.cts` always CommonJS, and `.js`/`.ts` follow the nearest `package.json` `"type"` field (with no field, Node guesses from the syntax). Check: `"type"` is set explicitly; `tsconfig` uses `module` and `moduleResolution` `nodenext` for Node code so the compiler applies the same rules; relative imports carry file extensions where Node resolves them.
- **Use `require()` of ESM only where every supported Node version has it.** It is unflagged from Node 20.19 and 22.12, and throws `ERR_REQUIRE_ASYNC_MODULE` when the module graph has top-level `await`. Check: `engines.node` in `package.json` matches the CI matrix; CommonJS code that loads an ESM-only dependency uses `import()` on older lines.
- **Running `.ts` directly on Node strips types and checks nothing.** Type stripping is on by default from Node 22.18 and 23.6 (stable from 24.12 and 25.2), ignores `tsconfig.json` (so `paths` do not work), does not support `.tsx`, refuses files under `node_modules`, and throws `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX` on enums, namespaces with values, parameter properties and import aliases. Check: such projects set `erasableSyntaxOnly` and `verbatimModuleSyntax` so `tsc` flags those constructs and type-only imports use `import type`; `tsc --noEmit` still runs as the gate.

## Dependencies and supply chain

- **Install from the lockfile.** `npm ci` refuses to run when `package.json` and the lockfile disagree, deletes `node_modules` first and never writes either file. Check: CI and verification use `npm ci`, `pnpm install --frozen-lockfile` or `yarn install --immutable` (`security.md`, "Commit the lockfile and install from it"); never `npm install` inside a worktree that shares `node_modules` with another checkout.
- **Look every new package up on the registry before adding it.** Models invent plausible names and attackers register them (`security.md`, "Look up every new package name on the registry before adding it"). Check: `npm view <name> repository time.created` matches the intended project; a `@types/` package exists only where the library ships no types.
- **Audit dependencies and their signatures.** Check: `npm audit --audit-level=high` (exits non-zero at or above the level) and `npm audit signatures` (registry signatures and provenance) after dependency changes; findings in runtime dependencies are fixed or reported.
- **Pin `typescript-eslint` and read its changelog before upgrading when using `strict-type-checked`.** The `strict` configs may change their rules in minor releases, so an unpinned upgrade can fail CI unrelated to the change. Check: the version is exact or locked; new lint failures after an upgrade are reported, not silenced.

## Tests

- **Test types that are part of the contract.** Public generics, overloads and inferred return types can regress while every runtime test passes. Check: type tests with `expectTypeOf` or `assertType` in `*.test-d.ts` run under `vitest --typecheck` (which runs `tsc --noEmit`), or `tsd`/`expect-type` where the project uses them; a type test that expects an error is also run as a normal test, because `@ts-expect-error` passes on a typo in the variable name.
- **Run the runtime tests in the runtime that ships.** jsdom and Node differ from browsers, and Node from embedded JavaScript engines. Check: `testing.md`, "The test runtime is not the production runtime", and real-browser checks in `web.md`.
- **Lint test files with the same typed rules.** A missing `await` on an assertion or a Playwright call passes locally and flakes in CI (`web.md`, "Lint for missing `await`"). Check: the ESLint config's `files` and `parserOptions.projectService: true` cover test files.

## Verify it

Gate, each as its own command (Node project; replace `npm` with the project's package manager):

```bash
npm ci
npx tsc --noEmit            # or: npx tsc -b for project references
npx eslint .                # typed linting via projectService
npm test                    # with vitest: npx vitest run --typecheck
npm run build
npm audit --audit-level=high && npm audit signatures
```

Typed lint config (flat, `eslint.config.mjs`), the base to compare against:

```js
import js from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig({
  files: ['**/*.{js,mjs,cjs,ts,mts,cts,tsx}'],
  extends: [js.configs.recommended, tseslint.configs.recommendedTypeChecked],
  languageOptions: { parserOptions: { projectService: true } },
});
```

Runtime warnings in a real run: `node --trace-deprecation --trace-warnings dist/server.js` under the sandbox from `backend.md` Verify it, then scan the log for `DeprecationWarning`, `UnhandledPromiseRejection` and `MaxListenersExceededWarning`.

Event-loop delay under load (inside the service, logged at shutdown): `const h = perf_hooks.monitorEventLoopDelay({ resolution: 20 }); h.enable();` then log `h.percentile(99) / 1e6` ms.

## Sources

- TypeScript handbook and TSConfig reference (Apache-2.0, adapted): strict family membership, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, `useUnknownInCatchVariables`, `satisfies` (TypeScript 4.9 release notes), discriminated unions and `never` exhaustiveness (Narrowing chapter).
- typescript-eslint documentation (MIT, adapted): `no-floating-promises` (type information, `ignoreVoid` caveat), `no-misused-promises`, `no-unsafe-*` family, `strict-boolean-expressions`, typed linting with `projectService`, stability of the `strict` configs.
- Node.js documentation (MIT, adapted; rechecked 2026-11): `--unhandled-rejections` default since v15, `AbortSignal.timeout` and `AbortSignal.any` versions, TypeScript type stripping (default from 22.18 and 23.6, stable from 24.12 and 25.2, unsupported syntax, no type checking), `require(esm)` versions and `ERR_REQUIRE_ASYNC_MODULE`, the `"type"` field; Node.js guides "Don't block the event loop" and "Backpressuring in streams" (sync APIs, ReDoS, JSON timings, `pipeline`, memory figures).
- WHATWG DOM Standard (CC-BY-4.0, facts only): `TimeoutError` and `AbortError` reasons.
- zod documentation (MIT, adapted): `parse` and `safeParse`, `z.infer`, unknown-key handling, coercion; valibot documentation (MIT, ideas only): types are not executed, schemas validate unknown data at runtime.
- Vitest documentation (MIT, adapted): type tests, `--typecheck`, the `@ts-expect-error` typo caveat.
- npm CLI documentation (Artistic-2.0, facts only): `npm ci` behaviour, `npm audit --audit-level`, `npm audit signatures`.
- goldbergyoni/nodebestpractices (CC-BY-SA, paraphrased): crash on unknown state, process manager.
- Scientific findings on LLM-written code, facts only: Spracklen et al., package hallucinations (USENIX Security 2025); Wang et al., deprecated API usage (ICSE 2025).
- Lessons from real agent mistakes in own projects, kept where they hold for any TypeScript codebase: original text under the project licence.
