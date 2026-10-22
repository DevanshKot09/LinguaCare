import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/role_setup/role_setup_screen.dart';
import '../../features/role_setup/profile_form_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/settings/terms_of_service_screen.dart';
import '../../features/parent/parent_home_screen.dart';
import '../../features/teacher/teacher_home_screen.dart';
import '../../features/adult/adult_home_screen.dart';
import '../../features/specialist/specialist_home_screen.dart';
import '../../features/screening/screening_intro_screen.dart';
import '../../features/screening/screening_question_screen.dart';
import '../../features/screening/screening_report_screen.dart';
import '../../features/screening/screening_history_screen.dart';
import '../../features/tools/tools_hub_screen.dart';
import '../../features/export/export_summary_screen.dart';
import 'app_session.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(appSessionStateProvider);
  final sessionNotifier = ref.watch(appSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: sessionNotifier,
    redirect: (context, state) {
      final path = state.uri.path;
      String? target;

      if (session.status == AuthSessionStatus.loading || session.status == AuthSessionStatus.error) {
        if (path != '/splash') target = '/splash';
      } else if (session.isFirstLaunch && !session.onboardingDone) {
        if (path != '/onboarding') target = '/onboarding';
      } else if (session.status == AuthSessionStatus.unauthenticated) {
        const publicAuthPaths = ['/welcome', '/login', '/sign-up', '/forgot-password', '/onboarding', '/privacy-policy', '/terms-of-service'];
        if (!publicAuthPaths.contains(path)) {
          target = '/welcome';
        }
      } else if (session.status == AuthSessionStatus.unverifiedEmail) {
        if (path != '/verify-email') target = '/verify-email';
      } else if (session.status == AuthSessionStatus.needsProfileSetup) {
        if (!path.startsWith('/role-setup')) target = '/role-setup';
      } else if (session.status == AuthSessionStatus.authenticated && session.role != null) {
        final targetRoleHome = switch (session.role!) {
          UserRole.parent => '/parent',
          UserRole.teacher => '/teacher',
          UserRole.adult => '/adult',
          UserRole.specialist => '/specialist',
        };

        const authPaths = ['/splash', '/onboarding', '/welcome', '/login', '/sign-up', '/verify-email', '/forgot-password', '/role-setup'];
        if (authPaths.any((p) => path.startsWith(p))) {
          target = targetRoleHome;
        }

        const roleHomes = ['/parent', '/teacher', '/adult', '/specialist'];
        if (roleHomes.any((h) => path.startsWith(h)) && !path.startsWith(targetRoleHome)) {
          target = targetRoleHome;
        }
      }

      if (kDebugMode && target != null) {
        debugPrint('[Router] redirect: $path -> $target');
      }

      return target;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/sign-up', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/role-setup', builder: (context, state) => const RoleSetupScreen()),
      GoRoute(
        path: '/role-setup/form',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'parent';
          return ProfileFormScreen(roleStr: role);
        },
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms-of-service', builder: (context, state) => const TermsOfServiceScreen()),
      GoRoute(path: '/tools', builder: (context, state) => const ToolsHubScreen()),
      GoRoute(path: '/parent', builder: (context, state) => const ParentHomeScreen()),
      GoRoute(path: '/teacher', builder: (context, state) => const TeacherHomeScreen()),
      GoRoute(path: '/adult', builder: (context, state) => const AdultHomeScreen()),
      GoRoute(path: '/specialist', builder: (context, state) => const SpecialistHomeScreen()),
      GoRoute(
        path: '/screening/intro',
        builder: (context, state) {
          final instrumentId = state.uri.queryParameters['instrumentId'] ?? 'parent_5_11';
          final childId = state.uri.queryParameters['childId'];
          return ScreeningIntroScreen(instrumentId: instrumentId, childId: childId);
        },
      ),
      GoRoute(
        path: '/screening/questions',
        builder: (context, state) {
          final instrumentId = state.uri.queryParameters['instrumentId'] ?? 'parent_5_11';
          final childId = state.uri.queryParameters['childId'];
          return ScreeningQuestionScreen(instrumentId: instrumentId, childId: childId);
        },
      ),
      GoRoute(
        path: '/screening/report',
        builder: (context, state) {
          final instrumentId = state.uri.queryParameters['instrumentId'] ?? 'parent_5_11';
          final childId = state.uri.queryParameters['childId'];
          return ScreeningReportScreen(instrumentId: instrumentId, childId: childId);
        },
      ),
      GoRoute(
        path: '/screening/history',
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          final subjectUid = state.uri.queryParameters['subjectUid'];
          return ScreeningHistoryScreen(childId: childId, subjectUid: subjectUid);
        },
      ),
      GoRoute(path: '/export', builder: (context, state) => const ExportSummaryScreen()),
    ],
  );
});
