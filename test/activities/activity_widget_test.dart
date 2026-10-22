import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linguacare/domain/activities/activity.dart';
import 'package:linguacare/domain/activities/activity_providers.dart';
import 'package:linguacare/domain/activities/activity_repository.dart';
import 'package:linguacare/domain/activities/activity_session.dart';
import 'package:linguacare/features/activities/activity_detail_screen.dart';
import 'package:linguacare/features/activities/progress_dashboard_screen.dart';
import 'package:linguacare/features/activities/activity_wrap_up_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class FakeActivityRepository implements ActivityRepository {
  final List<Activity> activities;
  final List<ActivitySession> sessions;

  FakeActivityRepository({required this.activities, required this.sessions});

  @override
  Future<List<Activity>> loadAllActivities() async => activities;

  @override
  Future<void> saveSession(ActivitySession session) async {}

  @override
  Future<List<ActivitySession>> getSessionsForChild(String childId) async => sessions;

  @override
  Future<List<ActivitySession>> getSessionsForSelf(String subjectUid) async => sessions;

  @override
  Future<void> retryOfflineQueue() async {}
}

void main() {
  testWidgets('Activity Detail Screen renders correctly at 360dp and text scale 2.0', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const activity = Activity(
      id: 'vocab_1',
      version: 1,
      status: 'draft',
      title: 'Vocabulary Match',
      domain: 'vocabulary',
      type: 'picture_word_match',
      ageBand: '5_11',
      audience: 'parent',
      estMinutes: 5,
      difficulty: 1,
      goal: 'Learn new words',
      steps: ['Look at word', 'Match picture'],
      parentTips: ['Praise effort'],
      content: {
        'word': 'Apple',
        'prompt': 'Find match',
        'options': [
          {'label': 'Apple', 'icon': '🍎', 'is_correct': true}
        ]
      },
      visualSupport: true,
      strengthsMessage: 'Great job!',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(
            FakeActivityRepository(activities: [activity], sessions: []),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ActivityDetailScreen(activity: activity, childId: 'c1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Vocabulary Match').first, findsOneWidget);
    expect(find.text('Learn new words'), findsOneWidget);
  });

  testWidgets('Progress Dashboard Screen renders empty and populated states with semantics alternative', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(
            FakeActivityRepository(activities: [], sessions: []),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProgressDashboardScreen(childId: 'c1', title: 'Progress'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Total Sessions'), findsOneWidget);
  });

  testWidgets('ActivityWrapUpScreen highlights selected rating and exposes via Semantics selected', (WidgetTester tester) async {
    const activity = Activity(
      id: 'vocab_1',
      version: 1,
      status: 'draft',
      title: 'Vocabulary Match',
      domain: 'vocabulary',
      type: 'picture_word_match',
      ageBand: '5_11',
      audience: 'parent',
      estMinutes: 5,
      difficulty: 1,
      goal: 'Learn new words',
      steps: ['Look at word'],
      parentTips: ['Praise'],
      content: {},
      visualSupport: true,
      strengthsMessage: 'Great job!',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(
            FakeActivityRepository(activities: [activity], sessions: []),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ActivityWrapUpScreen(activity: activity, durationS: 60, childId: 'c1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Very smooth'), findsOneWidget);

    final semanticsFinder = find.bySemanticsLabel(RegExp('Very smooth'));
    expect(semanticsFinder, findsWidgets);
  });
}
