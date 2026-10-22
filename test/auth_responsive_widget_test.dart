import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/features/auth/login_screen.dart';
import 'package:linguacare/features/auth/sign_up_screen.dart';
import 'package:linguacare/features/auth/verify_email_screen.dart';
import 'package:linguacare/features/auth/welcome_screen.dart';
import 'package:linguacare/features/role_setup/role_setup_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class FakeAppSessionNotifier extends AppSessionNotifier {
  FakeAppSessionNotifier(super.ref) : super(autoInit: false);
}

void main() {
  const resolutions = [
    Size(320, 480),
    Size(360, 640),
    Size(360, 720),
  ];

  for (final resolution in resolutions) {
    group('Responsive Widget Tests at ${resolution.width}x${resolution.height} textScale 2.0', () {
      testWidgets('WelcomeScreen renders without overflow', (tester) async {
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
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      });

      testWidgets('SignUpScreen renders without overflow', (tester) async {
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
              home: const SignUpScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      });

      testWidgets('LoginScreen renders without overflow', (tester) async {
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
              home: const LoginScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      });

      testWidgets('VerifyEmailScreen renders without overflow', (tester) async {
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
              home: const VerifyEmailScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      });

      testWidgets('RoleSetupScreen renders without overflow', (tester) async {
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
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      });
    });
  }
}
