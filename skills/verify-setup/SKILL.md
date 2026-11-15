---
name: verify-setup
description: "Set up how changes to this project are verified: gate command, sandboxed real-app run, fakes, log scanning, budgets. Use when the user asks to set up verification, a verify recipe, a CI gate, or budgets for the current project."
argument-hint: "[focus, e.g. 'budgets' or 'desktop run']"
user-invocable: true
disable-model-invocation: false
---

# Verify setup

Offer the user a verification setup fitted to this project, write only what they pick, and prove it runs. The output is Claude Code's native project skill `.claude/skills/verify/SKILL.md`, which Claude Code (2.1.286 and later) prompts Claude to run before each commit, docs-only and tests-only commits excepted. It is a prompt, not an enforced hook.

Focus requested by the user: $ARGUMENTS

If a focus is given, limit the inventory report and the proposal to it.

## Knowledge files

Read these first. Paths resolve through the plugin root, so they work from any project directory.

- Setup recipe, inventory, proposal menu and recipe template: `${CLAUDE_PLUGIN_ROOT}/skills/kb-engineering/references/setup.md`
- Stack detection table and checklist selection: `${CLAUDE_PLUGIN_ROOT}/skills/kb-engineering/SKILL.md`
- Per-stack "Verify it" sections: `${CLAUDE_PLUGIN_ROOT}/skills/kb-engineering/checklists/<file>.md` for the checklists the stack table selects
- Optional resource sampler (copy only if the user picks budgets): `${CLAUDE_PLUGIN_ROOT}/skills/kb-engineering/helpers/procbudget.py`

## Flow

1. **Inventory.** Follow the inventory in `setup.md` against the current project. Report what exists: stack, the gate and the command CI runs, any `.claude/skills/verify/` or `run-*` skills, external dependencies, tools present and missing. Check `claude --version` against 2.1.286.
2. **Propose.** Present the menu from `setup.md`, trimmed to what fits the findings. For each item give a recommendation, the reason and the cost. Ask which to set up. Do not write anything before the user answers.
3. **Write only what was chosen.** The recipe goes to `.claude/skills/verify/SKILL.md`, built from the `setup.md` template with every placeholder replaced and only the picked parts kept. Other choices: gate or CI edits, a commands line in `CLAUDE.md`, a copy of `procbudget.py` into the project's script directory with its SPDX header. If a file already exists, show the diff you intend and ask before replacing it. If writing under `.claude/` needs approval that cannot be given (a non-interactive run), stage the file outside the repo and print the exact `mv` command to put it in place; copy the helper with Read and Write if `cp` is refused.
4. **Run the fast path once.** Execute the recipe's fast path in its sandbox and show the evidence: commands with exit codes, output directory, screenshots read, log-scan result, budget numbers. Time it; if the fast path takes over about 2 minutes, move the heavy parts to the full sweep. If budgets were picked, run the full sweep once too; that run records the baseline. Fix recipe and sandbox faults until the run is clean.
   - A real app defect the run finds (a warning, error or failed scenario caused by the app's code) is reported to the user, never allowlisted; leave the app code alone unless they ask. Only known benign noise the project cannot fix gets an allowlist entry, with its reason.
   - Prove the scan once: plant one warning line in the app's output, see the scan fail and name the line, then remove it. A scan that passes anyway is missing output (buffering, or scanning before the app stopped).
5. **Hand over.** Give the user the exact command to try it and what working looks like. Leave every change uncommitted.

## Contributing to someone else's project

Prefer the project's existing scripts and CI. Keep devline-only pieces under `.claude/`. Ask before adding any file that would land in an upstream pull request.

## Never

- Touch the user's live session, config, devices or running instances while trying runs. Use the sandbox from the recipe, start processes yourself and stop them by PID.
- Install system packages. Name the missing ones for the user instead.
- Write, commit or change anything the user did not pick.
