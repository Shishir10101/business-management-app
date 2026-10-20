import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

/// The app frame: a persistent bottom navigation bar over five branch
/// navigators.
///
/// Every khata app a Nepali shopkeeper already uses puts the four or five
/// things they do all day in a thumb-reachable bar. This app shipped with a
/// single home screen carrying a 20-tile grid, which meant "Purchases" was
/// three scrolls down and the current section was never visible. The bar fixes
/// both: the tabs are the shop's spine, and everything else lives behind
/// **More**.
class AppShell extends StatelessWidget {
  /// The branch navigator rendered by go_router.
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // The inner pages own their own AppBar and FAB; the shell only supplies
      // the bar, so a page can scroll under it without a second Scaffold.
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.dividerTheme.color ?? Colors.transparent,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) {
            // Tapping the active tab returns to its root (the pattern every
            // tab bar has); tapping another switches branch and keeps each
            // branch's own scroll position and stack.
            shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: l10n.sales,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: l10n.navParties,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: l10n.navItems,
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
