import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/research/research_consent.dart';
import '../../domain/research/research_consent_repository.dart';

class SupabaseResearchConsentRepository implements ResearchConsentRepository {
  final SupabaseClient _supabase;

  SupabaseResearchConsentRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<String> grantResearchConsent({
    String? childId,
    String? subjectUid,
    required String consentVersion,
    required List<String> scopes,
    required bool childAssent,
  }) async {
    try {
      final response = await _supabase.rpc('grant_research_consent', params: {
        'p_child_id': childId,
        'p_subject_uid': subjectUid,
        'p_consent_version': consentVersion,
        'p_scopes': scopes,
        'p_child_assent': childAssent,
      });
      return response.toString();
    } catch (e) {
      throw Exception('Failed to grant research consent: $e');
    }
  }

  @override
  Future<String> withdrawResearchConsent({
    String? childId,
    String? subjectUid,
    required String consentVersion,
  }) async {
    try {
      final response = await _supabase.rpc('withdraw_research_consent', params: {
        'p_child_id': childId,
        'p_subject_uid': subjectUid,
        'p_consent_version': consentVersion,
      });
      return response.toString();
    } catch (e) {
      throw Exception('Failed to withdraw research consent: $e');
    }
  }

  @override
  Future<List<ResearchConsent>> getResearchConsents() async {
    try {
      final response = await _supabase.from('research_consents').select().order('created_at', ascending: false);
      return (response as List)
          .map((item) => ResearchConsent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch research consents: $e');
    }
  }
}
