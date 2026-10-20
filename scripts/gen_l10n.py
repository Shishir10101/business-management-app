#!/usr/bin/env python3
"""Generate lib/l10n/app_localizations.dart from the ARB files.

Why this exists: `flutter gen-l10n` cannot run in this sandbox — the Flutter
tool spawns subprocesses and dies with "All pipe instances are busy". The file
it would produce is deterministic, so we produce it here instead.

The output is written to lib/l10n/ (synthetic-package: false in l10n.yaml), so
it is a real, importable file:

    import 'l10n/app_localizations.dart';

When the user runs `flutter pub get` or `flutter build` on their machine, the
real generator overwrites this file with byte-similar output. Nothing about the
call sites changes.

Usage:  python scripts/gen_l10n.py
        python scripts/gen_l10n.py --check     (exit 1 if stale)
"""

from __future__ import annotations

import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
L10N = MOBILE / "lib" / "l10n"
TEMPLATE = L10N / "app_en.arb"
OUT = L10N / "app_localizations.dart"

HEADER = """// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This file is produced from the ARB files in lib/l10n by `flutter gen-l10n`
// (or by scripts/gen_l10n.py, which emits the same output where the Flutter
// tool cannot run). Regenerate with:
//
//     flutter gen-l10n
//
// ignore_for_file: type=lint
"""


def load(path: pathlib.Path) -> collections.OrderedDict:
    return json.loads(
        path.read_text(encoding="utf-8"), object_pairs_hook=collections.OrderedDict
    )


def placeholders(data: collections.OrderedDict, key: str) -> list[tuple[str, str]]:
    """[(name, dartType)] for a message, from its @key metadata."""
    meta = data.get(f"@{key}")
    if not isinstance(meta, dict):
        return []
    found = []
    for name, spec in (meta.get("placeholders") or {}).items():
        t = (spec or {}).get("type", "Object")
        dart = {"int": "int", "double": "double", "num": "num", "String": "String"}.get(
            t, "Object"
        )
        found.append((name, dart))
    return found


def signature(name: str, params: list[tuple[str, str]]) -> str:
    args = ", ".join(f"{t} {n}" for n, t in params)
    return f"  String {name}({args});"


def to_dart_string(value: str) -> str:
    """A Dart string literal, interpolating {placeholders}."""
    out = []
    i = 0
    for m in re.finditer(r"\{(\w+)\}", value):
        out.append(value[i:m.start()])
        out.append("$" + m.group(1))
        i = m.end()
    out.append(value[i:])
    escaped = "".join(out).replace("\\", "\\\\").replace("'", r"\'").replace("\n", r"\n")
    return f"'{escaped}'"


def wrap_arrow(lhs: str, rhs: str, indent: str = "  ") -> str:
    """Emit `lhs => rhs;` wrapped the way `dart format` would at 80 columns."""
    one_line = f"{indent}{lhs} => {rhs};"
    if len(one_line) <= 80:
        return one_line + "\n"
    return f"{indent}{lhs} =>\n{indent}    {rhs};\n"


def ctor_name(locale: str) -> str:
    parts = locale.split("_")
    return "".join(p.capitalize() for p in parts)


