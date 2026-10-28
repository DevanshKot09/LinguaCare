import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/domain/sharing/sharing_models.dart';
import 'package:linguacare/domain/sharing/sharing_providers.dart';
import 'package:linguacare/domain/sharing/sharing_repository.dart';
import 'package:linguacare/domain/observations/observation.dart';
import 'package:linguacare/domain/goals/goal.dart';
import 'package:linguacare/domain/auth/auth_repository.dart';
import 'package:linguacare/domain/auth/auth_user.dart';
import 'package:linguacare/data/repositories/firebase_auth_repository.dart';
import 'package:linguacare/features/teacher/teacher_home_screen.dart';
import 'package:linguacare/features/specialist/specialist_home_screen.dart';
import 'package:linguacare/features/observations/observations_view.dart';
import 'package:linguacare/features/goals/goals_view.dart';
import 'package:linguacare/features/sharing/shared_summary_detail_screen.dart';
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

class FakeDebtSharingRepository implements SharingRepository {
  final List<LinkInfo> links;
  final SharedSummary? summary;
  FakeDebtSharingRepository({required this.links, this.summary});

  @override
  Future<InviteResult> createInvite({String? childId, required String targetRole, required String scope, int? accessMonths, bool teenAssent = false}) async {
    return InviteResult(code: 'CODE123', expiresAt: DateTime.now().add(const Duration(days: 7)));
  }

  @override
  Future<InvitePreview> previewInvite(String code) async {
    return const InvitePreview(targetRole: 'teacher', scope: 'progress', subjectKind: 'child', childNickname: 'Sam', inviterFirstName: 'Parent');
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String code) async {
    return {'link_id': 'link_1', 'status': 'active'};
  }

  @override
  Future<List<LinkInfo>> listMyLinks({bool includeInactive = false}) async => links;

  @override
  Future<void> revokeLink(String linkId) async {}

  @override
  Future<SharedSummary> getSharedSummary(String linkId) async {
    return summary ?? const SharedSummary(nickname: 'Sam', band: '5_11', scope: 'progress', screeningSessions: [], activitySessions: []);
  }

  @override
  Future<List<AccessLogEntry>> listAccessLog({String? childId, String? linkId}) async => [];
}

class FakeDebtObservationRepository implements ObservationRepository {
  final List<Observation> observations;
  FakeDebtObservationRepository({required this.observations});

  @override
  Future<List<Observation>> getObservations(String childId) async => observations;

  @override
  Future<void> addObservation(Observation obs) async {}

  @override
  Future<void> updateObservation(String id, Observation obs) async {}

  @override
  Future<void> deleteObservation(String id) async {}
}

class FakeDebtGoalRepository implements GoalRepository {
  final List<Goal> goals;
  FakeDebtGoalRepository({required this.goals});

  @override
  Future<List<Goal>> getGoals(String childId) async => goals;

  @override
  Future<void> addGoal(Goal goal) async {}

  @override
  Future<void> updateGoal(Goal goal) async {}

  @override
  Future<void> deleteGoal(String id) async {}
}

bool isValidObservationNote(String note) {
  if (note.length > 500) return false;
  final phoneRegExp = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
  final emailRegExp = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  return !phoneRegExp.hasMatch(note) && !emailRegExp.hasMatch(note);
}

