#!/usr/bin/env python3
"""Swaps the native Gregorian showDatePicker for the BS picker in form pages.

Every form page keeps the same call shape (context / initialDate /
firstDate / lastDate are all named), so the picker drops straight in — the
bounds are AD, exactly what showBsDatePicker expects. Dry-run by default;
pass --apply to write.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'apps/mobile/lib')

FILES = [
    'features/expenses/presentation/pages/expense_form_page.dart',
    'features/invoices/presentation/pages/invoice_form_page.dart',
    'features/income/presentation/pages/income_form_page.dart',
    'features/reminders/presentation/pages/reminder_form_page.dart',
    'features/payments/presentation/pages/payment_form_page.dart',
    'features/quotations/presentation/pages/quotation_form_page.dart',
]

IMPORT_ANCHOR = "import '../../../../core/widgets/khata_snackbars.dart';\n"
IMPORT_NEW = IMPORT_ANCHOR + "import '../../../../core/widgets/bs_date_picker.dart';\n"

CALL_OLD = 'final picked = await showDatePicker('
CALL_NEW = 'final picked = await showBsDatePicker('


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    misses, patched = [], []
    for rel in FILES:
        path = os.path.join(LIB, rel)
        if not os.path.isfile(path):
            misses.append(f'{rel}: FILE NOT FOUND')
            continue
        with open(path, encoding='utf-8') as fh:
            text = fh.read()
        if CALL_OLD not in text:
            misses.append(f'{rel}: MISS showDatePicker call')
            continue
        if IMPORT_ANCHOR not in text:
            misses.append(f'{rel}: MISS import anchor')
            continue
        text = text.replace(CALL_OLD, CALL_NEW)
        text = text.replace(IMPORT_ANCHOR, IMPORT_NEW)
        patched.append(rel)
        if args.apply:
            with open(path, 'w', encoding='utf-8') as fh:
                fh.write(text)

    print(f'{"APPLIED" if args.apply else "DRY RUN"}: {len(patched)} file(s) '
          f'switched to showBsDatePicker')
    if misses:
        print(f'\n{len(misses)} MISS(ES):')
        for m in misses:
            print(f'  {m}')
        sys.exit(1)
    print('no misses')


if __name__ == '__main__':
    main()
