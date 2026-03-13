---
name: setup
description: This skill should be used when the user runs "/setup", "setup my project", "initialize CLAUDE.md", "create CLAUDE.md", or wants to set up the devline clarification protocol for a project. Creates a CLAUDE.md that tells agents to stop and ask when they hit something they cannot confidently resolve, and to request the user adds the clarification to CLAUDE.md for future agents.
user-invocable: true
---

# Setup

Create or update a `CLAUDE.md` in the project root. This file holds only non-obvious context that agents need to work efficiently — things that cannot be derived from the code, tests, or git history easily.

## Process

### 1. Check for Existing CLAUDE.md

Read `CLAUDE.md` in the working directory root.

- If it already contains the clarification protocol, inform the user and ask whether to stop, overwrite, append or optimize.
- If it exists without the protocol, and the user chooses to append, append the protocol section only (without the heading and intro paragraph).
- If it does not exist, or the user chooses override, create it with only the content below.
- If it exists and the user chooses optimize, attempt to integrate the protocol into the beginning of the CLAUDE.md. Separate from that run a quick explore and then remove any obvious or boilerplate content that is currently present and present the new content to the user for confirmation before writing.

### 2. Present and Confirm

Show the user the exact content using **AskUserQuestion** with a preview. Only write after confirmation.

Full content for a new CLAUDE.md:

```
# CLAUDE.md

This file is the single source of non-obvious project context — things that cannot be figured out from the code, tests, or git history alone. Do not add anything here that is already discoverable.

## Clarification Protocol

If you run into a problem you cannot confidently resolve while working on this project — whether it is a failing build with no clear fix, a pattern that contradicts the rest of the codebase, implicit domain logic, unclear conventions, or anything else where guessing would be risky — do the following:

1. Stop. Do not guess or silently work around it.
2. Tell the user exactly what you were doing, what went wrong or confused you, and why you cannot proceed.
3. Ask the user to add the clarification to this file if it is relevant to the entire project and not just the specific task, so that any agent working on this project in the future will have the answer immediately.
```

### 3. Write the File

Write or append based on what was found in step 1.

### 4. Confirm

Tell the user the file has been created or updated.

### 5. Further Instructions

Show the following text to the user:

```
Maintain the CLAUDE.md file as you work on the project. Whenever you encounter CLAUDE making repeated mistakes or getting stuck on something, add the relevant clarification to CLAUDE.md so that future agents can avoid the same issue. This will make CLAUDE more effective over time and help it understand the unique context of this project.
Absolutely avoid adding information to CLAUDE.md that can be easily discovered from the code, tests, or git history. The goal is to keep it concise and focused on non-obvious context that agents cannot figure out on their own.
Stale, inaccurate, or irrelevant content in this file is worse than no content, so if you find something in here that is no longer relevant or helpful, remove it.
If you require workflow or agent changes, consider cloning this git repository and making the changes in the agents or skills themselves, instead of adding instructions here. CLAUDE.md should be kept focused on project-specific context, not general workflow or agent behavior.
```
