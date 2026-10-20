#!/usr/bin/env python3
"""Second wave of parameterised-literal migrations (Phase 11 residual sweep).

Same contract as migrate_interpolated_strings.py: exact (file, old, new)
triples; a rule whose `old` no longer appears is reported as a miss rather
than silently skipped, so the exit summary is a real signal.

Some literals are reused across sibling pages (the four list pages share one
"could not load X" shape), so those rules are listed once per file.
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "apps" / "mobile" / "lib"

DRY = "--dry-run" in sys.argv

RULES: list[tuple[str, str, str]] = [
    # ---------- shared: "Could not load <thing>.\n$error" ----------
    *[
        (f, f"'Could not load {what}.\\n$error'", f"l10n.couldNotLoadX(l10n.{key}, '$error')")
        for f, what, key in [
            ("features/reports/presentation/pages/receivable_payable_page.dart", "balances", "balances"),
            ("features/reports/presentation/pages/expense_report_page.dart", "the expense report", "expenseReport"),
            ("features/reports/presentation/pages/income_report_page.dart", "the income report", "incomeReport"),
            ("features/reports/presentation/pages/profit_loss_page.dart", "the profit & loss", "profitAndLoss"),
            ("features/reports/presentation/pages/sales_report_page.dart", "the sales report", "salesReportTitle"),
            ("features/reports/presentation/pages/stock_report_page.dart", "the stock report", "stockReportTitle"),
            ("features/invoices/presentation/pages/invoice_list_page.dart", "invoices", "invoices"),
            ("features/invoices/presentation/pages/invoice_detail_page.dart", "invoice", "invoice"),
            ("features/purchases/presentation/pages/purchase_list_page.dart", "purchases", "purchasesTitle"),
            ("features/purchases/presentation/pages/purchase_detail_page.dart", "purchase", "purchase"),
            ("features/quotations/presentation/pages/quotation_list_page.dart", "quotations", "quotationsTitle"),
            ("features/quotations/presentation/pages/quotation_detail_page.dart", "quotation", "quotation"),
            ("features/sales/presentation/pages/sale_list_page.dart", "sales", "salesTitle"),
            ("features/sales/presentation/pages/sale_detail_page.dart", "sale", "sale"),
            ("features/payments/presentation/pages/payment_list_page.dart", "payments", "payments"),
            ("features/payments/presentation/pages/payment_methods_page.dart", "methods", "paymentMethods"),
            ("features/inventory/presentation/pages/stock_movements_page.dart", "movements", "stockMovements"),
            ("features/expenses/presentation/pages/expense_list_page.dart", "expenses", "expenses"),
            ("features/income/presentation/pages/income_list_page.dart", "income", "income"),
            ("features/notifications/presentation/pages/notification_list_page.dart", "notifications", "notifications"),
            ("features/notifications/presentation/pages/notification_settings_page.dart", "devices", "devices"),
            ("features/notifications/presentation/pages/notification_settings_page.dart", "settings", "settings"),
            ("features/reminders/presentation/pages/reminder_list_page.dart", "reminders", "reminders"),
            ("features/business/presentation/pages/business_list_page.dart", "businesses", "businesses"),
            ("features/parties/presentation/pages/party_ledger_page.dart", "khata", "khata"),
        ]
    ],
    # ---------- one-off load errors ----------
    (
        "features/business/presentation/pages/business_setup_page.dart",
        "'Could not create business: $e'",
        "l10n.couldNotCreateBusiness('$e')",
    ),
    (
        "features/business/presentation/pages/business_list_page.dart",
        "'Could not switch business: $e'",
        "l10n.couldNotSwitchBusiness('$e')",
    ),
    (
        "features/parties/presentation/pages/party_list_page.dart",
        "'Could not load.\\n$error'",
        "l10n.couldNotLoad('$error')",
    ),
    (
        "features/products/presentation/pages/category_manage_page.dart",
        "'Could not load.\\n$message'",
        "l10n.couldNotLoad('$message')",
    ),
    # ---------- chart / list empty states ----------
    (
        "features/reports/presentation/widgets/report_charts.dart",
        "'No data in this range'",
        "l10n.noDataInRange",
    ),
    (
        "features/reports/presentation/widgets/report_charts.dart",
        "'Nothing to break down'",
        "l10n.nothingToBreakDown",
    ),
    (
        "features/reports/presentation/pages/stock_report_page.dart",
        "'No products match this filter'",
        "l10n.noProductsMatchFilter",
    ),
    (
        "features/reports/presentation/pages/sales_report_page.dart",
        "'No products sold in this range'",
        "l10n.noProductsSoldInRange",
    ),
    (
        "features/reports/presentation/pages/sales_report_page.dart",
        "'No sales to customers in this range'",
        "l10n.noSalesToCustomersInRange",
    ),
    (
        "features/reports/presentation/pages/receivable_payable_page.dart",
        "'Nobody owes you money'",
        "l10n.nobodyOwesYou",
    ),
    (
        "features/reports/presentation/pages/receivable_payable_page.dart",
        "'You owe nobody'",
        "l10n.youOweNobody",
    ),
    # ---------- counted section headers ----------
    # NOTE: the middle dot is written literally (U+00B7), not as a \u escape —
    # a literal escape sequence in a non-raw Python string is not decoded here.
    (
        "features/reports/presentation/pages/receivable_payable_page.dart",
        "'Receivables \u00b7 ${data.receivables.length}'",
        "l10n.receivablesCount(data.receivables.length)",
    ),
    (
        "features/reports/presentation/pages/receivable_payable_page.dart",
        "'Payables \u00b7 ${data.payables.length}'",
        "l10n.payablesCount(data.payables.length)",
    ),
    (
        "features/reports/presentation/pages/sales_report_page.dart",
        "'Sales trend \u00b7 ${_scope(data.groupBy)}'",
        "l10n.salesTrendScope(_scope(data.groupBy))",
    ),
    # ---------- line totals ----------
    (
        "features/invoices/presentation/pages/invoice_form_page.dart",
        "'Line total: ${formatPaisa(line.draft.lineTotal)}'",
        "l10n.lineTotalIs(formatPaisa(line.draft.lineTotal))",
    ),
    # ---------- detail-page item counts ----------
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "'Items (${invoice.items.length})'",
        "l10n.itemsCount(invoice.items.length)",
    ),
    (
        "features/purchases/presentation/pages/purchase_detail_page.dart",
        "'Items (${purchase.items.length})'",
        "l10n.itemsCount(purchase.items.length)",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "'Items (${quotation.items.length})'",
        "l10n.itemsCount(quotation.items.length)",
    ),
    (
        "features/sales/presentation/pages/sale_detail_page.dart",
        "'Items (${sale.items.length})'",
        "l10n.itemsCount(sale.items.length)",
    ),
    # ---------- notes / terms ----------
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "'Notes: ${invoice.notes}'",
        "l10n.notesLabel('${invoice.notes}')",
    ),
    (
        "features/purchases/presentation/pages/purchase_detail_page.dart",
        "'Notes: ${purchase.notes}'",
        "l10n.notesLabel('${purchase.notes}')",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "'Notes: ${quotation.notes}'",
        "l10n.notesLabel('${quotation.notes}')",
    ),
    (
        "features/sales/presentation/pages/sale_detail_page.dart",
        "'Notes: ${sale.notes}'",
        "l10n.notesLabel('${sale.notes}')",
    ),
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "'Terms: ${invoice.terms}'",
        "l10n.termsLabel('${invoice.terms}')",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "'Terms: ${quotation.terms}'",
        "l10n.termsLabel('${quotation.terms}')",
    ),
    # ---------- invoice / quotation dates ----------
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "'Issued ${_date(invoice.issueDate)}'",
        "l10n.issuedOn(_date(invoice.issueDate))",
    ),
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "'Due ${_date(invoice.dueDate!)}'",
        "l10n.dueOn(_date(invoice.dueDate!))",
    ),
    (
        "features/invoices/presentation/pages/invoice_detail_page.dart",
        "'From sale ${invoice.saleInvoiceNumber}'",
        "l10n.fromSale('${invoice.saleInvoiceNumber}')",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "'Issued ${_date(quotation.issueDate)}'",
        "l10n.issuedOn(_date(quotation.issueDate))",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "'Valid until ${_date(quotation.validUntil!)}'",
        "l10n.validUntilOn(_date(quotation.validUntil!))",
    ),
    (
        "features/quotations/presentation/pages/quotation_detail_page.dart",
        "'Converted to sale #${quotation.convertedSaleId}'",
        "l10n.convertedToSale('${quotation.convertedSaleId}')",
    ),
    # ---------- members / offline banner / inventory ----------
    (
        "features/business/presentation/pages/business_members_page.dart",
        "'${member.email}\\n${member.role}'",
        "l10n.emailAndRole('${member.email}', '${member.role}')",
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
            misses.append(f"{rel}: {old}")
            continue
        if not DRY:
            path.write_text(src.replace(old, new), encoding="utf-8")
        hits += 1
    print(f"{'would apply' if DRY else 'applied'} {hits}/{len(RULES)} rule(s)")
    if misses:
        print("MISSES:")
        for m in misses:
            print("  ", m)
    return 1 if misses else 0


if __name__ == "__main__":
    raise SystemExit(main())
