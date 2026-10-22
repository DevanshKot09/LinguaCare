class ScheduleStep {
  final String id;
  final String iconName;
  final String label;
  final String? timeText;

  ScheduleStep({
    required this.id,
    required this.iconName,
    required this.label,
    this.timeText,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'iconName': iconName,
        'label': label,
        'timeText': timeText,
      };

  factory ScheduleStep.fromJson(Map<String, dynamic> json) => ScheduleStep(
        id: json['id'] as String? ?? '',
        iconName: json['iconName'] as String? ?? 'star',
        label: json['label'] as String? ?? '',
        timeText: json['timeText'] as String?,
      );

  ScheduleStep copyWith({
    String? iconName,
    String? label,
    String? timeText,
  }) {
    return ScheduleStep(
      id: id,
      iconName: iconName ?? this.iconName,
      label: label ?? this.label,
      timeText: timeText ?? this.timeText,
    );
  }
}

class VisualSchedule {
  final String id;
  final String title;
  final String? childNickname;
  final List<ScheduleStep> steps;

  VisualSchedule({
    required this.id,
    required this.title,
    this.childNickname,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'childNickname': childNickname,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory VisualSchedule.fromJson(Map<String, dynamic> json) => VisualSchedule(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        childNickname: json['childNickname'] as String?,
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((s) => ScheduleStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  VisualSchedule copyWith({
    String? title,
    String? childNickname,
    List<ScheduleStep>? steps,
  }) {
    return VisualSchedule(
      id: id,
      title: title ?? this.title,
      childNickname: childNickname ?? this.childNickname,
      steps: steps ?? this.steps,
    );
  }
}

class CommunicationCardModel {
  final String id;
  final String title;
  final List<String> needs;
  final List<String> customLines;

  CommunicationCardModel({
    required this.id,
    required this.title,
    required this.needs,
    required this.customLines,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'needs': needs,
        'customLines': customLines,
      };

  factory CommunicationCardModel.fromJson(Map<String, dynamic> json) => CommunicationCardModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        needs: (json['needs'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        customLines: (json['customLines'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );

  CommunicationCardModel copyWith({
    String? title,
    List<String>? needs,
    List<String>? customLines,
  }) {
    return CommunicationCardModel(
      id: id,
      title: title ?? this.title,
      needs: needs ?? this.needs,
      customLines: customLines ?? this.customLines,
    );
  }
}

class JournalEntry {
  final String id;
  final String dateIso;
  final String mood; // 'great', 'good', 'okay', 'low', 'overwhelmed'
  final List<String> situationTags;
  final String? note;

  JournalEntry({
    required this.id,
    required this.dateIso,
    required this.mood,
    required this.situationTags,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateIso': dateIso,
        'mood': mood,
        'situationTags': situationTags,
        'note': note,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String? ?? '',
        dateIso: json['dateIso'] as String? ?? DateTime.now().toIso8601String(),
        mood: json['mood'] as String? ?? 'good',
        situationTags: (json['situationTags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        note: json['note'] as String?,
      );

  DateTime get dateTime => DateTime.tryParse(dateIso) ?? DateTime.now();
}
