import 'research_consent.dart';

abstract class ResearchConsentRepository {
  Future<String> grantResearchConsent({
    String? childId,
    String? subjectUid,
    required String consentVersion,
    required List<String> scopes,
    required bool childAssent,
  });

  Future<String> withdrawResearchConsent({
    String? childId,
    String? subjectUid,
    required String consentVersion,
  });

  Future<List<ResearchConsent>> getResearchConsents();
}
