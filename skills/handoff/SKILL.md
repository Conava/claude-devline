---
name: handoff
description: Write a handoff file so a fresh session can pick up this work. Runs only when typed as /devline:handoff. Saves goal, user instructions, failed attempts, working state and open questions to .devline/handoff.md, then prints the one line to start the new session with.
argument-hint: "[focus]"
user-invocable: true
disable-model-invocation: true
---

# Handoff

Write `.devline/handoff.md` so a new session can continue without this conversation. `$ARGUMENTS` is an optional focus: weight the file toward it.

## Rules

- Point, don't copy. Name plans, commits, state files, logs and diffs by path or SHA. Quote only the specific error lines the work is about.
- Strip secrets: no tokens, keys, passwords or `.env` contents. Name the file, never its values.
- Keep paths, URLs and identifiers exact.
- Do not stop agents, commit or change anything else.

## Steps

1. Find the git root. Create `.devline/` there. If git does not already ignore it, add it to `.git/info/exclude`.
2. If `.devline/handoff.md` exists, show its modification date and ask before overwriting. If the user declines, stop.
3. Write the file with these sections, in order:
   1. **Goal and status**: what the user asked for overall, what is done, what is in progress right now, and the immediate next step.
   2. **Everything the user pointed you to**: one line each, with the context and intent it was given in: file paths, directories, log locations, URLs, repos, screenshots (what they showed and what the user wanted noticed), commands, error messages.
   3. **What the user said**: requirements, decisions, preferences and every correction, with what was wrong. Quote short ones verbatim. Mark which are already written to a file (give the path) and which exist only in this conversation.
   4. **Attempts that failed**: for the current problem, each approach tried, how it failed (error, symptom, measurement) and why, including hypotheses ruled out and the evidence.
   5. **Working state**: files changed and why, branches, worktrees, running processes or servers (PID or how to find them), background agents and what each is doing, uncommitted work.
   6. **Open questions waiting on the user**, and what each answer unblocks.
   7. **Skills, commands or references the next steps will need.**
   8. **Read next**: an ordered list of files to read first, most important first, each with a few words on why.
4. If `.devline/state.md` exists, add the pipeline to Working state: current stage, chosen stages, tasks in progress, worktrees, and whether agents are still running. Agents do not survive the session, so say that any running agent is lost and its task must be relaunched; point at `.devline/tasks/N/partial.patch` where one exists.
5. Print the first message for the new session, with the absolute path:

   `Read <absolute path>/.devline/handoff.md and continue.`
