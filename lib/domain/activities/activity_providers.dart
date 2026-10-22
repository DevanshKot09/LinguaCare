import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/activity_repository_impl.dart';
import 'activity.dart';
import 'activity_repository.dart';
import 'activity_session.dart';
import 'daily_plan.dart';
import 'daily_plan_generator.dart';
import 'progress_aggregator.dart';
import '../screening/screening_providers.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl();
});

final allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.loadAllActivities();
});

final activitySessionsForChildProvider = FutureProvider.family<List<ActivitySession>, String>((ref, childId) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getSessionsForChild(childId);
});

final activitySessionsForSelfProvider = FutureProvider.family<List<ActivitySession>, String>((ref, subjectUid) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getSessionsForSelf(subjectUid);
});

final dailyPlanForChildProvider = FutureProvider.family<DailyPlan, String>((ref, childId) async {
  final allActivitiesAsync = await ref.watch(allActivitiesProvider.future);
  final sessionsAsync = await ref.watch(activitySessionsForChildProvider(childId).future);
  final screeningsAsync = await ref.watch(childScreeningHistoryProvider(childId).future);

  final latestScreening = screeningsAsync.isNotEmpty ? screeningsAsync.first : null;
  return DailyPlanGenerator.generate(
    availableActivities: allActivitiesAsync,
    recentSessions: sessionsAsync,
    latestScreening: latestScreening,
  );
});

final dailyPlanForSelfProvider = FutureProvider.family<DailyPlan, String>((ref, subjectUid) async {
  final allActivitiesAsync = await ref.watch(allActivitiesProvider.future);
  final sessionsAsync = await ref.watch(activitySessionsForSelfProvider(subjectUid).future);
  final screeningsAsync = await ref.watch(selfScreeningHistoryProvider(subjectUid).future);

  final latestScreening = screeningsAsync.isNotEmpty ? screeningsAsync.first : null;
  return DailyPlanGenerator.generate(
    availableActivities: allActivitiesAsync,
    recentSessions: sessionsAsync,
    latestScreening: latestScreening,
  );
});

final progressForChildProvider = FutureProvider.family<ProgressSummary, String>((ref, childId) async {
  final sessions = await ref.watch(activitySessionsForChildProvider(childId).future);
  return ProgressAggregator.aggregate(sessions);
});

final progressForSelfProvider = FutureProvider.family<ProgressSummary, String>((ref, subjectUid) async {
  final sessions = await ref.watch(activitySessionsForSelfProvider(subjectUid).future);
  return ProgressAggregator.aggregate(sessions);
});
