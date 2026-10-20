#!/usr/bin/env python3
"""Replace parameterized Dart string literals with ARB message calls.

The plain-literal migrators skip interpolation because '${x} items' has no ARB
counterpart until someone declares the placeholder. This does that: each entry
below is an exact (source-pattern, key, argument-expression) triple.

Matching is exact-string on the Dart source text, so a change to the surrounding
code makes the rule a no-op rather than a wrong edit — the counts printed at the
end tell you whether every rule fired.

Usage: python scripts/migrate_interpolated_strings.py [--dry-run]
"""

from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
LIB = MOBILE / "lib"

# (file, exact old text, exact new text)
RULES: list[tuple[str, str, str]] = [
    # --- sync status page ---
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'${conflict.entityType} #${conflict.entityId}'",
        "l10n.entityRef(conflict.entityType, conflict.entityId)",
    ),
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'${operation.entityType} #${operation.entityId}'",
        "l10n.entityRef(operation.entityType, operation.entityId)",
    ),
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'${rejection.entityType} #${rejection.entityId}'",
        "l10n.entityRef(rejection.entityType, rejection.entityId)",
    ),
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'${operation.operation} failed '",
        "l10n.operationFailed(operation.operation) + ' '",
    ),
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'Sync failed: $error'",
        "l10n.syncFailed('$error')",
    ),
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'operation: ${conflict.operation}'",
        "l10n.operationDetail(conflict.operation)",
    ),
    (
        "lib/features/sync/presentation/pages/sync_status_page.dart",
        "'server version: ${jsonEncode(server)}'",
        "l10n.serverVersion(jsonEncode(server))",
    ),
    # --- backup page ---
    (
        "lib/features/backup/presentation/pages/backup_page.dart",
        "'${result.totalInserted} record(s) added'",
        "l10n.recordsAddedCount(result.totalInserted)",
    ),
    (
        "lib/features/backup/presentation/pages/backup_page.dart",
        "'${result.totalSkipped} already present, left alone'",
        "l10n.alreadyPresentCount(result.totalSkipped)",
    ),
    (
        "lib/features/backup/presentation/pages/backup_page.dart",
        "'Khata backup'",
        "l10n.backupSubject",
    ),
    (
        "lib/features/backup/presentation/pages/backup_page.dart",
        "'Khata backup exported from this device.'",
        "l10n.backupShareText",
    ),
    # --- business members ---
    (
        "lib/features/business/presentation/pages/business_members_page.dart",
        "'Could not change role: $e'",
        "l10n.couldNotChangeRole('$e')",
    ),
    (
        "lib/features/business/presentation/pages/business_members_page.dart",
        "'Could not remove member: $e'",
        "l10n.couldNotRemoveMember('$e')",
    ),
    (
        "lib/features/business/presentation/pages/business_members_page.dart",
        "'Invite failed: $e'",
        "l10n.inviteFailed('$e')",
    ),
    (
        "lib/features/business/presentation/pages/business_members_page.dart",
        "'Could not load staff.\\n$error'",
        "l10n.couldNotLoad('$error')",
    ),
    # --- products / units ---
    (
        "lib/features/products/presentation/pages/product_form_page.dart",
        "'Could not load product: ${productAsync.error}'",
        "l10n.couldNotLoadProduct('${productAsync.error}')",
    ),
    (
        "lib/features/products/presentation/pages/product_form_page.dart",
        "'${u.name} (${u.shortName})'",
        "l10n.unitNameShort(u.name, u.shortName)",
    ),
    (
        "lib/features/products/presentation/pages/unit_manage_page.dart",
        "'${unit.productCount} product(s)'",
        "l10n.productsCount(unit.productCount)",
    ),
    (
        "lib/features/products/presentation/pages/unit_manage_page.dart",
        "'Could not load units.\\n$error'",
        "l10n.couldNotLoad('$error')",
    ),
    # --- inventory ---
    (
        "lib/features/inventory/presentation/pages/inventory_dashboard_page.dart",
        "'Could not load inventory.\\n$error'",
        "l10n.couldNotLoad('$error')",
    ),
    # --- reports ---
    (
        "lib/features/reports/presentation/pages/stock_report_page.dart",
        "'${data.items.length} product(s)'",
        "l10n.productsCount(data.items.length)",
    ),
    (
        "lib/features/reports/presentation/pages/stock_report_page.dart",
        "'retail ${formatPaisa(item.retailValue)}'",
        "l10n.retailValue(formatPaisa(item.retailValue))",
    ),
    # --- sales / purchases ---
    (
        "lib/features/sales/presentation/pages/sale_form_page.dart",
        "'Due ${formatPaisa(_due)} → customer khata'",
        "l10n.dueToCustomerKhata(formatPaisa(_due))",
    ),
    (
        "lib/features/purchases/presentation/pages/purchase_form_page.dart",
        "'Due ${formatPaisa(_due)} → supplier khata'",
        "l10n.dueToSupplierKhata(formatPaisa(_due))",
    ),
]


def main() -> int:
    dry = "--dry-run" in sys.argv
    fired = 0
    missed: list[tuple[str, str]] = []
    by_file: dict[str, int] = {}

    for rel, old, new in RULES:
        path = LIB / pathlib.Path(rel).relative_to("lib")
        if not path.exists():
            missed.append((rel, old))
            continue
        src = path.read_text(encoding="utf-8")
        # Only replace the widget-argument occurrence, not any other context.
        needle = old
        if needle not in src:
            missed.append((rel, old))
            continue
        src = src.replace(needle, new)
        fired += 1
        by_file[rel] = by_file.get(rel, 0) + 1
        if not dry:
            path.write_text(src, encoding="utf-8")

    for rel, n in sorted(by_file.items()):
        print(f"  {rel}: {n}")
    print(f"\n{'[dry-run] ' if dry else ''}{fired}/{len(RULES)} rule(s) fired")
    if missed:
        print(f"\n{len(missed)} rule(s) did NOT match (already migrated, or text changed):")
        for rel, old in missed:
            print(f"  {rel}\n    {old}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
