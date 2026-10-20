#!/usr/bin/env python3
"""Static sanity checks for the Flutter app that `dart format` cannot catch.

`dart format` only parses syntax, and `dart analyze` cannot run in the sandboxed
shell (the analysis server fails to spawn). These two checks cover the failure
modes that actually bit us: an app that parses fine but cannot compile.

  1. every relative / package:khata import must resolve to a real file
     (catches off-by-one `../` after moving a folder)
  2. every `XxxProvider` used in a file must be declared in that file or in a
     file it directly imports (Dart has no transitive imports)

Usage:  python scripts/check_flutter_imports.py
Exit code 0 = clean, 1 = problems found.
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "apps", "mobile", "lib")
ROOT = os.path.normpath(ROOT)

import_re = re.compile(r"""^import\s+['"]([^'"]+)['"]""", re.M)
decl_re = re.compile(r"^final\s+([A-Za-z_]\w*Provider)\s*=", re.M)
use_re = re.compile(r"\b([A-Za-z_]\w*Provider)\b")


def collect() -> dict[str, str]:
    files: dict[str, str] = {}
    for dirpath, _, names in os.walk(ROOT):
        for name in names:
            if name.endswith(".dart"):
                path = os.path.normpath(os.path.join(dirpath, name))
                with open(path, encoding="utf-8") as handle:
                    files[path] = handle.read()
    return files


def rel(path: str) -> str:
    return os.path.relpath(path, ROOT).replace("\\", "/")


def resolve(importer: str, spec: str) -> str | None:
    if spec.startswith("package:khata/"):
        return os.path.normpath(os.path.join(ROOT, spec[len("package:khata/"):]))
    if spec.startswith(("package:", "dart:")):
        return None
    return os.path.normpath(os.path.join(os.path.dirname(importer), spec))


def main() -> int:
    files = collect()
    if not files:
        print(f"no Dart files found under {ROOT}")
        return 1

    problems: list[str] = []
    import_count = 0

    declared: dict[str, str] = {}
    for path, text in files.items():
        for match in decl_re.finditer(text):
            declared.setdefault(match.group(1), path)

    for path, text in files.items():
        imported: set[str] = {path}
        for spec in import_re.findall(text):
            target = resolve(path, spec)
            if target is None:
                continue
            import_count += 1
            if os.path.isfile(target):
                imported.add(target)
            else:
                problems.append(f"{rel(path)}\n      broken import -> {spec}")

        body = "\n".join(
            line for line in text.splitlines()
            if not line.lstrip().startswith(("import ", "export ", "//", "///"))
        )
        for ident in sorted(set(use_re.findall(body))):
            owner = declared.get(ident)
            if owner and owner not in imported:
                problems.append(
                    f"{rel(path)}\n      uses {ident} without importing {rel(owner)}")

    print(f"checked {import_count} imports across {len(files)} files")

    if problems:
        print(f"\n{len(problems)} problem(s):\n")
        for problem in problems:
            print(f"  {problem}\n")
        return 1

    print("no broken imports, no unresolvable provider references")
    return 0


if __name__ == "__main__":
    sys.exit(main())
