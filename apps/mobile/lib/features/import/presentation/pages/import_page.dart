import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/repositories/import_repository_impl.dart';
import '../../domain/entities/import_entities.dart';

/// CSV import for products and customers.
///
/// There is no file-picker dependency in this project, so the file reaches the
/// app the same way a backup does: the user copies the template (or exports
/// from Excel to the clipboard) and pastes it here. The server does every check
/// and the screen shows exactly what would happen BEFORE anything is written.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  /// Example header rows. These are wire format (the importer's column names),
  /// so they are deliberately NOT translated — a Nepali user pastes the same
  /// English headers into Excel.
  static const _productHint =
      'name,sku,category,unit,costPrice,sellingPrice,taxRate,openingQuantity';
  static const _customerHint =
      'name,phone,openingBalance,city,district,pan,creditLimit';

  final TextEditingController _csvController = TextEditingController();

  ImportTarget _target = ImportTarget.products;
  ImportPreview? _preview;
  bool _checking = false;
  bool _importing = false;
  bool _copyingTemplate = false;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  String get _hint =>
      _target == ImportTarget.products ? _productHint : _customerHint;

  void _selectTarget(ImportTarget target) {
    if (target == _target) return;
    setState(() {
      _target = target;
      // The columns differ per entity, so a previous check no longer applies.
      _preview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasText = _csvController.text.trim().isNotEmpty;
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.products),
                selected: _target == ImportTarget.products,
                onSelected: (_) => _selectTarget(ImportTarget.products),
              ),
              ChoiceChip(
                label: Text(l10n.customers),
                selected: _target == ImportTarget.customers,
                onSelected: (_) => _selectTarget(ImportTarget.customers),
              ),
            ],
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
                      Icon(Icons.table_chart_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.importExplainerTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.importExplainerBody),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyingTemplate ? null : _copyTemplate,
                        icon: _copyingTemplate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.copy_all_outlined),
                        label: Text(l10n.importCopyTemplate),
                      ),
                      OutlinedButton.icon(
                        onPressed: _importing ? null : _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste),
                        label: Text(l10n.importPasteFromClipboard),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // The example header row has to be readable without touching the
          // field. A hint inside an empty TextField is easy to miss — and on
          // the web build it did not render at all — so the expected columns
          // for the selected entity also live here, always on screen.
          _ExpectedColumns(columns: _hint),
          const SizedBox(height: 16),
          TextField(
            controller: _csvController,
            maxLines: 12,
            minLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              labelText: l10n.importCsvLabel,
              hintText: _hint,
              hintMaxLines: 2,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() => _preview = null),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: (!hasText || _checking || _importing) ? null : _check,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(_checking ? l10n.importChecking : l10n.importCheckFile),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: (preview == null ||
                        preview.isBlocked ||
                        !preview.hasSomethingToImport ||
                        _importing)
                    ? null
                    : _import,
                icon: _importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_importing ? l10n.importImporting : l10n.importRun),
              ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: 16),
            _PreviewCard(preview: preview, onClear: _clear),
          ],
        ],
      ),
    );
  }

  Future<void> _copyTemplate() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _copyingTemplate = true);
    try {
      final csv = await ref.read(importRepositoryProvider).template(_target);
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) showInfoSnackBar(context, l10n.importTemplateCopied);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _copyingTemplate = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
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
    setState(() {
      _csvController.text = text;
      _preview = null;
    });
  }

  void _clear() {
    setState(() {
      _csvController.clear();
      _preview = null;
    });
  }

  Future<void> _check() async {
    final csv = _csvController.text.trim();
    if (csv.isEmpty) return;

    setState(() => _checking = true);
    try {
      final preview =
          await ref.read(importRepositoryProvider).preview(_target, csv);
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _import() async {
    final csv = _csvController.text.trim();
    if (csv.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.importRun),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importing = true);
    try {
      final outcome =
          await ref.read(importRepositoryProvider).importCsv(_target, csv);

      if (!mounted) return;

      // A refusal is a normal outcome: show the same preview the user just
      // saw, and write nothing.
      if (outcome.wasRejected) {
        setState(() => _preview = outcome.rejection);
        showErrorSnackBar(context, l10n.importRejected);
        return;
      }

      final result = outcome.result!;
      _refreshAffectedLists();
      await _showResult(result);
      if (mounted) _clear();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// The imported rows must show up immediately in the catalog / party lists.
  void _refreshAffectedLists() {
    if (_target == ImportTarget.products) {
      refreshCatalog(ref);
    } else {
      refreshParties(ref);
    }
  }

  Future<void> _showResult(ImportResult result) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importCompleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importCreatedCount(result.created)),
            if (result.skipped > 0) ...[
              const SizedBox(height: 4),
              Text(l10n.importSkippedCount(result.skipped)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

/// The current entity's column names, shown as a wrapped monospace line so the
/// user can build (or check) their CSV without first focusing the text field.
class _ExpectedColumns extends StatelessWidget {
  final String columns;

  const _ExpectedColumns({required this.columns});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.importExpectedColumns,
              style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          SelectableText(
            columns,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dry-run report: the counts, what was ignored, and the rows to fix.
class _PreviewCard extends StatelessWidget {
  final ImportPreview preview;
  final VoidCallback onClear;

  const _PreviewCard({required this.preview, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final issues = preview.issues.take(20).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.importPreviewTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.importClear,
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Stat(label: l10n.importRowsTotal, value: preview.totalRows),
                _Stat(
                  label: l10n.importRowsValid,
                  value: preview.validRows,
                  emphasize: true,
                ),
                if (preview.duplicateRows > 0)
                  _Stat(
                    label: l10n.importRowsDuplicate,
                    value: preview.duplicateRows,
                  ),
                if (preview.invalidRows > 0)
                  _Stat(
                    label: l10n.importRowsInvalid,
                    value: preview.invalidRows,
                    isError: true,
                  ),
              ],
            ),
            if (preview.isBlocked) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.importBlockedHint,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
            if (preview.ignoredColumns.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.importIgnoredColumns(preview.ignoredColumns.join(', ')),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.importIssuesTitle, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    issue.column == null
                        ? l10n.importIssueLine(issue.row, issue.message)
                        : l10n.importIssueLineWithColumn(
                            issue.row,
                            issue.column!,
                            issue.message,
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              if (preview.issues.length > issues.length)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.importMoreIssues(preview.issues.length - issues.length),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final bool emphasize;
  final bool isError;

  const _Stat({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError
        ? theme.colorScheme.error
        : emphasize
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
