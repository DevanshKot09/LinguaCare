class ActivitySession {
  final String? id;
  final String? childId;
  final String? subjectUid;
  final String actorUid;
  final String activityId;
  final int activityVersion;
  final String domain;
  final DateTime startedAt;
  final int durationS;
  final bool completed;
  final int? successLevel;
  final String? supportLevel;
  final DateTime? createdAt;
  final String clientId;

  const ActivitySession({
    this.id,
    this.childId,
    this.subjectUid,
    required this.actorUid,
    required this.activityId,
    required this.activityVersion,
    required this.domain,
    required this.startedAt,
    required this.durationS,
    required this.completed,
    this.successLevel,
    this.supportLevel,
    this.createdAt,
    required this.clientId,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'] as String?,
      childId: json['child_id'] as String?,
      subjectUid: json['subject_uid'] as String?,
      actorUid: json['actor_uid'] as String? ?? '',
      activityId: json['activity_id'] as String? ?? '',
      activityVersion: json['activity_version'] as int? ?? 1,
      domain: json['domain'] as String? ?? '',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : DateTime.now(),
      durationS: json['duration_s'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      successLevel: json['success_level'] as int?,
      supportLevel: json['support_level'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      clientId: json['client_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (childId != null) 'child_id': childId,
        if (subjectUid != null) 'subject_uid': subjectUid,
        'actor_uid': actorUid,
        'activity_id': activityId,
        'activity_version': activityVersion,
        'domain': domain,
        'started_at': startedAt.toIso8601String(),
        'duration_s': durationS,
        'completed': completed,
        if (successLevel != null) 'success_level': successLevel,
        if (supportLevel != null) 'support_level': supportLevel,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'client_id': clientId,
      };
}
