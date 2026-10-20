#!/usr/bin/env python3
"""Wires the leftover Phase-11 literals to their ARB keys.

Exact (file, old, new) triples. A rule whose `old` is absent is reported as
a MISS and nothing is written for it — the summary is a real signal, never
silently skipped. Dry-run by default; pass --apply to write.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'apps/mobile/lib')

# (relative path under lib/, [(old, new), ...])
RULES = [
    ('features/backup/presentation/pages/backup_page.dart', [
        ("l10n.exporting : 'Export backup'", "l10n.exporting : l10n.exportBackup"),
        ("showInfoSnackBar(context, 'Clipboard is empty')",
         "showInfoSnackBar(context, l10n.clipboardEmpty)"),
    ]),
    ('features/business/presentation/pages/business_setup_page.dart', [
        ("'Please enter a valid email'", "l10n.emailInvalid"),
    ]),
    ('features/notifications/presentation/pages/notification_list_page.dart', [
        ("l10n.showingUnread : 'Showing all'", "l10n.showingUnread : l10n.showingAll"),
        ("'Nothing matches this filter'", "l10n.nothingMatchesFilter"),
        ("'No notifications yet'", "l10n.noNotifications"),
        ("'Nothing to mark'", "l10n.nothingToMark"),
    ]),
    ('features/notifications/presentation/pages/notification_settings_page.dart', [
        ("'Push notifications'", "l10n.pushNotifications"),
        ("'Registered devices'", "l10n.registeredDevices"),
    ]),
    ('features/parties/presentation/pages/party_form_page.dart', [
        ("_isEdit ? 'Save changes' : 'Create'", "_isEdit ? l10n.saveChanges : l10n.create"),
        ("'Enter a valid amount.'", "l10n.amountInvalidFull"),
    ]),
    ('features/parties/presentation/pages/party_ledger_page.dart', [
        ("'Supplier khata'", "l10n.supplierKhata"),
        ("'To collect'", "l10n.toCollect"),
        ("'To pay'", "l10n.toPay"),
    ]),
    ('features/parties/presentation/pages/party_list_page.dart', [
        ("'To collect'", "l10n.toCollect"),
        ("'To pay'", "l10n.toPay"),
    ]),
    ('features/payments/presentation/pages/payment_form_page.dart', [
        ("'Record payment'", "l10n.recordPayment"),
        ("l10n.applyToInvoice : 'Apply to bill'",
         "l10n.applyToInvoice : l10n.applyToBill"),
    ]),
    ('features/payments/presentation/pages/payment_list_page.dart', [
        ("'To collect'", "l10n.toCollect"),
        ("'To pay'", "l10n.toPay"),
    ]),
    ('features/payments/presentation/pages/payment_methods_page.dart', [
        ("'Payments already recorded with this method keep working. '",
         "l10n.methodChangeNote"),
        ("'New method'", "l10n.newMethod"),
    ]),
    ('features/purchases/presentation/pages/purchase_detail_page.dart', [
        ("'Stock will be reduced back and the supplier khata reversed. '",
         "l10n.purchaseDeleteNoteFull"),
    ]),
    ('features/reports/presentation/pages/expense_report_page.dart', [
        ("ReportTotal('Categories',", "ReportTotal(l10n.categories,"),
    ]),
    ('features/reports/presentation/pages/profit_loss_page.dart', [
        ("'Revenue excludes VAT. '", "l10n.revenueExcludesVat"),
    ]),
    ('features/reports/presentation/pages/sales_report_page.dart', [
        ("ReportTotal('Sales',", "ReportTotal(l10n.sales,"),
    ]),
    ('features/reports/presentation/pages/stock_report_page.dart', [
        ("ReportTotal('Low stock',", "ReportTotal(l10n.lowStockAlert,"),
    ]),
    ('features/reports/presentation/pages/receivable_payable_page.dart', [
        ("'To collect'", "l10n.toCollect"),
        ("'To pay'", "l10n.toPay"),
    ]),
    ('features/sales/presentation/pages/sale_detail_page.dart', [
        ("'Walk-in customer'", "l10n.walkInCustomer"),
        ("'Discount', '-${formatPaisa(sale.discountAmount)}'",
         "l10n.discount, '-${formatPaisa(sale.discountAmount)}'"),
        ("'Stock will be restored and the customer khata reversed. '",
         "l10n.saleDeleteNoteFull"),
    ]),
    ('features/sales/presentation/pages/sale_form_page.dart', [
        ("'Rate (Rs.)'", "l10n.rateRs"),
        ("'Disc (Rs.)'", "l10n.discountRs"),
        ("'Add at least one item'", "l10n.addAtLeastOneItem"),
    ]),
    ('features/quotations/presentation/pages/quotation_form_page.dart', [
        ("'Rate (Rs.)'", "l10n.rateRs"),
        ("'Disc (Rs.)'", "l10n.discountRs"),
        ("'Add at least one item'", "l10n.addAtLeastOneItem"),
    ]),
    ('features/reminders/presentation/pages/reminder_form_page.dart', [
        ("_isEdit ? 'Edit reminder' : 'New reminder'",
         "_isEdit ? l10n.editReminder : l10n.newReminder"),
        ("'A title is required'", "l10n.reminderTitleRequired"),
        ("'Save reminder'", "l10n.saveReminder"),
        ("'Reminder saved'", "l10n.reminderSaved"),
    ]),
    ('features/reminders/presentation/pages/reminder_list_page.dart', [
        ("'Needs attention'", "l10n.needsAttention"),
        ("'Nothing is due right now'", "l10n.nothingDue"),
        ("'Marked done'", "l10n.markedDone"),
    ]),
    ('features/sync/presentation/pages/sync_status_page.dart', [
        ("l10n.syncing : 'Sync now'", "l10n.syncing : l10n.syncNow"),
    ]),
    ('features/products/presentation/pages/product_form_page.dart', [
        ("_isEdit ? 'Edit product' : 'New product'",
         "_isEdit ? l10n.editProduct : l10n.newProduct"),
        ("'Enter a valid amount'", "l10n.amountInvalid"),
    ]),
    ('features/dashboard/presentation/pages/home_page.dart', [
        ('label: "Today\'s sales"', 'label: l10n.todaysSales'),
        ('label: "Today\'s profit"', 'label: l10n.todaysProfit'),
    ]),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    misses, hits, files_touched = [], 0, []
    for rel, rules in RULES:
        path = os.path.join(LIB, rel)
        if not os.path.isfile(path):
            misses.append(f'{rel}: FILE NOT FOUND')
            continue
        with open(path, encoding='utf-8') as fh:
            text = fh.read()
        original = text
        for old, new in rules:
            if old not in text:
                misses.append(f'{rel}: MISS {old!r}')
                continue
            # Replace every occurrence (e.g. the two clipboard sites).
            count = text.count(old)
            text = text.replace(old, new)
            hits += count
            if count > 1:
                print(f'{rel}: {old!r} x{count}')
        if text != original:
            files_touched.append(rel)
            if args.apply:
                with open(path, 'w', encoding='utf-8') as fh:
                    fh.write(text)

    print(f'\n{"APPLIED" if args.apply else "DRY RUN"}: '
          f'{hits} replacement(s) across {len(files_touched)} file(s)')
    if misses:
        print(f'\n{len(misses)} MISS(ES):')
        for m in misses:
            print(f'  {m}')
        sys.exit(1)
    print('no misses')


if __name__ == '__main__':
    main()
