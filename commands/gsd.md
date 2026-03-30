Enter structured planning mode for this project using the GSD-inspired framework.

Check whether `.planning/` already exists in the project root.

**If `.planning/` does not exist yet — initialise the project:**
Ask the user the following questions (all at once, not one by one):
1. What does this project do, and who is it for?
2. What is the single most important thing it must deliver?
3. What is the tech stack?
4. Are there any hard constraints (platform, performance, must-use libraries)?
5. What is explicitly out of scope?
6. Do you want REQUIREMENTS.md and ROADMAP.md, or just PROJECT.md and STATE.md?

Once the user answers, create `.planning/` and populate the files using the templates
at `~/projects/claude/templates/planning/`. Fill in all known information — do not
leave placeholder text where the answer is already known. Tell the user which files
were created.

**If `.planning/` already exists — plan the next piece of work:**
Read STATE.md, PROJECT.md, and any other planning files present. Then:
1. Summarise where things stand in one short paragraph.
2. Ask what the user wants to tackle next (or propose the next logical step from STATE.md).
3. Break the work into concrete tasks.
4. If a ROADMAP.md exists, update it. Always update STATE.md when done.

Stay in planning mode — do not start writing code until the user explicitly says to proceed.