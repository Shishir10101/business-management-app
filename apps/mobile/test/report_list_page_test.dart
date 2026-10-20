import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/reports/presentation/pages/report_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReportListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every standard report', (tester) async {
    await pumpList(tester);

    expect(find.text('Sales report'), findsOneWidget);
    expect(find.text('Profit & loss'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Stock valuation'), findsOneWidget);
    expect(find.text('Receivables & payables'), findsOneWidget);
  });

  testWidgets('shows a subtitle describing each report', (tester) async {
    await pumpList(tester);

    expect(
      find.text('Trends, totals, top products and customers'),
      findsOneWidget,
    );
    expect(
      find.text('Revenue, cost of goods and net profit'),
      findsOneWidget,
    );
  });
}
