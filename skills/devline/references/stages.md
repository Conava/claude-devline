# Stages

The menu a run is composed from. The orchestrator picks a preset, adds the stages that the change's reach pulls in, shows the result and records it. Reach categories and their signals are in `kb-blast-radius` (`## Reach`).

## Stages

| Stage | What runs | Pulled in by |
|---|---|---|
| `brainstorm` | brainstorm skill, with grilling rounds | `full` preset; an unclear or open-ended request |
| `design` | design skill with designer agents (Stage 1.5) | reach: UI with a new or changed visible surface |
| `planner` | planner agent, plan approval | `full` preset; more than one implementer |
| `preparatory refactor` | implementer on the planner's refactor-first task | the planner offers one and the user accepts it at plan approval |
| `implementers` | implementer agents: 1, or N parallel; N > 1 requires planner | every preset |
| `per-task review` | reviewer `scope: task` after each task | every preset |
| `branch review` | reviewer `scope: branch` on sonnet | `full` preset; a large change with no reach category |
| `deep review` | reviewer `scope: branch` on opus | `full` preset; reach: security surface, public contract, persisted data, concurrency |
| `security scan` | reviewer `focus: security` | reach: security surface |
| `resource profiling` | reviewer `focus: resources` | reach: resource use |
| `optimization pass` | reviewer `focus: optimization` | reach: resource use on a hot path; a request about speed or size |
| `best-practices review` | reviewer `focus: best-practices` | reach: UI, build/release; a new stack or framework in the project |
| `docs` | docs-keeper | `implement` and `full` presets; reach: public contract |
| `final gate` | merged-tree gate, final commit, merge/PR question | every preset |

## Presets

- **quick**: `implementers`, `per-task review`, `final gate`
- **implement**: `implementers`, `per-task review`, `docs`
- **full**: `brainstorm`, `design`, `planner`, `preparatory refactor`, `implementers`, `per-task review`, `branch review`, `deep review`, `docs`, `final gate`

`quick` runs one implementer in place, and its final gate is the commit plus the merge/PR question. `implement` starts from an existing plan. In `full`, `design` runs only with UI reach and `preparatory refactor` only when the user accepts one; the specialists come only from reach.

## Composing a run

1. **Preset** from the command:
   - `/devline:quick` → `quick`
   - `/devline:implement` → `implement`
   - `/devline` → the devline config's `fast_lane`: `auto` lets the orchestrator start from `quick` for a change of about one file with no reach category; `always` → `quick`; `off` → `full`.
2. **Reach:** run the `kb-blast-radius` Reach steps on the request and add every stage its categories pull in. Reach only adds stages; it never removes one from the preset. An explicit preset wins over size, so `quick` on a new endpoint stays `quick` plus what reach adds.
3. **Bug fixes** start from the debugger route plus `per-task review`, then reach adds.

Examples: a one-line change to auth input validation is security surface, so it gets `security scan` and `deep review` even under `quick`. An isolated refactor with no reach category gets none of the specialists.

## Showing the run

Show a short table, one line per chosen stage:

| Stage | Reason |
|---|---|
| `implementers` | preset `quick` |
| `security scan` | reach: security surface (auth input parsing) |

Then, by the devline config's `stage_menu` (lookup in `${CLAUDE_PLUGIN_ROOT}/skills/setup/references/config.md`):

- `ask` (default): AskUserQuestion with "Run as shown", "Change stages", "Stop". On "Change stages" the user names adds and removes in free text; apply them and show the table again.
- `auto`: print the table and proceed.

An explicit preset with no reach additions prints the table and proceeds, whatever `stage_menu` says.

## Recording

Write the chosen stages and their reasons to `.devline/state.md` under `## Stages` (schema in `recovery.md`). Run only the recorded stages. Stages added at plan approval, from plan tasks' `**Reach:**` lines, are appended with their reason and shown again before implementation starts.
