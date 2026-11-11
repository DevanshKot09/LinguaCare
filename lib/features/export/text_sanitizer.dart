class TextSanitizer {
  // Pre-compiled static regex to collapse whitespace sequences.
  // Optimization: Pre-compiling static RegExp avoids repeated regex compilation and allocation
  // across every field sanitized during PDF and summary exports.
  static final RegExp _spacesRegex = RegExp(r'[ \t]+');

  /// Sanitizes text for PDF export by replacing curly quotes/dashes,
  /// stripping non-printable or unsupported characters, and collapsing whitespace.
  ///
  /// Performance optimization: Single-pass character code inspection replaces
  /// 6 chained string allocations (.replaceAll) and avoids creating intermediate strings.
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final codeUnit = input.codeUnitAt(i);
      switch (codeUnit) {
        case 0x201C: // “
        case 0x201D: // ”
          buffer.write('"');
          break;
        case 0x2018: // ‘
        case 0x2019: // ’
          buffer.write("'");
          break;
        case 0x2014: // —
        case 0x2013: // –
          buffer.write('-');
          break;
        default:
          if ((codeUnit >= 32 && codeUnit <= 126) ||
              codeUnit == 10 ||
              codeUnit == 13 ||
              codeUnit == 9) {
            buffer.writeCharCode(codeUnit);
          } else if (codeUnit >= 160 && codeUnit <= 255) {
            buffer.writeCharCode(codeUnit);
          } else {
            buffer.writeCharCode(0x20); // space
          }
      }
    }

    return buffer.toString().replaceAll(_spacesRegex, ' ').trim();
  }
}
