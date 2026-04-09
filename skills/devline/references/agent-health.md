# Agent Health Monitoring

## Time-Based Escalation

Elapsed time is computed from the absolute ISO 8601 timestamp in `state.md`'s Task Progress table (the "Launched" field). This survives context compaction — after recovery, recompute elapsed time from these timestamps to resume monitoring at the correct escalation level.

| Elapsed | Action | Icon |
|---------|--------|------|
| < 20 min | Normal operation | — |
| 20 min | `SendMessage` nudge: "Status check — progress and blockers?" | ⚠️ |
| 30 min | Investigate: check written files, query via `SendMessage` for detailed status. If clearly progressing, let continue. | 🐌 |
| 45 min | **Hard kill.** `TaskStop` immediately. Follow killed-agent recovery protocol (see worktree-protocol.md). Relaunch fresh agent with context from previous work. | 🔁 |

If a task fails on its second relaunch (three total attempts): escalate to the user.

## Post-Compaction Recovery

After compaction or conversation resume:
1. Read `state.md` Task Progress table for launch timestamps
2. Use `TaskList` (not stored agent IDs) to identify running agents — agent IDs are conversation-scoped and stale after compaction
3. Match running tasks from TaskList to state.md entries by task number
4. Compute elapsed time from absolute timestamps
5. Apply the escalation ladder immediately — if an agent has been running 50 minutes, hard kill it now (it already passed the 45-minute threshold)

## Proactive Check-Ins

If no agent has completed in 15 minutes, check on all running agents. Query each for status, display an updated progress table.

## Common Stuck Patterns

| Pattern | Response |
|---------|----------|
| Build daemon contention (Gradle lock errors, "Could not connect to daemon") | Replacement agent uses `--no-daemon` explicitly |
| Test retry loops (same test failing 3+ times) | Replacement checks if the test is wrong, not just re-runs |
| Compilation errors from other agents | Replacement pulls latest file state first |
| Agent completed but no notification | Check with `TaskList`. If agent gone, treat as complete, send to review. |
