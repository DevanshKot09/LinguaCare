import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/screening/instrument.dart';
import '../../domain/screening/screening_repository.dart';
import '../../domain/screening/screening_result.dart';

class ScreeningRepositoryImpl implements ScreeningRepository {
  final SupabaseClient _supabase;

  ScreeningRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<Instrument> loadInstrument(String instrumentId) async {
    final jsonString = await rootBundle.loadString('assets/screening/v1/$instrumentId.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return Instrument.fromJson(jsonMap);
  }

  @override
  Future<void> saveScreeningResult(ScreeningResult result) async {
    final data = result.toJson();
    await _supabase.from('screening_sessions').insert(data);
  }

  @override
  Future<List<ScreeningResult>> getScreeningHistoryForChild(String childId) async {
    final response = await _supabase
        .from('screening_sessions')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => ScreeningResult.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScreeningResult>> getScreeningHistoryForSelf(String subjectUid) async {
    final response = await _supabase
        .from('screening_sessions')
        .select()
        .eq('subject_uid', subjectUid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => ScreeningResult.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteScreeningResult(String sessionId) async {
    await _supabase.from('screening_sessions').delete().eq('id', sessionId);
  }

  @override
  Future<void> saveDraftAnswers(String instrumentId, Map<String, int?> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = answers.map((k, v) => MapEntry(k, v?.toString() ?? 'null'));
    await prefs.setString('screening_draft_$instrumentId', json.encode(encoded));
  }

  @override
  Future<Map<String, int?>> loadDraftAnswers(String instrumentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('screening_draft_$instrumentId');
    if (raw == null) return {};

    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final result = <String, int?>{};
      decoded.forEach((k, v) {
        result[k] = (v == 'null' || v == null) ? null : int.tryParse(v.toString());
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> clearDraftAnswers(String instrumentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('screening_draft_$instrumentId');
  }
}
