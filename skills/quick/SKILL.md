---
name: quick
description: The small-change preset — branch, implement, per-task review, commit, without brainstorm, planning or approval gates. Use for bugfixes, typos, tweaks and other small changes. Reach (what the change can affect) can still add stages.
argument-hint: "<small task description>"
user-invocable: true
disable-model-invocation: false
---

# Quick — Small-Change Preset

Run preset `quick` from [stages.md](../devline/references/stages.md). The command picks the preset, so there is no lane question and the task never moves to another pipeline.

1. **Branch setup** — Stage 0 of the `devline` skill.
2. **Assess and Compose** — as in the `devline` skill, starting from preset `quick`. Reach can add stages (for example a security scan); it never removes any.
3. **Implement** — launch ONE **implementer** agent in place, with a brief per `## Agent Briefs` in [implementation-protocol.md](../devline/references/implementation-protocol.md). Pass the task text as the user wrote it plus the brief's facts; no "Report:" or "Verify:" lines, no TDD steps and no design choices of your own. The implementer does not commit.
4. **Review** — per-task review, plus any specialist reviews that reach added. Run a fix cycle on blocking findings.
5. **Commit** — once the agent has stopped, the main session commits with the `git` skill (commit mode), then asks whether to merge, open a PR (`git` pr mode), or leave it.

Skipped: brainstorm, design, planner, worktrees and waves, branch and deep review, docs, and approval gates, unless reach added them.
