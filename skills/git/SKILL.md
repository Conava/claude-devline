---
name: git
description: Commit, push, or open a pull request with a Conventional Commit message and a PR body the user can edit before it is posted. Use when the user asks to commit, commit and push, push the branch, open/create a PR, write a commit message, or write a PR description, and when devline or quick reach their commit step. Do not use for general git questions (how rebase works, reading history, resolving a conflict).
argument-hint: "[commit|push|pr] [notes]"
user-invocable: true
disable-model-invocation: false
---

# Git — Commit, Push, Pull Request

You make the commits, pushes and pull requests devline produces on the user's behalf. The goal is a commit message and a PR body the user would post without editing.

## Defaults

A later config layer may override these; until then they apply as written. The rest of this skill refers to them instead of repeating values.

- **Protected branches** (`protected_branches`): main, master, develop, release, production, staging.
- **Branch names**: `branch_format` `{kind}/{title}`; `branch_kinds` feat, fix, refactor, docs, chore, test, ci. Values in `.claude/devline.local.md` win.
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

Each mode includes the one before it. Free text maps to the nearest mode ("commit and push" is `push`, "open a PR" is `pr`). `push` and `pr` skip the commit step when the tree is clean. Notes after the mode, and any context paths a caller passes, feed the *why*. If `.devline/brainstorm.md` or `.devline/plan.md` exist and their `**Branch:**` matches the current branch, read them for the reason behind the change.

## Branch guard (all modes)

Read `protected_branches`, `branch_format` and `branch_kinds` from `.claude/devline.local.md`, falling back to the Defaults. If the current branch is protected:

- `commit`: ask whether to branch off first. Offer a name built from `branch_format`, with `{kind}` taken from the commit type when it is one of `branch_kinds` (otherwise `chore`) and `{title}` a short kebab-case summary.
- `push` / `pr`: do not push to it without an explicit yes. Offer to branch off as above. In a non-interactive run, stop and report instead of pushing.

## Staging

1. Read `git status` and `git diff` (plus `git diff --staged`) before touching anything.
2. Stage the files that belong to the change by name. Never `git add -A` or `git add .`.
3. Never stage secrets (`.env`, keys, tokens, credentials) or junk (build output, caches, editor files, logs). Mention anything suspicious you left out.
4. If the tree holds unrelated changes, propose separate commits, one per logical change, and say which files go where. Do not fold them into one mixed commit.

## Commit message

**Subject:** `type(scope)!: summary`. Imperative mood, lowercase after the colon, no trailing period, within the Defaults length. Scope is optional; use it when the change sits in one clear area.

Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `ci`, `perf`, `build`, `style`. Add `!` and a `BREAKING CHANGE:` footer when behaviour users rely on changes.

**Body** (omit it for trivial changes such as a typo):

- First, why the change was needed: the bug, the limitation, the request.
- Then what it does, at a level the code does not show: the approach, the trade-off, what now behaves differently.
- Never list files, restate the diff line by line, or narrate ("This commit...", "This PR...").

The message text follows the `writing` skill's rules; apply them.

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
- Rejected push: stop. Run `git fetch`, explain how local and remote diverged, and ask what to do. Do not force push on your own initiative.
- The user asks to update a rebased or amended branch: `git push --force-with-lease`, never bare `--force`.

## PR mode

1. **Base:** the repo default (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`) unless the user named one. State the base you use.
2. **Title:** the same Conventional Commits form as a subject; squash merges use it as the commit subject.
3. **Template:** if `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/` exists, its structure wins and the content below fills it.
4. **Body sections**, in this order, omitting any that would be empty:
   - **Background**: the problem or need, in a few sentences.
   - **What it does**: the change in the abstract, a few sentences.
   - **Details**: only what a reviewer needs to judge the change. Add a small diff sketch, call tree or file tree only if it makes a point clearer than prose.
   - **Screenshots**: UI changes only. Capture headlessly with what the project already has (Playwright, an existing screenshot script), save to the Defaults assets directory, and put one placeholder line per image in the body. `gh` cannot upload images, so tell the user to drag them into the PR on GitHub. If nothing can capture, say so and leave the placeholder. Never install a tool for this.
   - **How to verify**: exact commands or steps, and what the reviewer should see.
5. **Write** the body to the Defaults PR body file. Create `.devline/` and add it to `.gitignore` first if either is missing. Print the proposed title and the absolute path of the file, then stop and wait for the user.
6. **Post** only when the user says so: `gh pr create --base <base> --title "<title>" --body-file .devline/pr-body.md`, then report the PR URL. Never run `gh pr merge`; merging is the user's call.

No `gh`, not authenticated, or no remote: say so and stop after writing the file.

Prose in the body follows the `writing` skill as well. Skip preambles; evidence (before/after, test output) beats adjectives.

## Hooks

devline's hooks ask before a bare force push and before `gh pr merge`. `--force-with-lease` and `gh pr create` pass. When a hook asks, put the question to the user; never rephrase or split a command to get around it.

## Credits

Paraphrased, not copied, from:

- obra/superpowers, `finishing-a-development-branch` (MIT): the user owns the integration decision, confirm the base, investigate a rejected push instead of forcing it, follow the repo's PR template.
- mattpocock/skills, `pr` (MIT; its summary section credits humanlayer `show-me`): brief prose, evidence over description, a small visual only when it clarifies.
- Conventional Commits 1.0.0 (CC-BY-3.0): the subject and `BREAKING CHANGE:` format.
