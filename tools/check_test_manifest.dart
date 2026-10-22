// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final requiredFile = File('supabase/tests/required_tests.txt');
  if (!requiredFile.existsSync()) {
    print('Error: required_tests.txt not found.');
    exit(1);
  }

  final lines = requiredFile.readAsLinesSync();
  String currentSection = '';
  final Map<String, List<String>> sectionTests = {
    'rls_checks.sql': [],
    'rls_checks_links.sql': [],
    'rls_checks_obs_goals.sql': [],
  };

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      currentSection = trimmed.substring(1, trimmed.length - 1);
    } else if (trimmed.isNotEmpty && sectionTests.containsKey(currentSection)) {
      sectionTests[currentSection]!.add(trimmed);
    }
  }

  bool hasError = false;

  for (final entry in sectionTests.entries) {
    final fileName = entry.key;
    final tests = entry.value;
    final sqlFile = File('supabase/tests/$fileName');
    if (!sqlFile.existsSync()) {
      print('Error: Test file supabase/tests/$fileName not found.');
      hasError = true;
      continue;
    }

    final sqlContent = sqlFile.readAsStringSync();
    print('Checking manifest for $fileName (${tests.length} required tests)...');

    for (final testName in tests) {
      if (!sqlContent.contains(testName)) {
        print('  [MISSING] Required test "$testName" not found in $fileName');
        hasError = true;
      } else {
        print('  [OK] Found "$testName"');
      }
    }
  }

  if (hasError) {
    print('\nManifest validation FAILED: Some required tests are missing from test scripts.');
    exit(1);
  } else {
    print('\nManifest validation PASSED: All required tests are present in test scripts.');
    exit(0);
  }
}
