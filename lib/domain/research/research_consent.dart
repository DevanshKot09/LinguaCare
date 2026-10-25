class ResearchConsent {
  final String id;
  final String grantorUid;
  final String? childId;
  final String? subjectUid;
  final String consentVersion;
  final List<String> scopes; // 'questionnaire', 'tasks', 'clinical_label' - NO audio
  final bool childAssent;
  final bool granted;
  final DateTime createdAt;

  const ResearchConsent({
    required this.id,
    required this.grantorUid,
    this.childId,
    this.subjectUid,
    required this.consentVersion,
    required this.scopes,
    required this.childAssent,
    required this.granted,
    required this.createdAt,
  });

  factory ResearchConsent.fromJson(Map<String, dynamic> json) {
    return ResearchConsent(
      id: json['id'] as String? ?? '',
      grantorUid: json['grantor_uid'] as String? ?? '',
      childId: json['child_id'] as String?,
      subjectUid: json['subject_uid'] as String?,
      consentVersion: json['consent_version'] as String? ?? 'v1.0',
      scopes: List<String>.from(json['scopes'] ?? []),
      childAssent: json['child_assent'] as bool? ?? false,
      granted: json['granted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}
