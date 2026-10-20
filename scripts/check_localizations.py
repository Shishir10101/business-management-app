#!/usr/bin/env python3
"""Verify that every `l10n.<key>` reference is in scope and the key exists.

Two failure modes this catches, neither of which `dart format` or the import
checker can see:

  1. A page references `l10n.foo` but never declared `final l10n = ...` in the
     enclosing build method. Dart reports this as an undefined name at compile
     time, which we cannot run here.
  2. A page references a key that is not in the ARB files (typo, or a key that
     was renamed). Also a compile error.

Scope detection is heuristic but deliberately conservative: a `l10n` variable
counts as in scope for the rest of the enclosing function/method body after its
declaration. We look for `final l10n =` / `final l10n = AppLocalizations.of(`
within the same brace block that contains the use.

Usage: python scripts/check_localizations.py
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
LIB = MOBILE / "lib"

# Known-good names that are not ARB keys and are legitimately referenced.
ALLOWED_NONKEY = {"of", "delegate", "supportedLocales"}


def arb_keys() -> set[str]:
    data = json.loads((LIB / "l10n" / "app_en.arb").read_text(encoding="utf-8"))
    return {k for k in data if not k.startswith("@")}


def block_of_use(lines: list[str], use_line: int) -> tuple[int, int]:
    """The brace block enclosing a line, by scanning outward for balance.

    Returns (start, end) line indices of the innermost block that contains an
    `l10n` declaration before the use, or (-1, -1) when there is none.

    `l10n` reaches a body two ways: a local `final l10n = ...`, or an
    `AppLocalizations l10n` parameter on the enclosing function (the pure
    helpers in core/utils are written that way). Both count as in scope.

    A declaration only counts if it is *inside the same function scope* as
    the use. The scan stops at the first function/method header above the
    use — a `final l10n =` living in a sibling method (e.g. `build`) does
    NOT satisfy a use inside `_phoneValidator`. Closures (`onPressed: () {}`,
    `builder: (c) => ...`) are NOT boundaries: they legally capture the
    enclosing method's `l10n`.

    Header shapes handled (a boundary is any of these):
      * `Type name(args) {`            — block-bodied member/method
      * `Type name(args) async {`      — async variant
      * `Type name(args) =>`           — arrow-bodied member (arrow closures
                                          with a `label:` prefix do not match
                                          and correctly stay capturable)
      * `Type get name =>` / `{`       — getters
      * `Type name(` / `name({`        — multi-line headers whose `{` or
                                          closing paren is on a later line
    Control-flow headers (`if (`, `for (`, `while (`, `switch (`, `catch (`,
    `else`, `return`, ...) are NOT boundaries: an `l10n` declared above an
    `if` block is still in scope inside it.
    """
    decl = re.compile(
        r"\b(?:late\s+)?(?:final\s+)?(?:AppLocalizations\s+)?l10n\s*="
        r"|\bAppLocalizations\s+l10n\b"
    )
    headers = _function_header_re()
    for i in range(use_line, -1, -1):
        if decl.search(lines[i]):
            return i, _end_of_block(lines, i)
        if i < use_line and _is_boundary(lines, i, headers):
            # Reached a function/method header without passing a decl.
            break
    return -1, -1


def _is_boundary(lines: list[str], i: int, headers: list[re.Pattern[str]]) -> bool:
    """A header line at class-member (2-space) or top-level (0-space) indent.

    Headers at indent >= 4 are LOCAL functions declared inside a method
    (`void onSearch(String v) => ...` inside `build`). Those legally capture
    the enclosing method's locals — `l10n` included — so they must NOT act
    as scope boundaries.
    """
    if not any(p.match(lines[i]) for p in headers):
        return False
    indent = len(lines[i]) - len(lines[i].lstrip())
    return indent <= 2


_FUNCTION_HEADER_CACHE: list[re.Pattern[str]] | None = None


def _function_header_re() -> list[re.Pattern[str]]:
    """Regexes matching a function/method/getter header line.

    A header needs a type-ish token run before the name so that plain calls
    (`Text(`), field initializers (`final x = Foo(`) and control flow
    (`if (`) do not match.
    """
    global _FUNCTION_HEADER_CACHE
    if _FUNCTION_HEADER_CACHE is not None:
        return _FUNCTION_HEADER_CACHE
    control = (
        r"(?:if|for|while|switch|catch|do|else|return|try|when|assert|await"
        r"|yield|throw|break|continue|case|default|new|super|this"
        r"|const|final|var)"
    )
    # A header never starts with ternary/colon/comma/paren punctuation —
    # `? const SizedBox(` and `: Text(` are continuation lines, not headers.
    not_punct = r"(?![?:,.=)\]}>])"
    type_run = r"(?:[\w<>,\[\]\?\.]+\s+)+"
    name = r"([A-Za-z_]\w*)"
    patterns = [
        # Block-bodied member: `Type name(args) {` (also `async`).
        re.compile(rf"^\s*{not_punct}(?!{control}\b){type_run}{name}\s*\([^)]*\)"
                   rf"\s*(?:async\s*)?\{{"),
        # Arrow-bodied member: `Type name(args) =>` and `Type get name =>`.
        re.compile(rf"^\s*{not_punct}(?!{control}\b){type_run}{name}\s*\([^)]*\)"
                   rf"\s*(?:async\s*)?=>"),
        re.compile(rf"^\s*{not_punct}(?!{control}\b){type_run}get\s+{name}\s*(?:=>|\{{)"),
        # Multi-line header: line ends at `(` or `({` after `Type name`.
        # (A bare `name(` line is NOT a header — it is usually a constructor
        # call inside an expression, e.g. `Text(` on its own line.)
        re.compile(rf"^\s*{not_punct}(?!{control}\b){type_run}{name}\s*\(\s*\{{?\s*$"),
    ]
    _FUNCTION_HEADER_CACHE = patterns
    return patterns


def _end_of_block(lines: list[str], start: int) -> int:
    """First line index after [start] where brace depth returns to zero."""
    depth = 0
    started = False
    for j in range(start, len(lines)):
        depth += lines[j].count("{") - lines[j].count("}")
        if "{" in lines[j]:
            started = True
        if started and depth <= 0 and j > start:
            return j
    return len(lines) - 1


def main() -> int:
    keys = arb_keys()
    files = sorted(LIB.glob("**/*.dart"))
    problems: list[str] = []
    refs = 0

    for path in files:
        src = path.read_text(encoding="utf-8")
        if "l10n." not in src:
            continue
        # Generated localizations are the definition site, not a consumer.
        if path.name == "app_localizations.dart":
            continue
        lines = src.split("\n")
        for idx, line in enumerate(lines):
            # Ignore matches inside string literals (e.g. 'error in l10n.yaml').
            stripped = re.sub(r"'[^']*'", "''", line)
            stripped = re.sub(r'"[^"]*"', '""', stripped)
            for m in re.finditer(r"\bl10n\.(\w+)", stripped):
                name = m.group(1)
                refs += 1
                if name not in keys and name not in ALLOWED_NONKEY:
                    problems.append(
                        f"{path.relative_to(MOBILE)}:{idx + 1}: unknown key 'l10n.{name}'"
                    )
                    continue
                start, end = block_of_use(lines, idx)
                if start < 0:
                    problems.append(
                        f"{path.relative_to(MOBILE)}:{idx + 1}: 'l10n.{name}' has no "
                        f"`final l10n = ...` in scope"
                    )

    print(f"checked {refs} l10n reference(s) across {len(files)} files")
    if problems:
        print(f"\n{len(problems)} PROBLEM(S):\n")
        for p in problems:
            print("  " + p)
        return 1
    print("every l10n reference is in scope with a known key")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
