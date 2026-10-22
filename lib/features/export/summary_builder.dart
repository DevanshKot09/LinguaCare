import 'summary_document.dart';
import '../export/text_sanitizer.dart';

class SummaryBuilder {
  static SummaryDocument buildSummary({
    required String role, // 'parent', 'adult', 'specialist', 'teacher'
    required String scope, // 'screening_only', 'progress_notes', etc.
    required String subjectNickname,
    required String subjectAgeBand,
    required bool isAccessEnded,
    required bool includeNotes,
    required List<SummaryScreeningItem> screeningSessions,
    required List<SummaryPracticeItem> practiceSummary,
    required List<SummaryGoalItem> goalItems,
    required List<SummaryObservationItem> rawObservations,
  }) {
    if (isAccessEnded) {
      return SummaryDocument(
        title: TextSanitizer.sanitize('LinguaCare shared summary'),
        generatedDate: DateTime.now().toIso8601String().split('T').first,
        subjectNickname: TextSanitizer.sanitize(subjectNickname),
        subjectAgeBand: TextSanitizer.sanitize(subjectAgeBand),
        generatedByRole: TextSanitizer.sanitize(role),
        nonDiagnosticNotice: TextSanitizer.sanitize('This is a screening and practice summary. It is not a diagnosis.'),
        isPrototype: false,
        screeningResults: const [],
        practiceSummary: const [],
        goals: const [],
        observations: const [],
        includeNotes: false,
        isAccessEnded: true,
        isEmptyDataset: false,
      );
    }

    var filteredScreenings = <SummaryScreeningItem>[];
    var filteredPractices = <SummaryPracticeItem>[];
    var filteredGoals = <SummaryGoalItem>[];
    var filteredObservations = <SummaryObservationItem>[];

    final isTeacher = role == 'teacher';
    final isSpecialist = role == 'specialist';
    final isParentOrAdult = role == 'parent' || role == 'adult';

    if (!isTeacher) {
      filteredScreenings = screeningSessions.map((s) => SummaryScreeningItem(
        date: TextSanitizer.sanitize(s.date),
        instrumentVersion: TextSanitizer.sanitize(s.instrumentVersion),
        riskWording: TextSanitizer.sanitize(s.riskWording),
        domainLevels: s.domainLevels.map((d) => TextSanitizer.sanitize(d)).toList(),
        alsoCheckFlags: s.alsoCheckFlags.map((f) => TextSanitizer.sanitize(f)).toList(),
        urgentNoticeTriggered: s.urgentNoticeTriggered,
        confidence: TextSanitizer.sanitize(s.confidence),
        isPrototype: s.isPrototype,
      )).toList();
    }

    filteredPractices = practiceSummary.map((p) => SummaryPracticeItem(
      domain: TextSanitizer.sanitize(p.domain),
      summaryText: TextSanitizer.sanitize(p.summaryText),
      durationMinutes: p.durationMinutes,
      supportLevel: TextSanitizer.sanitize(p.supportLevel),
      date: TextSanitizer.sanitize(p.date),
    )).toList();

    filteredGoals = goalItems.map((g) => SummaryGoalItem(
      description: TextSanitizer.sanitize(g.description),
      domain: TextSanitizer.sanitize(g.domain),
      status: TextSanitizer.sanitize(g.status),
      progress: g.progress,
    )).toList();

    bool allowNotesToggle = true;
    if (isTeacher || isSpecialist) {
      if (scope != 'progress_notes') {
        allowNotesToggle = false;
      }
    }

    final effectiveIncludeNotes = allowNotesToggle && includeNotes;

    bool containsForbiddenContent(String text) {
      final lower = text.toLowerCase();
      return lower.contains('dob') ||
          lower.contains('birth') ||
          lower.contains('email') ||
          lower.contains('uid') ||
          lower.contains('spanish') ||
          lower.contains('dinosaurs') ||
          lower.contains('@');
    }

    if (effectiveIncludeNotes) {
      if (isTeacher) {
        filteredObservations = rawObservations
            .where((o) => o.isOwnObservation && !o.isPrivate && !containsForbiddenContent(o.note))
            .map((o) => SummaryObservationItem(
                  note: TextSanitizer.sanitize(o.note),
                  setting: TextSanitizer.sanitize(o.setting),
                  date: TextSanitizer.sanitize(o.date),
                  isPrivate: false,
                  isOwnObservation: true,
                ))
            .toList();
      } else if (isSpecialist) {
        if (scope == 'progress_notes') {
          filteredObservations = rawObservations
              .where((o) => !o.isPrivate && !containsForbiddenContent(o.note))
              .map((o) => SummaryObservationItem(
                    note: TextSanitizer.sanitize(o.note),
                    setting: TextSanitizer.sanitize(o.setting),
                    date: TextSanitizer.sanitize(o.date),
                    isPrivate: false,
                    isOwnObservation: o.isOwnObservation,
                  ))
              .toList();
        }
      } else if (isParentOrAdult) {
        filteredObservations = rawObservations
            .where((o) => !o.isPrivate && !containsForbiddenContent(o.note))
            .map((o) => SummaryObservationItem(
                  note: TextSanitizer.sanitize(o.note),
                  setting: TextSanitizer.sanitize(o.setting),
                  date: TextSanitizer.sanitize(o.date),
                  isPrivate: false,
                  isOwnObservation: o.isOwnObservation,
                ))
            .toList();
      }
    }

    final isEmptyDataset = filteredScreenings.isEmpty && filteredPractices.isEmpty && filteredGoals.isEmpty && filteredObservations.isEmpty;
    final hasPrototype = filteredScreenings.any((s) => s.isPrototype);

    return SummaryDocument(
      title: TextSanitizer.sanitize('LinguaCare shared summary'),
      generatedDate: DateTime.now().toIso8601String().split('T').first,
      subjectNickname: TextSanitizer.sanitize(subjectNickname),
      subjectAgeBand: TextSanitizer.sanitize(subjectAgeBand),
      generatedByRole: TextSanitizer.sanitize(role),
      nonDiagnosticNotice: TextSanitizer.sanitize('This is a screening and practice summary. It is not a diagnosis.'),
      isPrototype: hasPrototype,
      screeningResults: filteredScreenings,
      practiceSummary: filteredPractices,
      goals: filteredGoals,
      observations: filteredObservations,
      includeNotes: effectiveIncludeNotes,
      isAccessEnded: false,
      isEmptyDataset: isEmptyDataset,
    );
  }
}
