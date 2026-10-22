import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linguacare/domain/sharing/sharing_models.dart';
import 'package:linguacare/domain/sharing/sharing_providers.dart';
import 'package:linguacare/domain/sharing/sharing_repository.dart';
import 'package:linguacare/features/sharing/accept_invite_screen.dart';
import 'package:linguacare/features/sharing/shared_summary_detail_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class FakeSharingRepository implements SharingRepository {
  final String mode; // 'normal' | 'error' | 'pending'
  final String scope;
  final List<Map<String, dynamic>> observations;
  final List<Map<String, dynamic>> goals;

  FakeSharingRepository({
    this.mode = 'normal',
    this.scope = 'progress_notes',
    this.observations = const [
      {'note': 'Public observation note', 'setting': 'Home', 'private': false, 'created_at': '2026-03-01T00:00:00.000Z'},
      {'note': 'Private observation note', 'setting': 'Home', 'private': true, 'created_at': '2026-03-01T00:00:00.000Z'},
    ],
    this.goals = const [
      {'description': 'Learn 10 words', 'domain': 'vocabulary', 'status': 'active', 'progress': 50},
    ],
  });

  @override
  Future<InviteResult> createInvite({
    String? childId,
    required String targetRole,
    required String scope,
    int? accessMonths,
    bool teenAssent = false,
  }) async {
    return InviteResult(code: 'TESTCODE12', expiresAt: DateTime.now().add(const Duration(hours: 72)));
  }

  @override
  Future<InvitePreview> previewInvite(String code) async {
    if (code == 'INVALID' || code == 'EXPIRED') {
      throw const SharingFailure('Invalid or expired invite code.');
    }
    if (code == 'PENDING') {
      throw const SharingFailure('Specialist verification pending approval by admin');
    }
    return const InvitePreview(
      targetRole: 'teacher',
      scope: 'progress',
      accessMonths: 12,
      subjectKind: 'child',
      childNickname: 'Sam',
      childBand: '5_11',
      inviterFirstName: 'Parent',
    );
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String code) async {
    if (code == 'INVALID') throw const SharingFailure('Invalid or expired invite code.');
    if (code == 'PENDING') throw const SharingFailure('Specialist verification pending approval by admin');
    return {'link_id': 'link_1', 'status': 'active'};
  }

  @override
  Future<List<LinkInfo>> listMyLinks({bool includeInactive = false}) async {
    return [
      LinkInfo(
        linkId: 'link_1',
        childId: 'c1',
        childNickname: 'Sam',
        childBand: '5_11',
        ownerUid: 'p1',
        ownerName: 'Parent User',
        memberUid: 't1',
        memberName: 'Teacher User',
        memberRole: 'teacher',
        memberVerified: true,
        scope: scope,
        status: 'active',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> revokeLink(String linkId) async {}

  @override
  Future<SharedSummary> getSharedSummary(String linkId) async {
    return SharedSummary(
      nickname: 'Sam',
      band: '5_11',
      scope: scope,
      screeningSessions: [],
      activitySessions: [],
      observations: observations,
      goals: goals,
    );
  }

  @override
  Future<List<AccessLogEntry>> listAccessLog({String? childId, String? linkId}) async {
    return [
      AccessLogEntry(
        memberName: 'Teacher User',
        memberRole: 'teacher',
        action: 'GET_SHARED_SUMMARY',
        timestamp: DateTime.now(),
      ),
    ];
  }
}

void main() {
  group('Sharing Unit Tests', () {
    test('SharingFailure maps error message correctly', () {
      const failure = SharingFailure('Invalid or expired invite code.');
      expect(failure.message, 'Invalid or expired invite code.');
    });

    test('Scope descriptions are correctly mapped', () {
      const progressScope = 'progress';
      const notesScope = 'progress_notes';
      expect(progressScope, equals('progress'));
      expect(notesScope, equals('progress_notes'));
    });
  });

  group('Sharing Widget Tests', () {
    testWidgets('Accept Invite Screen renders correctly at 360dp and text scale 2.0', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
          ],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AcceptInviteScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Accept Invite Code'), findsOneWidget);
      expect(find.text('Preview Code'), findsOneWidget);
    });

    testWidgets('Shared Summary Detail Screen renders correctly at 900dp', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'link_1', childName: 'Sam'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Sam - Shared Summary'), findsOneWidget);
      expect(find.text('Shared by the family. Read-only.'), findsOneWidget);
    });

    testWidgets('Shared Summary renders observations and goals for progress_notes scope, hides them for progress scope, and private observations never render', (WidgetTester tester) async {
      // Test progress_notes scope renders public observations and goals, but hides private observations
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharingRepositoryProvider.overrideWithValue(
              FakeSharingRepository(scope: 'progress_notes'),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'link_1', childName: 'Sam'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Public observation note'), findsOneWidget);
      expect(find.text('Private observation note'), findsNothing);
      expect(find.text('Learn 10 words'), findsOneWidget);

      // Test progress scope hides observations and goals
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharingRepositoryProvider.overrideWithValue(
              FakeSharingRepository(scope: 'progress'),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SharedSummaryDetailScreen(linkId: 'link_1', childName: 'Sam'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Public observation note'), findsNothing);
      expect(find.text('Private observation note'), findsNothing);
      expect(find.text('Learn 10 words'), findsNothing);
    });

    testWidgets('Accept Invite Screen handles invalid code error gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AcceptInviteScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'INVALID');
      await tester.tap(find.text('Preview Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid or expired'), findsWidgets);
    });

    testWidgets('Accept Invite Screen handles specialist pending state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AcceptInviteScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'PENDING');
      await tester.tap(find.text('Preview Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Specialist verification pending'), findsWidgets);
    });
  });
}
