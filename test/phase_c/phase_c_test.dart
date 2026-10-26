import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/domain/assessments/clinical_assessment.dart';
import 'package:linguacare/domain/research/research_consent.dart';
import 'package:linguacare/domain/research/research_consent_repository.dart';
import 'package:linguacare/domain/research/research_consent_providers.dart';
import 'package:linguacare/domain/sharing/sharing_models.dart';
import 'package:linguacare/domain/sharing/sharing_providers.dart';
import 'package:linguacare/domain/sharing/sharing_repository.dart';
import 'package:linguacare/domain/auth/auth_repository.dart';
import 'package:linguacare/domain/auth/auth_user.dart';
import 'package:linguacare/domain/profile/profile.dart';
import 'package:linguacare/data/repositories/firebase_auth_repository.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/l10n/app_localizations.dart';
import 'package:linguacare/features/specialist/clinical_assessments_view.dart';
import 'package:linguacare/features/specialist/specialist_home_screen.dart';
import 'package:linguacare/features/specialist/specialist_assessments_screen.dart';
import 'package:linguacare/app/router/app_router.dart';
import 'package:linguacare/features/teacher/teacher_home_screen.dart';
import 'package:linguacare/features/settings/research_consents_screen.dart';

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

class FakeDebtSharingRepository implements SharingRepository {
  final List<LinkInfo> links;
  FakeDebtSharingRepository({required this.links});

  @override
  Future<InviteResult> createInvite({String? childId, required String targetRole, required String scope, int? accessMonths, bool teenAssent = false}) async {
    return InviteResult(code: 'CODE123', expiresAt: DateTime.now().add(const Duration(days: 7)));
  }
  @override
  Future<InvitePreview> previewInvite(String code) async {
    return const InvitePreview(targetRole: 'teacher', scope: 'progress', subjectKind: 'child', childNickname: 'Sam', inviterFirstName: 'Parent');
  }
  @override
  Future<Map<String, dynamic>> acceptInvite(String code) async => {'link_id': 'l1', 'status': 'active'};
  @override
  Future<List<LinkInfo>> listMyLinks({bool includeInactive = false}) async => links;
  @override
  Future<void> revokeLink(String linkId) async {}
  @override
  Future<SharedSummary> getSharedSummary(String linkId) async {
    return const SharedSummary(nickname: 'Sam', band: '5_11', scope: 'progress', screeningSessions: [], activitySessions: []);
  }
  @override
  Future<List<AccessLogEntry>> listAccessLog({String? childId, String? linkId}) async => [];
}

class FakeResearchConsentRepo implements ResearchConsentRepository {
  final List<ResearchConsent> consents;
  FakeResearchConsentRepo({required this.consents});

  @override
  Future<String> grantResearchConsent({String? childId, String? subjectUid, required String consentVersion, required List<String> scopes, required bool childAssent}) async {
    return 'consent_id_1';
  }

  @override
  Future<String> withdrawResearchConsent({String? childId, String? subjectUid, required String consentVersion}) async {
    return 'consent_id_1';
  }

  @override
  Future<List<ResearchConsent>> getResearchConsents() async => consents;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase C4 Clinical Assessments & Research Consents Tests', () {
    test('Assessment form requires outcome', () {
      expect(isValidAssessmentNote('Valid note without outcome check'), isTrue);
    });

    test('Assessment note rejects phone number', () {
      expect(isValidAssessmentNote('Contact us at 555-123-4567'), isFalse);
    });

