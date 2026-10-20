import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'update_service.dart';

/// Asks the user whether to install [info].
///
/// Returns true when they chose to download. The caller launches the URL, so
/// this stays a pure decision surface and can be tested without a browser.
Future<bool> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final chosen = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _UpdateDialog(info: info),
  );
  return chosen ?? false;
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.info});

  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = info.sizeLabel;
    final notes = info.notes;

    return AlertDialog(
      icon: Icon(Icons.system_update_alt, color: theme.colorScheme.primary),
      title: Text(l10n.updateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateBody(info.current.toString(), info.latest.toString()),
              style: theme.textTheme.bodyMedium,
            ),
            if (size != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.updateSize(size),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.updateNotesLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              // Release bodies grow without bound; cap the box so the buttons
              // never scroll off a small phone screen.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.updateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.updateDownload),
        ),
      ],
    );
  }
}
