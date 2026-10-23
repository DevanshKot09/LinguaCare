// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final manifestFiles = [
    File('supabase/tests/required_tests.txt'),
    File('supabase/tests/required_existing.txt'),
  ];

  final Map<String, List<String>> sectionTests = {
    'rls_checks': [],
    'rls_checks_links': [],
    'rls_checks_obs_goals': [],
  };

  final Map<String, String> sectionToSqlFile = {
    'rls_checks': 'rls_checks.sql',
    'rls_checks_links': 'rls_checks_links.sql',
    'rls_checks_obs_goals': 'rls_checks_obs_goals.sql',
  };

  int totalRequired = 0;

  for (final file in manifestFiles) {
    if (!file.existsSync()) {
      print('Error: ${file.path} not found.');
      exit(1);
    }

    final lines = file.readAsLinesSync();
    String currentSection = '';
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        currentSection = trimmed.substring(1, trimmed.length - 1);
      } else if (trimmed.isNotEmpty && sectionTests.containsKey(currentSection)) {
        sectionTests[currentSection]!.add(trimmed);
        totalRequired++;
      }
    }
  }

  bool hasError = false;

  for (final entry in sectionTests.entries) {
    final sectionKey = entry.key;
    final tests = entry.value;
    final fileName = sectionToSqlFile[sectionKey]!;
    final sqlFile = File('supabase/tests/$fileName');
    if (!sqlFile.existsSync()) {
      print('Error: Test file supabase/tests/$fileName not found.');
      hasError = true;
      continue;
    }

    final sqlContent = sqlFile.readAsStringSync();
    print('Checking manifest for $fileName (${tests.length} tests)...');

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
    print('\nManifest validation PASSED: All $totalRequired required tests across both manifest files are present in test scripts.');
    exit(0);
  }
}
