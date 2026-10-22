class Instrument {
  final String id;
  final String version;
  final String status;
  final String audience;
  final String ageBand;
  final int estimatedMinutes;
  final String introText;
  final List<DomainConfig> domains;
  final List<Item> items;
  final ScoringConfig scoring;
  final Map<String, String> wording;

  Instrument({
    required this.id,
    required this.version,
    required this.status,
    required this.audience,
    required this.ageBand,
    required this.estimatedMinutes,
    required this.introText,
    required this.domains,
    required this.items,
    required this.scoring,
    required this.wording,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      id: json['id'] as String,
      version: json['version'] as String,
      status: json['status'] as String,
      audience: json['audience'] as String,
      ageBand: json['age_band'] as String,
      estimatedMinutes: json['estimated_minutes'] as int,
      introText: json['intro_text'] as String,
      domains: (json['domains'] as List)
          .map((d) => DomainConfig.fromJson(d as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List)
          .map((i) => Item.fromJson(i as Map<String, dynamic>))
          .toList(),
      scoring: ScoringConfig.fromJson(json['scoring'] as Map<String, dynamic>),
      wording: Map<String, String>.from(
        (json['wording']?['risk'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class DomainConfig {
  final String id;
  final String name;

  DomainConfig({required this.id, required this.name});

  factory DomainConfig.fromJson(Map<String, dynamic> json) {
    return DomainConfig(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class Item {
  final String id;
  final String text;
  final String domain;
  final String scaleType;
  final bool direction; // true = higher frequency means more difficulty
  final List<String> alsoCheck;
  final bool urgent;

  Item({
    required this.id,
    required this.text,
    required this.domain,
    required this.scaleType,
    required this.direction,
    required this.alsoCheck,
    required this.urgent,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      text: json['text'] as String,
      domain: json['domain'] as String,
      scaleType: json['scale_type'] as String? ?? 'frequency',
      direction: json['direction'] as bool? ?? true,
      alsoCheck: List<String>.from(json['also_check'] ?? []),
      urgent: json['urgent'] as bool? ?? false,
    );
  }
}

class ScoringConfig {
  final int minAnsweredPerDomain;
  final Map<String, ScoreRange> domainLevels;
  final RiskRules riskRules;
  final ConfidenceThresholds confidenceThresholds;

  ScoringConfig({
    required this.minAnsweredPerDomain,
    required this.domainLevels,
    required this.riskRules,
    required this.confidenceThresholds,
  });

  factory ScoringConfig.fromJson(Map<String, dynamic> json) {
    final levelsMap = <String, ScoreRange>{};
    final rawLevels = json['domain_levels'] as Map<String, dynamic>? ?? {};
    rawLevels.forEach((k, v) {
      levelsMap[k] = ScoreRange.fromJson(v as Map<String, dynamic>);
    });

    return ScoringConfig(
      minAnsweredPerDomain: json['min_answered_per_domain'] as int? ?? 2,
      domainLevels: levelsMap,
      riskRules: RiskRules.fromJson(json['risk_rules'] as Map<String, dynamic>? ?? {}),
      confidenceThresholds: ConfidenceThresholds.fromJson(
        json['confidence_thresholds'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class ScoreRange {
  final double? min;
  final double? max;

  ScoreRange({this.min, this.max});

  factory ScoreRange.fromJson(Map<String, dynamic> json) {
    return ScoreRange(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  bool contains(double score) {
    if (min != null && score < min!) return false;
    if (max != null && score > max!) return false;
    return true;
  }
}

class RiskRules {
  final int highThresholdCount;
  final int someThresholdCount;

  RiskRules({required this.highThresholdCount, required this.someThresholdCount});

  factory RiskRules.fromJson(Map<String, dynamic> json) {
    return RiskRules(
      highThresholdCount: json['high_threshold_count'] as int? ?? 2,
      someThresholdCount: json['some_threshold_count'] as int? ?? 1,
    );
  }
}

class ConfidenceThresholds {
  final double high;
  final double medium;

  ConfidenceThresholds({required this.high, required this.medium});

  factory ConfidenceThresholds.fromJson(Map<String, dynamic> json) {
    return ConfidenceThresholds(
      high: (json['high'] as num?)?.toDouble() ?? 0.90,
      medium: (json['medium'] as num?)?.toDouble() ?? 0.70,
    );
  }
}
