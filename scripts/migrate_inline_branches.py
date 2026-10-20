#!/usr/bin/env python3
"""Migrate user-facing literals that sit in ternary branches.

These are `cond ? 'X' : 'Y'` expressions — the value is handed to a widget, so
the Text(...)-shaped matcher never sees the literal. Exact (file, old, new)
triples, same contract as the other migrators: a rule whose `old` is absent is
reported, not silently skipped.
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "apps" / "mobile" / "lib"

DRY = "--dry-run" in sys.argv

RULES: list[tuple[str, str, str]] = [
    # --- snackbar / button states -------------------------------------------
    (
        "features/expenses/presentation/pages/expense_form_page.dart",
        "showInfoSnackBar(context, _isEdit ? 'Saved' : 'Created');",
        "showInfoSnackBar(context, _isEdit ? l10n.saved : l10n.created);",
    ),
    (
        "features/income/presentation/pages/income_form_page.dart",
        "showInfoSnackBar(context, _isEdit ? 'Saved' : 'Created');",
        "showInfoSnackBar(context, _isEdit ? l10n.saved : l10n.created);",
    ),
    (
        "features/products/presentation/pages/product_form_page.dart",
        "_isEdit ? 'Product saved' : 'Product created',",
        "_isEdit ? l10n.productSaved : l10n.productCreated,",
    ),
    (
        "features/backup/presentation/pages/backup_page.dart",
        "'Exporting...'",
        "l10n.exporting",
    ),
    (
        "features/reminders/presentation/pages/reminder_form_page.dart",
        "'Saving...'",
        "l10n.saving",
    ),
    # --- form titles --------------------------------------------------------
    (
        "features/expenses/presentation/pages/expense_form_page.dart",
        "title: Text(_isEdit ? 'Edit expense' : 'New expense'),",
        "title: Text(_isEdit ? l10n.editKind(l10n.expense) : l10n.newKind(l10n.expense)),",
    ),
    (
        "features/income/presentation/pages/income_form_page.dart",
        "title: Text(_isEdit ? 'Edit income' : 'New income'),",
        "title: Text(_isEdit ? l10n.editKind(l10n.income) : l10n.newKind(l10n.income)),",
    ),
    (
        "features/payments/presentation/pages/payment_methods_page.dart",
        "'Edit method'",
        "l10n.editKind(l10n.paymentMethod)",
    ),
    # --- required-field validators -----------------------------------------
    (
        "features/expenses/presentation/pages/expense_form_page.dart",
        "? 'Category is required'",
        "? l10n.categoryRequired",
    ),
    (
        "features/income/presentation/pages/income_form_page.dart",
        "? 'Source is required'",
        "? l10n.sourceRequired",
    ),
    (
        "features/parties/presentation/pages/party_form_page.dart",
        "? 'Name is required'",
        "? l10n.nameRequired",
    ),
    (
        "features/products/presentation/pages/product_form_page.dart",
        "? 'Name is required'",
        "? l10n.nameRequired",
    ),
    # --- fallback values ----------------------------------------------------
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "invoice.customerName ?? 'Walk-in customer',",
        "invoice.customerName ?? l10n.walkInCustomer,",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "quotation.customerName ?? 'Walk-in customer',",
        "quotation.customerName ?? l10n.walkInCustomer,",
    ),
    (
        "features/purchases/presentation/pages/purchase_list_page.dart",
        "'No supplier'",
        "l10n.noSupplier",
    ),
    (
        "features/purchases/presentation/pages/purchase_detail_page.dart",
        "'No supplier'",
        "l10n.noSupplier",
    ),
    # --- status words -------------------------------------------------------
    (
        "features/sales/data/repositories/sale_repository_impl.dart",
        "'Unpaid'",
        "l10n.unpaid",
    ),
    (
        "features/purchases/data/repositories/purchase_repository_impl.dart",
        "'Unpaid'",
        "l10n.unpaid",
    ),
    (
        "features/products/presentation/pages/product_list_page.dart",
        "'No products match your search'",
        "l10n.noProductsMatchSearch",
    ),
    (
        "features/inventory/presentation/pages/inventory_dashboard_page.dart",
        "'No low-stock products — all good!'",
        "l10n.noLowStockProducts",
    ),
    (
        "features/notifications/presentation/pages/notification_list_page.dart",
        "'Showing unread'",
        "l10n.showingUnread",
    ),
    (
        "features/parties/presentation/pages/party_ledger_page.dart",
        "'Customer khata'",
        "l10n.customerKhata",
    ),
    (
        "features/parties/presentation/pages/party_ledger_page.dart",
        "'Debit'",
        "l10n.debit",
    ),
    (
        "features/payments/presentation/pages/payment_form_page.dart",
        "'Record receipt'",
        "l10n.recordReceipt",
    ),
    (
        "features/payments/presentation/pages/payment_form_page.dart",
        "'Apply to invoice'",
        "l10n.applyToInvoice",
    ),
    (
        "features/payments/presentation/pages/payment_list_page.dart",
        "'Receipt'",
        "l10n.receipt",
    ),
    (
        "features/business/presentation/pages/business_members_page.dart",
        "'Viewer'",
        "l10n.roleViewer",
    ),
    (
        "features/sync/presentation/pages/sync_status_page.dart",
        "'Never'",
        "l10n.never",
    ),
    (
        "features/sync/presentation/pages/sync_status_page.dart",
        "'Syncing…'",
        "l10n.syncing",
    ),
    (
        "features/sales/presentation/pages/sale_form_page.dart",
        "'Paid (full)'",
        "l10n.paidInFull",
    ),
    (
        "features/purchases/presentation/pages/purchase_form_page.dart",
        "'Paid (full)'",
        "l10n.paidInFull",
    ),
    (
        "features/invoices/presentation/pages/invoice_form_page.dart",
        "'Not set'",
        "l10n.notSet",
    ),
    (
        "features/quotations/presentation/pages/quotation_form_page.dart",
        "'Not set'",
        "l10n.notSet",
    ),
    # --- interpolated branch labels ----------------------------------------
    (
        "features/dashboard/presentation/pages/home_page.dart",
        "? 'To collect ${formatPaisa(receivable)}'",
        "? l10n.toCollectAmount(formatPaisa(receivable))",
    ),
    (
        "features/dashboard/presentation/pages/home_page.dart",
        "? 'To pay ${formatPaisa(payable)}'",
        "? l10n.toPayAmount(formatPaisa(payable))",
    ),
    (
        "features/dashboard/presentation/pages/home_page.dart",
        "? 'In ${formatPaisa(receivable)} · Out ${formatPaisa(payable)}'",
        "? l10n.moneyInOut(\n                                formatPaisa(receivable), formatPaisa(payable))",
    ),
    (
        "features/payments/presentation/pages/payment_form_page.dart",
        "'Due ${formatPaisa(selectedDue)}'",
        "l10n.dueAmount(formatPaisa(selectedDue))",
    ),
    (
        "features/sales/presentation/pages/sale_list_page.dart",
        "'Due ${formatPaisa(sale.dueAmount)}'",
        "l10n.dueAmount(formatPaisa(sale.dueAmount))",
    ),
    (
        "features/purchases/presentation/pages/purchase_list_page.dart",
        "'Due ${formatPaisa(purchase.dueAmount)}'",
        "l10n.dueAmount(formatPaisa(purchase.dueAmount))",
    ),
]


def main() -> int:
    misses: list[str] = []
    hits = 0
    for rel, old, new in RULES:
        path = LIB / rel
        if not path.exists():
            misses.append(f"{rel} (file not found)")
            continue
        src = path.read_text(encoding="utf-8")
        if old not in src:
            misses.append(f"{rel}: {old[:70]}")
            continue
        if not DRY:
            path.write_text(src.replace(old, new, 1), encoding="utf-8")
        hits += 1
    print(f"{'would apply' if DRY else 'applied'} {hits}/{len(RULES)} rule(s)")
    if misses:
        print("MISSES:")
        for m in misses:
            print("  ", m)
    return 1 if misses else 0


if __name__ == "__main__":
    raise SystemExit(main())
