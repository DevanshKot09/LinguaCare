import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No Supabase auth usage in lib/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), true);

    final forbiddenPatterns = [
      'Supabase.instance.client.auth',
      '.auth.currentUser',
      'onAuthStateChange',
      'auth.signOut',
      'supabase.auth',
    ];

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = entity.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          if (content.contains(pattern)) {
            violations.add('${entity.path}: contains "$pattern"');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Found forbidden Supabase auth usage in lib/:\n${violations.join('\n')}',
    );
  });
}
