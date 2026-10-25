class ClinicalAssessment {
  final String id;
  final String? childId;
  final String? subjectUid;
  final String specialistUid;
  final DateTime assessedOn;
  final List<String> toolsUsed;
  final List<String> languagesAssessed;
  final String hearingStatus; // 'normal', 'impaired', 'not_tested'
  final String outcome; // 'typical', 'dld', 'language_difficulty_other_cause', 'speech_sound_disorder', 'other'
  final List<String> domainsAffected; // 'understanding', 'expressive', 'vocabulary', 'grammar', 'narrative', 'pragmatics'
  final String? severity; // 'mild', 'moderate', 'severe'
  final String? note;
  final String? supersedesId;
  final DateTime createdAt;

  const ClinicalAssessment({
    required this.id,
    this.childId,
    this.subjectUid,
    required this.specialistUid,
    required this.assessedOn,
    required this.toolsUsed,
    required this.languagesAssessed,
    required this.hearingStatus,
    required this.outcome,
    required this.domainsAffected,
    this.severity,
    this.note,
    this.supersedesId,
    required this.createdAt,
  });

  factory ClinicalAssessment.fromJson(Map<String, dynamic> json) {
    return ClinicalAssessment(
      id: json['id'] as String? ?? '',
      childId: json['child_id'] as String?,
      subjectUid: json['subject_uid'] as String?,
      specialistUid: json['specialist_uid'] as String? ?? '',
      assessedOn: json['assessed_on'] != null ? DateTime.parse(json['assessed_on'] as String) : DateTime.now(),
      toolsUsed: List<String>.from(json['tools_used'] ?? []),
      languagesAssessed: List<String>.from(json['languages_assessed'] ?? []),
      hearingStatus: json['hearing_status'] as String? ?? 'not_tested',
      outcome: json['outcome'] as String? ?? 'typical',
      domainsAffected: List<String>.from(json['domains_affected'] ?? []),
      severity: json['severity'] as String?,
      note: json['note'] as String?,
      supersedesId: json['supersedes_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}

bool isValidAssessmentNote(String? note) {
  if (note == null || note.isEmpty) return true;
  if (note.length > 500) return false;
  final phoneRegExp = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
  final emailRegExp = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  return !phoneRegExp.hasMatch(note) && !emailRegExp.hasMatch(note);
}
