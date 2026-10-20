#!/usr/bin/env python3
"""Fix the two mechanical errors the string migration introduces.

1. `const Text(l10n.foo)` — `l10n.foo` is not a compile-time constant, so the
   enclosing `const` must go. Dart cannot infer this, and we cannot run the
   analyzer, so we strip it textually.
2. `l10n.foo` referenced inside a method that has a `context` parameter but no
   `final l10n = ...` declaration — we insert the declaration at the top of
   the method body.

Both are conservative: `const` is only removed from a widget expression whose
text (up to the matching close paren) contains `l10n.`, and the declaration is
only inserted into methods that actually reference l10n.

Usage: python scripts/fix_localized_pages.py [--dry-run]
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
LIB = MOBILE / "lib"


def strip_const_for_l10n(src: str) -> tuple[str, int]:
    """Remove `const` immediately preceding a widget expression that uses l10n."""
    out = src
    removed = 0
    # `const X(...)` where the parenthesised argument list mentions l10n.
    pattern = re.compile(r"\bconst\s+([A-Z]\w*(?:\.\w+)*\s*\()")

    pos = 0
    pieces: list[str] = []
    for m in pattern.finditer(out):
        # Find the matching close paren for the call opened at m.end()-1.
        depth = 0
        i = m.end() - 1
        while i < len(out):
            if out[i] == "(":
                depth += 1
            elif out[i] == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = out[m.end() - 1 : i + 1]
        if "l10n." in body:
            pieces.append(out[pos : m.start()])
            pieces.append(m.group(1))  # drop the `const `
            pos = m.end()
            removed += 1
    pieces.append(out[pos:])
    return "".join(pieces), removed


FUNC_WITH_CONTEXT = re.compile(
    r"^(\s*)(?:(?:Future|void|Widget|String|int|bool|double|List<[^>]+>)\s+)?"
    r"(_?\w+)\s*\(([^)]*)\)\s*(?:async\s*)?\{"
)
HAS_CONTEXT_PARAM = re.compile(r"\bBuildContext\s+\w+")


def add_l10n_to_context_methods(src: str) -> tuple[str, int]:
    """Insert `final l10n = AppLocalizations.of(context);` into methods that
    take a BuildContext and reference l10n without declaring it."""
    lines = src.split("\n")
    out: list[str] = []
    added = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = FUNC_WITH_CONTEXT.match(line)
        if m and HAS_CONTEXT_PARAM.search(m.group(3)):
            indent = m.group(1)
            # Scan the body for l10n usage and an existing declaration.
            depth = 1
            j = i + 1
            uses = False
            declares = False
            while j < len(lines) and depth > 0:
                depth += lines[j].count("{") - lines[j].count("}")
                if "l10n." in lines[j]:
                    uses = True
                if re.search(r"\bfinal\s+l10n\s*=", lines[j]):
                    declares = True
                j += 1
            if uses and not declares:
                out.append(f"{indent}  final l10n = AppLocalizations.of(context);")
                added += 1
        i += 1
    return "\n".join(out), added


def main() -> int:
    dry = "--dry-run" in sys.argv
    total_const = 0
    total_decl = 0
    touched = 0
    for path in sorted(LIB.glob("**/*.dart")):
        if path.name == "app_localizations.dart":
            continue
        src = path.read_text(encoding="utf-8")
        if "l10n." not in src:
            continue
        new, c = strip_const_for_l10n(src)
        new, d = add_l10n_to_context_methods(new)
        if c or d:
            touched += 1
            total_const += c
            total_decl += d
            print(f"  {path.relative_to(MOBILE)}: -{c} const, +{d} decl")
            if not dry:
                path.write_text(new, encoding="utf-8")
    print(
        f"\n{'[dry-run] ' if dry else ''}stripped {total_const} const, "
        f"added {total_decl} declarations across {touched} files"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
