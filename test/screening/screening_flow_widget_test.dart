import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linguacare/domain/screening/instrument.dart';
import 'package:linguacare/domain/screening/screening_providers.dart';
import 'package:linguacare/domain/screening/screening_repository.dart';
import 'package:linguacare/domain/screening/screening_result.dart';
import 'package:linguacare/features/screening/screening_intro_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';

class FakeScreeningRepository implements ScreeningRepository {
  @override
  Future<Instrument> loadInstrument(String instrumentId) async {
    return Instrument(
      id: instrumentId,
      version: '1.0.0',
      status: 'draft',
      audience: 'parent',
      ageBand: '5_11',
      estimatedMinutes: 5,
      introText: 'Intro text',
      domains: [DomainConfig(id: 'vocabulary', name: 'Vocabulary')],
      items: [
        Item(id: 'p1', text: 'Sample statement 1', domain: 'vocabulary', scaleType: 'frequency', direction: true, alsoCheck: [], urgent: false),
      ],
      scoring: ScoringConfig(
        minAnsweredPerDomain: 1,
        domainLevels: {},
        riskRules: RiskRules(highThresholdCount: 2, someThresholdCount: 1),
        confidenceThresholds: ConfidenceThresholds(high: 0.9, medium: 0.7),
      ),
      wording: {},
    );
  }

  @override
  Future<void> saveScreeningResult(ScreeningResult result) async {}

  @override
  Future<List<ScreeningResult>> getScreeningHistoryForChild(String childId) async => [];

  @override
  Future<List<ScreeningResult>> getScreeningHistoryForSelf(String subjectUid) async => [];

  @override
  Future<void> deleteScreeningResult(String sessionId) async {}

  @override
  Future<void> saveDraftAnswers(String instrumentId, Map<String, int?> answers) async {}

  @override
  Future<Map<String, int?>> loadDraftAnswers(String instrumentId) async => {};

  @override
  Future<void> clearDraftAnswers(String instrumentId) async {}
}

void main() {
  testWidgets('Screening Intro Screen renders correctly at 360dp, 900dp, and text scale 2.0', (WidgetTester tester) async {
    // 360dp compact layout test
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screeningRepositoryProvider.overrideWithValue(FakeScreeningRepository()),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ScreeningIntroScreen(instrumentId: 'parent_5_11', childId: 'c1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Language Check Overview'), findsOneWidget);
    expect(find.text('Start Check'), findsOneWidget);

    // 900dp expanded layout test
    tester.view.physicalSize = const Size(900, 1200);
    await tester.pumpAndSettle();
    expect(find.text('Language Check Overview'), findsOneWidget);
  });
}
