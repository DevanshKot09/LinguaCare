class TextSanitizer {
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = input
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('—', '-')
        .replaceAll('–', '-');

    final buffer = StringBuffer();
    for (int i = 0; i < sanitized.length; i++) {
      final codeUnit = sanitized.codeUnitAt(i);
      if ((codeUnit >= 32 && codeUnit <= 126) || codeUnit == 10 || codeUnit == 13 || codeUnit == 9) {
        buffer.write(sanitized[i]);
      } else if (codeUnit >= 160 && codeUnit <= 255) {
        buffer.write(sanitized[i]);
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }
}
