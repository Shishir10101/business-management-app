/// Party domain entities — customers, suppliers and their khata ledgers.
/// Pure Dart, no serialization.
library;

import '../../../../l10n/app_localizations.dart';

/// A customer. Balances are paisa; positive current balance = the customer
/// owes the business (receivable).

class CustomerEntity {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? addressLine;
  final String? city;
  final String? district;
  final int openingBalance;
  final String? panNumber;
  final int? creditLimit;
  final String? notes;
  final bool isActive;
  final int currentBalance;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.addressLine,
    this.city,
    this.district,
    this.openingBalance = 0,
    this.panNumber,
    this.creditLimit,
    this.notes,
    this.isActive = true,
    this.currentBalance = 0,
  });
}

/// A supplier. Positive current balance = the business owes the supplier
/// (payable).
class SupplierEntity {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? addressLine;
  final String? city;
  final String? district;
  final int openingBalance;
  final String? panNumber;
  final String? notes;
  final bool isActive;
  final int currentBalance;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.addressLine,
    this.city,
    this.district,
    this.openingBalance = 0,
    this.panNumber,
    this.notes,
    this.isActive = true,
    this.currentBalance = 0,
  });
}

/// Running summary of a party ledger (khata).
/// Closing = opening + debits − credits (customer, receivable)
/// or opening + credits − debits (supplier, payable).
class LedgerSummaryEntity {
  final int openingBalance;
  final int totalDebit;
  final int totalCredit;
  final int closingBalance;

  const LedgerSummaryEntity({
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
  });

  static const empty = LedgerSummaryEntity(
    openingBalance: 0,
    totalDebit: 0,
    totalCredit: 0,
    closingBalance: 0,
  );
}

/// One immutable ledger entry. Amount is positive; direction is the type.
/// Customer: debit = they owe more (sale), credit = they paid.
/// Supplier: debit = we paid, credit = we owe more (purchase).
class LedgerTransactionEntity {
  final int id;
  final String transactionType; // 'Debit' | 'Credit'
  final int amount;
  final int balanceAfter;
  final DateTime transactionDate;
  final String? referenceType;
  final int? referenceId;
  final String? description;
  final DateTime createdAt;

  const LedgerTransactionEntity({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    required this.transactionDate,
    this.referenceType,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  bool get isDebit => transactionType == 'Debit';

  /// Human label for the reference type: 'opening' → 'Opening balance'.
  ///
  /// Takes [l10n] because an entity has no BuildContext. An unrecognised type
  /// falls through as its raw wire value rather than being blanked.
  String referenceLabel(AppLocalizations l10n) => switch (referenceType) {
        'opening' => l10n.openingBalance,
        'adjustment' => l10n.adjustment,
        'sale' => l10n.sale,
        'purchase' => l10n.purchase,
        'payment' => l10n.payment,
        _ => referenceType ?? '',
      };
}

/// Full ledger payload for one party: summary + transactions (newest first).
class PartyLedgerEntity {
  final LedgerSummaryEntity summary;
  final List<LedgerTransactionEntity> transactions;
  final bool hasNext;
  final int totalItems;

  const PartyLedgerEntity({
    required this.summary,
    required this.transactions,
    this.hasNext = false,
    this.totalItems = 0,
  });
}

/// Which kind of party a screen is working with.
enum PartyKind { customer, supplier }

/// One page of parties plus the paging metadata the list needs.
///
/// The list used to take a bare `List` and silently show only the first page —
/// which hid every party past the 50th with no hint. Carrying `totalItems` and
/// `hasNext` lets the screen say how many there are and load the rest.
class PartyPage<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final bool hasNext;

  const PartyPage({
    required this.items,
    this.page = 1,
    this.pageSize = 50,
    this.totalItems = 0,
    this.hasNext = false,
  });

  /// Rows still to load after this page.
  int get remaining => totalItems - items.length;
}

extension PartyKindLabel on PartyKind {
  /// Localized singular. Takes [l10n] because an enum has no context.
  String label(AppLocalizations l10n) =>
      this == PartyKind.customer ? l10n.customer : l10n.supplier;

  /// Plural used for list titles.
  String labelPlural(AppLocalizations l10n) =>
      this == PartyKind.customer ? l10n.customers : l10n.suppliers;

  /// 'customer' | 'supplier' — matches the API partyType.
  String get apiValue => this == PartyKind.customer ? 'customer' : 'supplier';
}
