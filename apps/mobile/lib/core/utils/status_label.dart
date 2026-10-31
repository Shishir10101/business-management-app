import '../../l10n/app_localizations.dart';

/// Localized chip label for a document's payment or lifecycle status.
///
/// The raw value is what the API speaks and is left untouched on the wire, but
/// rendering it directly put English ("Unpaid", "Accepted") in the middle of an
/// otherwise Nepali screen. Sales, invoices and quotations overlap but are not
/// identical, so one helper serves all three.
String statusLabel(String status, AppLocalizations l10n) => switch (status) {
      // Payment status (sales, invoices).
      'Paid' => l10n.paid,
      'Partial' => l10n.partial,
      'Unpaid' => l10n.unpaid,
      'Overdue' => l10n.overdue,

      // Lifecycle status (invoices, quotations).
      'Draft' => l10n.draft,
      'Sent' => l10n.sent,
      'Accepted' => l10n.accepted,
      'Rejected' => l10n.rejected,
      'Expired' => l10n.expired,

      // An unknown value is shown as the server sent it rather than guessed at.
      _ => status,
    };

/// Localized label for a sale/purchase type ('Cash' | 'Credit' | 'Partial').
///
/// Same problem as [statusLabel]: the list rows interpolated the wire value
/// directly, so a Nepali screen read "INV-00001 · Credit".
String saleTypeLabel(String type, AppLocalizations l10n) => switch (type) {
      'Cash' => l10n.cash,
      'Credit' => l10n.credit,
      'Partial' => l10n.partial,
      _ => type,
    };

/// Localized label for a business role name coming from the API.
///
/// The member list and the business switcher printed the raw value, so a
/// Nepali screen showed "Owner" and "SalesStaff".
String roleLabel(String role, AppLocalizations l10n) => switch (role) {
      'Owner' => l10n.roleOwner,
      'Admin' => l10n.roleAdmin,
      'Manager' => l10n.roleManager,
      'Accountant' => l10n.roleAccountant,
      'SalesStaff' => l10n.roleSalesStaff,
      'InventoryStaff' => l10n.roleInventoryStaff,
      'Viewer' => l10n.roleViewer,
      _ => role,
    };
