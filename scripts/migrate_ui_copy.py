#!/usr/bin/env python3
"""Migrate the remaining user-facing copy found by the broad idempotent sweep.

Every rule is an exact (file, old, new) triple. Rules whose `old` is absent are
reported as misses, so the summary is a real signal rather than a no-op.
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "apps" / "mobile" / "lib"

DRY = "--dry-run" in sys.argv

RULES: list[tuple[str, str, str]] = [
    # ---- invoice detail / form summaries --------------------------------
    ("features/invoices/presentation/pages/invoice_detail_page.dart", "'Subtotal'", "l10n.subtotal"),
    ("features/invoices/presentation/pages/invoice_detail_page.dart", "'Discount'", "l10n.discount"),
    ("features/invoices/presentation/pages/invoice_detail_page.dart", "'Total'", "l10n.total"),
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Subtotal'", "l10n.subtotal"),
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Discount'", "l10n.discount"),
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Total'", "l10n.total"),
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Rate (Rs.)'", "l10n.rateRs"),
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Disc (Rs.)'", "l10n.discountRs"),
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Add at least one item'", "l10n.addAtLeastOneItem"),
    ("features/purchases/presentation/pages/purchase_form_page.dart", "'Rate (Rs.)'", "l10n.rateRs"),
    ("features/purchases/presentation/pages/purchase_form_page.dart", "'Disc (Rs.)'", "l10n.discountRs"),
    ("features/purchases/presentation/pages/purchase_form_page.dart", "'Add at least one item'", "l10n.addAtLeastOneItem"),
    # ---- success toasts -------------------------------------------------
    ("features/invoices/presentation/pages/invoice_form_page.dart", "'Invoice created'", "l10n.invoiceCreated"),
    ("features/invoices/presentation/pages/invoice_detail_page.dart", "'Invoice deleted'", "l10n.invoiceDeleted"),
    ("features/quotations/presentation/pages/quotation_form_page.dart", "'Quotation created'", "l10n.quotationCreated"),
    ("features/quotations/presentation/pages/quotation_detail_page.dart", "'Quotation deleted'", "l10n.quotationDeleted"),
    ("features/quotations/presentation/pages/quotation_detail_page.dart", "'Converted to sale'", "l10n.convertedToSaleToast"),
    ("features/sales/presentation/pages/sale_form_page.dart", "'Sale created'", "l10n.saleCreated"),
    ("features/sales/presentation/pages/sale_detail_page.dart", "'Sale reversed'", "l10n.saleReversed"),
    ("features/sales/presentation/pages/sale_detail_page.dart", "'The sale is kept in history as reversed.'", "l10n.saleKeptAsReversed"),
    ("features/sales/presentation/pages/sale_form_page.dart", "'A credit sale needs a customer'", "l10n.creditSaleNeedsCustomer"),
    ("features/purchases/presentation/pages/purchase_form_page.dart", "'Purchase created'", "l10n.purchaseCreated"),
    ("features/purchases/presentation/pages/purchase_detail_page.dart", "'Purchase reversed'", "l10n.purchaseReversed"),
    ("features/purchases/presentation/pages/purchase_detail_page.dart", "'The purchase is kept in history as reversed.'", "l10n.purchaseKeptAsReversed"),
    ("features/purchases/presentation/pages/purchase_form_page.dart", "'A credit purchase needs a supplier'", "l10n.creditPurchaseNeedsSupplier"),
    ("features/payments/presentation/pages/payment_form_page.dart", "'Payment recorded'", "l10n.paymentRecorded"),
    ("features/payments/presentation/pages/payment_methods_page.dart", "'Method saved'", "l10n.methodSaved"),
    ("features/payments/presentation/pages/payment_methods_page.dart", "'Method deleted'", "l10n.methodDeleted"),
    ("features/payments/presentation/pages/payment_methods_page.dart", "'At least one payment method must remain.'", "l10n.atLeastOneMethodMustRemain"),
    ("features/products/presentation/pages/category_manage_page.dart", "'Category saved'", "l10n.categorySaved"),
    ("features/products/presentation/pages/category_manage_page.dart", "'Category deleted'", "l10n.categoryDeleted"),
    ("features/products/presentation/pages/product_form_page.dart", "'Product deleted'", "l10n.productDeleted"),
    ("features/products/presentation/pages/unit_manage_page.dart", "'Unit saved'", "l10n.unitSaved"),
    ("features/products/presentation/pages/unit_manage_page.dart", "'Unit deleted'", "l10n.unitDeleted"),
    ("features/notifications/presentation/pages/notification_settings_page.dart", "'Settings saved'", "l10n.settingsSaved"),
    ("features/backup/presentation/pages/backup_page.dart", "'This is not a Khata backup.'", "l10n.notAkhataBackup"),
    # ---- validation / interpolated --------------------------------------
    ("features/inventory/presentation/pages/stock_adjust_page.dart", "'Enter a non-zero quantity'", "l10n.enterNonZeroQuantity"),
    ("features/payments/presentation/pages/payment_form_page.dart", "'Enter an amount greater than zero'", "l10n.enterAmountGreaterThanZero"),
    ("features/inventory/presentation/pages/stock_adjust_page.dart",
     "'Current stock: ${formatQuantity(product.stockQuantity)}'",
     "l10n.currentStockIs(formatQuantity(product.stockQuantity))"),
    ("features/inventory/presentation/pages/stock_movements_page.dart",
     "'Bal ${formatQuantity(movement.balanceAfter)}'",
     "l10n.balanceAfterIs(formatQuantity(movement.balanceAfter))"),
    ("features/sync/presentation/pages/sync_status_page.dart",
     "'Conflicts (${conflicts.length})'",
     "l10n.conflictsNamed(conflicts.length)"),
    ("features/sync/presentation/pages/sync_status_page.dart", "'Rejected & failed'", "l10n.rejectedAndFailed"),
    ("features/payments/presentation/pages/payment_list_page.dart",
     "'Advance ${formatPaisa(payment.unappliedAmount)}'",
     "l10n.advanceAmount(formatPaisa(payment.unappliedAmount))"),
    ("features/products/presentation/pages/product_list_page.dart",
     "'Could not load products.\\n$message'",
     "l10n.couldNotLoadProducts('$message')"),
    ("features/invoices/presentation/pages/invoice_form_page.dart",
     "'Line items will be copied from the selected sale and its '\n                  'invoice number reused.',",
     "l10n.lineItemsCopiedFromSale,"),
    # ---- report chrome ---------------------------------------------------
    ("features/reports/presentation/pages/expense_report_page.dart", "'Entries'", "l10n.entries"),
    ("features/reports/presentation/pages/expense_report_page.dart", "'Average'", "l10n.average"),
    ("features/reports/presentation/pages/income_report_page.dart", "'Entries'", "l10n.entries"),
    ("features/reports/presentation/pages/income_report_page.dart", "'Average'", "l10n.average"),
    ("features/reports/presentation/pages/income_report_page.dart", "'Sources'", "l10n.sources"),
    ("features/reports/presentation/pages/profit_loss_page.dart", "'Revenue'", "l10n.revenue"),
    ("features/reports/presentation/pages/profit_loss_page.dart", "'Cost of goods sold'", "l10n.costOfGoodsSold"),
    ("features/reports/presentation/pages/profit_loss_page.dart", "'Gross profit'", "l10n.grossProfit"),
    ("features/reports/presentation/pages/profit_loss_page.dart", "'Other income'", "l10n.otherIncome"),
    ("features/reports/presentation/pages/profit_loss_page.dart", "'Net profit'", "l10n.netProfit"),
    ("features/reports/presentation/pages/profit_loss_page.dart", "'Tax collected in this period: '", "l10n.taxCollectedInPeriod"),
    ("features/reports/presentation/pages/receivable_payable_page.dart", "'Customer advances'", "l10n.customerAdvances"),
    ("features/reports/presentation/pages/receivable_payable_page.dart", "'Supplier advances'", "l10n.supplierAdvances"),
    ("features/reports/presentation/pages/receivable_payable_page.dart",
     "'Advances are money you already hold (customer) or have '\n                  'overpaid (supplier).',",
     "l10n.advancesExplain,"),
    ("features/reports/presentation/pages/report_list_page.dart", "'Trends, totals, top products and customers'", "l10n.reportSalesBlurb"),
    ("features/reports/presentation/pages/report_list_page.dart", "'Revenue, cost of goods and net profit'", "l10n.reportProfitLossBlurb"),
    ("features/reports/presentation/pages/report_list_page.dart", "'Where the money went, by category'", "l10n.reportExpenseBlurb"),
    ("features/reports/presentation/pages/report_list_page.dart", "'Other income by source'", "l10n.reportIncomeBlurb"),
    ("features/reports/presentation/pages/report_list_page.dart", "'Cost and retail value of stock on hand'", "l10n.reportStockBlurb"),
    ("features/reports/presentation/pages/report_list_page.dart", "'Who owes you and who you owe'", "l10n.reportReceivableBlurb"),
    ("features/reports/presentation/pages/stock_report_page.dart", "'Cost value'", "l10n.costValue"),
    ("features/reports/presentation/pages/stock_report_page.dart", "'Retail value'", "l10n.retailValueReport"),
    ("features/reports/presentation/pages/stock_report_page.dart", "'Potential margin'", "l10n.potentialMargin"),
    ("features/reports/presentation/widgets/report_range_bar.dart",
     "'BS: ${_bs(range.from)}  →  ${_bs(range.to)}'",
     "l10n.bsRange(_bs(range.from), _bs(range.to))"),
    # ---- ledger hints / roles -------------------------------------------
    ("features/parties/presentation/pages/party_ledger_page.dart",
     "'Amount they owe you (customer) / you paid (supplier)'",
     "l10n.ledgerOwesYouHint"),
    ("features/parties/presentation/pages/party_ledger_page.dart",
     "'Amount paid to you (customer) / you owe (supplier)'",
     "l10n.ledgerYouOweHint"),
    ("features/dashboard/presentation/pages/home_page.dart", "'No business'", "l10n.noBusiness"),
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
