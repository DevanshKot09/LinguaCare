import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/domain/auth/auth_repository.dart';
import 'package:linguacare/domain/auth/auth_user.dart';
import 'package:linguacare/domain/profile/profile.dart';
import 'package:linguacare/data/repositories/firebase_auth_repository.dart';
import 'package:linguacare/features/admin/admin_home_screen.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
  });

  group('Admin Authentication & Console Tests', () {
    testWidgets('Admin user is routed to AdminHomeScreen and displays console tabs', (tester) async {
      final notifier = AppSessionNotifier(null, autoInit: false);
      notifier.debugSetState(
        status: AuthSessionStatus.authenticated,
        onboardingDone: true,
        isFirstLaunch: false,
        user: const AuthUser(
          uid: 'admin-uid-1',
          email: 'admin@lingua.ai',
          emailVerified: true,
          profileExists: true,
          role: UserRole.admin,
        ),
        profile: const Profile(
          uid: 'admin-uid-1',
          role: UserRole.admin,
          fullName: 'Platform Admin',
          email: 'admin@lingua.ai',
          emailVerified: true,
          country: 'US',
          language: 'en',
          verified: true,
          children: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWithValue(notifier),
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: MaterialApp(
            home: const AdminHomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('LinguaCare Console'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('Non-admin user role is blocked and redirected by AdminHomeScreen guard', (tester) async {
      final notifier = AppSessionNotifier(null, autoInit: false);
      notifier.debugSetState(
        status: AuthSessionStatus.authenticated,
        onboardingDone: true,
        isFirstLaunch: false,
        user: const AuthUser(
          uid: 'parent-uid-1',
          email: 'parent@linguacare.app',
          emailVerified: true,
          profileExists: true,
          role: UserRole.parent,
        ),
        profile: const Profile(
          uid: 'parent-uid-1',
          role: UserRole.parent,
          fullName: 'Test Parent',
          email: 'parent@linguacare.app',
          emailVerified: true,
          country: 'US',
          language: 'en',
          verified: false,
          children: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWithValue(notifier),
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: const MaterialApp(
            home: AdminHomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Guard blocks the screen and does not display admin headers
      expect(find.text('LinguaCare Console'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
