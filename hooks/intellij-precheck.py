#!/usr/bin/env python3
"""
PreToolUse hook: for Bash/Grep/Glob tool calls in an IntelliJ/Java project,
block and ask Claude to check the intellij-index MCP server for better tools.

Flow:
  1. If not an IntelliJ project -> approve immediately.
  2. If the operation doesn't look like code navigation/search -> approve.
  3. If a sync-needed flag exists (set by companion post-hook after edits)
     -> block and ask Claude to call ide_sync_files first, then check MCP tools.
  4. Otherwise -> block and ask Claude to query MCP tools and use them if suitable.
"""

import json
import sys
import re
import hashlib
from pathlib import Path


def stable_hash(s: str) -> str:
    return hashlib.md5(s.encode()).hexdigest()[:8]


def find_project_root() -> Path | None:
    """Walk up from cwd looking for .idea/ or Java build files."""
    cwd = Path.cwd()
    for path in [cwd, *cwd.parents]:
        if (path / ".idea").exists():
            return path
        if any((path / f).exists() for f in ("build.gradle", "build.gradle.kts", "pom.xml")):
            return path
    return None


def is_java_project(root: Path) -> bool:
    return any(
        (root / f).exists()
        for f in ("build.gradle", "build.gradle.kts", "pom.xml")
    )


# Patterns that indicate code navigation / search in a Bash command.
_BASH_NAV_PATTERNS = [
    r"\bgrep\b",
    r"\brg\b",
    r"\bripgrep\b",
    r"\bfind\b",
    r"\bcat\b.+\.(java|kt|groovy|xml|gradle|properties|yaml|yml)\b",
    r"\bhead\b.+\.(java|kt|groovy|xml|gradle)\b",
    r"\btail\b.+\.(java|kt|groovy|xml|gradle)\b",
    r"\bsed\b.+\.(java|kt|groovy)\b",
    r"\bawk\b.+\.(java|kt|groovy)\b",
    r"\bwc\b.+\.(java|kt)\b",
    r"\bls\b.+src\b",
]
_BASH_NAV_RE = re.compile("|".join(_BASH_NAV_PATTERNS), re.IGNORECASE)


def looks_like_navigation(tool_name: str, tool_input: dict) -> bool:
    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        return bool(_BASH_NAV_RE.search(cmd))
    if tool_name in ("Grep", "Glob"):
        return True
    return False


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_name = data.get("tool_name", "")

    if tool_name not in ("Bash", "Grep", "Glob"):
        sys.exit(0)

    root = find_project_root()
    if root is None or not (root / ".idea").exists():
        sys.exit(0)

    tool_input = data.get("tool_input", {})
    if not looks_like_navigation(tool_name, tool_input):
        sys.exit(0)

    # Check sync flag (set by intellij-sync-marker.py after file edits)
    sync_flag = Path(f"/tmp/.claude-intellij-sync-{stable_hash(str(root))}")
    needs_sync = sync_flag.exists()
    if needs_sync:
        sync_flag.unlink(missing_ok=True)

    project_type = "Java/IntelliJ" if is_java_project(root) else "IntelliJ"

    if needs_sync:
        reason = (
            f"You are in a {project_type} project at `{root}` and files were recently "
            f"modified. Before searching or navigating the code, do the following:\n\n"
            f"1. Call `ide_sync_files` on the `intellij-index` MCP server so IntelliJ "
            f"picks up the latest changes.\n"
            f"2. Then check what tools the `intellij-index` MCP server has available "
            f"and decide whether any of them are suitable for the current task.\n"
            f"3. If a suitable MCP tool exists, use it instead of `{tool_name}`.\n"
            f"4. Only fall back to `{tool_name}` if no MCP tool fits."
        )
    else:
        reason = (
            f"You are in a {project_type} project at `{root}`. "
            f"Before using `{tool_name}` for code navigation or search, check what "
            f"tools the `intellij-index` MCP server has available and decide whether "
            f"any of them are suitable for your current goal.\n\n"
            f"IntelliJ MCP tools understand the semantic structure of the project "
            f"(symbols, references, type hierarchies, usages) and are generally more "
            f"accurate than text-based search for code navigation tasks.\n\n"
            f"If a suitable MCP tool exists, use it instead of `{tool_name}`. "
            f"Only fall back to `{tool_name}` if none of the MCP tools fit."
        )

    print(json.dumps({"decision": "block", "reason": reason}))


if __name__ == "__main__":
    main()