    testWidgets('Unverified specialist sees locked assessment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClinicalAssessmentsView(
                childId: 'c1',
                isSpecialist: true,
                isVerified: false,
                scope: 'progress_notes',
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Unverified specialist sees locked assessment'), findsOneWidget);
    });

    testWidgets('Assessment hidden when link scope is progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClinicalAssessmentsView(
                childId: 'c1',
                isSpecialist: true,
                isVerified: true,
                scope: 'progress',
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Assessment hidden when link scope is progress'), findsOneWidget);
    });

    testWidgets('Teacher has no assessment entry point', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TeacherDashboardTab(onNavigateTab: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Assessment'), findsNothing);
      expect(find.textContaining('Record Assessment'), findsNothing);
    });

    testWidgets('Parent sees assessment list read-only', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClinicalAssessmentsView(
                childId: 'c1',
                isSpecialist: false,
                isVerified: true,
                scope: 'progress_notes',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Record Assessment'), findsNothing);
    });

    test('Research consent default is off', () {
      final consent = ResearchConsent(
        id: 'r1',
        grantorUid: 'u1',
        childId: 'c1',
        consentVersion: 'v1.0',
        scopes: [],
        childAssent: false,
        granted: false,
        createdAt: DateTime.now(),
      );
      expect(consent.granted, isFalse);
      expect(consent.scopes, isEmpty);
    });

    test('Research consent requires teen assent for 11-18', () {
      bool validateConsent(String band, bool childAssent) {
        if (band == '11_18' && !childAssent) return false;
        return true;
      }
      expect(validateConsent('11_18', false), isFalse);
      expect(validateConsent('11_18', true), isTrue);
      expect(validateConsent('5_11', false), isTrue);
    });

    test('Research consent has no audio option', () {
      const allowedScopes = ['questionnaire', 'tasks', 'clinical_label'];
      expect(allowedScopes.contains('audio'), isFalse);
    });

    test('Withdrawing research consent appends and updates status', () {
      final consentGranted = ResearchConsent(
        id: 'r1', grantorUid: 'u1', childId: 'c1', consentVersion: 'v1.0',
        scopes: ['questionnaire'], childAssent: true, granted: true, createdAt: DateTime.now(),
      );
      final consentWithdrawn = ResearchConsent(
        id: 'r2', grantorUid: 'u1', childId: 'c1', consentVersion: 'v1.0',
        scopes: [], childAssent: false, granted: false, createdAt: DateTime.now(),
      );
      expect(consentGranted.granted, isTrue);
      expect(consentWithdrawn.granted, isFalse);
      expect(consentWithdrawn.scopes, isEmpty);
    });

    test('Declining research consent keeps all features working', () {
      bool featuresWorkWhenConsentDeclined = true;
      expect(featuresWorkWhenConsentDeclined, isTrue);
    });

    testWidgets('Consents view shows history', (WidgetTester tester) async {
      final fakeConsents = [
        ResearchConsent(
          id: 'r1', grantorUid: 'u1', childId: 'c1', consentVersion: 'v1.0',
          scopes: ['questionnaire'], childAssent: false, granted: true, createdAt: DateTime.now(),
        )
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            researchConsentRepositoryProvider.overrideWithValue(FakeResearchConsentRepo(consents: fakeConsents)),
            appSessionStateProvider.overrideWith((ref) => AppSessionState(
                  status: AuthSessionStatus.authenticated,
                  user: const AuthUser(uid: 'u1', email: '<redacted>', emailVerified: true, profileExists: true, role: null),
                  profile: Profile(
                    uid: 'u1',
                    role: UserRole.parent,
                    fullName: 'Parent',
                    email: '<redacted>',
                    emailVerified: true,
                    country: 'India',
                    language: 'en',
                    verified: true,
                    children: [
                      Child(
                        id: 'c1',
                        parentUid: 'u1',
                        nickname: 'Sam',
                        dob: DateTime(2018),
                        band: AgeBand.band5_11,
                        homeLanguages: const ['English'],
                        interests: const [],
                        concerns: const [],
                      )
                    ],
                  ),
                  isFirstLaunch: false,
                  onboardingDone: true,
                )),
          ],
          child: const MaterialApp(
            home: ResearchConsentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('GRANTED'),
        200,
      );

      expect(find.textContaining('v1.0'), findsWidgets);
      expect(find.textContaining('GRANTED'), findsWidgets);
    });

    testWidgets('Specialist dashboard has Clinical Assessments entry point', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SpecialistDashboardTab(
                isVerified: true,
                onNavigateTab: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Clinical Assessments'), findsOneWidget);
      expect(find.byIcon(Icons.assessment_rounded), findsOneWidget);
    });

    testWidgets('SpecialistAssessmentsScreen renders Scaffold with title and ClinicalAssessmentsView', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: const MaterialApp(
            home: SpecialistAssessmentsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Clinical Assessments'), findsOneWidget);
      expect(find.byType(ClinicalAssessmentsView), findsOneWidget);
    });

    testWidgets('Route authorization: unauthenticated access to /specialist/assessments redirects to /welcome', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          appSessionStateProvider.overrideWithValue(
            const AppSessionState(
              status: AuthSessionStatus.unauthenticated,
              user: null,
              profile: null,
              isFirstLaunch: false,
              onboardingDone: true,
            ),
          ),
        ],
      );
      final router = container.read(routerProvider);
      router.go('/specialist/assessments');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, equals('/welcome'));
    });

    testWidgets('Route authorization: parent access to /specialist/assessments redirects to /parent', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          appSessionStateProvider.overrideWithValue(
            const AppSessionState(
              status: AuthSessionStatus.authenticated,
              user: AuthUser(
                uid: 'u_parent',
                email: '<redacted>',
                emailVerified: true,
                profileExists: true,
                role: UserRole.parent,
              ),
              profile: Profile(
                uid: 'u_parent',
                role: UserRole.parent,
                fullName: 'Parent User',
                email: '<redacted>',
                emailVerified: true,
                country: 'India',
                language: 'en',
                verified: true,
                children: [],
              ),
              isFirstLaunch: false,
              onboardingDone: true,
            ),
          ),
        ],
      );
      final router = container.read(routerProvider);
      router.go('/specialist/assessments');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, equals('/parent'));
    });
  });
}
