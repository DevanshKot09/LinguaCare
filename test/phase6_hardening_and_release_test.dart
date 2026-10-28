import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/theme/app_theme.dart';
import 'package:linguacare/core/responsive/responsive_scaffold.dart';
import 'package:linguacare/core/local_store/local_store.dart';
import 'package:linguacare/features/settings/about_screen.dart';
import 'package:linguacare/features/settings/privacy_policy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 6 Hardening, Accessibility & Release Readiness Tests', () {
    test('Accessibility: AppTheme enforces 48dp minimum touch target height on all buttons', () {
      final BuildContext mockContext = _MockContext();
      final light = AppTheme.lightTheme(mockContext);
      final dark = AppTheme.darkTheme(mockContext);

      // Elevated buttons
      expect(
        light.elevatedButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(48.0),
      );
      expect(
        dark.elevatedButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(48.0),
      );

      // Outlined buttons
      expect(
        light.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(48.0),
      );
      expect(
        dark.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(48.0),
      );
    });

    testWidgets('Accessibility & Dynamic Type: AboutScreen renders without overflow at 2.0x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const AboutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About LinguaCare'), findsOneWidget);
      expect(find.text('LinguaCare DLD Support App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Accessibility & Dynamic Type: PrivacyPolicyScreen renders without overflow at 2.0x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy and Your Data'), findsOneWidget);
      expect(find.text('DPDP Act 2023 Compliance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Device Matrix: ResponsiveScaffold uses NavigationBar on compact and NavigationRail on medium/expanded',
        (tester) async {
      const items = [
        ResponsiveScaffoldItem(label: 'Home', icon: Icons.home),
        ResponsiveScaffoldItem(label: 'Practise', icon: Icons.sports_esports),
      ];

      // 1. Compact screen (width = 360)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            title: 'Test',
            currentIndex: 0,
            onDestinationSelected: (_) {},
            items: items,
            body: const Text('Body Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // 2. Medium screen (width = 720, e.g. Foldable or Tablet portrait)
      tester.view.physicalSize = const Size(720, 1000);
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            title: 'Test',
            currentIndex: 0,
            onDestinationSelected: (_) {},
            items: items,
            body: const Text('Body Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    test('Security & DPDP Act: LocalStore strictly namespaces keys and supports clearAllForUser', () async {
      final userAStore = LocalStore('user_alpha');
      final userBStore = LocalStore('user_beta');

      await userAStore.writeJson('profile_meta', {'role': 'adult'});
      await userBStore.writeJson('profile_meta', {'role': 'parent'});

      final dataA = await userAStore.readJson('profile_meta', {});
      final dataB = await userBStore.readJson('profile_meta', {});

      expect(dataA['role'], 'adult');
      expect(dataB['role'], 'parent');

      // Clear user A without affecting user B
      await userAStore.clearAllForUser();

      final dataACleared = await userAStore.readJson('profile_meta', {});
      final dataBRetained = await userBStore.readJson('profile_meta', {});

      expect(dataACleared, isEmpty);
      expect(dataBRetained['role'], 'parent');
    });

    test('Clinical Screening Assets: All 4 clinical instruments are valid and published', () {
      final instruments = ['adult.json', 'parent_5_11.json', 'parent_11_18.json', 'teacher_5_11.json'];

      for (final name in instruments) {
        final file = File('assets/screening/v1/$name');
        expect(file.existsSync(), isTrue, reason: 'Missing $name');

        final content = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(content['id'], isNotNull);
        expect(content['status'], 'published');
        expect(content['age_band'], isNotNull);
        expect(content['domains'], isList);
        expect(content['items'], isList);
        expect((content['items'] as List), isNotEmpty);
      }
    });

    test('Activity Engine Assets: All 15 activity bundles are valid and marked published', () {
      final dir = Directory('assets/activities/v1');
      expect(dir.existsSync(), isTrue);

      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files.length, 15, reason: 'Expected 15 published activity bundles');

      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect(data['id'], isNotNull, reason: 'Missing id in ${f.path}');
        expect(data['title'], isNotNull, reason: 'Missing title in ${f.path}');
        expect(data['status'], 'published', reason: 'Activity ${data['id']} is not published');
        expect(data['steps'], isList, reason: 'Missing steps list in ${f.path}');
        expect((data['steps'] as List), isNotEmpty, reason: 'Empty steps in ${f.path}');
      }
    });
  });
}

class _MockContext extends Fake implements BuildContext {}
