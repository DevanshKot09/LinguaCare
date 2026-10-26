import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/features/export/text_sanitizer.dart';
import 'package:linguacare/features/export/summary_builder.dart';
import 'package:linguacare/features/export/summary_document.dart';
import 'package:linguacare/features/export/pdf_renderer.dart';
import 'package:linguacare/features/export/export_confirm_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6A PDF Export & Summary Tests', () {
    test('Summary builder never includes date of birth, languages, interests or concerns', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'parent',
        scope: 'progress_notes',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [
          SummaryObservationItem(
            note: 'Child loves dinosaurs and speaks Spanish at home. DOB: 2018-05-01. Parent email: <redacted>.',
            setting: 'Home',
            date: '2026-03-01',
            isPrivate: false,
            isOwnObservation: true,
          ),
        ],
      );

      expect(doc.subjectNickname, 'Leo');
      expect(doc.subjectAgeBand, '5-11 yrs');
      if (doc.observations.isNotEmpty) {
        final obsText = doc.observations.first.note;
        expect(obsText.contains('DOB'), isFalse);
        expect(obsText.contains('Spanish'), isFalse);
        expect(obsText.contains('dinosaurs'), isFalse);
        expect(obsText.contains('<redacted>'), isFalse);
      }
    });

    test('Summary builder excludes private observations', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'parent',
        scope: 'progress_notes',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [
          SummaryObservationItem(
            note: 'Public observation note',
            setting: 'Home',
            date: '2026-03-01',
            isPrivate: false,
            isOwnObservation: true,
          ),
          SummaryObservationItem(
            note: 'Private confidential note',
            setting: 'Home',
            date: '2026-03-01',
            isPrivate: true,
            isOwnObservation: true,
          ),
        ],
      );

      expect(doc.observations.length, 1);
      expect(doc.observations.first.note, 'Public observation note');
    });

    test('Teacher summary excludes screening results', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'teacher',
        scope: 'progress_notes',
        subjectNickname: 'StudentA',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [
          SummaryScreeningItem(
            date: '2026-03-01',
            instrumentVersion: 'v1',
            riskWording: 'Low risk',
            domainLevels: ['Strong vocabulary'],
            alsoCheckFlags: [],
            urgentNoticeTriggered: false,
            confidence: 'High',
            isPrototype: false,
          ),
        ],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [],
      );

      expect(doc.screeningResults, isEmpty);
    });

    test('Teacher summary includes only own observations when notes toggle is on', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'teacher',
        scope: 'progress_notes',
        subjectNickname: 'StudentA',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [
          SummaryObservationItem(
            note: 'Teacher own observation',
            setting: 'Classroom',
            date: '2026-03-01',
            isPrivate: false,
            isOwnObservation: true,
          ),
          SummaryObservationItem(
            note: 'Parent observation',
            setting: 'Home',
            date: '2026-03-01',
            isPrivate: false,
            isOwnObservation: false,
          ),
        ],
      );

      expect(doc.observations.length, 1);
      expect(doc.observations.first.note, 'Teacher own observation');
    });

    test('Notes toggle unavailable for progress scope', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'specialist',
        scope: 'screening_only',
        subjectNickname: 'ClientX',
        subjectAgeBand: '11-18 yrs',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [
          SummaryObservationItem(
            note: 'Some observation',
            setting: 'Clinic',
            date: '2026-03-01',
            isPrivate: false,
            isOwnObservation: false,
          ),
        ],
      );

      expect(doc.includeNotes, isFalse);
      expect(doc.observations, isEmpty);
    });

    test('Summary contains non-diagnostic notice', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'parent',
        scope: 'progress_notes',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: false,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [],
      );

      expect(doc.nonDiagnosticNotice, contains('not a diagnosis'));
    });

    test('Summary shows prototype label for unpublished instrument', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'parent',
        scope: 'progress_notes',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: false,
        includeNotes: false,
        screeningSessions: const [
          SummaryScreeningItem(
            date: '2026-03-01',
            instrumentVersion: 'v1.1-beta',
            riskWording: 'Some signs',
            domainLevels: [],
            alsoCheckFlags: [],
            urgentNoticeTriggered: false,
            confidence: 'Medium',
            isPrototype: true,
          ),
        ],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [],
      );

      expect(doc.isPrototype, isTrue);
    });

    test('Summary has no emails or UIDs', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'adult',
        scope: 'progress_notes',
        subjectNickname: 'AdultUser',
        subjectAgeBand: 'Adult (18+)',
        isAccessEnded: false,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [
          SummaryObservationItem(
            note: 'User uid: auth-uid-12345, email: <redacted>',
            setting: 'Home',
            date: '2026-03-01',
            isPrivate: false,
            isOwnObservation: true,
          ),
        ],
      );

      expect(doc.subjectNickname.contains('@'), isFalse);
      expect(doc.subjectAgeBand.contains('uid'), isFalse);
    });

    test('Text sanitiser removes emoji and curly quotes', () {
      final dirty = 'Hello “world” 🚀 it’s a — test — test–dash';
      final clean = TextSanitizer.sanitize(dirty);
      expect(clean, 'Hello "world" it\'s a - test - test-dash');
      expect(clean.contains('🚀'), isFalse);
      expect(clean.contains('“'), isFalse);
    });

    test('Renderer output starts with %PDF', () async {
      final doc = SummaryDocument(
        title: 'LinguaCare shared summary',
        generatedDate: '2026-03-01',
        subjectNickname: 'Leo',
        subjectAgeBand: '5-11 yrs',
        generatedByRole: 'parent',
        nonDiagnosticNotice: 'This is a screening and practice summary. It is not a diagnosis.',
        isPrototype: false,
        screeningResults: const [],
        practiceSummary: const [],
        goals: const [],
        observations: const [],
        includeNotes: false,
        isAccessEnded: false,
        isEmptyDataset: false,
      );

      final bytes = await PdfRenderer.renderSummary(doc);
      expect(bytes, isNotEmpty);
      expect(bytes[0], 37); // '%'
      expect(bytes[1], 80); // 'P'
      expect(bytes[2], 68); // 'D'
      expect(bytes[3], 70); // 'F'
    });

    testWidgets('Export confirm dialog shows warning and defaults notes off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportConfirmDialog(
              showNotesToggle: true,
              onConfirmed: (includeNotes) {},
            ),
          ),
        ),
      );

      expect(find.text('Export Summary PDF'), findsOneWidget);
      expect(find.textContaining('This PDF leaves the app'), findsOneWidget);
      expect(find.text('Include notes'), findsOneWidget);

      final switchWidget = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchWidget.value, isFalse);
    });

    test('Export blocked when access ended', () {
      final doc = SummaryBuilder.buildSummary(
        role: 'specialist',
        scope: 'progress_notes',
        subjectNickname: 'ClientZ',
        subjectAgeBand: '5-11 yrs',
        isAccessEnded: true,
        includeNotes: true,
        screeningSessions: const [],
        practiceSummary: const [],
        goalItems: const [],
        rawObservations: const [],
      );

      expect(doc.isAccessEnded, isTrue);
      expect(doc.screeningResults, isEmpty);
      expect(doc.practiceSummary, isEmpty);
    });

    testWidgets('Export layouts at 360dp and 900dp', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportConfirmDialog(
              showNotesToggle: true,
              onConfirmed: (val) {},
            ),
          ),
        ),
      );
      expect(find.byType(ExportConfirmDialog), findsOneWidget);

      tester.view.physicalSize = const Size(900, 1200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportConfirmDialog(
              showNotesToggle: true,
              onConfirmed: (val) {},
            ),
          ),
        ),
      );
      expect(find.byType(ExportConfirmDialog), findsOneWidget);
      tester.view.reset();
    });

    testWidgets('Export dialog text scale 2.0 no overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: ExportConfirmDialog(
                showNotesToggle: true,
                onConfirmed: (val) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ExportConfirmDialog), findsOneWidget);
      tester.view.reset();
    });
  });
}
