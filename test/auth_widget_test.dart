import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/data/repositories/firebase_auth_repository.dart';
import 'package:linguacare/domain/auth/auth_repository.dart';
import 'package:linguacare/domain/auth/auth_user.dart';
import 'package:linguacare/features/auth/sign_up_screen.dart';
import 'package:linguacare/features/auth/verify_email_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class FakeAuthRepository implements AuthRepository {
  bool signUpCalled = false;
  bool verifyOtpCalled = false;
  bool sendOtpCalled = false;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(
        const AuthUser(
          uid: '123',
          email: '<redacted>',
          emailVerified: false,
          profileExists: false,
          role: null,
        ),
      );

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    signUpCalled = true;
    return const AuthUser(uid: '123', email: '<redacted>', emailVerified: false, profileExists: false, role: null);
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async =>
      const AuthUser(uid: '123', email: '<redacted>', emailVerified: true, profileExists: true, role: UserRole.parent);

  @override
  Future<AuthUser> signInWithGoogle() async =>
      const AuthUser(uid: '123', email: '<redacted>', emailVerified: true, profileExists: true, role: UserRole.parent);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUser?> getCurrentUser() async =>
      const AuthUser(uid: '123', email: '<redacted>', emailVerified: false, profileExists: false, role: null);

  @override
  Future<void> sendOtp() async {
    sendOtpCalled = true;
  }

  @override
  Future<void> verifyOtp(String code) async {
    verifyOtpCalled = true;
  }

  @override
  Future<void> setClaims() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SignUp validation error messages', (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: const SignUpScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SignUpScreen));
    final l10n = AppLocalizations.of(context)!;

    final emailField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(emailField.validator!(null), l10n.emailRequired);
    expect(emailField.validator!('invalid'), l10n.invalidEmail);
    expect(emailField.validator!('user@test.com'), null);

    final passwordField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    expect(passwordField.validator!(''), l10n.passwordRequired);
    expect(passwordField.validator!('short'), l10n.passwordRequirements);
    expect(passwordField.validator!('ValidPass123'), null);

    final confirmField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
    expect(confirmField.validator!(null), isNotNull);
    expect(confirmField.validator!(''), isNotNull);
  });

  testWidgets('VerifyEmail resend countdown and auto-submit at 6 digits', (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          appSessionStateProvider.overrideWith((ref) => const AppSessionState(
                status: AuthSessionStatus.unverifiedEmail,
                user: AuthUser(
                  uid: '123',
                  email: '<redacted>',
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

    // Verify countdown text appears
    expect(find.textContaining('Resend code in'), findsOneWidget);

    // Enter 6 digits in code field
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    // Verify that verifyOtp was called via auto-submit
    expect(fakeRepo.verifyOtpCalled, true);
  });
}
