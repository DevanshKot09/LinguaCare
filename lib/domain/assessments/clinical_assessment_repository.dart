import 'clinical_assessment.dart';

abstract class ClinicalAssessmentRepository {
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
  });

  Future<List<ClinicalAssessment>> getAssessments({String? childId, String? subjectUid});
}
