import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Last row of a paged list: a "load more" button, or a spinner while the next
/// page is on its way.
///
/// Lists used to stop at the first page with no hint that more existed; this
/// footer is what makes the rest reachable and the truncation visible.
class LoadMoreFooter extends StatelessWidget {
  final bool loading;

  /// Rows still to load, shown so the user knows how much is left.
  final int remaining;

  final VoidCallback onPressed;

  const LoadMoreFooter({
    super.key,
    required this.loading,
    required this.remaining,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.expand_more),
                label: Text(
                  l10n.loadMoreRemaining(remaining < 0 ? 0 : remaining),
                ),
              ),
      ),
    );
  }
}
