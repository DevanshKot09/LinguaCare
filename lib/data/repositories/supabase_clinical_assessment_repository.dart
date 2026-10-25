import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/assessments/clinical_assessment.dart';
import '../../domain/assessments/clinical_assessment_repository.dart';

class SupabaseClinicalAssessmentRepository implements ClinicalAssessmentRepository {
  final SupabaseClient _supabase;

  SupabaseClinicalAssessmentRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<String> recordAssessment({
    String? childId,
    String? subjectUid,
    required DateTime assessedOn,
    required List<String> toolsUsed,
    required List<String> languagesAssessed,
    required String hearingStatus,
    required String outcome,
    required List<String> domainsAffected,
    String? severity,
    String? note,
    String? supersedesId,
  }) async {
    try {
      final response = await _supabase.rpc('record_assessment', params: {
        'p_child_id': childId,
        'p_subject_uid': subjectUid,
        'p_assessed_on': assessedOn.toIso8601String().split('T').first,
        'p_tools_used': toolsUsed,
        'p_languages_assessed': languagesAssessed,
        'p_hearing_status': hearingStatus,
        'p_outcome': outcome,
        'p_domains_affected': domainsAffected,
        'p_severity': severity,
        'p_note': note,
        'p_supersedes_id': supersedesId,
      });

      return response.toString();
    } catch (e) {
      throw Exception('Failed to record assessment: $e');
    }
  }

  @override
  Future<List<ClinicalAssessment>> getAssessments({String? childId, String? subjectUid}) async {
    try {
      var query = _supabase.from('clinical_assessments').select();
      if (childId != null) {
        query = query.eq('child_id', childId);
      } else if (subjectUid != null) {
        query = query.eq('subject_uid', subjectUid);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((item) => ClinicalAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch assessments: $e');
    }
  }
}
