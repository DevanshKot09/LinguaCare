import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Observation {
  final String? id;
  final String childId;
  final String authorUid;
  final List<String> tags;
  final String note;
  final String? setting;
  final bool private;
  final DateTime createdAt;

  const Observation({
    this.id,
    required this.childId,
    required this.authorUid,
    required this.tags,
    required this.note,
    this.setting,
    required this.private,
    required this.createdAt,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['id'] as String?,
      childId: json['child_id'] as String? ?? '',
      authorUid: json['author_uid'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      note: json['note'] as String? ?? '',
      setting: json['setting'] as String?,
      private: json['private'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'child_id': childId,
        'author_uid': authorUid,
        'tags': tags,
        'note': note,
        if (setting != null) 'setting': setting,
        'private': private,
      };

  Map<String, dynamic> toInsertJson() => {
        'child_id': childId,
        'tags': tags,
        'note': note,
        if (setting != null) 'setting': setting,
        'private': private,
      };

  Map<String, dynamic> toUpdateJson() => {
        'tags': tags,
        'note': note,
        if (setting != null) 'setting': setting,
        'private': private,
      };
}

class ObservationRepository {
  final SupabaseClient _supabase;
  ObservationRepository({SupabaseClient? supabase}) : _supabase = supabase ?? Supabase.instance.client;

  Future<List<Observation>> getObservations(String childId) async {
    final response = await _supabase
        .from('observations')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Observation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addObservation(Observation obs) async {
    await _supabase.from('observations').insert(obs.toInsertJson());
  }

  Future<void> updateObservation(String id, Observation obs) async {
    await _supabase.from('observations').update(obs.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteObservation(String id) async {
    await _supabase.from('observations').delete().eq('id', id);
  }
}

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  return ObservationRepository();
});

final observationsProvider = FutureProvider.family<List<Observation>, String>((ref, childId) async {
  final repo = ref.watch(observationRepositoryProvider);
  return repo.getObservations(childId);
});
