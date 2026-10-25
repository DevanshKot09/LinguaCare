import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/features/auth/welcome_screen.dart';
import 'package:linguacare/features/role_setup/role_setup_screen.dart';
import 'package:linguacare/features/settings/research_consents_screen.dart';
import 'package:linguacare/features/specialist/clinical_assessments_view.dart';
import 'package:linguacare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAppSessionNotifier extends AppSessionNotifier {
  FakeAppSessionNotifier(super.ref) : super(autoInit: false);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Accessibility Guidelines Tests at 360dp and textScale 2.0', () {
    const resolution = Size(360, 640);

    testWidgets('WelcomeScreen meets text contrast and labeling guidelines', (tester) async {
      tester.view.physicalSize = resolution * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith((ref) => FakeAppSessionNotifier(ref)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: const WelcomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('RoleSetupScreen meets text contrast and labeling guidelines', (tester) async {
      tester.view.physicalSize = resolution * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith((ref) => FakeAppSessionNotifier(ref)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: const RoleSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('ResearchConsentsScreen meets text contrast and labeling guidelines', (tester) async {
      tester.view.physicalSize = resolution * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith((ref) => FakeAppSessionNotifier(ref)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: const ResearchConsentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('ClinicalAssessmentsView meets text contrast and labeling guidelines', (tester) async {
      tester.view.physicalSize = resolution * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWith((ref) => FakeAppSessionNotifier(ref)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: const Scaffold(
              body: ClinicalAssessmentsView(
                childId: 'c1',
                isSpecialist: true,
                isVerified: true,
                scope: 'progress_notes',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
