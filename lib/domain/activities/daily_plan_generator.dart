import 'activity.dart';
import 'activity_session.dart';
import '../screening/screening_result.dart';
import 'daily_plan.dart';

class DailyPlanGenerator {
  static DailyPlan generate({
    required List<Activity> availableActivities,
    required List<ActivitySession> recentSessions,
    ScreeningResult? latestScreening,
  }) {
    // 1. Identify domains with signs from latest screening if available
    final domainsNeedingFocus = <String>{};
    if (latestScreening != null) {
      latestScreening.domainLevels.forEach((domain, level) {
        if (level == 'some_signs' || level == 'more_signs') {
          domainsNeedingFocus.add(domain);
        }
      });
    }

    // 2. Identify activity IDs done in the last 2 days
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final recentlyDoneActivityIds = recentSessions
        .where((s) => s.startedAt.isAfter(twoDaysAgo))
        .map((s) => s.activityId)
        .toSet();

    // 3. Filter out recently done activities
    final eligibleActivities = availableActivities
        .where((a) => !recentlyDoneActivityIds.contains(a.id))
        .toList();

    // Fallback if all recently done: use all available
    final candidatePool = eligibleActivities.isNotEmpty ? eligibleActivities : availableActivities;

    // 4. Sort candidates: prioritize focused domains
    candidatePool.sort((a, b) {
      final aFocus = domainsNeedingFocus.contains(a.domain) ? 0 : 1;
      final bFocus = domainsNeedingFocus.contains(b.domain) ? 0 : 1;
      return aFocus.compareTo(bFocus);
    });

    // 5. Select 2-3 activities such that totalMinutes <= 15
    final selected = <Activity>[];
    int totalMinutes = 0;

    for (final activity in candidatePool) {
      if (selected.length >= 3) break;
      if (totalMinutes + activity.estMinutes <= 15) {
        selected.add(activity);
        totalMinutes += activity.estMinutes;
      }
    }

    // Ensure at least 1 if pool is not empty and none selected yet
    if (selected.isEmpty && candidatePool.isNotEmpty) {
      selected.add(candidatePool.first);
      totalMinutes = candidatePool.first.estMinutes;
    }

    return DailyPlan(
      activities: selected,
      totalMinutes: totalMinutes,
    );
  }
}
