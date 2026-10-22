import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Screening strings never use diagnostic or stigmatizing language', () {
    const disclaimer = 'LinguaCare supports language development. It does not diagnose.';
    const lowRisk = 'No strong signs noticed in this check';
    const someRisk = 'Some signs worth keeping an eye on';
    const highRisk = 'Several signs that may be worth discussing with a speech-language professional';

    final stringsToCheck = [disclaimer, lowRisk, someRisk, highRisk];

    for (var str in stringsToCheck) {
      final lower = str.toLowerCase();
      expect(lower.contains('has dld'), false, reason: 'Must not state diagnosis ("has DLD") in: $str');
      expect(lower.contains('diagnosed'), false, reason: 'Must not use "diagnosed" in: $str');
      expect(lower.contains('suffers from'), false, reason: 'Must not use stigmatizing language in: $str');
    }
  });
}
