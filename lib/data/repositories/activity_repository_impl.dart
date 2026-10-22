import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/activities/activity.dart';
import '../../domain/activities/activity_repository.dart';
import '../../domain/activities/activity_session.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final SupabaseClient _supabase;
  static const String _offlineQueueKey = 'activity_sessions_offline_queue_v1';

  ActivityRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  static const List<String> _activityFiles = [
    'vocab_colors_5_11',
    'follow_shapes_5_11',
    'story_pets_5_11',
    'sentence_food_5_11',
    'scenario_friends_5_11',
    'vocab_tech_11_18',
    'follow_plan_11_18',
    'story_event_11_18',
    'sentence_complex_11_18',
    'scenario_group_11_18',
    'vocab_work_adult',
    'follow_instructions_adult',
    'story_recount_adult',
    'sentence_professional_adult',
    'scenario_workplace_adult',
  ];

  @override
  Future<List<Activity>> loadAllActivities() async {
    final activities = <Activity>[];
    for (final filename in _activityFiles) {
      try {
        final jsonString = await rootBundle.loadString('assets/activities/v1/$filename.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        activities.add(Activity.fromJson(jsonMap));
      } catch (e) {
        // Skip missing or invalid asset safely
      }
    }
    return activities;
  }

  @override
  Future<void> saveSession(ActivitySession session) async {
    try {
      final data = session.toJson();
      await _supabase.from('activity_sessions').insert(data);
      // Also try to flush any offline queue
      await retryOfflineQueue();
    } catch (_) {
      // Offline fallback: save to local queue with duplicate protection (client_id)
      await _enqueueOffline(session);
    }
  }

  Future<void> _enqueueOffline(ActivitySession session) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_offlineQueueKey) ?? [];
    final jsonStr = json.encode(session.toJson());
    // Avoid duplicates by client_id
    queue.removeWhere((item) {
      try {
        final map = json.decode(item);
        return map['client_id'] == session.clientId;
      } catch (_) {
        return false;
      }
    });
    queue.add(jsonStr);
    await prefs.setStringList(_offlineQueueKey, queue);
  }

  @override
  Future<void> retryOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_offlineQueueKey) ?? [];
    if (queue.isEmpty) return;

    final remaining = <String>[];
    for (final item in queue) {
      try {
        final Map<String, dynamic> data = json.decode(item);
        await _supabase.from('activity_sessions').insert(data);
      } catch (_) {
        remaining.add(item);
      }
    }
    await prefs.setStringList(_offlineQueueKey, remaining);
  }

  @override
  Future<List<ActivitySession>> getSessionsForChild(String childId) async {
    try {
      await retryOfflineQueue();
      final response = await _supabase
          .from('activity_sessions')
          .select()
          .eq('child_id', childId)
          .order('started_at', ascending: false);

      return (response as List)
          .map((row) => ActivitySession.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback to local queue items matching childId if offline
      return _getLocalSessionsForChild(childId);
    }
  }

  @override
  Future<List<ActivitySession>> getSessionsForSelf(String subjectUid) async {
    try {
      await retryOfflineQueue();
      final response = await _supabase
          .from('activity_sessions')
          .select()
          .eq('subject_uid', subjectUid)
          .order('started_at', ascending: false);

      return (response as List)
          .map((row) => ActivitySession.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _getLocalSessionsForSelf(subjectUid);
    }
  }

  Future<List<ActivitySession>> _getLocalSessionsForChild(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_offlineQueueKey) ?? [];
    return queue
        .map((item) {
          try {
            return ActivitySession.fromJson(json.decode(item));
          } catch (_) {
            return null;
          }
        })
        .where((s) => s != null && s.childId == childId)
        .cast<ActivitySession>()
        .toList();
  }

  Future<List<ActivitySession>> _getLocalSessionsForSelf(String subjectUid) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_offlineQueueKey) ?? [];
    return queue
        .map((item) {
          try {
            return ActivitySession.fromJson(json.decode(item));
          } catch (_) {
            return null;
          }
        })
        .where((s) => s != null && s.subjectUid == subjectUid)
        .cast<ActivitySession>()
        .toList();
  }
}
