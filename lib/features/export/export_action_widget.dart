import 'package:flutter/material.dart';
import 'summary_document.dart';
import 'summary_builder.dart';
import 'export_confirm_dialog.dart';
import 'export_service.dart';

void showExportSummaryDialog({
  required BuildContext context,
  required String role,
  required String scope,
  required String subjectNickname,
  required String subjectAgeBand,
  required bool isAccessEnded,
  required List<SummaryScreeningItem> screeningSessions,
  required List<SummaryPracticeItem> practiceItems,
  required List<SummaryGoalItem> goalItems,
  required List<SummaryObservationItem> rawObservations,
  List<SummaryAssessmentItem> clinicalAssessments = const [],
}) {
  final showNotesToggle = scope == 'progress_notes' || role == 'parent' || role == 'adult';

  showDialog(
    context: context,
    builder: (context) => ExportConfirmDialog(
      showNotesToggle: showNotesToggle,
      onConfirmed: (includeNotes) async {
        final doc = SummaryBuilder.buildSummary(
          role: role,
          scope: scope,
          subjectNickname: subjectNickname,
          subjectAgeBand: subjectAgeBand,
          isAccessEnded: isAccessEnded,
          includeNotes: includeNotes,
          screeningSessions: screeningSessions,
          practiceSummary: practiceItems,
          goalItems: goalItems,
          rawObservations: rawObservations,
          clinicalAssessments: clinicalAssessments,
        );
        await ExportService.exportAndShare(doc);
      },
    ),
  );
}
