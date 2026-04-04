Create `.planning/` files for this project. Do not write code.

**Assess the repo first:**
- If it has meaningful code or config, explore it (entry points, package manifests, READMEs, key source files) and derive what you can: what it does, who it's for, tech stack, likely constraints.
- If it's essentially empty, skip exploration.

Then ask the user only what you could not confidently derive. Always ask:
1. What is the single most important thing this project must deliver?
2. What is explicitly out of scope?
3. Which files do you want: just PROJECT.md + STATE.md, or REQUIREMENTS.md and ROADMAP.md too?

If you derived facts from the code, show your understanding briefly and let the user correct anything before asking questions.

**Interactive questioning rules:**
- If a user's answer is vague or too broad to be actionable, follow up with a more specific question - or offer multiple-choice options to help them pin it down (e.g. "Is the primary user a developer, an end-user, or internal ops team?").
- Keep drilling until you have enough specificity to write useful, non-placeholder content. Don't accept "it should be fast" - ask what fast means in this context.
- Ask follow-ups one at a time, not as a new batch.

Once answers are solid, read `~/projects/claude/templates/planning/` for structure, create `.planning/`, populate the requested files with all known information (no unfilled placeholders), and tell the user what was created.
