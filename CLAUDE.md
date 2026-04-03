# Global Claude instructions

## Editing files
- Never rewrite or overwrite a file if the result would be identical to the original — skip it silently instead of prompting for confirmation on a no-op change.
- Always use `vim` in suggested shell commands, never `nano`.

## Claude configuration repository

All Claude configuration files (`~/.claude/CLAUDE.md`, settings, memory, etc.) are symlinked from `~/projects/claude/`. When committing or pushing changes to these files, work in `~/projects/claude/`.

## Logs and debugging
- Always point to app log files for investigation, never suggest `journalctl` or `systemctl status` as the primary way to read logs.

## Asking questions

When you need to ask the user one or more questions, always use the `AskUserQuestion` tool to present them as interactive forms with tabs. Never ask questions as plain prose when the tool is available.

## Writing style
- Never use em-dashes (—) in any output, including prose, comments, and documentation. Use a regular hyphen (-) instead.
- Be warm and conversational. Use contractions naturally. Feel free to express mild enthusiasm when something is interesting or elegant.
- Always align markdown table columns with consistent whitespace so columns line up visually.

## Git
- Do not commit or push unprompted — wait for the user to ask.
- Do not append `Co-Authored-By` or any other signature to commit messages.

## Project context files

At the start of every session, check whether any of the following files exist in
the project root or a `.planning/` subdirectory. Read whichever are present before
doing anything else — in this order:

1. `STATE.md` — current status, last session summary, blockers, next steps
2. `PROJECT.md` — what this project is, constraints, key decisions
3. `REQUIREMENTS.md` — what "done" looks like, acceptance criteria, scope boundaries
4. `ROADMAP.md` — phases, tasks, dependencies

Not all projects will have all four files. Small projects may only have `STATE.md`
and `PROJECT.md` — that is fine. Only read what exists.

After completing any meaningful unit of work (a feature, a bug fix, a refactor),
update `STATE.md` to reflect what was just done, the current position, and what
comes next. If a requirement was completed, check it off in `REQUIREMENTS.md`.
Do not ask for permission to update these files — just do it silently.

If a project has a `CLAUDE.md` of its own, that file contains project-specific
conventions (code style, naming, formatting, commit message format, project
structure rules). Follow those in addition to these global instructions, with
project-level rules taking precedence where they conflict.

## Plans

Never voluntarily write plans to `~/.claude/plans/`. Always store plans, tasks,
and session state in the project's `.planning/` directory (STATE.md, ROADMAP.md,
etc.). If a task list or implementation plan needs to be captured, add it to
ROADMAP.md or STATE.md — do not create a separate file outside the project.

Exception: plan mode is a harness feature that forces writes to `~/.claude/plans/`
— that is fine and unavoidable. Those files are ephemeral approval scaffolding.
The meaningful record of what was decided and done belongs in `.planning/` as usual.

## Templates

Starter templates for all planning files and project-level CLAUDE.md live at:
`~/projects/claude/templates/`

- `templates/CLAUDE.md`              — project conventions (style, naming, commits)
- `templates/planning/PROJECT.md`    — what the project is, decisions, constraints
- `templates/planning/STATE.md`      — session memory, current status, next steps
- `templates/planning/REQUIREMENTS.md` — done criteria, scope boundaries
- `templates/planning/ROADMAP.md`    — phases and tasks

When the user asks to set up planning files or initialise a new project, use these
templates as the basis. Copy and fill them in based on what the user has told you
about the project — do not leave placeholder text unfilled where the information
is already known.
