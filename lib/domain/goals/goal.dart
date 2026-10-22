import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Goal {
  final String? id;
  final String childId;
  final String authorUid;
  final String domain;
  final String description;
  final String? targetDate;
  final String status; // active | completed | paused
  final int progress; // 0-100
  final DateTime createdAt;

  const Goal({
    this.id,
    required this.childId,
    required this.authorUid,
    required this.domain,
    required this.description,
    this.targetDate,
    required this.status,
    required this.progress,
    required this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String?,
      childId: json['child_id'] as String? ?? '',
      authorUid: json['author_uid'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetDate: json['target_date'] as String?,
      status: json['status'] as String? ?? 'active',
      progress: json['progress'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'child_id': childId,
        'author_uid': authorUid,
        'domain': domain,
        'description': description,
        if (targetDate != null) 'target_date': targetDate,
        'status': status,
        'progress': progress,
      };

  Map<String, dynamic> toInsertJson() => {
        'child_id': childId,
        'domain': domain,
        'description': description,
        if (targetDate != null) 'target_date': targetDate,
        'status': status,
        'progress': progress,
      };

  Map<String, dynamic> toUpdateJson() => {
        'domain': domain,
        'description': description,
        if (targetDate != null) 'target_date': targetDate,
        'status': status,
        'progress': progress,
      };
}

class GoalRepository {
  final SupabaseClient _supabase;
  GoalRepository({SupabaseClient? supabase}) : _supabase = supabase ?? Supabase.instance.client;

  Future<List<Goal>> getGoals(String childId) async {
    final response = await _supabase
        .from('goals')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addGoal(Goal goal) async {
    await _supabase.from('goals').insert(goal.toInsertJson());
  }

  Future<void> updateGoal(Goal goal) async {
    await _supabase.from('goals').update(goal.toUpdateJson()).eq('id', goal.id!);
  }

  Future<void> deleteGoal(String id) async {
    await _supabase.from('goals').delete().eq('id', id);
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final goalsProvider = FutureProvider.family<List<Goal>, String>((ref, childId) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoals(childId);
});
