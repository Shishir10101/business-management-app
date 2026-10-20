#!/usr/bin/env python3
"""Replace multi-line adjacent string literals with an ARB lookup.

Handles the shape dart formatter produces for long strings:

    Text(
      'Saves every product, party, sale, purchase, expense, '
      'income, payment, invoice and quotation in the active business. '
      'Soft-deleted records are kept, so history survives.',
    ),

which is one logical string split across lines. The simple literal matcher in
migrate_strings.py cannot see it, so those strings stayed English.

Only replaces when the concatenated text matches an ARB value exactly — no
guessing.

Usage: python scripts/migrate_multiline_strings.py [--dry-run]
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
LIB = MOBILE / "lib"
ARB = LIB / "l10n" / "app_en.arb"

# A call argument that is 2+ adjacent single-quoted literals, possibly with
# newlines/indentation between them.
CONCAT = re.compile(
    r"(?P<pre>\b(?:Text|content|label|title|subtitle|helperText|tooltip)\s*[:\(]\s*)"
    r"(?P<parts>'(?:[^'\\]|\\.)*'"
    r"(?:\s*\n\s*'(?:[^'\\]|\\.)*')+)",
    re.MULTILINE,
)


def unescape(s: str) -> str:
    return s.replace(r"\'", "'").replace(r"\\", "\\")


def main() -> int:
    dry = "--dry-run" in sys.argv
    arb = json.loads(ARB.read_text(encoding="utf-8"))
    by_value = {
        v: k for k, v in arb.items() if not k.startswith("@") and isinstance(v, str)
    }

    total = 0
    touched = 0
    for path in sorted(LIB.glob("**/*.dart")):
        if path.name == "app_localizations.dart":
            continue
        src = path.read_text(encoding="utf-8")
        if "l10n." not in src:
            continue
        count = 0

        def repl(m: re.Match) -> str:
            nonlocal count
            parts = re.findall(r"'((?:[^'\\]|\\.)*)'", m.group("parts"))
            joined = "".join(unescape(p) for p in parts)
            key = by_value.get(joined)
            if key is None:
                return m.group(0)
            count += 1
            return f"{m.group('pre')}l10n.{key}"

        new = CONCAT.sub(repl, src)
        if count:
            touched += 1
            total += count
            print(f"  {path.relative_to(MOBILE)}: {count}")
            if not dry:
                path.write_text(new, encoding="utf-8")

    print(f"\n{'[dry-run] ' if dry else ''}{total} multi-line string(s) in {touched} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
