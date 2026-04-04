Commit and push project changes (source code, not `.planning/` files).

**Default behavior** (no arguments):
1. Run `git status` and `git diff` to analyze what has actually changed (both staged and unstaged).
2. Exclude `.planning/` files - they have their own `/gsd:push` command.
3. If there are no project changes, tell the user and stop.
4. Show the user the file list and a summary of what changed semantically (features added, bugs fixed, refactors, etc.).
5. Ask for confirmation before proceeding.
6. Stage the identified files, write a concise descriptive commit message based on the actual changes, and push to the current branch.

**With `amend` argument** (e.g. `/push amend`):
1. Analyze changes the same way, but amend the previous commit instead of creating a new one.
2. Show the user what will be amended and ask for confirmation.
3. Stage files, amend the last commit, attempt to push.
4. If push fails because the remote already has the previous commit, ask the user if they want to force push. Do not force push without asking.

**Commit messages:**
- Check recent `git log` to match the project's commit message style.
- Write semantically, not per-file (e.g. "Refactor auth middleware and add session endpoint" not "Update auth.ts").
- Do not append Co-Authored-By or any signature.
