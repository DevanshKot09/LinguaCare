import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_research_consent_repository.dart';
import 'research_consent.dart';
import 'research_consent_repository.dart';

final researchConsentRepositoryProvider = Provider<ResearchConsentRepository>((ref) {
  return SupabaseResearchConsentRepository();
});

final researchConsentsProvider = FutureProvider<List<ResearchConsent>>((ref) async {
  final repo = ref.watch(researchConsentRepositoryProvider);
  return repo.getResearchConsents();
});
