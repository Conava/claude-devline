---
name: git
description: Commit, push, or open a pull request with a Conventional Commit message and a PR body the user can edit before it is posted. Use when the user asks to commit, commit and push, push the branch, open/create a PR, write a commit message, or write a PR description. Do not use for general git questions.
argument-hint: "[commit|push|pr] [notes]"
user-invocable: true
disable-model-invocation: false
---

# Git — Commit, Push, Pull Request

You handle commits, pushes and pull requests during or at the end of a devline pipeline or fast lane, or whenever the user asks. The goal is a commit message and a PR body the user would write themselves.

## Defaults

The devline config files override any value here; lookup and precedence: `${CLAUDE_PLUGIN_ROOT}/skills/setup/references/config.md`. Git policy written as prose in those files (squash merges, a PR for every change, commit size) wins over these defaults too. The rest of this skill refers to these values instead of repeating them.

- **Protected branches** (`protected_branches`): main, master, develop, release, production, staging.
- **Branch names**: `branch_format` `{kind}/{title}`; `branch_kinds` feat, fix, refactor, docs, chore, test, ci.
- **Granularity**: one commit per logical change.
- **Subject**: at most 72 characters. Body wrapped at 72.
- **PR body file**: `.devline/pr-body.md`; screenshots in `.devline/pr-assets/`.
- **Never** force push on your own initiative, never run `gh pr merge`, never push to a protected branch without an explicit yes.

## Modes

```
/devline:git [commit|push|pr] [notes]     (no argument: commit)
  commit : branch guard -> stage the related files -> Conventional Commit
  push   : commit (if anything is pending) -> push the current branch
  pr     : commit + push -> PR body file -> user edits -> gh pr create
```

Each mode includes the one before it. Free text maps to the nearest mode ("commit and push" is `push`, "open a PR" is `pr`). `push` and `pr` skip the commit step when the tree is clean. A request only for a message or description is draft-only: print the commit message, or write the PR body file, and do not commit, push or post unless the user asked to. Notes after the mode, and any context paths a caller passes, feed the *why*. If `.devline/plan.md` exists and its `**Branch:**` matches the current branch, read it, and `.devline/brainstorm.md` too (it has no branch header), for the reason behind the change.

## Branch guard (all modes)

Resolve `protected_branches`, `branch_format` and `branch_kinds` from the config, falling back to the Defaults. If the current branch is protected:

- `commit`: ask whether to branch off first. Offer a name built from `branch_format`, with `{kind}` taken from the commit type when it is one of `branch_kinds` (otherwise `chore`) and `{title}` a short kebab-case summary.
- `push` / `pr`: offer to branch off as above. If the user declines, push only after an explicit yes to pushing to that branch.
- Non-interactive run: stop and report; do not commit on the protected branch.

## Staging

1. Read `git status` and `git diff` (plus `git diff --staged`) before touching anything.
2. Stage the files that belong to the change by name. Never `git add -A` or `git add .`.
3. Never stage secrets (`.env`, keys, tokens, credentials), junk (build output, caches, editor files, logs) or `.devline/`. If `.devline/` is not ignored, add it to `.git/info/exclude` first (local, no tracked-file change). Mention anything suspicious you left out.
4. If the tree holds unrelated changes, propose separate commits, one per logical change, and say which files go where. Do not fold them into one mixed commit.

## Commit message

**Subject:** `type(scope)!: summary`. Imperative mood, lowercase after the colon, no trailing period, within the Defaults length. Scope is optional; use it when the change sits in one clear area.

Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `ci`, `perf`, `build`, `style`. Add `!` and a `BREAKING CHANGE:` footer when behaviour users rely on changes.

**Body** (omit it for trivial changes such as a typo):

- First, why the change was needed: the bug, the limitation, the request.
- Then what it does, at a level the code does not show: the approach, the trade-off, what now behaves differently.
- Never list files, restate the diff line by line, or narrate ("This commit...", "This PR...").

Message text and the PR body follow the `writing` skill. Skip preambles; evidence (before/after, test output) beats adjectives.

Example shape:

```
fix(parser): keep quoted commas inside one field

CSV rows with a quoted value such as "Smith, Jane" were split into two
columns, so imports silently shifted every later field.

The tokenizer now tracks quote state and only treats a comma as a
separator outside quotes. Escaped quotes ("") inside a field still work.
```

Pass the message with a heredoc (`git commit -F - <<'EOF'`) or a `-F` file so line breaks survive.

**Failures:** if a pre-commit hook fails, fix the cause, re-stage and make a new commit. Never `--no-verify`. Never `--amend` unless the user asked for it.

## Push

- No upstream yet: `git push -u origin <branch>`. Otherwise `git push`.
- Rejected push: stop. Run `git fetch`, explain how local and remote diverged, and ask what to do.
- The user asks to update a rebased or amended branch: `git push --force-with-lease`, never bare `--force`.

## PR mode

1. **Base:** the repo default (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`) unless the user named one. State the base you use.
2. **Title:** the same Conventional Commits form as a subject; squash merges use it as the commit subject.
3. **Template:** if `pull_request_template.md` (any case) exists in the repo root, `docs/` or `.github/`, or `.github/PULL_REQUEST_TEMPLATE/` exists, its structure wins and the content below fills it.
4. **Body** (no template), in this order, omitting any part that would be empty:
   - `## Description`: a very short overview of what the change does and why: the intended effect, the use case, the issue it addresses. A few sentences.
   - Technical details below it, as plain paragraphs or a short list: how it works, trade-offs, notable side effects, `Closes #N` for closed issues. Only what a reviewer needs to judge the change; a small diff sketch or tree only when it is clearer than prose.
   - **Screenshots**: UI changes only. Capture headlessly with what the project already has (Playwright, an existing screenshot script), save to the Defaults assets directory, and put one placeholder line per image in the body. `gh` cannot upload images, so tell the user to drag them into the PR on GitHub. If nothing can capture, say so and leave the placeholder. Never install a tool for this.
   - `## Verification`: only when a reviewer can't easily tell how to check the change. Short: the command or steps and what they should see.

   No generic section names such as "Background" or "What it does".
5. **Write** the body to the Defaults PR body file. Create `.devline/` first if missing, and exclude it per Staging. Print the proposed title and the absolute path of the file, then stop and wait for the user.
6. **Post** only when the user says so. If `gh pr view` shows an open PR for the branch, offer `gh pr edit --body-file .devline/pr-body.md` instead. Otherwise `gh pr create --base <base> --title "<title>" --body-file .devline/pr-body.md`, then report the PR URL. Never run `gh pr merge`; merging is the user's call.

No `gh`, not authenticated, or no remote: say so and stop after writing the file.

## Hooks

When devline's hooks are active (they skip in default permission mode), they ask before a bare force push and before `gh pr merge`; `--force-with-lease` and `gh pr create` pass. The rules in this skill apply either way. When a hook asks, put the question to the user; never rephrase or split a command to get around it.

## Credits

Paraphrased, not copied, from:

- obra/superpowers, `finishing-a-development-branch` (MIT): the user owns the integration decision, confirm the base, investigate a rejected push instead of forcing it, follow the repo's PR template.
- mattpocock/skills, `pr` (MIT; its summary section credits humanlayer `show-me`): brief prose, evidence over description, a small visual only when it clarifies.
- Conventional Commits 1.0.0 (CC-BY-3.0): the subject and `BREAKING CHANGE:` format.
