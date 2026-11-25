# PR descriptions, commits and technical text (voice only)

Section structure for PRs and commits comes from the git conventions in use, not from here. This layer covers how the text sounds.

- Sound like a knowledgeable colleague explaining a change to another: conversational, tighter than speech, neither cute nor dry.
- Lead with what the change does for the person using it. The reasons for design choices come after, each in one clause with "because" or "so".
- When the change adds a flag, command or option, show one real invocation in a code span or block. That is often the most useful line in the PR.
- Say plainly what you didn't test, why, and what would help, in one or two sentences.
- No form labels ("**Title:**", "**Description:**"). The title is the first line; the body starts with content.
- Don't call a step simple, easy or quick; it insults anyone for whom it wasn't.
- No idioms, metaphors or pop-culture references. Readers include non-native speakers and translation tools.
- Use plain links ("so", "this way") rather than "however" and "nonetheless".
- A short body is prose, or prose with one real list where the items are truly parallel (test cases, files). Don't break a three-paragraph body into headed sections.
- Issue references use the keyword GitHub recognises ("Closes #12"), in English even in a German text.
- Cut lines that say what stays the same, reports on how you tested by hand, and how you found the bug, unless the reviewer needs them.

## German PRs

- Open with what the change does, as the English version would: "Fügt das Flag `--dry-run` hinzu, damit ...".
- Keep the technical words German developers say in English (Flag, Pipe, Build, Merge). Translating them reads stranger than leaving them.
