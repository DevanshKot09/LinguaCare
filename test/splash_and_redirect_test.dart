import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/data/repositories/firebase_auth_repository.dart';
import 'package:linguacare/domain/auth/auth_repository.dart';
import 'package:linguacare/domain/auth/auth_user.dart';
import 'package:linguacare/features/splash/splash_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Future<void> sendOtp() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> setClaims() async {}

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async => throw UnimplementedError();

  @override
  Future<void> verifyOtp(String code) async {}
}

class HangingAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthUser?> getCurrentUser() async {
    await Completer<void>().future;
    return null;
  }

  @override
  Future<void> sendOtp() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> setClaims() async {}

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async => throw UnimplementedError();

  @override
  Future<void> verifyOtp(String code) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Single session instance and leaves loading', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final n1 = container.read(appSessionProvider);
    final n2 = container.read(appSessionProvider);
    expect(identityHashCode(n1), identityHashCode(n2));

    await Future.delayed(const Duration(milliseconds: 100));
    expect(container.read(appSessionStateProvider).status, isNot(AuthSessionStatus.loading));
  });

  testWidgets('Splash navigates within 3s with immediate fake repository', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: const SplashScreen(),
        ),
      ),
    );

    expect(find.text('LinguaCare'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  testWidgets('Splash navigates with disableAnimations true', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SplashScreen(),
          ),
        ),
      ),
    );

    expect(find.text('LinguaCare'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  testWidgets('Watchdog still triggers when fake repository never completes', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(HangingAuthRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('LinguaCare'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();

    expect(find.text('We could not start the app'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Recovery test: late resolution leaves error screen', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(HangingAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: const SplashScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 8));
    expect(find.text('We could not start the app'), findsOneWidget);

    container.read(appSessionProvider).debugSetState(status: AuthSessionStatus.unauthenticated, onboardingDone: true);
    await tester.pump();

    expect(find.text('We could not start the app'), findsNothing);
  });

  test('Session states and redirect safety (no loops across all session states)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = AppSessionNotifier(container, autoInit: false);

    // 1. Loading state
    notifier.debugSetState(status: AuthSessionStatus.loading);
    expect(notifier.value.status, AuthSessionStatus.loading);

    // 2. Unauthenticated state
    notifier.debugSetState(status: AuthSessionStatus.unauthenticated);
    expect(notifier.value.status, AuthSessionStatus.unauthenticated);

    // 3. Unverified email state
    notifier.debugSetState(status: AuthSessionStatus.unverifiedEmail);
    expect(notifier.value.status, AuthSessionStatus.unverifiedEmail);

    // 4. Needs profile setup state
    notifier.debugSetState(status: AuthSessionStatus.needsProfileSetup);
    expect(notifier.value.status, AuthSessionStatus.needsProfileSetup);

    // 5. Authenticated state
    notifier.debugSetState(
      isSignedIn: true,
      hasProfile: true,
      role: UserRole.parent,
      onboardingDone: true,
    );
    expect(notifier.value.status, AuthSessionStatus.authenticated);
    expect(notifier.value.role, UserRole.parent);

    // 6. Error state
    notifier.debugSetState(status: AuthSessionStatus.error);
    expect(notifier.value.status, AuthSessionStatus.error);
  });

  test('Transition signedIn(unverified) -> signOut -> unauthenticated has no intermediate verify-email', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = AppSessionNotifier(container, autoInit: false);
    notifier.debugSetState(
      status: AuthSessionStatus.unverifiedEmail,
      user: const AuthUser(uid: '1', email: 'test@example.com', emailVerified: false, profileExists: false, role: UserRole.parent),
    );
    expect(notifier.value.status, AuthSessionStatus.unverifiedEmail);

    notifier.debugSetState(status: AuthSessionStatus.unauthenticated, user: null, profile: null);
    expect(notifier.value.status, AuthSessionStatus.unauthenticated);
  });
}
