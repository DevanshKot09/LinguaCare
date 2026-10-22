import 'activity.dart';
import 'activity_session.dart';

abstract class ActivityRepository {
  Future<List<Activity>> loadAllActivities();
  Future<void> saveSession(ActivitySession session);
  Future<List<ActivitySession>> getSessionsForChild(String childId);
  Future<List<ActivitySession>> getSessionsForSelf(String subjectUid);
  Future<void> retryOfflineQueue();
}
