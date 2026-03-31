#!/usr/bin/env python3
"""
PostToolUse hook: after any file edit/write in an IntelliJ project, set a
flag so the pre-hook knows to ask Claude to sync via ide_sync_files before
the next code navigation call.
"""

import json
import sys
import hashlib
from pathlib import Path


def stable_hash(s: str) -> str:
    return hashlib.md5(s.encode()).hexdigest()[:8]


def find_intellij_root() -> Path | None:
    cwd = Path.cwd()
    for path in [cwd, *cwd.parents]:
        if (path / ".idea").exists():
            return path
    return None


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_name = data.get("tool_name", "")
    if tool_name not in ("Write", "Edit", "NotebookEdit"):
        sys.exit(0)

    root = find_intellij_root()
    if root is None:
        sys.exit(0)

    sync_flag = Path(f"/tmp/.claude-intellij-sync-{stable_hash(str(root))}")
    sync_flag.touch()


if __name__ == "__main__":
    main()
