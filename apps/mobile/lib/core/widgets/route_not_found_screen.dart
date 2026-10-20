import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Screen shown when a location matches no route.
///
/// go_router's default error screen is English-only, built from bare
/// `Container`s that ignore the theme, and it prints the raw exception. For a
/// mistyped or stale deep link that exception is an opaque `GoException` whose
/// text can leak an internal file path into the UI — nothing a shopkeeper can
/// act on. This keeps the useful part (a way back) and drops the rest.
///
/// It is wired up as `errorBuilder` on the `GoRouter`, so it also replaces the
/// screen the user lands on when a bad deep link is opened from outside the app.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.pageNotFound,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.pageNotFoundBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  // `/` rather than a hard-coded dashboard route: the router's
                  // redirect still owns where an unauthenticated user goes.
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(l10n.dashboard),
                ),
                // Only offered when there is something to go back to — an
                // unknown initial location has no history to pop.
                if (context.canPop()) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(l10n.back),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
