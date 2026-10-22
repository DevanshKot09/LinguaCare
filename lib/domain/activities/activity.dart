class Activity {
  final String id;
  final int version;
  final String status;
  final String title;
  final String domain;
  final String type;
  final String ageBand;
  final String audience;
  final int estMinutes;
  final int difficulty;
  final String goal;
  final List<String> steps;
  final List<String> parentTips;
  final Map<String, dynamic> content;
  final bool visualSupport;
  final String strengthsMessage;

  const Activity({
    required this.id,
    required this.version,
    required this.status,
    required this.title,
    required this.domain,
    required this.type,
    required this.ageBand,
    required this.audience,
    required this.estMinutes,
    required this.difficulty,
    required this.goal,
    required this.steps,
    required this.parentTips,
    required this.content,
    required this.visualSupport,
    required this.strengthsMessage,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      status: json['status'] as String? ?? 'draft',
      title: json['title'] as String? ?? '',
      domain: json['domain'] as String? ?? 'vocabulary',
      type: json['type'] as String? ?? 'picture_word_match',
      ageBand: json['age_band'] as String? ?? '5_11',
      audience: json['audience'] as String? ?? 'parent',
      estMinutes: json['est_minutes'] as int? ?? 5,
      difficulty: json['difficulty'] as int? ?? 1,
      goal: json['goal'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      parentTips: (json['parent_tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      content: json['content'] as Map<String, dynamic>? ?? {},
      visualSupport: json['visual_support'] as bool? ?? true,
      strengthsMessage: json['strengths_message'] as String? ?? 'Great job!',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'status': status,
        'title': title,
        'domain': domain,
        'type': type,
        'age_band': ageBand,
        'audience': audience,
        'est_minutes': estMinutes,
        'difficulty': difficulty,
        'goal': goal,
        'steps': steps,
        'parent_tips': parentTips,
        'content': content,
        'visual_support': visualSupport,
        'strengths_message': strengthsMessage,
      };
}
