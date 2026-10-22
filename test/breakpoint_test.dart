import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/core/responsive/breakpoints.dart';

void main() {
  testWidgets('ScreenType breakpoints test', (WidgetTester tester) async {
    // Test Compact (< 600)
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(getScreenType(context), ScreenType.compact);
              expect(isCompact(context), true);
              return Container();
            },
          ),
        ),
      ),
    );

    // Test Medium (600 - 839)
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(700, 900)),
          child: Builder(
            builder: (context) {
              expect(getScreenType(context), ScreenType.medium);
              expect(isMedium(context), true);
              return Container();
            },
          ),
        ),
      ),
    );

    // Test Expanded (>= 840)
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(900, 1000)),
          child: Builder(
            builder: (context) {
              expect(getScreenType(context), ScreenType.expanded);
              expect(isExpanded(context), true);
              return Container();
            },
          ),
        ),
      ),
    );
  });
}
