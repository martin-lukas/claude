Commit and push the current project to the remote.

**Default behavior** (no arguments, or unrecognized argument):
- Look at the recent conversation to identify what was worked on
- Stage only the files related to that work (be selective - do not stage unrelated changes)
- Write a concise commit message reflecting what was done
- Push to the current branch

**Override with `all`** (e.g. `/cp all`):
- Stage all modified and untracked files (`git add -A`)
- Write a commit message summarizing all changes
- Push to the current branch

**In both cases:**
- Show the user what files will be staged before committing, so they can confirm
- Follow the project's commit message style (check recent `git log` first)
- Do not append Co-Authored-By or any signature to the commit message
- Do not amend existing commits - always create a new one

The user's argument (if any): $ARGUMENTS
