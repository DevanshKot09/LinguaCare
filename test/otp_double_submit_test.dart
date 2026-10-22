import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/data/repositories/firebase_auth_repository.dart';
import 'package:linguacare/domain/auth/auth_repository.dart';
import 'package:linguacare/domain/auth/auth_user.dart';
import 'package:linguacare/features/auth/verify_email_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class SlowFakeAuthRepository implements AuthRepository {
  int verifyCallCount = 0;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(
        const AuthUser(
          uid: '123',
          email: 'test@example.com',
          emailVerified: false,
          profileExists: false,
          role: null,
        ),
      );

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async =>
      const AuthUser(uid: '123', email: 'test@example.com', emailVerified: false, profileExists: false, role: null);

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async =>
      const AuthUser(uid: '123', email: 'test@example.com', emailVerified: true, profileExists: true, role: UserRole.parent);

  @override
  Future<AuthUser> signInWithGoogle() async =>
      const AuthUser(uid: '123', email: 'test@example.com', emailVerified: true, profileExists: true, role: UserRole.parent);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUser?> getCurrentUser() async =>
      const AuthUser(uid: '123', email: 'test@example.com', emailVerified: false, profileExists: false, role: null);

  @override
  Future<void> sendOtp() async {}

  @override
  Future<void> verifyOtp(String code) async {
    verifyCallCount++;
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> setClaims() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('VerifyEmail double-submit test ensures verifyOtp is called only once', (WidgetTester tester) async {
    final fakeRepo = SlowFakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          appSessionStateProvider.overrideWith((ref) => const AppSessionState(
                status: AuthSessionStatus.unverifiedEmail,
                user: AuthUser(
                  uid: '123',
                  email: 'test@example.com',
                  emailVerified: false,
                  profileExists: false,
                  role: null,
                ),
                profile: null,
                isFirstLaunch: false,
                onboardingDone: true,
              )),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: VerifyEmailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter 6 digits
    await tester.enterText(find.byType(TextField), '123456');
    
    // Tap verify button multiple times rapidly while in flight
    await tester.tap(find.text('Verify'));
    await tester.tap(find.text('Verify'));
    await tester.tap(find.text('Verify'));

    await tester.pump(const Duration(milliseconds: 100));

    // verifyOtp should have been called exactly once due to single-flight guard
    expect(fakeRepo.verifyCallCount, 1);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
