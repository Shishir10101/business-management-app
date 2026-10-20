#!/usr/bin/env python3
"""Rewrite page literals to use AppLocalizations.

Scope: the 51 presentation files that still render English inline. Models,
repositories, datasources and providers are untouched — they must not depend on
a BuildContext.

What it does per file:
  1. Adds `import '../../../../l10n/app_localizations.dart';` (path depth
     computed from the file's location) unless already present.
  2. Replaces `Text('Literal')` / `label: 'Literal'` / ... with
     `l10n.<key>` for every literal that has an ARB key.
  3. Keeps interpolated strings as-is unless a matching key exists.

It deliberately does NOT try to be clever about builder scope: after running,
`check_localizations.py` reports every `l10n` reference that has no in-scope
`l10n` variable, and those are fixed by hand. Guessing scope automatically is
how you get code that compiles in nine files and breaks in the tenth.

Usage:  python scripts/migrate_strings.py           # apply
        python scripts/migrate_strings.py --dry-run # report only
"""

from __future__ import annotations

import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
LIB = MOBILE / "lib"
ARB = LIB / "l10n" / "app_en.arb"

# Widget parameters whose string argument is user-facing.
CALL_KEYS = (
    "Text",
    "SelectableText",
    "label",
    "labelText",
    "hintText",
    "helperText",
    "tooltip",
    "title",
    "subtitle",
    "content",
    "text",
    "hint",
    "semanticLabel",
    "message",
    "subject",
    "errorText",
    "prefixText",
    "suffixText",
    "confirmText",
    "cancelText",
    "labelText_",
)

# Literals that must never be translated (identifiers, format strings, etc).
SKIP_LITERALS = {
    "",
    "-",
    "+",
    "/",
    "|",
    "•",
    "·",
    "×",
    "→",
    "Rs.",
    "Rs",
    "OK",
    "id",
    "qty",
    "SKU",
    "PAN",
    "VAT",
    "PDF",
    "CSV",
    "JSON",
    "Bs",
    "BS",
    "AD",
}

# Values that are actually dynamic even though they look literal.
DYNAMIC = re.compile(r"\$|\{|\}")


def key_for(value: str, by_value: dict[str, str]) -> str | None:
    if value in SKIP_LITERALS:
        return None
    if DYNAMIC.search(value):
        return None
    return by_value.get(value)


def import_path_for(path: pathlib.Path) -> str:
    rel = path.relative_to(LIB)
    depth = len(rel.parts) - 1
    return "../" * depth + "l10n/app_localizations.dart"


# A `build`/`buildX` method body that uses l10n needs a declaration. We insert
# it as the first statement of the method, which is where it belongs and does
# not depend on any earlier code in the body.
BUILD_SIG = re.compile(
    r"^(\s*)(Widget\s+build\s*\([^)]*\)\s*(?:async\s*)?\{\s*)$"
)
CTOR_LIKE = re.compile(r"^\s*(?:const\s+)?\w+\s*\([^;]*\)\s*[:{]")
ARROW_BODY = re.compile(r"^(\s*)(Widget\s+build\s*\([^)]*\)\s*=>\s*)")


def inject_l10n_locals(src: str) -> str:
    """Declare `final l10n = AppLocalizations.of(context);` at the top of every
    method body that references l10n through a `context` in scope."""
    lines = src.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = BUILD_SIG.match(line)
        if m:
            indent, _ = m.groups()
            # Does this build method's body use l10n?
            depth = 1
            j = i + 1
            uses = False
            while j < len(lines) and depth > 0:
                depth += lines[j].count("{") - lines[j].count("}")
                if "l10n." in lines[j]:
                    uses = True
                j += 1
            if uses:
                out.append(f"{indent}  final l10n = AppLocalizations.of(context);")
                out.append("")
        i += 1
    return "\n".join(out)


def main() -> int:
    dry = "--dry-run" in sys.argv
    arb = json.loads(ARB.read_text(encoding="utf-8"))
    by_value: dict[str, str] = {}
    for k, v in arb.items():
        if k.startswith("@") or not isinstance(v, str):
            continue
        by_value.setdefault(v, k)

    import re as _re

    file_re = _re.compile(
        r"Text\('[A-Z]|label: '[A-Z]|title: '[A-Z]|hintText: '[A-Z]|labelText: '[A-Z]"
    )
    targets = []
    for f in sorted(LIB.glob("features/**/presentation/**/*.dart")) + sorted(
        LIB.glob("core/widgets/*.dart")
    ):
        if file_re.search(f.read_text(encoding="utf-8")):
            targets.append(f)

    call_re = _re.compile(
        r"(?P<pre>\b(?:" + "|".join(CALL_KEYS) + r")\s*[:\(]\s*)"
        r"'(?P<lit>(?:[^'\\]|\\.)*)'"
    )

    changed_files = 0
    total_replacements = 0
    for path in targets:
        src = path.read_text(encoding="utf-8")
        original = src
        count = 0

        def repl(m: re.Match) -> str:
            nonlocal count
            lit = m.group("lit")
            key = key_for(lit, by_value)
            if key is None:
                return m.group(0)
            count += 1
            return f"{m.group('pre')}l10n.{key}"

        src = call_re.sub(repl, src)

        if count:
            imp = import_path_for(path)
            line = f"import '{imp}';"
            if "app_localizations.dart" not in src:
                # Insert after the last import line.
                lines = src.split("\n")
                last = 0
                for i, l in enumerate(lines):
                    if l.startswith("import "):
                        last = i
                lines.insert(last + 1, line)
                src = "\n".join(lines)
            src = inject_l10n_locals(src)
            if not dry:
                path.write_text(src, encoding="utf-8")
            changed_files += 1
            total_replacements += count
            print(f"  {path.relative_to(MOBILE)}: {count} replacement(s)")

        _ = original

    print(
        f"\n{'[dry-run] ' if dry else ''}"
        f"{total_replacements} replacements across {changed_files} files"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
