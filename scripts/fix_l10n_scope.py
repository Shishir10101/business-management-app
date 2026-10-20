#!/usr/bin/env python3
"""Adds `final l10n = AppLocalizations.of(context);` to methods that use
`l10n` without declaring it.

The Phase 11 migration wired `l10n.X` references into validator closures,
dialog builders and snackbar helpers that never had a `final l10n = ...` —
Dart compile errors the old scope checker could not see. Every flagged
method is an instance method of a State class (or a top-level function with
a `BuildContext context` parameter), so the declaration can always be
resolved from `context`.

Insertion is brace-aware: for a multi-line header
(`Future<void> foo(\n  ...\n) async {`) the declaration goes AFTER the
opening brace line, not among the parameters. A method that already has a
declaration between its header and the first use is skipped. Also reports
duplicate declarations in the same scope (a separate compile error).

Dry-run by default; pass --apply to write.
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_localizations import (  # noqa: E402
    _function_header_re,
    _is_boundary,
)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "apps", "mobile", "lib")

DECL = re.compile(
    r"\b(?:late\s+)?(?:final\s+)?(?:AppLocalizations\s+)?l10n\s*="
    r"|\bAppLocalizations\s+l10n\b"
)
DECL_LINE = "final l10n = AppLocalizations.of(context);"


def body_open_line(lines: list[str], header_idx: int) -> int:
    """Line index of the `{` that opens the body of the header at header_idx.

    Handles multi-line headers by counting braces from the header line.
    Returns -1 when:
      * the member is arrow-bodied (`=> [...]`) — there is no block to insert
        into, and the fix must be a parameter instead of a declaration;
      * no `{` is found before the next method header or end of file.
    """
    headers = _function_header_re()
    depth = 0
    for j in range(header_idx, len(lines)):
        line = lines[j]
        # Arrow body before any brace on this line: nothing to insert into.
        arrow = line.find("=>")
        brace = line.find("{")
        if arrow >= 0 and (brace < 0 or arrow < brace):
            return -1
        depth += line.count("{") - line.count("}")
        if "{" in line and depth > 0:
            return j
        if j > header_idx and any(p.match(lines[j]) for p in headers):
            return -1
    return -1


def method_of_use(lines: list[str], use_idx: int) -> int:
    """Nearest class-member/top-level header at or above a use line, or -1.

    Local functions (indent >= 4) are skipped: they capture the enclosing
    method's scope, so the use belongs to the enclosing method.
    """
    headers = _function_header_re()
    for i in range(use_idx, -1, -1):
        if _is_boundary(lines, i, headers):
            return i
    return -1


def fix_file(path: str, apply: bool) -> tuple[int, list[str]]:
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    headers = _function_header_re()
    problem_uses = []
    for idx, line in enumerate(lines):
        stripped = re.sub(r"'[^']*'", "''", line)
        stripped = re.sub(r'"[^"]*"', '""', stripped)
        for m in re.finditer(r"\bl10n\.(\w+)", stripped):
            in_scope = False
            for i in range(idx, -1, -1):
                if DECL.search(lines[i]):
                    in_scope = True
                    break
                if i < idx and _is_boundary(lines, i, headers):
                    break
            if not in_scope:
                problem_uses.append(idx)
                break  # one fix per line is enough

    notes: list[str] = []
    inserted = 0
    # Insert from the bottom up so earlier indices stay valid.
    for use_idx in reversed(problem_uses):
        header_idx = method_of_use(lines, use_idx)
        if header_idx < 0:
            notes.append(f"line {use_idx + 1}: use outside any method")
            continue
        # Already declared between header and use?
        declared = False
        for i in range(header_idx, use_idx):
            if DECL.search(lines[i]):
                declared = True
                break
        if declared:
            continue
        open_idx = body_open_line(lines, header_idx)
        if open_idx < 0:
            is_static = re.match(
                r"\s*static\s", lines[header_idx]) is not None
            kind = "static member" if is_static else "arrow-bodied member"
            notes.append(
                f"line {use_idx + 1}: enclosing {kind} cannot resolve "
                f"`context` — needs an `AppLocalizations l10n` parameter "
                f"(manual fix)"
            )
            continue
        indent = re.match(r"\s*", lines[open_idx]).group(0)
        lines.insert(open_idx + 1, f"{indent}  {DECL_LINE}")
        inserted += 1

    # Duplicate decls in the same method scope (the migration inserted a
    # second `final l10n = ...` below the original in some build methods —
    # Dart rejects a redeclaration in one scope). Scope-aware, not just
    # adjacent-line: the extra decl may sit after a blank line.
    decl_lines = [
        i for i, line in enumerate(lines)
        if re.match(r"\s*final\s+l10n\s*=\s*AppLocalizations\.of\(context\);\s*$",
                    line)
    ]
    drop: set[int] = set()
    for a, b in zip(decl_lines, decl_lines[1:]):
        if method_of_use(lines, a) != method_of_use(lines, b):
            continue
        if method_of_use(lines, a) < 0:
            continue
        between = [
            i for i in range(a + 1, b)
            if any(p.match(lines[i]) for p in headers)
            and not _is_boundary(lines, i, headers)
        ]
        if not between:
            drop.add(b)  # remove the later (inserted) one
    if drop:
        lines = [l for i, l in enumerate(lines) if i not in drop]
        notes.append(f"removed {len(drop)} duplicate `final l10n` "
                     f"declaration(s)")

    if apply and (inserted or drop):
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines))
    return inserted, notes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    # Re-derive the problem files from the checker itself.
    from check_localizations import arb_keys
    keys = arb_keys()
    problem_files = []
    for dirpath, _, names in os.walk(LIB):
        if "l10n" in dirpath:
            continue
        for name in sorted(names):
            if not name.endswith(".dart"):
                continue
            p = os.path.join(dirpath, name)
            src = open(p, encoding="utf-8").read()
            if "l10n." not in src or name == "app_localizations.dart":
                continue
            lines = src.split("\n")
            headers = _function_header_re()
            bad = False
            for idx, line in enumerate(lines):
                stripped = re.sub(r"'[^']*'", "''", line)
                stripped = re.sub(r'"[^"]*"', '""', stripped)
                for m in re.finditer(r"\bl10n\.(\w+)", stripped):
                    if m.group(1) not in keys:
                        continue
                    in_scope = False
                    for i in range(idx, -1, -1):
                        if DECL.search(lines[i]):
                            in_scope = True
                            break
                        if i < idx and _is_boundary(lines, i, headers):
                            break
                    if not in_scope:
                        bad = True
                        break
                if bad:
                    break
            if bad:
                problem_files.append(p)

    total, all_notes = 0, []
    for p in problem_files:
        inserted, notes = fix_file(p, args.apply)
        rel = os.path.relpath(p, ROOT).replace("\\", "/")
        if args.apply:
            total += inserted
            if inserted or notes:
                print(f"{rel}: inserted {inserted} decl(s)"
                      + (f" + notes: {'; '.join(notes)}" if notes else ""))
            for n in notes:
                all_notes.append(f"{rel}: {n}")
        else:
            print(f"{rel}: would fix ({inserted} insert(s)"
                  + (f", notes: {'; '.join(notes)}" if notes else "") + ")")
    if not args.apply:
        print(f"\nDRY RUN — re-run with --apply to write {len(problem_files)} "
              f"file(s)")
    else:
        print(f"\ninserted {total} declaration(s) across "
              f"{len(problem_files)} file(s)")
        for n in all_notes:
            print(f"  NOTE {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
