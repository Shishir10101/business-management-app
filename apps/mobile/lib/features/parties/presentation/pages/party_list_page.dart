import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/nav.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/cached_data_note.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../domain/entities/party_entity.dart';
import '../providers/party_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Customer or supplier list (kind selects which) with search, balances and
/// a link to each party's khata ledger.
class PartyListPage extends ConsumerWidget {
  final PartyKind kind;

  /// Shows the Customers / Suppliers segmented control. On for the Parties
  /// tab; off when the page is pushed from somewhere that already named the
  /// kind.
  final bool showKindToggle;

  const PartyListPage({
    super.key,
    required this.kind,
    this.showKindToggle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final search = ref.watch(kind == PartyKind.customer
        ? customerSearchProvider
        : supplierSearchProvider);

    // Written as a branch rather than a ternary: `.notifier` on a
    // conditional expression loses the concrete provider type.
    void onSearch(String value) {
      if (kind == PartyKind.customer) {
        ref.read(customerSearchProvider.notifier).state = value;
      } else {
        ref.read(supplierSearchProvider.notifier).state = value;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(showKindToggle ? l10n.navParties : kind.labelPlural(l10n)),
        actions: [
          if (kind == PartyKind.customer)
            _TotalChip(
              icon: Icons.call_received_outlined,
              provider: totalReceivableProvider,
            )
          else
            _TotalChip(
              icon: Icons.call_made_outlined,
              provider: totalPayableProvider,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (showKindToggle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<PartyKind>(
                segments: [
                  ButtonSegment(
                    value: PartyKind.customer,
                    label: Text(l10n.customers),
                    icon: const Icon(Icons.call_received, size: 16),
                  ),
                  ButtonSegment(
                    value: PartyKind.supplier,
                    label: Text(l10n.suppliers),
                    icon: const Icon(Icons.call_made, size: 16),
                  ),
                ],
                selected: {kind},
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                // Both routes live in the same shell branch, so switching keeps
                // the bottom bar and the tab's own scroll state.
                onSelectionChanged: (value) => context.go(
                  value.first == PartyKind.customer ? '/customers' : '/suppliers',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchPartyHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          CachedDataNote(
            group: kind == PartyKind.customer ? 'customers' : 'suppliers',
          ),
          Expanded(
            child: kind == PartyKind.customer
                ? _PartyListBody<CustomerEntity>(
                    kind: kind,
                    searching: search.isNotEmpty,
                    listAsync: ref.watch(customerListProvider),
                    toRow: (party) => _PartyRow(
                      id: party.id,
                      name: party.name,
                      phoneNumber: party.phoneNumber,
                      currentBalance: party.currentBalance,
                    ),
                    onRetry: () => refreshParties(ref),
                    loadingMore: ref.watch(customerLoadingMoreProvider),
                    onLoadMore: () => _loadMore(context, ref, kind),
                  )
                : _PartyListBody<SupplierEntity>(
                    kind: kind,
                    searching: search.isNotEmpty,
                    listAsync: ref.watch(supplierListProvider),
                    toRow: (party) => _PartyRow(
                      id: party.id,
                      name: party.name,
                      phoneNumber: party.phoneNumber,
                      currentBalance: party.currentBalance,
                    ),
                    onRetry: () => refreshParties(ref),
                    loadingMore: ref.watch(supplierLoadingMoreProvider),
                    onLoadMore: () => _loadMore(context, ref, kind),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(
            context,
            kind == PartyKind.customer ? '/customers/new' : '/suppliers/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addLabel(kind.label(l10n).toLowerCase())),
      ),
    );
  }

  /// Fetches the next page of whichever party kind is on screen.
  Future<void> _loadMore(
    BuildContext context,
    WidgetRef ref,
    PartyKind kind,
  ) async {
    try {
      if (kind == PartyKind.customer) {
        await ref.read(customerListProvider.notifier).loadMore();
      } else {
        await ref.read(supplierListProvider.notifier).loadMore();
      }
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, '$error');
    }
  }
}

/// Minimal typed shape shared by customer and supplier list rows.
class _PartyRow {
  final int id;
  final String name;
  final String? phoneNumber;
  final int currentBalance;

  const _PartyRow({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.currentBalance,
  });
}

/// Body of the list: loading / error / empty / data states, shared by both
/// party kinds via a generic entity type.
class _PartyListBody<T> extends StatelessWidget {
  final PartyKind kind;
  final bool searching;
  final AsyncValue<PartyPage<T>> listAsync;
  final _PartyRow Function(T party) toRow;
  final VoidCallback onRetry;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  const _PartyListBody({
    required this.kind,
    required this.searching,
    required this.listAsync,
    required this.toRow,
    required this.onRetry,
    required this.loadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(l10n.couldNotLoad('$error'), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
      data: (page) {
        final parties = page.items;
        if (parties.isEmpty) {
          if (searching) {
            return EmptyState(
              icon: Icons.search_off,
              message:
                  l10n.noKindMatchSearch(kind.labelPlural(l10n).toLowerCase()),
            );
          }
          return EmptyState(
            icon: Icons.people_outline,
            message: l10n.noKindYet(kind.labelPlural(l10n).toLowerCase()),
            actionLabel: l10n.addKind(kind.label(l10n)),
            onAction: () => openRoute(context,
                kind == PartyKind.customer ? '/customers/new' : '/suppliers/new'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: ListView.builder(
            // Clear of the extended FAB, which otherwise covers the last row.
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: parties.length + (page.hasNext ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= parties.length) {
                return LoadMoreFooter(
                  loading: loadingMore,
                  remaining: page.remaining,
                  onPressed: onLoadMore,
                );
              }
              return _PartyTile(kind: kind, party: toRow(parties[index]));
            },
          ),
        );
      },
    );
  }
}

/// Aggregate balance chip in the app bar ("To collect" / "To pay").
class _TotalChip extends ConsumerWidget {
  final IconData icon;
  final FutureProvider<int> provider;

  const _TotalChip({required this.icon, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(provider).valueOrNull ?? 0;
    if (total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text(
          formatPaisa(total),
          style: const TextStyle(
            fontSize: 12,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// One row in the party list: name, phone, khata balance.
///
/// Tapping the row opens the khata, not the edit form — a shopkeeper taps a
/// person to see what they owe and edits them once a year. The old behaviour
/// (tap → edit form) put a form one accidental tap away and left the ledger
/// behind a tiny icon.
class _PartyTile extends ConsumerWidget {
  final PartyKind kind;
  final _PartyRow party;

  const _PartyTile({required this.kind, required this.party});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = context.money;
    final balance = party.currentBalance;

    // Customers: positive = they owe us (to collect). Suppliers: positive =
    // we owe them (to pay). Green means money coming in, red money going out —
    // the same pairing the dashboard uses.
    final isCustomer = kind == PartyKind.customer;
    final owesUs = isCustomer && balance > 0;
    final weOwe = isCustomer ? balance < 0 : balance > 0;

    final color = balance == 0
        ? money.neutral
        : (owesUs ? money.positive : (weOwe ? money.negative : money.neutral));
    final tint = balance == 0
        ? theme.colorScheme.surfaceContainerHighest
        : (owesUs ? money.positiveTint : money.negativeTint);

    final label = balance == 0
        ? l10n.settled
        : (owesUs ? l10n.toCollect : (weOwe ? l10n.toPay : l10n.advance));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRoute(context, '/${kind.apiValue}s/${party.id}/ledger'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Text(
                  _initials(party.name),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (party.phoneNumber != null)
                      Text(
                        party.phoneNumber!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPaisa(balance.abs()),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: balance == 0
                          ? theme.colorScheme.onSurfaceVariant
                          : color,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                // Not `l10n.more`: that string is the bottom-bar tab, and two
                // different controls announcing "More" is a screen-reader trap.
                tooltip: l10n.moreActions,
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    openRoute(context, '/${kind.apiValue}s/${party.id}/edit');
                  } else if (value == 'share') {
                    _shareReminder(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(l10n.shareReminder),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hands a ready-written payment reminder to the system share sheet, where
  /// WhatsApp is the first target on every phone in Nepal. Deliberately not a
  /// `wa.me` deep link: that needs a URL-launcher dependency, and the share
  /// sheet reaches the same place in one extra tap.
  Future<void> _shareReminder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final business = ref.read(activeBusinessProvider)?.name ?? l10n.appName;
    final message = l10n.reminderShareMessage(
      party.name,
      formatPaisa(party.currentBalance.abs()),
      business,
    );
    try {
      await Share.share(message, subject: l10n.shareReminder);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, '$error');
    }
  }

  /// "Bikash Shrestha" -> "BS"; a single word keeps its first letter.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}
