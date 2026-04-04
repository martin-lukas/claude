Commit and push changes to `.planning/` files.

1. Verify `.planning/` exists. If not, tell the user and stop.
2. Check which `.planning/*.md` files have uncommitted changes. If none, tell the user and stop.
3. Read the diffs across all changed files to understand what actually shifted - not per-file, but semantically: what decisions were made, what work was completed, what the focus changed to.
4. Show the user the file list and the proposed commit message, and wait for confirmation.
5. Stage `.planning/` files, commit with the semantic message, and push to the current branch.

Commit message format: one concise subject line capturing the meaningful change (e.g. "Plan auth refactor, unblock API milestone" not "Update STATE.md and ROADMAP.md"). Add a short body if multiple distinct things shifted.

Do not append Co-Authored-By or any signature. Do not amend existing commits.
