class ScreeningResult {
  final String? id;
  final String? childId;
  final String? subjectUid;
  final String respondentUid;
  final String respondentRole;
  final String instrumentId;
  final String instrumentVersion;
  final String instrumentStatus;
  final Map<String, int?> answers;
  final Map<String, double> domainScores;
  final Map<String, String> domainLevels;
  final String riskLevel; // low, some_signs, high, not_enough_info
  final List<String> alsoCheck;
  final bool urgent;
  final double completeness;
  final String confidence; // high, medium, low
  final String configVersion;
  final DateTime createdAt;

  ScreeningResult({
    this.id,
    this.childId,
    this.subjectUid,
    required this.respondentUid,
    required this.respondentRole,
    required this.instrumentId,
    required this.instrumentVersion,
    required this.instrumentStatus,
    required this.answers,
    required this.domainScores,
    required this.domainLevels,
    required this.riskLevel,
    required this.alsoCheck,
    required this.urgent,
    required this.completeness,
    required this.confidence,
    required this.configVersion,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (subjectUid != null) 'subject_uid': subjectUid,
      'respondent_uid': respondentUid,
      'respondent_role': respondentRole,
      'instrument_id': instrumentId,
      'instrument_version': instrumentVersion,
      'instrument_status': instrumentStatus,
      'answers': answers.map((k, v) => MapEntry(k, v)),
      'domain_scores': domainScores,
      'domain_levels': domainLevels,
      'risk_level': riskLevel,
      'also_check': alsoCheck,
      'urgent': urgent,
      'completeness': completeness,
      'config_version': configVersion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ScreeningResult.fromJson(Map<String, dynamic> json) {
    return ScreeningResult(
      id: json['id'] as String?,
      childId: json['child_id'] as String?,
      subjectUid: json['subject_uid'] as String?,
      respondentUid: json['respondent_uid'] as String? ?? '',
      respondentRole: json['respondent_role'] as String? ?? 'parent',
      instrumentId: json['instrument_id'] as String? ?? '',
      instrumentVersion: json['instrument_version'] as String? ?? '1.0.0',
      instrumentStatus: json['instrument_status'] as String? ?? 'draft',
      answers: (json['answers'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as int?),
      ),
      domainScores: (json['domain_scores'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      domainLevels: (json['domain_levels'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as String),
      ),
      riskLevel: json['risk_level'] as String? ?? 'not_enough_info',
      alsoCheck: List<String>.from(json['also_check'] ?? []),
      urgent: json['urgent'] as bool? ?? false,
      completeness: (json['completeness'] as num?)?.toDouble() ?? 0.0,
      confidence: json['confidence'] as String? ?? 'low',
      configVersion: json['config_version'] as String? ?? '1.0.0',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
