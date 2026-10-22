class InstructionSimplifier {
  static const List<String> defaultFillerWords = [
    'please',
    'kindly',
    'just',
    'actually',
    'basically',
    'you know',
    'now',
    'so',
    'well',
    'very',
  ];

  static List<String> simplify(String input, {List<String>? customFillers}) {
    if (input.trim().isEmpty) return [];
    if (input.length > 500) {
      input = input.substring(0, 500);
    }

    final fillers = customFillers ?? defaultFillerWords;

    var text = input;
    final transitions = ['and then', 'after that', 'then', 'next', 'before', ','];
    for (final t in transitions) {
      text = text.replaceAll(RegExp(r'\b' + RegExp.escape(t) + r'\b', caseSensitive: false), ' | ');
    }
    text = text.replaceAll(RegExp(r'[.!?]+'), ' | ');

    final rawSegments = text.split('|');
    final steps = <String>[];

    for (var segment in rawSegments) {
      var cleaned = segment.trim();
      if (cleaned.isEmpty) continue;

      for (final filler in fillers) {
        cleaned = cleaned.replaceAll(RegExp(r'\b' + RegExp.escape(filler) + r'\b', caseSensitive: false), '');
      }

      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.isNotEmpty) {
        cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
        if (cleaned.length > 80) {
          cleaned = cleaned.substring(0, 80).trim();
        }
        steps.add(cleaned);
      }
    }

    return steps;
  }
}
