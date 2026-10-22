import 'sharing_models.dart';

abstract class SharingRepository {
  Future<InviteResult> createInvite({
    String? childId,
    required String targetRole,
    required String scope,
    int? accessMonths,
    bool teenAssent = false,
  });

  Future<InvitePreview> previewInvite(String code);

  Future<Map<String, dynamic>> acceptInvite(String code);

  Future<List<LinkInfo>> listMyLinks({bool includeInactive = false});

  Future<void> revokeLink(String linkId);

  Future<SharedSummary> getSharedSummary(String linkId);

  Future<List<AccessLogEntry>> listAccessLog({String? childId, String? linkId});
}