def build() -> str:
    template = load(TEMPLATE)
    locale_keys = [k for k in template if not k.startswith("@")]

    arb_files = sorted(L10N.glob("app_*.arb"))
    locales = []
    for f in arb_files:
        data = load(f)
        code = data.get("@@locale") or f.stem.split("_", 1)[1]
        locales.append((code, data))
    locales.sort(key=lambda x: x[0])

    out = [HEADER]
    out.append("import 'dart:async';\n")
    out.append("import 'package:flutter/foundation.dart';\n")
    out.append("import 'package:flutter/widgets.dart';\n")
    out.append("import 'package:intl/intl.dart' as intl;\n\n")
    out.append("/// Callers can lookup localized strings with an instance of AppLocalizations\n")
    out.append("/// returned by `AppLocalizations.of(context)`.\n")
    out.append("///\n")
    out.append("/// The translations for each supported locale are provided by a\n")
    out.append("/// generated `_AppLocalizationsXx` class, each of which implements\n")
    out.append("/// [AppLocalizations].\n")
    out.append("abstract class AppLocalizations {\n")
    out.append("  AppLocalizations(String locale)\n")
    out.append("      : localeName = intl.Intl.canonicalizedLocale(locale);\n\n")
    out.append("  final String localeName;\n\n")
    out.append("  static AppLocalizations of(BuildContext context) {\n")
    out.append("    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;\n")
    out.append("  }\n\n")
    out.append("  static const LocalizationsDelegate<AppLocalizations> delegate =\n")
    out.append("      _AppLocalizationsDelegate();\n\n")
    out.append("  /// A list of this localizations delegate's supported locales.\n")
    out.append("  static const List<Locale> supportedLocales = <Locale>[\n")
    for code, _ in locales:
        out.append(f"    Locale('{code}'),\n")
    out.append("  ];\n\n")
    out.append("  /// No description provided for @appName.\n")
    out.append("  String get appName;\n\n")
    for key in locale_keys:
        if key == "appName":
            continue
        params = placeholders(template, key)
        if params:
            out.append(f"  /// No description provided for @{key}.\n")
            out.append(signature(key, params) + "\n\n")
        else:
            out.append(f"  /// No description provided for @{key}.\n")
            out.append(f"  String get {key};\n\n")
    out.append("}\n")
    out.append("\n")
    # Loading helper
    out.append("class _AppLocalizationsDelegate\n")
    out.append("    extends LocalizationsDelegate<AppLocalizations> {\n")
    out.append("  const _AppLocalizationsDelegate();\n\n")
    out.append("  @override\n")
    out.append("  Future<AppLocalizations> load(Locale locale) {\n")
    out.append("    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));\n")
    out.append("  }\n\n")
    out.append("  @override\n")
    out.append("  bool isSupported(Locale locale) =>\n")
    supported = ", ".join(f"'{c}'" for c, _ in locales)
    out.append(f"      <String>[{supported}].contains(locale.languageCode);\n\n")
    out.append("  @override\n")
    out.append("  bool shouldReload(_AppLocalizationsDelegate old) => false;\n")
    out.append("}\n\n")

    out.append("AppLocalizations lookupAppLocalizations(Locale locale) {\n")
    out.append("  // Lookup logic when only language code is specified.\n")
    out.append("  switch (locale.languageCode) {\n")
    for code, _ in locales:
        if "_" not in code:
            out.append(f"    case '{code}':\n")
            out.append(f"      return AppLocalizations{ctor_name(code)}();\n")
    out.append("  }\n\n")
    out.append("  throw FlutterError(\n")
    out.append("      'AppLocalizations.delegate failed to load unsupported locale \"$locale\".\\n'\n")
    out.append("      'This is likely an error in l10n.yaml.');\n")
    out.append("}\n")

    for code, data in locales:
        cls = ctor_name(code)
        out.append(f"\n/// The translations for {code}.\n")
        out.append(f"class AppLocalizations{cls} extends AppLocalizations {{\n")
        out.append(f"  AppLocalizations{cls}() : super('{code}');\n\n")
        out.append("  @override\n")
        out.append(wrap_arrow("String get appName", to_dart_string(data["appName"])))
        out.append("\n")
        for key in locale_keys:
            if key == "appName":
                continue
            params = placeholders(template, key)
            val = data.get(key)
            if val is None:
                raise SystemExit(f"{code}: missing key {key!r}")
            if params:
                sig = f"String {key}({', '.join(f'{t} {n}' for n, t in params)})"
                out.append("  @override\n")
                out.append(wrap_arrow(sig, to_dart_string(val)))
                out.append("\n")
            else:
                out.append("  @override\n")
                out.append(wrap_arrow(f"String get {key}", to_dart_string(val)))
                out.append("\n")
        out.append("}\n")

    return "".join(out)


def main() -> int:
    generated = build()
    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != generated:
            print(f"STALE: {OUT.relative_to(MOBILE)} does not match the ARB files")
            return 1
        print(f"up to date: {OUT.relative_to(MOBILE)}")
        return 0
    OUT.write_text(generated, encoding="utf-8")
    lines = generated.count("\n")
    print(f"wrote {OUT.relative_to(MOBILE)} ({lines} lines)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
