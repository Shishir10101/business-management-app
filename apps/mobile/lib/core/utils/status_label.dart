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
