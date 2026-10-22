import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/main.dart';

void main() {
  group('Supabase URL Validation Tests', () {
    test('Valid Supabase URL passes', () {
      expect(isValidSupabaseUrl('https://abcdefghijklmnopqrst.supabase.co'), isTrue);
    });

    test('URL with path fails', () {
      expect(isValidSupabaseUrl('https://abcdefghijklmnopqrst.supabase.co/rest/v1'), isFalse);
    });

    test('URL with trailing slash fails path check', () {
      expect(isValidSupabaseUrl('https://abcdefghijklmnopqrst.supabase.co/'), isFalse);
    });

    test('Malformed host fails', () {
      expect(isValidSupabaseUrl('https://invalid.supabase.co'), isFalse);
    });

    test('Empty URL fails', () {
      expect(isValidSupabaseUrl(''), isFalse);
    });
  });
}
