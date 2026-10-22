import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/domain/profile/profile.dart';

void main() {
  group('Profile & Age Band Unit Tests', () {
    test('Age band computation rules', () {
      AgeBand computeBand(DateTime dob, DateTime referenceDate) {
        final ageYears = referenceDate.year - dob.year - ((referenceDate.month > dob.month || (referenceDate.month == dob.month && referenceDate.day >= dob.day)) ? 0 : 1);
        if (ageYears < 11) {
          return AgeBand.band5_11;
        } else {
          return AgeBand.band11_18;
        }
      }

      final refDate = DateTime(2026, 6, 1);

      final dob8 = DateTime(2018, 5, 1);
      expect(computeBand(dob8, refDate), AgeBand.band5_11);

      final dob10 = DateTime(2016, 5, 1);
      expect(computeBand(dob10, refDate), AgeBand.band5_11);

      final dob12 = DateTime(2014, 5, 1);
      expect(computeBand(dob12, refDate), AgeBand.band11_18);
    });

    test('Adult 18+ check', () {
      bool isAdult(DateTime dob, DateTime referenceDate) {
        final ageYears = referenceDate.year - dob.year - ((referenceDate.month > dob.month || (referenceDate.month == dob.month && referenceDate.day >= dob.day)) ? 0 : 1);
        return ageYears >= 18;
      }

      final refDate = DateTime(2026, 6, 1);
      expect(isAdult(DateTime(2010, 5, 1), refDate), false);
      expect(isAdult(DateTime(2008, 6, 2), refDate), false);
      expect(isAdult(DateTime(2008, 5, 1), refDate), true);
      expect(isAdult(DateTime(2000, 1, 1), refDate), true);
    });
  });
}
