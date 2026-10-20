import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/offline/offline_providers.dart';
import 'package:khata/core/widgets/cached_data_note.dart';
import 'package:khata/l10n/app_localizations.dart';

/// The note that tells a user a list is showing the saved copy.
void main() {
  Future<void> pump(WidgetTester tester, {DateTime? savedAt}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cachedReadProvider.overrideWith(
            (ref) => savedAt == null
                ? CachedReadNotifier()
                : (CachedReadNotifier()..mark('products', savedAt)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CachedDataNote(group: 'products')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('stays hidden while the data is fresh', (tester) async {
    await pump(tester);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('names the time a saved copy was written today', (tester) async {
    await pump(tester, savedAt: DateTime.now());

    expect(find.textContaining('Showing saved data from'), findsOneWidget);
  });

  testWidgets('drops the time for a copy saved on an earlier day',
      (tester) async {
    await pump(tester, savedAt: DateTime(2020, 1, 2, 10, 30));

    expect(
      find.text('Showing saved data. Reconnect to refresh.'),
      findsOneWidget,
    );
  });

  testWidgets('ignores another group', (tester) async {
    await pump(tester, savedAt: DateTime.now());

    // The note is wired to 'products'; a customers note must not appear here.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cachedReadProvider.overrideWith(
            (ref) => CachedReadNotifier()..mark('products', DateTime.now()),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CachedDataNote(group: 'customers')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
  });
}