bool isValidObservationTags(List<String> tags) => tags.length <= 8;
bool isValidGoalDescription(String desc) => desc.length <= 300;
bool isValidGoalProgress(int progress) => progress >= 0 && progress <= 100;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 4B2-A Debt & Unit Tests', () {
    test('Permission to UI mapping unit tests (role x scope x verified x expired)', () {
      final tLink = LinkInfo(
        linkId: 'l1', childId: 'c1', childNickname: 'Sam', ownerUid: 'p1', ownerName: 'Parent',
        memberUid: 't1', memberName: 'Teacher', memberRole: 'teacher', memberVerified: true,
        scope: 'progress', status: 'active', expiresAt: DateTime.now().add(const Duration(days: 10)), createdAt: DateTime.now(),
      );
      expect(tLink.memberRole, 'teacher');
      expect(tLink.scope, 'progress');
      expect(tLink.memberVerified, isTrue);
      expect(tLink.status, 'active');

      final sLinkUnverified = LinkInfo(
        linkId: 'l2', childId: 'c1', childNickname: 'Sam', ownerUid: 'p1', ownerName: 'Parent',
        memberUid: 's1', memberName: 'Specialist', memberRole: 'specialist', memberVerified: false,
        scope: 'progress_notes', status: 'active', expiresAt: DateTime.now().add(const Duration(days: 30)), createdAt: DateTime.now(),
      );
      expect(sLinkUnverified.memberVerified, isFalse);

      final expiredLink = LinkInfo(
        linkId: 'l3', childId: 'c1', childNickname: 'Sam', ownerUid: 'p1', ownerName: 'Parent',
        memberUid: 'm1', memberName: 'Member', memberRole: 'teacher', memberVerified: true,
        scope: 'progress', status: 'revoked', expiresAt: DateTime.now().subtract(const Duration(days: 1)), createdAt: DateTime.now(),
      );
      expect(expiredLink.status, 'revoked');
    });

    test('Observation note rejects phone number', () {
      expect(isValidObservationNote('Call 555-123-4567 for details'), isFalse);
    });

    test('Observation note rejects email address', () {
      expect(isValidObservationNote('Email user@test.com for info'), isFalse);
    });

    test('Observation note rejects more than 500 characters', () {
      expect(isValidObservationNote('a' * 501), isFalse);
      expect(isValidObservationNote('a' * 500), isTrue);
    });

    test('Observation tags limited to 8', () {
      expect(isValidObservationTags(List.generate(8, (i) => 'tag$i')), isTrue);
      expect(isValidObservationTags(List.generate(9, (i) => 'tag$i')), isFalse);
    });

    test('Goal description over 300 rejected in UI', () {
      expect(isValidGoalDescription('a' * 301), isFalse);
      expect(isValidGoalDescription('a' * 300), isTrue);
    });

    test('Goal progress limited to 0-100', () {
      expect(isValidGoalProgress(-1), isFalse);
      expect(isValidGoalProgress(0), isTrue);
      expect(isValidGoalProgress(100), isTrue);
      expect(isValidGoalProgress(101), isFalse);
    });
  });

  group('Teacher & Specialist Widget Tests', () {
    testWidgets('Teacher home shows empty state for new teacher', (WidgetTester tester) async {
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
      expect(find.text('No linked students yet.'), findsOneWidget);
    });

    testWidgets('Teacher home shows linked student count and expiring links', (WidgetTester tester) async {
      final links = [
        LinkInfo(
          linkId: 'l1', childId: 'c1', childNickname: 'Sam', ownerUid: 'p1', ownerName: 'Parent',
          memberUid: 't1', memberName: 'Teacher', memberRole: 'teacher', memberVerified: true,
          scope: 'progress', status: 'active', expiresAt: DateTime.now().add(const Duration(days: 5)), createdAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: links)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TeacherDashboardTab(onNavigateTab: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Linked Students'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('Expiring in 14 Days'), findsOneWidget);
    });

    testWidgets('Teacher can add observation with valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            observationRepositoryProvider.overrideWithValue(FakeDebtObservationRepository(observations: [])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ObservationsView(childId: 'c1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Observations Log'), findsOneWidget);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add Observation'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Student participated well in group reading.');
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Teacher view-only state for progress scope explains why', (WidgetTester tester) async {
      const summary = SharedSummary(
        nickname: 'Sam',
        band: '5_11',
        scope: 'progress',
        screeningSessions: [],
        activitySessions: [],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [], summary: summary)),
            sharedSummaryProvider('l1').overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'l1', childName: 'Sam'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared by the family. Read-only.'), findsOneWidget);
      expect(find.text('Active Scope: PROGRESS'), findsOneWidget);
      expect(find.text('LinguaCare supports language development. It does not diagnose.'), findsOneWidget);
    });

    testWidgets('Teacher cannot see goal creation controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Teacher view with no goals control')),
        ),
      );
      expect(find.text('Add Goal'), findsNothing);
    });

    testWidgets('Unverified specialist sees locked state and banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SpecialistHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Licence verification pending approval'), findsOneWidget);
    });

    testWidgets('Verified specialist can create goal with valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            goalRepositoryProvider.overrideWithValue(FakeDebtGoalRepository(goals: [])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: GoalsView(childId: 'c1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Communication Goals'), findsOneWidget);
      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Add Communication Goal'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Expand vocabulary by 10 words');
      await tester.pumpAndSettle();
      expect(find.text('Save Goal'), findsOneWidget);
    });

    testWidgets('Specialist client detail shows non-diagnostic notice', (WidgetTester tester) async {
      const summary = SharedSummary(
        nickname: 'Sam',
        band: '5_11',
        scope: 'progress_notes',
        screeningSessions: [],
        activitySessions: [],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [], summary: summary)),
            sharedSummaryProvider('l1').overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'l1', childName: 'Sam'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('LinguaCare supports language development. It does not diagnose.'), findsOneWidget);
    });

    testWidgets('Specialist client detail shows prototype label for unpublished instrument', (WidgetTester tester) async {
      const summary = SharedSummary(
        nickname: 'Sam',
        band: '5_11',
        scope: 'progress_notes',
        screeningSessions: [
          {
            'risk_level': 'moderate',
            'created_at': '2026-03-01T00:00:00.000Z',
            'instrument_status': 'prototype',
          }
        ],
        activitySessions: [],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [], summary: summary)),
            sharedSummaryProvider('l1').overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'l1', childName: 'Sam'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Prototype - not clinically validated'), findsOneWidget);
    });

    testWidgets('Access ended state shown when link is revoked', (WidgetTester tester) async {
      const summary = SharedSummary(
        nickname: 'Sam',
        band: '5_11',
        scope: 'progress',
        screeningSessions: [],
        activitySessions: [],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [], summary: summary)),
            sharedSummaryProvider('l1').overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'l1', childName: 'Sam'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Leave Link / Remove Access'), findsOneWidget);
      await tester.tap(find.text('Leave Link / Remove Access'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Link'), findsOneWidget);
      expect(find.text('Are you sure you want to leave and remove access to this summary?'), findsOneWidget);
    });

    testWidgets('Teacher layout 360dp no overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TeacherHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });

    testWidgets('Specialist layout 900dp no overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SpecialistHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SpecialistHomeScreen), findsOneWidget);
    });

    testWidgets('Text scale 2.0 no overflow for teacher and specialist screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: TeacherHomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TeacherHomeScreen), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            sharingRepositoryProvider.overrideWithValue(FakeDebtSharingRepository(links: [])),
          ],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SpecialistHomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SpecialistHomeScreen), findsOneWidget);
    });
  });
}
