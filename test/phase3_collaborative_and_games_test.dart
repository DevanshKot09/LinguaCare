import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/features/activities/cartoon_memory_game_screen.dart';
import 'package:linguacare/features/activities/animal_spotter_game_screen.dart';
import 'package:linguacare/features/activities/sentence_reconstruction_screen.dart';
import 'package:linguacare/features/tools/tools_hub_screen.dart';
import 'package:linguacare/features/tools/communication_card_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3 - Interactive Child Games & Tools Hub Tests', () {
    testWidgets('CartoonMemoryGameScreen renders cards and stats', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartoonMemoryGameScreen(
            childNickname: 'Leo',
            childId: 'child_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Leo's Memory Match"), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('TAP ME'), findsWidgets);
    });

    testWidgets('AnimalSpotterGameScreen renders listening prompts and choices', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimalSpotterGameScreen(
            childNickname: 'Pip',
            childId: 'child_456',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Pip's Animal Spotter"), findsOneWidget);
      expect(find.text('Round 1 of 5'), findsOneWidget);
      expect(find.text('Who has a yellow fluffy mane and loves to ROAR?'), findsOneWidget);
      expect(find.text('Lion'), findsOneWidget);
    });

    testWidgets('SentenceReconstructionScreen renders word tiles and challenge prompt', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SentenceReconstructionScreen(
            studentName: 'Maya',
            childId: 'child_789',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Maya's Challenge"), findsOneWidget);
      expect(find.text('Challenge 1 of 3'), findsOneWidget);
      expect(find.text('Build a complex sentence showing contrast:'), findsOneWidget);
      expect(find.text('Available Word Tiles:'), findsOneWidget);
      expect(find.text('Check Sentence'), findsOneWidget);
    });

    testWidgets('ToolsHubScreen renders core support tool cards with tactile styling', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ToolsHubScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LinguaCare Tools Hub'), findsOneWidget);
      expect(find.text('Visual Schedule Builder'), findsOneWidget);
      expect(find.text('Instruction Simplifier'), findsOneWidget);
      expect(find.text('Communication Card'), findsOneWidget);
    });

    testWidgets('CommunicationCardScreen renders preset needs and copy action', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommunicationCardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Communication Cards'), findsOneWidget);
      expect(find.text('My Needs'), findsOneWidget);
      expect(find.text('Full Screen'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
    });
  });
}
