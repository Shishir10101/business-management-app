import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khata/core/widgets/route_not_found_screen.dart';
import 'package:khata/l10n/app_localizations.dart';

/// An unmatched location used to reach go_router's default error screen:
/// English-only, assembled from bare `Container`s outside the app theme, and
/// it rendered the raw exception — an opaque `GoException` whose message can
/// carry an internal file path into the UI.
///
/// These pin the replacement's contract: localized, themed, and the exception
/// never shown.
void main() {
  GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
        initialLocation: initialLocation,
        errorBuilder: (context, state) => const RouteNotFoundScreen(),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('home')),
            ),
          ),
        ],
      );

  Future<void> pump(
    WidgetTester tester, {
    Locale? locale,
    String initialLocation = '/',
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        // The locale belongs to MaterialApp, not to the GoRouter: the router
        // sits *below* Localizations, so a locale on it would do nothing.
        locale: locale,
        routerConfig: buildRouter(initialLocation: initialLocation),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an unmatched location renders the localized screen', (tester) async {
    await pump(tester, initialLocation: '/dashbord');

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.textContaining('may have been moved'), findsOneWidget);
    expect(find.byIcon(Icons.explore_off_outlined), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('the same screen is localized in Nepali', (tester) async {
    await pump(tester, locale: const Locale('ne'), initialLocation: '/dashbord');

    expect(find.text('पृष्ठ भेटिएन'), findsOneWidget);
    expect(find.textContaining('सारिएको हुन सक्छ'), findsOneWidget);
    expect(find.text('ड्यासबोर्ड'), findsOneWidget);
  });

  testWidgets('the raw routing exception never reaches the screen', (tester) async {
    await pump(tester, initialLocation: '/dashbord');

    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('no routes for location'), findsNothing);
  });

  testWidgets('the Dashboard action returns to a real route', (tester) async {
    await pump(tester, initialLocation: '/dashbord');

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
