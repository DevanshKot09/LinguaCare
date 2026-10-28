import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/features/tools/visual_schedule_screen.dart';
import 'package:linguacare/features/export/summary_document.dart';
import 'package:linguacare/features/export/summary_builder.dart';
import 'package:linguacare/features/export/pdf_renderer.dart';
import 'package:linguacare/features/sharing/shared_summary_detail_screen.dart';
import 'package:linguacare/domain/sharing/sharing_models.dart';
import 'package:linguacare/domain/sharing/sharing_providers.dart';
import 'package:linguacare/domain/assessments/clinical_assessment.dart';
import 'package:linguacare/domain/assessments/assessment_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 4 Collaboration & Clinical Export Tests', () {
    testWidgets('VisualScheduleScreen renders with routine templates action', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VisualScheduleScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Visual Schedules'), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);
    });

    testWidgets('VisualScheduleScreen opens template picker and adds template', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VisualScheduleScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Templates button
      final templatesBtn = find.text('Templates');
      expect(templatesBtn, findsOneWidget);
      await tester.tap(templatesBtn);
      await tester.pumpAndSettle();

      expect(find.text('Select Routine Template'), findsOneWidget);
      expect(find.text('Morning Speech Routine'), findsOneWidget);
      expect(find.text('Speech Practice Routine'), findsOneWidget);

      // Select Speech Practice Routine
      await tester.tap(find.text('Speech Practice Routine'));
      await tester.pumpAndSettle();

      expect(find.text('Speech Practice Routine'), findsOneWidget);
    });

    test('SummaryBuilder includes clinical assessments and confirmed outcomes in summary document', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'specialist',
        scope: 'progress_notes',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [],
        clinicalAssessments: const [
          SummaryAssessmentItem(
            outcome: 'dld',
            severity: 'moderate',
            date: '2026-10-28',
            domainsAffected: ['vocabulary', 'grammar', 'narrative'],
            note: 'Shows notable expressive grammatical delay and word-finding pauses.',
          ),
        ],
      );

      expect(doc.clinicalAssessments.length, 1);
      expect(doc.clinicalAssessments.first.outcome, 'dld');
      expect(doc.clinicalAssessments.first.severity, 'moderate');
      expect(doc.clinicalAssessments.first.domainsAffected, contains('grammar'));
      expect(doc.isEmptyDataset, isFalse);
    });

    test('PdfRenderer renders document with specialist confirmed clinical outcome', () async {
      final doc = SummaryBuilder.buildSummary(
        role: 'specialist',
        scope: 'progress_notes',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [],
        clinicalAssessments: const [
          SummaryAssessmentItem(
            outcome: 'dld',
            severity: 'moderate',
            date: '2026-10-28',
            domainsAffected: ['vocabulary', 'grammar'],
            note: 'Standardized assessment percentile <10th.',
          ),
        ],
      );

      final pdfBytes = await PdfRenderer.renderSummary(doc);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });

    testWidgets('SharedSummaryDetailScreen displays assessment action button for linked client', (tester) async {
      final fakeSummary = SharedSummary(
        nickname: 'Maya',
        band: '5_11',
        scope: 'progress_notes',
        screeningSessions: [
          {'risk_level': 'some_signs', 'created_at': '2026-10-28T09:00:00Z', 'instrument_status': 'published'}
        ],
        activitySessions: const [],
        observations: const [],
        goals: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedSummaryProvider('test_link').overrideWith((ref) => fakeSummary),
            assessmentsProvider('child_123').overrideWith((ref) => [
              ClinicalAssessment(
                id: 'ass_1',
                childId: 'child_123',
                specialistUid: 'spec_1',
                assessedOn: DateTime(2026, 10, 28),
                toolsUsed: const ['CELF-5'],
                languagesAssessed: const ['English'],
                hearingStatus: 'normal',
                outcome: 'dld',
                domainsAffected: const ['grammar', 'vocabulary'],
                severity: 'moderate',
                note: 'Significant expressive grammar difficulties.',
                createdAt: DateTime(2026, 10, 28),
              ),
            ]),
          ],
          child: const MaterialApp(
            home: SharedSummaryDetailScreen(
              linkId: 'test_link',
              childName: 'Maya',
              childId: 'child_123',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Maya - Shared Summary'), findsOneWidget);
      expect(find.text('Clinical Assessments & Outcomes'), findsOneWidget);
      expect(find.text('Confirmed Developmental Language Disorder (DLD)'), findsOneWidget);
      expect(find.text('MODERATE'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
    });
  });
}
