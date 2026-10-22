import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/sharing/sharing_models.dart';
import '../../domain/sharing/sharing_repository.dart';

class SupabaseSharingRepository implements SharingRepository {
  final SupabaseClient _supabase;

  SupabaseSharingRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<InviteResult> createInvite({
    String? childId,
    required String targetRole,
    required String scope,
    int? accessMonths,
    bool teenAssent = false,
  }) async {
    try {
      final response = await _supabase.rpc('create_invite', params: {
        'p_child_id': childId,
        'p_target_role': targetRole,
        'p_scope': scope,
        'p_access_months': accessMonths,
        'p_teen_assent': teenAssent,
      });

      return InviteResult.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  @override
  Future<InvitePreview> previewInvite(String code) async {
    try {
      final response = await _supabase.rpc('preview_invite', params: {
        'p_code': code.trim().toUpperCase(),
      });

      return InvitePreview.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String code) async {
    try {
      final response = await _supabase.rpc('accept_invite', params: {
        'p_code': code.trim().toUpperCase(),
      });

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  @override
  Future<List<LinkInfo>> listMyLinks({bool includeInactive = false}) async {
    try {
      final response = await _supabase.rpc('list_my_links', params: {
        'p_include_inactive': includeInactive,
      });

      if (response == null) return [];
      return (response as List)
          .map((item) => LinkInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  @override
  Future<void> revokeLink(String linkId) async {
    try {
      await _supabase.rpc('revoke_link', params: {
        'p_link_id': linkId,
      });
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  @override
  Future<SharedSummary> getSharedSummary(String linkId) async {
    try {
      final response = await _supabase.rpc('get_shared_summary', params: {
        'p_link_id': linkId,
      });

      return SharedSummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  @override
  Future<List<AccessLogEntry>> listAccessLog({String? childId, String? linkId}) async {
    try {
      final response = await _supabase.rpc('list_access_log', params: {
        'p_child_id': childId,
        'p_link_id': linkId,
      });

      if (response == null) return [];
      return (response as List)
          .map((item) => AccessLogEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SharingFailure(_parseError(e));
    }
  }

  String _parseError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('invalid or expired code')) {
      return 'Invalid or expired invite code.';
    }
    if (msg.contains('Specialist verification pending')) {
      return 'Specialist verification is pending approval by admin.';
    }
    if (msg.contains('Too many failed attempts')) {
      return 'Too many failed attempts. Locked for the hour.';
    }
    if (msg.contains('Teen sharing assent')) {
      return 'Teen sharing assent is required for children in band 11-18.';
    }
    return msg.replaceAll('Exception: ', '').replaceAll('PostgrestException(', '').replaceAll(')', '');
  }
}
