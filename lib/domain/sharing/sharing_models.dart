class InviteResult {
  final String code;
  final DateTime expiresAt;

  const InviteResult({required this.code, required this.expiresAt});

  factory InviteResult.fromJson(Map<String, dynamic> json) {
    return InviteResult(
      code: json['code'] as String? ?? '',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now().add(const Duration(hours: 72)),
    );
  }
}

class InvitePreview {
  final String targetRole;
  final String scope;
  final int? accessMonths;
  final String subjectKind; // child | adult
  final String? childNickname;
  final String? childBand;
  final String inviterFirstName;

  const InvitePreview({
    required this.targetRole,
    required this.scope,
    this.accessMonths,
    required this.subjectKind,
    this.childNickname,
    this.childBand,
    required this.inviterFirstName,
  });

  factory InvitePreview.fromJson(Map<String, dynamic> json) {
    return InvitePreview(
      targetRole: json['target_role'] as String? ?? 'teacher',
      scope: json['scope'] as String? ?? 'progress',
      accessMonths: json['access_months'] as int?,
      subjectKind: json['subject_kind'] as String? ?? 'child',
      childNickname: json['child_nickname'] as String?,
      childBand: json['child_band'] as String?,
      inviterFirstName: json['inviter_first_name'] as String? ?? '',
    );
  }
}

class LinkInfo {
  final String linkId;
  final String? childId;
  final String? subjectUid;
  final String childNickname;
  final String? childBand;
  final String ownerUid;
  final String ownerName;
  final String memberUid;
  final String memberName;
  final String memberRole;
  final bool memberVerified;
  final String? memberWorkplace;
  final String scope;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const LinkInfo({
    required this.linkId,
    this.childId,
    this.subjectUid,
    required this.childNickname,
    this.childBand,
    required this.ownerUid,
    required this.ownerName,
    required this.memberUid,
    required this.memberName,
    required this.memberRole,
    required this.memberVerified,
    this.memberWorkplace,
    required this.scope,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  factory LinkInfo.fromJson(Map<String, dynamic> json) {
    return LinkInfo(
      linkId: json['link_id'] as String? ?? '',
      childId: json['child_id'] as String?,
      subjectUid: json['subject_uid'] as String?,
      childNickname: json['child_nickname'] as String? ?? '',
      childBand: json['child_band'] as String?,
      ownerUid: json['owner_uid'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      memberUid: json['member_uid'] as String? ?? '',
      memberName: json['member_name'] as String? ?? '',
      memberRole: json['member_role'] as String? ?? '',
      memberVerified: json['member_verified'] as bool? ?? false,
      memberWorkplace: json['member_workplace'] as String?,
      scope: json['scope'] as String? ?? 'progress',
      status: json['status'] as String? ?? 'active',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}

class SharedSummary {
  final String nickname;
  final String? band;
  final String scope;
  final List<Map<String, dynamic>> screeningSessions;
  final List<Map<String, dynamic>> activitySessions;
  final List<Map<String, dynamic>> observations;
  final List<Map<String, dynamic>> goals;

  const SharedSummary({
    required this.nickname,
    this.band,
    required this.scope,
    required this.screeningSessions,
    required this.activitySessions,
    this.observations = const [],
    this.goals = const [],
  });

  factory SharedSummary.fromJson(Map<String, dynamic> json) {
    return SharedSummary(
      nickname: json['nickname'] as String? ?? '',
      band: json['band'] as String?,
      scope: json['scope'] as String? ?? 'progress',
      screeningSessions: List<Map<String, dynamic>>.from(json['screening_sessions'] ?? []),
      activitySessions: List<Map<String, dynamic>>.from(json['activity_sessions'] ?? []),
      observations: List<Map<String, dynamic>>.from(json['observations'] ?? []),
      goals: List<Map<String, dynamic>>.from(json['goals'] ?? []),
    );
  }
}

class AccessLogEntry {
  final String memberName;
  final String memberRole;
  final String action;
  final DateTime timestamp;

  const AccessLogEntry({
    required this.memberName,
    required this.memberRole,
    required this.action,
    required this.timestamp,
  });

  factory AccessLogEntry.fromJson(Map<String, dynamic> json) {
    return AccessLogEntry(
      memberName: json['member_name'] as String? ?? '',
      memberRole: json['member_role'] as String? ?? '',
      action: json['action'] as String? ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
    );
  }
}

class SharingFailure implements Exception {
  final String message;
  const SharingFailure(this.message);

  @override
  String toString() => message;
}
