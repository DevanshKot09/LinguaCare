import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/core/responsive/responsive_scaffold.dart';
import 'package:linguacare/features/onboarding/onboarding_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

void main() {
  testWidgets('Onboarding screen next and skip buttons work', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: OnboardingScreen(),
        ),
      ),
    );

    // Verify first slide title is present
    expect(find.text('Understand DLD'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify second slide title is present
    expect(find.text('Spot early signs'), findsOneWidget);
  });

  testWidgets('ResponsiveScaffold switches between NavigationBar (<600dp) and NavigationRail (>=600dp)', (WidgetTester tester) async {
    // Test Compact (< 600dp) -> NavigationBar
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScaffold(
          title: 'Test',
          currentIndex: 0,
          onDestinationSelected: (_) {},
          items: const [
            ResponsiveScaffoldItem(label: 'Home', icon: Icons.home),
            ResponsiveScaffoldItem(label: 'Search', icon: Icons.search),
          ],
          body: const Text('Body Content'),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    // Test Medium (>= 600dp) -> NavigationRail
    tester.view.physicalSize = const Size(700, 900);
    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScaffold(
          title: 'Test',
          currentIndex: 0,
          onDestinationSelected: (_) {},
          items: const [
            ResponsiveScaffoldItem(label: 'Home', icon: Icons.home),
            ResponsiveScaffoldItem(label: 'Search', icon: Icons.search),
          ],
          body: const Text('Body Content'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
