class SummaryScreeningItem {
  final String date;
  final String instrumentVersion;
  final String riskWording;
  final List<String> domainLevels;
  final List<String> alsoCheckFlags;
  final bool urgentNoticeTriggered;
  final String confidence;
  final bool isPrototype;

  const SummaryScreeningItem({
    required this.date,
    required this.instrumentVersion,
    required this.riskWording,
    required this.domainLevels,
    required this.alsoCheckFlags,
    required this.urgentNoticeTriggered,
    required this.confidence,
    required this.isPrototype,
  });
}

class SummaryPracticeItem {
  final String domain;
  final String summaryText;
  final int durationMinutes;
  final String supportLevel;
  final String date;

  const SummaryPracticeItem({
    required this.domain,
    required this.summaryText,
    required this.durationMinutes,
    required this.supportLevel,
    required this.date,
  });
}

class SummaryGoalItem {
  final String description;
  final String domain;
  final String status;
  final int progress;

  const SummaryGoalItem({
    required this.description,
    required this.domain,
    required this.status,
    required this.progress,
  });
}

class SummaryObservationItem {
  final String note;
  final String setting;
  final String date;
  final bool isPrivate;
  final bool isOwnObservation;

  const SummaryObservationItem({
    required this.note,
    required this.setting,
    required this.date,
    required this.isPrivate,
    required this.isOwnObservation,
  });
}

class SummaryDocument {
  final String title;
  final String generatedDate;
  final String subjectNickname;
  final String subjectAgeBand;
  final String generatedByRole;
  final String nonDiagnosticNotice;
  final bool isPrototype;
  final List<SummaryScreeningItem> screeningResults;
  final List<SummaryPracticeItem> practiceSummary;
  final List<SummaryGoalItem> goals;
  final List<SummaryObservationItem> observations;
  final bool includeNotes;
  final bool isAccessEnded;
  final bool isEmptyDataset;

  const SummaryDocument({
    required this.title,
    required this.generatedDate,
    required this.subjectNickname,
    required this.subjectAgeBand,
    required this.generatedByRole,
    required this.nonDiagnosticNotice,
    required this.isPrototype,
    required this.screeningResults,
    required this.practiceSummary,
    required this.goals,
    required this.observations,
    required this.includeNotes,
    required this.isAccessEnded,
    required this.isEmptyDataset,
  });
}
