import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/features/tools/instruction_simplifier.dart';
import 'package:linguacare/features/tools/instruction_simplifier_screen.dart';
import 'package:linguacare/features/tools/adult_journal_screen.dart';
import 'package:linguacare/features/tools/communication_card_screen.dart';
import 'package:linguacare/features/adult/adult_home_screen.dart';
import 'package:linguacare/l10n/app_localizations.dart';
import 'package:linguacare/core/local_store/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 5 Adult Self-Advocacy & Everyday Tools Tests', () {
    test('InstructionSimplifier cleanly chunks multi-step text and removes filler words', () {
      const input =
          'Please kindly check the draft report before noon, and then email it to the team lead.';
      final steps = InstructionSimplifier.simplify(input);

      expect(steps.length, greaterThanOrEqualTo(2));
      expect(steps.any((s) => s.toLowerCase().contains('check the draft report')), isTrue);
      expect(steps.any((s) => s.toLowerCase().contains('email it to the team lead')), isTrue);
      // Filler words removed
      expect(steps.every((s) => !s.toLowerCase().startsWith('please')), isTrue);
      expect(steps.every((s) => !s.toLowerCase().startsWith('kindly')), isTrue);
    });

    testWidgets('InstructionSimplifierScreen displays preset chips and opens step-by-step focus',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: InstructionSimplifierScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Instruction Simplifier'), findsOneWidget);
      expect(find.text('Workplace Task'), findsOneWidget);
      expect(find.text("Doctor's Advice"), findsOneWidget);
      expect(find.text('Official Procedure'), findsOneWidget);

      // Tap Workplace Task preset
      await tester.tap(find.text('Workplace Task'));
      await tester.pumpAndSettle();

      // Check simplified steps appeared
      expect(find.text('Side-by-Side Comparison'), findsOneWidget);

      final focusBtn = find.text('Step-by-Step Focus');
      expect(focusBtn, findsOneWidget);

      // Open Step-by-Step Focus View
      await tester.tap(focusBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(find.text('Mark this step done'), findsOneWidget);

      // Mark step done
      await tester.tap(find.text('Mark this step done'));
      await tester.pumpAndSettle();
      expect(find.text('Marked as Done'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('AdultJournalScreen filters entries by situation tag', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pre-populate via LocalStore with user 'guest'
      final store = LocalStore('guest');
      final sampleEntries = [
        {
          'id': 'j1',
          'dateIso': DateTime.now().toIso8601String(),
          'mood': 'great',
          'situationTags': ['at work or school'],
          'note': 'Work meeting was clear and well paced.',
        },
        {
          'id': 'j2',
          'dateIso': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'mood': 'low',
          'situationTags': ['on the phone'],
          'note': 'Phone call was too fast.',
        },
      ];
      await store.writeList('adult_journal_entries', sampleEntries);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionStateProvider.overrideWith((ref) => const AppSessionState(
                  status: AuthSessionStatus.unauthenticated,
                  user: null,
                  profile: null,
                  isFirstLaunch: false,
                  onboardingDone: true,
                )),
          ],
          child: const MaterialApp(
            home: AdultJournalScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Adult Wellbeing Journal'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('Work meeting was clear and well paced.'), findsOneWidget);
      expect(find.text('Phone call was too fast.'), findsOneWidget);

      // Filter by 'at work or school'
      await tester.tap(find.widgetWithText(FilterChip, 'at work or school'));
      await tester.pumpAndSettle();

      expect(find.text('1 entry'), findsOneWidget);
      expect(find.text('Work meeting was clear and well paced.'), findsOneWidget);
      expect(find.text('Phone call was too fast.'), findsNothing);

      // Switch back to 'All'
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();
      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('Phone call was too fast.'), findsOneWidget);
    });

    testWidgets('CommunicationCardScreen opens template picker and adds workplace accommodation card',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionStateProvider.overrideWith((ref) => const AppSessionState(
                  status: AuthSessionStatus.unauthenticated,
                  user: null,
                  profile: null,
                  isFirstLaunch: false,
                  onboardingDone: true,
                )),
          ],
          child: const MaterialApp(
            home: CommunicationCardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Communication Cards'), findsOneWidget);

      // Tap Add Card icon in AppBar
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Choose Card Template'), findsOneWidget);
      expect(find.text('Workplace Accommodation'), findsOneWidget);
      expect(find.text('Healthcare & Medical Visit'), findsOneWidget);
      expect(find.text('Everyday Conversation'), findsOneWidget);

      // Select Workplace Accommodation
      await tester.tap(find.text('Workplace Accommodation'));
      await tester.pumpAndSettle();

      expect(find.text('Workplace Accommodations'), findsOneWidget);
      expect(find.text('Thank you for supporting clear communication at work.'), findsOneWidget);
    });

    testWidgets('AdultHomeScreen renders quick actions and opens journal from reflection card',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionStateProvider.overrideWith((ref) => const AppSessionState(
                  status: AuthSessionStatus.authenticated,
                  user: null,
                  profile: null,
                  isFirstLaunch: false,
                  onboardingDone: true,
                )),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdultHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions & Tools'), findsOneWidget);
      expect(find.text('Tools Hub'), findsOneWidget);
      expect(find.text('Comm Card'), findsOneWidget);
      expect(find.text('Simplifier'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Practise'), findsOneWidget);
      expect(find.text('Daily Self-Advocacy Check-In'), findsOneWidget);

      // Tap Open Journal button
      await tester.tap(find.text('Open Journal'));
      await tester.pumpAndSettle();

      // Should switch to AdultJournalScreen
      expect(find.text('Adult Wellbeing Journal'), findsOneWidget);
    });

    test('LocalStore guarantees private on-device data persistence', () async {
      final store = LocalStore('test_user_phase5');
      await store.writeList('adult_journal_entries', [
        {'id': 'entry_1', 'mood': 'good', 'note': 'Private reflection'},
      ]);

      final loaded = await store.readList('adult_journal_entries', []);
      expect(loaded.length, 1);
      expect(loaded.first['note'], 'Private reflection');

      // Ensure isolation between different users
      final otherStore = LocalStore('other_user');
      final otherLoaded = await otherStore.readList('adult_journal_entries', []);
      expect(otherLoaded, isEmpty);
    });
  });
}
