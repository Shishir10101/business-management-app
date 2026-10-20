#!/usr/bin/env python3
"""Fail on real Dart errors in the mobile app.

This replaced a `dart format`-based parse check that was silently useless: it
passed all ~180 file paths in ONE invocation, which exceeds the Windows
command-line limit ("The command line is too long."), and the resulting empty
output was indistinguishable from "everything parses". The mobile app
therefore accumulated 145 real compile errors that no checker reported.

`dart analyze` is both stronger and immune to that failure mode:
  * it catches syntax errors AND type/name errors (the classes of bug that
    actually break a build), and
  * it runs on directories, so there is no argument-length limit.

Only `error` severity fails the check — `info`/`warning` are style lints
(always_use_package_imports, require_trailing_commas, ...) that do not stop
a build and would drown the signal.

Usage:  python scripts/check_flutter_syntax.py
        python scripts/check_flutter_syntax.py --all   # include lints
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
DART_BAT = pathlib.Path(
    "E:/Flutter window/flutter_windows_3.16.0-stable/flutter/bin/dart.bat"
)

ISSUE_LINE = re.compile(r"^\s*(error|warning|info)\s+-\s+(.+?)\s+-\s+(.+?)\s+-\s+(\S+)\s*$")


def dart_exe() -> str:
    if DART_BAT.exists():
        return str(DART_BAT)
    raise SystemExit("could not locate the dart executable")


def main() -> int:
    show_all = "--all" in sys.argv

    proc = subprocess.run(
        [dart_exe(), "analyze", "lib", "test"],
        cwd=MOBILE,
        capture_output=True,
        text=True,
        shell=False,
    )
    out = (proc.stdout or "") + (proc.stderr or "")

    if not out.strip():
        print("analyzer produced no output — it did not run")
        return 1

    # The analyzer failing to start is NOT a pass; say so loudly.
    if "issues found" not in out and "No issues found" not in out:
        print("analyzer did not complete:\n" + out[:2000])
        return 1

    errors: list[tuple[str, str, str]] = []
    for line in out.splitlines():
        m = ISSUE_LINE.match(line)
        if m and m.group(1) == "error":
            errors.append((m.group(2), m.group(3), m.group(4)))

    totals = re.search(r"(\d+) issues? found", out)
    total = int(totals.group(1)) if totals else 0

    print(f"analyzed apps/mobile (lib + test): {total} issue(s), "
          f"{len(errors)} error(s)")

    if errors:
        print(f"\n{len(errors)} ERROR(S) — these break the build:\n")
        for location, message, code in errors:
            print(f"  {location}\n      {message}  [{code}]")
        return 1

    if show_all:
        print("\n" + out)

    print("no errors — the app compiles")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
