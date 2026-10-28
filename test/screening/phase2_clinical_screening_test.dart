import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/domain/screening/instrument.dart';
import 'package:linguacare/domain/screening/screening_result.dart';
import 'package:linguacare/features/screening/data/screening_milestone_data.dart';
import 'package:linguacare/features/screening/services/clinical_referral_pdf_service.dart';
import 'package:linguacare/features/screening/widgets/milestone_breakdown_matrix.dart';
import 'package:linguacare/features/screening/widgets/screening_domain_chart.dart';

void main() {
  final sampleInstrument = Instrument(
    id: 'parent_5_11',
    version: '1.0.0',
    status: 'published',
    audience: 'parent',
    ageBand: '5_11',
    estimatedMinutes: 5,
    introText: 'Test intro',
    domains: [
      DomainConfig(id: 'understanding', name: 'Understanding Language'),
      DomainConfig(id: 'words', name: 'Words & Vocabulary'),
      DomainConfig(id: 'grammar', name: 'Grammar & Sentences'),
      DomainConfig(id: 'stories', name: 'Stories & Explanations'),
      DomainConfig(id: 'conversation', name: 'Conversation & Social Use'),
    ],
    items: [
      Item(
        id: 'p5_1',
        text: 'How often does child ask for repeats?',
        domain: 'understanding',
        scaleType: 'frequency',
        direction: true,
        alsoCheck: [],
        urgent: false,
      ),
    ],
    scoring: ScoringConfig(
      minAnsweredPerDomain: 1,
      domainLevels: {},
      riskRules: RiskRules(highThresholdCount: 2, someThresholdCount: 1),
      confidenceThresholds: ConfidenceThresholds(high: 0.9, medium: 0.7),
    ),
    wording: {
      'low': 'No strong signs',
      'some_signs': 'Some signs',
      'high': 'Several signs',
    },
  );

  final sampleResult = ScreeningResult(
    respondentUid: 'user-1',
    respondentRole: 'parent',
    instrumentId: 'parent_5_11',
    instrumentVersion: '1.0.0',
    instrumentStatus: 'published',
    answers: {'p5_1': 2},
    domainScores: {
      'understanding': 30.0,
      'words': 45.0,
      'grammar': 80.0,
      'stories': 60.0,
      'conversation': 25.0,
    },
    domainLevels: {
      'understanding': 'typical_range',
      'words': 'typical_range',
      'grammar': 'more_signs',
      'stories': 'some_signs',
      'conversation': 'strength',
    },
    riskLevel: 'some_signs',
    alsoCheck: ['hearing'],
    urgent: true,
    completeness: 1.0,
    confidence: 'high',
    configVersion: '1.0',
  );

  group('Phase 2 - Clinical Screening Milestones & PDF Service', () {
    test('ScreeningMilestoneData returns real-world examples for question items', () {
      final example1 = ScreeningMilestoneData.itemExamples['p5_1'];
      expect(example1, isNotNull);
      expect(example1, contains('asks'));

      final example5 = ScreeningMilestoneData.itemExamples['p5_5'];
      expect(example5, isNotNull);
      expect(example5, contains('grammatical'));

      final milestone = ScreeningMilestoneData.getMilestone('grammar', '5_11');
      expect(milestone.domain, contains('Grammar'));
      expect(milestone.recommendation, contains('recasting'));
    });

    test('ClinicalReferralPdfService formats plain text summary correctly', () {
      final summary = ClinicalReferralPdfService.generateTextSummary(
        instrument: sampleInstrument,
        result: sampleResult,
        childName: 'Aarav (Age 6)',
      );

      expect(summary, contains('CLINICAL LANGUAGE SCREENING SUMMARY'));
      expect(summary, contains('Aarav (Age 6)'));
      expect(summary, contains('5–11 Years'));
      expect(summary, contains('SOME SIGNS'));
      expect(summary, contains('URGENT CLINICAL NOTICE: Hearing check'));
      expect(summary, contains('Grammar & Sentences: 80%'));
      expect(summary, contains('Speech-Language Pathologist'));
    });

    testWidgets('ScreeningDomainChart renders all 5 domains with score labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScreeningDomainChart(
                instrument: sampleInstrument,
                result: sampleResult,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Domain Score Breakdown'), findsOneWidget);
      expect(find.textContaining('Strength / Typical'), findsWidgets);
    });

    testWidgets('MilestoneBreakdownMatrix renders domain cards and target milestones', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MilestoneBreakdownMatrix(
                instrument: sampleInstrument,
                result: sampleResult,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Developmental Milestone Matrix'), findsOneWidget);
      expect(find.text('Understanding Language'), findsOneWidget);
      expect(find.text('Grammar & Sentences'), findsOneWidget);
      expect(find.text('Needs Focused Practice'), findsOneWidget);
    });
  });
}
