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

  // Pre-compiled static regexes for default transitions, fillers, sentence boundaries, and whitespace.
  // Optimization: Pre-compiling static RegExp instances avoids regex parsing and compilation overhead
  // on every keystroke in live-typing fields (e.g. InstructionSimplifierScreen).
  static const List<String> _defaultTransitions = ['and then', 'after that', 'then', 'next', 'before', ','];

  static final List<RegExp> _compiledDefaultTransitions = _defaultTransitions
      .map((t) => RegExp(r'\b' + RegExp.escape(t) + r'\b', caseSensitive: false))
      .toList(growable: false);

  static final List<RegExp> _compiledDefaultFillers = defaultFillerWords
      .map((f) => RegExp(r'\b' + RegExp.escape(f) + r'\b', caseSensitive: false))
      .toList(growable: false);

  static final RegExp _sentenceEndRegex = RegExp(r'[.!?]+');
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  static List<String> simplify(String input, {List<String>? customFillers}) {
    if (input.trim().isEmpty) return [];
    if (input.length > 500) {
      input = input.substring(0, 500);
    }

    var text = input;

    // Use pre-compiled regexes for default transitions
    for (final reg in _compiledDefaultTransitions) {
      text = text.replaceAll(reg, ' | ');
    }
    text = text.replaceAll(_sentenceEndRegex, ' | ');

    final rawSegments = text.split('|');
    final steps = <String>[];

    // Determine filler regexes (use pre-compiled default list if customFillers is null or identical)
    final fillerRegexes = (customFillers == null)
        ? _compiledDefaultFillers
        : customFillers
            .map((f) => RegExp(r'\b' + RegExp.escape(f) + r'\b', caseSensitive: false))
            .toList(growable: false);

    for (var segment in rawSegments) {
      var cleaned = segment.trim();
      if (cleaned.isEmpty) continue;

      for (final reg in fillerRegexes) {
        cleaned = cleaned.replaceAll(reg, '');
      }

      cleaned = cleaned.replaceAll(_whitespaceRegex, ' ').trim();
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
