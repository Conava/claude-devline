---
name: quick
description: Fast-lane a small change — branch, implement (TDD), one review, commit. Skips brainstorm, planning, design-system, deep review, and all approval gates. Use for bugfixes, typos, tweaks, or any change that touches ~1 file / ≲30 lines with no new component, schema, endpoint, or UI surface.
argument-hint: "<small task description>"
user-invocable: true
disable-model-invocation: false
---

# Quick — Devline Fast Lane

Force the devline **fast lane** for the given task, regardless of `fast_lane` config. This is the same fast lane described in the `devline` skill — skip the classification step and run it directly.

Steps (single task, run in place — no worktrees, no waves, no gates):

1. **Branch setup** — Stage 0 of the `devline` skill (branch off protected branches, create `.devline/`).
2. **Implement** — launch ONE **implementer** agent with the task. It writes tests first (TDD at the right level: unit for pure logic, integration for persistence/endpoints — see `kb-tdd-workflow`), then implements.
3. **Review** — launch ONE **reviewer** agent (scope=task). Run a fix cycle if it returns blocking findings.
4. **Commit**, then ask only whether to merge (auto-proceed otherwise).

Explicitly SKIP: brainstorm + its gate, design-system, the full plan doc + plan gate, the Feature E2E task, worktree/wave machinery, the deferred-findings batch-fix cycle, the docs-keeper full scan, `reviewer scope=branch` (deep review), and the final approval gate.

If the task turns out to be larger than a fast-lane change (new component, schema/migration, new endpoint, UI surface, or clearly multi-file), stop and hand off to the full `/devline` pipeline instead.
