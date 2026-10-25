// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final directories = ['lib/features', 'lib/core'];
  int totalCount = 0;
  final counts = <String, int>{};

  final regex = RegExp(r'''(?:Text\s*\(\s*['"]([^'"]+)['"]|labelText:\s*['"]([^'"]+)['"]|hintText:\s*['"]([^'"]+)['"]|label:\s*['"]([^'"]+)['"]|tooltip:\s*['"]([^'"]+)['"])''');

  for (final dirPath in directories) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = entity.readAsStringSync();
        final matches = regex.allMatches(content).toList();
        // Filter out empty or technical strings (like keys, routes, icons, etc.)
        final filtered = matches.where((m) {
          final s = m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? m.group(5) ?? '';
          if (s.isEmpty || s.startsWith('/') || s.contains('_') && !s.contains(' ')) return false;
          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          counts[entity.path] = filtered.length;
          totalCount += filtered.length;
        }
      }
    }
  }

  print('=== Hardcoded String Literals Report ===');
  counts.forEach((file, count) {
    print('$file: $count literal(s)');
  });
  print('Total hardcoded literals found: $totalCount');
}
