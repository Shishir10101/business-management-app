#!/usr/bin/env python3
"""Adds AppLocalizations delegates to every test MaterialApp.

Phase 11 wired every page to `AppLocalizations.of(context)`, whose generated
implementation asserts non-null. A bare `MaterialApp` registers no delegate,
so `Localizations.of` returns null and every widget test built on the old
literal-rendering pages would crash. This harness fix keeps the tests runnable
against the localized pages. Dry-run by default; pass --apply to write.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TESTS = os.path.join(ROOT, 'apps/mobile/test')

DELEGATES = (
    'localizationsDelegates: const [\n'
    '        AppLocalizations.delegate,\n'
    '        GlobalMaterialLocalizations.delegate,\n'
    '        GlobalWidgetsLocalizations.delegate,\n'
    '        GlobalCupertinoLocalizations.delegate,\n'
    '      ],\n'
    '      supportedLocales: AppLocalizations.supportedLocales,\n'
)

IMPORT = "import 'package:khata/l10n/app_localizations.dart';\n"

# (file, old, new) — exact triples, MISS reported if absent.
RULES = [
    ('backup_page_test.dart',
     'child: const MaterialApp(home: BackupPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const BackupPage(),\n'
     '    ),'),
    ('invoice_list_page_test.dart',
     'child: const MaterialApp(home: InvoiceListPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const InvoiceListPage(),\n'
     '    ),'),
    ('login_page_test.dart',
     'child: const MaterialApp(home: LoginPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const LoginPage(),\n'
     '    ),'),
    ('notification_pages_test.dart',
     'child: const MaterialApp(home: NotificationListPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const NotificationListPage(),\n'
     '    ),'),
    ('notification_pages_test.dart',
     'child: const MaterialApp(home: NotificationSettingsPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const NotificationSettingsPage(),\n'
     '    ),'),
    ('party_list_page_test.dart',
     'child: MaterialApp(home: PartyListPage(kind: kind)),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: PartyListPage(kind: kind),\n'
     '    ),'),
    ('payment_list_page_test.dart',
     'child: const MaterialApp(home: PaymentListPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const PaymentListPage(),\n'
     '    ),'),
    ('product_list_page_test.dart',
     'child: const MaterialApp(home: ProductListPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const ProductListPage(),\n'
     '    ),'),
    ('reminder_list_page_test.dart',
     'child: const MaterialApp(home: ReminderListPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const ReminderListPage(),\n'
     '    ),'),
    ('report_list_page_test.dart',
     'const ProviderScope(child: MaterialApp(home: ReportListPage())),',
     'ProviderScope(\n'
     '        child: MaterialApp(\n'
     '          ' + DELEGATES.replace('      ', '          ') +
     '          home: const ReportListPage(),\n'
     '        ),\n'
     '      ),'),
    ('sale_list_page_test.dart',
     'child: const MaterialApp(home: SaleListPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const SaleListPage(),\n'
     '    ),'),
    ('sync_status_page_test.dart',
     'child: const MaterialApp(home: SyncStatusPage()),',
     'child: MaterialApp(\n'
     '      ' + DELEGATES +
     '      home: const SyncStatusPage(),\n'
     '    ),'),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    misses, hits = [], 0
    per_file = {}
    for fname, old, new in RULES:
        per_file.setdefault(fname, []).append((old, new))

    for fname, rules in per_file.items():
        path = os.path.join(TESTS, fname)
        if not os.path.isfile(path):
            misses.append(f'{fname}: FILE NOT FOUND')
            continue
        with open(path, encoding='utf-8') as fh:
            text = fh.read()
        for old, new in rules:
            if old not in text:
                misses.append(f'{fname}: MISS {old!r}')
                continue
            text = text.replace(old, new)
            hits += 1
        if IMPORT not in text:
            # insert after the last existing package: import
            lines = text.split('\n')
            last_pkg = 0
            for i, line in enumerate(lines):
                if line.startswith("import 'package:"):
                    last_pkg = i
            lines.insert(last_pkg + 1, IMPORT.rstrip('\n'))
            text = '\n'.join(lines)
        if args.apply:
            with open(path, 'w', encoding='utf-8') as fh:
                fh.write(text)

    print(f'{"APPLIED" if args.apply else "DRY RUN"}: {hits} MaterialApp(s) '
          f'patched across {len(per_file)} file(s)')
    if misses:
        print(f'\n{len(misses)} MISS(ES):')
        for m in misses:
            print(f'  {m}')
        sys.exit(1)
    print('no misses')


if __name__ == '__main__':
    main()
