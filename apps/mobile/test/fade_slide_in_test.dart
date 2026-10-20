import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/widgets/fade_slide_in.dart';

void main() {
  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeSlideIn(
            child: Text('hello'),
          ),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('starts invisible and settles fully visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeSlideIn(
            duration: Duration(milliseconds: 100),
            child: Text('hello'),
          ),
        ),
      ),
    );
    // Frame 0: animation has not started, opacity is 0.
    expect(find.byType(Opacity), findsOneWidget);
    final opacityAtStart = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacityAtStart.opacity, 0);

    // Let the delayed start fire and the animation run to completion.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final opacityAtEnd = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacityAtEnd.opacity, 1);
  });

  testWidgets('delay staggers the start', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeSlideIn(
            delay: Duration(milliseconds: 200),
            child: Text('hello'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // Still inside the delay window: not yet animating.
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0);
  });
}
