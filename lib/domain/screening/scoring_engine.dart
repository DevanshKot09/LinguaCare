import 'instrument.dart';
import 'screening_result.dart';

class ScoringEngine {
  static ScreeningResult evaluate({
    required Instrument instrument,
    required Map<String, int?> answers,
    required String respondentUid,
    required String respondentRole,
    String? childId,
    String? subjectUid,
  }) {
    final totalItems = instrument.items.length;
    int answeredCount = 0;
    
    // Group items by domain
    final domainItems = <String, List<Item>>{};
    for (var domain in instrument.domains) {
      domainItems[domain.id] = [];
    }
    for (var item in instrument.items) {
      if (domainItems.containsKey(item.domain)) {
        domainItems[item.domain]!.add(item);
      }
    }

    final domainScores = <String, double>{};
    final domainLevels = <String, String>{};
    final collectedAlsoCheck = <String>{};
    bool urgentTriggered = false;

    // Evaluate each domain
    domainItems.forEach((domainId, items) {
      int domainAnswered = 0;
      double domainPointsSum = 0;
      int domainMaxPossible = 0;

      for (var item in items) {
        final rawScore = answers[item.id];
        if (rawScore != null) {
          domainAnswered++;
          answeredCount++;
          
          // Calculate difficulty points (0 to 3)
          // Scale: 0 = Rarely/Never, 1 = Sometimes, 2 = Often, 3 = Almost always
          double points = rawScore.toDouble();
          if (!item.direction) {
            // Reverse score: higher frequency means more strength -> invert to difficulty
            points = (3 - rawScore).toDouble();
          }
          domainPointsSum += points;
          domainMaxPossible += 3;

          // Collect also_check if endorsed (score >= 1)
          if (rawScore >= 1) {
            collectedAlsoCheck.addAll(item.alsoCheck);
          }

          // Check urgent rule (urgent item with score >= 2)
          if (item.urgent && rawScore >= 2) {
            urgentTriggered = true;
          }
        }
      }

      if (domainAnswered >= instrument.scoring.minAnsweredPerDomain && domainMaxPossible > 0) {
        final normalizedScore = (domainPointsSum / domainMaxPossible) * 100.0;
        domainScores[domainId] = double.parse(normalizedScore.toStringAsFixed(1));

        // Determine domain level based on scoring config thresholds
        final levels = instrument.scoring.domainLevels;
        String level = 'typical_range';
        
        if (levels['strength'] != null && levels['strength']!.contains(normalizedScore)) {
          level = 'strength';
        } else if (levels['typical_range'] != null && levels['typical_range']!.contains(normalizedScore)) {
          level = 'typical_range';
        } else if (levels['some_signs'] != null && levels['some_signs']!.contains(normalizedScore)) {
          level = 'some_signs';
        } else if (levels['more_signs'] != null && levels['more_signs']!.contains(normalizedScore)) {
          level = 'more_signs';
        }
        domainLevels[domainId] = level;
      } else {
        domainLevels[domainId] = 'insufficient_data';
      }
    });

    final completeness = totalItems > 0 ? answeredCount / totalItems : 0.0;

    // Determine confidence based on completeness
    String confidence = 'low';
    if (completeness >= instrument.scoring.confidenceThresholds.high) {
      confidence = 'high';
    } else if (completeness >= instrument.scoring.confidenceThresholds.medium) {
      confidence = 'medium';
    }

    // Determine overall risk level
    // Check if we have enough answered domains
    int validDomainsCount = domainLevels.values.where((l) => l != 'insufficient_data').length;
    String riskLevel = 'not_enough_info';

    if (validDomainsCount > 0 && answeredCount >= instrument.scoring.minAnsweredPerDomain) {
      int moreSignsCount = domainLevels.values.where((l) => l == 'more_signs').length;
      int someSignsCount = domainLevels.values.where((l) => l == 'some_signs' || l == 'more_signs').length;

      final riskRules = instrument.scoring.riskRules;
      if (moreSignsCount >= riskRules.highThresholdCount) {
        riskLevel = 'high';
      } else if (someSignsCount >= riskRules.someThresholdCount || moreSignsCount > 0) {
        riskLevel = 'some_signs';
      } else {
        riskLevel = 'low';
      }
    }

    // Hearing check rule: ALWAYS suggested when risk is some_signs or high
    if (riskLevel == 'some_signs' || riskLevel == 'high') {
      collectedAlsoCheck.add('hearing');
    }

    return ScreeningResult(
      childId: childId,
      subjectUid: subjectUid,
      respondentUid: respondentUid,
      respondentRole: respondentRole,
      instrumentId: instrument.id,
      instrumentVersion: instrument.version,
      instrumentStatus: instrument.status,
      answers: answers,
      domainScores: domainScores,
      domainLevels: domainLevels,
      riskLevel: riskLevel,
      alsoCheck: collectedAlsoCheck.toList()..sort(),
      urgent: urgentTriggered,
      completeness: double.parse(completeness.toStringAsFixed(2)),
      confidence: confidence,
      configVersion: instrument.version,
    );
  }
}
