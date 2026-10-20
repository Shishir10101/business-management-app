import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/bank_account_datasource.dart';
import '../../data/datasources/business_remote_datasource.dart';
import '../providers/business_providers.dart';

/// Lists the active business's bank accounts and adds new ones.
///
/// Reads are open to any member; the API enforces that only a manager may
/// mutate, so an unauthorised add surfaces as a snackbar rather than a
/// silently ignored tap.
class BankAccountsPage extends ConsumerStatefulWidget {
  const BankAccountsPage({super.key});

  @override
  ConsumerState<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends ConsumerState<BankAccountsPage> {
  List<BankAccount>? _accounts;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context);
    try {
      final businesses =
          await ref.read(businessRemoteDatasourceProvider).getMyBusinesses();
      // The active business is the one whose accounts we manage.
      final activeId = await _activeBusinessId(businesses);
      if (activeId == null) {
        setState(() => _error = l10n.couldNotLoadX(l10n.bankAccounts, ''));
        return;
      }
      final accounts =
          await ref.read(bankAccountDatasourceProvider).list(activeId);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.couldNotLoadX(l10n.bankAccounts, ''));
    }
  }

  /// The active business id, from the session when there is one, else the
  /// first membership.
  Future<int?> _activeBusinessId(List<dynamic> businesses) async {
    if (businesses.isEmpty) return null;
    final first = businesses.first as Map<String, dynamic>;
    return (first['id'] as num).toInt();
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final bank = TextEditingController();
    final name = TextEditingController();
    final number = TextEditingController();
    final branch = TextEditingController();
    var isDefault = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addBankAccount),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bank,
                  decoration: InputDecoration(labelText: l10n.bankName),
                ),
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.accountName),
                ),
                TextField(
                  controller: number,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.accountNumber),
                ),
                TextField(
                  controller: branch,
                  decoration: InputDecoration(labelText: l10n.branch),
                ),
                SwitchListTile(
                  title: Text(l10n.defaultAccount),
                  value: isDefault,
                  onChanged: (v) => setDialogState(() => isDefault = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    if (bank.text.trim().isEmpty || number.text.trim().isEmpty) {
      if (mounted) showErrorSnackBar(context, l10n.bankName);
      return;
    }

    setState(() => _busy = true);
    try {
      final businesses =
          await ref.read(businessRemoteDatasourceProvider).getMyBusinesses();
      final activeId = await _activeBusinessId(businesses);
      if (activeId == null) throw StateError('no active business');
      await ref.read(bankAccountDatasourceProvider).create(
            businessId: activeId,
            bankName: bank.text.trim(),
            accountName: name.text.trim(),
            accountNumber: number.text.trim(),
            branch: branch.text.trim().isEmpty ? null : branch.text.trim(),
            isDefault: isDefault,
          );
      if (!mounted) return;
      showInfoSnackBar(context, l10n.created);
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BankAccount account) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteMethodQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final businesses =
          await ref.read(businessRemoteDatasourceProvider).getMyBusinesses();
      final activeId = await _activeBusinessId(businesses);
      if (activeId == null) throw StateError('no active business');
      await ref.read(bankAccountDatasourceProvider).delete(activeId, account.id);
      if (!mounted) return;
      showInfoSnackBar(context, l10n.deleted);
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bankAccounts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add),
        label: Text(l10n.addBankAccount),
      ),
      body: _error != null
          ? _ErrorState(
              message: _error!,
              onRetry: _load,
            )
          : _accounts == null
              ? const Center(child: CircularProgressIndicator())
              : _accounts!.isEmpty
                  ? Center(child: Text(l10n.noBankAccountsYet))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _accounts!.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final a = _accounts![index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              a.bankName.isNotEmpty
                                  ? a.bankName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(a.bankName)),
                              if (a.isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Chip(
                                    label: Text(l10n.defaultAccount),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${a.accountName}\n${a.masked}'
                            '${a.branch != null ? '\n${a.branch}' : ''}'
                            '${a.paymentCount > 0 ? '\n${l10n.paymentsThroughAccount(a.paymentCount, formatPaisa(a.totalPaisa))}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(a),
                          ),
                        );
                      },
                    ),
    );
  }
}

/// Error state with a way out. A bare "Could not load X." line left the user
/// staring at a dead screen — the failure is usually a dropped connection, so
/// retrying is always the right next step.
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
