import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/domain/activities/activity.dart';
import 'package:linguacare/domain/activities/activity_session.dart';
import 'package:linguacare/domain/activities/daily_plan_generator.dart';
import 'package:linguacare/domain/activities/progress_aggregator.dart';
import 'package:linguacare/domain/screening/screening_result.dart';

void main() {
  group('Activity Unit Tests', () {
    test('Activity parsing from JSON works correctly for picture_word_match', () {
      final json = {
        'id': 'test_vocab',
        'version': 1,
        'status': 'draft',
        'title': 'Test Vocab',
        'domain': 'vocabulary',
        'type': 'picture_word_match',
        'age_band': '5_11',
        'audience': 'parent',
        'est_minutes': 5,
        'difficulty': 1,
        'goal': 'Goal text',
        'steps': ['Step 1'],
        'parent_tips': ['Tip 1'],
        'content': {'word': 'Apple'},
        'visual_support': true,
        'strengths_message': 'Great job!'
      };

      final activity = Activity.fromJson(json);
      expect(activity.id, 'test_vocab');
      expect(activity.type, 'picture_word_match');
      expect(activity.estMinutes, 5);
      expect(activity.visualSupport, isTrue);
    });

    test('DailyPlanGenerator prioritizes screening domains of need and respects 15 min cap', () {
      final activities = [
        const Activity(
          id: 'a1',
          version: 1,
          status: 'draft',
          title: 'Vocab',
          domain: 'vocabulary',
          type: 'picture_word_match',
          ageBand: '5_11',
          audience: 'parent',
          estMinutes: 5,
          difficulty: 1,
          goal: '',
          steps: [],
          parentTips: [],
          content: {},
          visualSupport: true,
          strengthsMessage: '',
        ),
        const Activity(
          id: 'a2',
          version: 1,
          status: 'draft',
          title: 'Grammar',
          domain: 'grammar',
          type: 'sentence_builder',
          ageBand: '5_11',
          audience: 'parent',
          estMinutes: 10,
          difficulty: 1,
          goal: '',
          steps: [],
          parentTips: [],
          content: {},
          visualSupport: true,
          strengthsMessage: '',
        ),
        const Activity(
          id: 'a3',
          version: 1,
          status: 'draft',
          title: 'Understanding',
          domain: 'understanding',
          type: 'follow_steps',
          ageBand: '5_11',
          audience: 'parent',
          estMinutes: 8,
          difficulty: 1,
          goal: '',
          steps: [],
          parentTips: [],
          content: {},
          visualSupport: true,
          strengthsMessage: '',
        ),
      ];

      final screening = ScreeningResult(
        instrumentId: 'parent_5_11',
        childId: 'c1',
        respondentUid: 'user1',
        respondentRole: 'parent',
        instrumentVersion: '1.0.0',
        instrumentStatus: 'draft',
        answers: {},
        domainScores: {'grammar': 75.0},
        domainLevels: {'grammar': 'some_signs'},
        riskLevel: 'some_signs',
        alsoCheck: [],
        urgent: false,
        completeness: 1.0,
        confidence: 'high',
        configVersion: '1.0.0',
        createdAt: DateTime.now(),
      );

      final plan = DailyPlanGenerator.generate(
        availableActivities: activities,
        recentSessions: [],
        latestScreening: screening,
      );

      expect(plan.totalMinutes, lessThanOrEqualTo(15));
      expect(plan.activities.isNotEmpty, true);
      // Grammar should be prioritized because it has someSigns
      expect(plan.activities.first.domain, 'grammar');
    });

    test('ProgressAggregator handles empty sessions and computes correct summaries', () {
      final emptySummary = ProgressAggregator.aggregate([]);
      expect(emptySummary.totalSessions, 0);
      expect(emptySummary.trendMessage, contains('Not enough practice yet'));

      final sessions = [
        ActivitySession(
          actorUid: 'user1',
          activityId: 'a1',
          activityVersion: 1,
          domain: 'vocabulary',
          startedAt: DateTime.now(),
          durationS: 300,
          completed: true,
          successLevel: 4,
          supportLevel: 'independent',
          clientId: 'uuid-1',
        ),
        ActivitySession(
          actorUid: 'user1',
          activityId: 'a2',
          activityVersion: 1,
          domain: 'vocabulary',
          startedAt: DateTime.now(),
          durationS: 300,
          completed: true,
          successLevel: 5,
          supportLevel: 'independent',
          clientId: 'uuid-2',
        ),
      ];

      final summary = ProgressAggregator.aggregate(sessions);
      expect(summary.totalSessions, 2);
      expect(summary.totalMinutes, 10);
      expect(summary.domainSummaries['vocabulary']?.sessionCount, 2);
      expect(summary.domainSummaries['vocabulary']?.averageSuccess, 4.5);
    });
  });
}
