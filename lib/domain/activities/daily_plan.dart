import 'activity.dart';

class DailyPlan {
  final List<Activity> activities;
  final int totalMinutes;

  const DailyPlan({
    required this.activities,
    required this.totalMinutes,
  });
}
