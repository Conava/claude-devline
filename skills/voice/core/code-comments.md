# Code comments

Write few comments, keep them short, and make each one stand on its own.

- Say what the code can't: why it is this way, the constraint it works around, a consequence that isn't obvious (an order that matters, a value that must match another file, a case that looks wrong but is deliberate).
- A deliberate shortcut with a known limit (global lock, O(n²) scan, naive heuristic) gets one short line naming the limit and the upgrade path.
- Don't narrate what the next lines do. A reader can see that, and the comment goes stale the first time the code changes.
- The one exception: a comment may explain WHAT the code does when the logic is so hard that a careful reader would struggle to work it out from the code itself (a dense bit trick, a numerical method, a tricky regex). Even then, keep it to what they need to follow it.
- Never point to local files, plans, tickets in private trackers, task IDs or working notes, and never to this conversation. A reader of the public repo can't open them. Put the fact in the comment instead.
- No commented-out code, no change logs ("added X", "fixed Y"), no author tags. Version control holds those.
- Public API doc comments follow the language's convention and the codebase's existing style.
- The voice rules apply here too: plain words, no stock phrases, no dashes as pauses.

When reviewing, flag comments that break these rules and give the lines to remove or the shorter text to replace them with.
