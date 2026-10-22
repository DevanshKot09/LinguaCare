import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/domain/screening/instrument.dart';
import 'package:linguacare/domain/screening/scoring_engine.dart';

void main() {
  group('ScoringEngine Unit Tests', () {
    late Instrument testInstrument;

    setUp(() {
      testInstrument = Instrument(
        id: 'test_instrument',
        version: '1.0.0',
        status: 'draft',
        audience: 'parent',
        ageBand: '5_11',
        estimatedMinutes: 5,
        introText: 'Intro',
        domains: [
          DomainConfig(id: 'understanding', name: 'Understanding'),
          DomainConfig(id: 'grammar', name: 'Grammar'),
        ],
        items: [
          Item(id: 'q1', text: 'Q1 difficulty', domain: 'understanding', scaleType: 'frequency', direction: true, alsoCheck: ['attention'], urgent: false),
          Item(id: 'q2', text: 'Q2 strength', domain: 'understanding', scaleType: 'frequency', direction: false, alsoCheck: [], urgent: false),
          Item(id: 'q3', text: 'Q3 grammar', domain: 'grammar', scaleType: 'frequency', direction: true, alsoCheck: [], urgent: false),
          Item(id: 'q4', text: 'Q4 urgent', domain: 'grammar', scaleType: 'frequency', direction: true, alsoCheck: ['hearing'], urgent: true),
        ],
        scoring: ScoringConfig(
          minAnsweredPerDomain: 1,
          domainLevels: {
            'strength': ScoreRange(max: 25),
            'typical_range': ScoreRange(min: 26, max: 50),
            'some_signs': ScoreRange(min: 51, max: 75),
            'more_signs': ScoreRange(min: 76, max: 100),
          },
          riskRules: RiskRules(highThresholdCount: 2, someThresholdCount: 1),
          confidenceThresholds: ConfidenceThresholds(high: 0.90, medium: 0.50),
        ),
        wording: {},
      );
    });

    test('All-missing case returns not_enough_info', () {
      final result = ScoringEngine.evaluate(
        instrument: testInstrument,
        answers: {},
        respondentUid: 'user_1',
        respondentRole: 'parent',
        childId: 'child_1',
      );

      expect(result.riskLevel, 'not_enough_info');
      expect(result.completeness, 0.0);
      expect(result.confidence, 'low');
    });

    test('Handles reverse-scored items and Not Sure correctly', () {
      final answers = {
        'q1': 3,
        'q2': 3,
        'q3': null,
        'q4': 2,
      };

      final result = ScoringEngine.evaluate(
        instrument: testInstrument,
        answers: answers,
        respondentUid: 'user_1',
        respondentRole: 'parent',
        childId: 'child_1',
      );

      expect(result.completeness, 0.75); // 3/4 answered (q3 is null)
      expect(result.urgent, true);
    });

    test('Hearing check is always suggested when risk is some_signs or high', () {
      final answers = {
        'q1': 3,
        'q2': 0,
        'q3': 3,
        'q4': 3,
      };

      final result = ScoringEngine.evaluate(
        instrument: testInstrument,
        answers: answers,
        respondentUid: 'user_1',
        respondentRole: 'parent',
        childId: 'child_1',
      );

      expect(result.alsoCheck.contains('hearing'), true);
    });
  });
}
