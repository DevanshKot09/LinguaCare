import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_clinical_assessment_repository.dart';
import 'clinical_assessment.dart';
import 'clinical_assessment_repository.dart';

final clinicalAssessmentRepositoryProvider = Provider<ClinicalAssessmentRepository>((ref) {
  return SupabaseClinicalAssessmentRepository();
});

final assessmentsProvider = FutureProvider.family<List<ClinicalAssessment>, String?>((ref, childId) async {
  final repo = ref.watch(clinicalAssessmentRepositoryProvider);
  return repo.getAssessments(childId: childId);
});
