import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import 'clinical_assessments_view.dart';

class SpecialistAssessmentsScreen extends ConsumerWidget {
  final String? childId;
  final String? subjectUid;

  const SpecialistAssessmentsScreen({
    super.key,
    this.childId,
    this.subjectUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionStateProvider);
    final isVerified = session.isSpecialistVerified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Assessments'),
        backgroundColor: AppColors.specialistAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClinicalAssessmentsView(
            childId: childId,
            subjectUid: subjectUid,
            isSpecialist: true,
            isVerified: isVerified,
            scope: 'progress_notes',
          ),
        ),
      ),
    );
  }
}
