import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/entities/backup_entities.dart';
import '../../../../l10n/app_localizations.dart';

/// Backup and restore for the active business.
///
/// Export downloads the snapshot, keeps a copy in the app's documents folder
/// (so it survives a reinstall on the same device) and offers it to the share
/// sheet — the file has to leave the phone to be worth anything.
///
/// Restore reads a snapshot back. There is no file picker dependency, so the
/// user either restores the copy this screen saved or pastes the JSON.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _exporting = false;
  bool _restoring = false;
  String? _lastExportPath;

  @override
  void initState() {
    super.initState();
    _loadLastExport();
  }

  Future<void> _loadLastExport() async {
    // No documents directory on the web, so there is never a "last export"
    // to offer — skip the button rather than fail.
    final path = await _snapshotPath();
    if (path == null) return;
    final exists = await File(path).exists();
    if (mounted) setState(() => _lastExportPath = exists ? path : null);
  }

  /// A stable name, so a later export replaces the previous copy rather than
  /// filling the folder with snapshots the user cannot tell apart.
  ///
  /// Returns null on the web, which has no documents directory: callers must
  /// say so to the user instead of letting the MissingPluginException escape.
  Future<String?> _snapshotPath() async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/khata-backup.json';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupAndRestore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.exportTitle, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.backupExportExplainerFull,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _export,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_exporting ? l10n.exporting : l10n.exportBackup),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restore, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.restoreTitle, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.backupRestoreExplainerFull,
                  ),
                  const SizedBox(height: 16),
                  if (_lastExportPath != null) ...[
                    OutlinedButton.icon(
                      onPressed: _restoring ? null : _restoreLastExport,
                      icon: const Icon(Icons.settings_backup_restore),
                      label: Text(l10n.restoreFromLastExport),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _restoring ? null : _restoreFromClipboard,
                    icon: const Icon(Icons.content_paste),
                    label: Text(l10n.restoreFromPastedJson),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.backupNotIncludedTitle),
                  SizedBox(height: 8),
                  Text(
                    l10n.backupNotIncludedExplainer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(backupRepositoryProvider).export();
      final path = await _snapshotPath();
      if (path == null) {
        // Web: no documents directory to keep the copy in.
        if (mounted) showInfoSnackBar(context, l10n.fileSaveNotSupported);
        return;
      }
      await File(path).writeAsBytes(bytes);
      if (mounted) setState(() => _lastExportPath = path);

      try {
        await Share.shareXFiles(
          [XFile(path, mimeType: 'application/json')],
          subject: l10n.backupSubject,
          text: l10n.backupShareText,
        );
      } catch (_) {
        if (mounted) showInfoSnackBar(context, l10n.savedTo('$path'));
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restoreLastExport() async {
    final path = _lastExportPath;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      await _restore(BackupRepositoryImpl.decode(bytes));
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  Future<void> _restoreFromClipboard() async {
    final l10n = AppLocalizations.of(context);
    String text;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      text = data?.text?.trim() ?? '';
    } catch (_) {
      if (mounted) showInfoSnackBar(context, l10n.clipboardEmpty);
      return;
    }
    if (text.isEmpty) {
      if (mounted) showInfoSnackBar(context, l10n.clipboardEmpty);
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException(l10n.notAkhataBackup);
      }
      await _restore(decoded);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  Future<void> _restore(Map<String, dynamic> payload) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(
          l10n.restoreConfirmBodyFull,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.restoreTitle),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _restoring = true);
    try {
      final result = await ref.read(backupRepositoryProvider).restore(payload);
      if (mounted) await _showResult(result);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _showResult(BackupRestoreResult result) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreComplete),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.recordsAddedCount(result.totalInserted)),
              if (result.totalSkipped > 0) ...[
                const SizedBox(height: 4),
                Text(l10n.alreadyPresentCount(result.totalSkipped)),
              ],
              const SizedBox(height: 12),
              ...result.breakdown.map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.$1),
                      Text(
                        row.$3 == 0
                            ? '${row.$2} added'
                            : '${row.$2} added, ${row.$3} kept',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.reminderStatusDone),
          ),
        ],
      ),
    );
  }
}
