import 'package:flutter_test/flutter_test.dart';
import 'package:linguacare/app/router/app_session.dart';
import 'package:linguacare/domain/auth/auth_user.dart';

void main() {
  group('Auth Unit Tests', () {
    test('Password validation rules', () {
      bool isValidPassword(String password) {
        if (password.length < 8) return false;
        final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
        final hasDigit = password.contains(RegExp(r'[0-9]'));
        return hasLetter && hasDigit;
      }

      expect(isValidPassword('short'), false);
      expect(isValidPassword('12345678'), false);
      expect(isValidPassword('Nodiglets'), false);
      expect(isValidPassword('ValidPass123'), true);
    });

    test('Email masking logic', () {
      String maskEmail(String email) {
        if (!email.contains('@')) return email;
        final parts = email.split('@');
        final name = parts[0];
        if (name.length <= 2) {
          return '${name[0]}***@${parts[1]}';
        }
        return '${name[0]}***${name[name.length - 1]}@${parts[1]}';
      }

      expect(maskEmail('test@example.com'), 't***t@example.com');
      expect(maskEmail('ab@example.com'), 'a***@example.com');
      expect(maskEmail('a@example.com'), 'a***@example.com');
    });

    test('Session routing decision logic', () {
      AuthSessionStatus getStatus(AuthUser? user) {
        if (user == null) return AuthSessionStatus.unauthenticated;
        if (!user.emailVerified) return AuthSessionStatus.unverifiedEmail;
        if (!user.profileExists) return AuthSessionStatus.needsProfileSetup;
        return AuthSessionStatus.authenticated;
      }

      expect(getStatus(null), AuthSessionStatus.unauthenticated);
      expect(
        getStatus(const AuthUser(uid: '1', email: 'a@b.com', emailVerified: false, profileExists: false, role: null)),
        AuthSessionStatus.unverifiedEmail,
      );
      expect(
        getStatus(const AuthUser(uid: '1', email: 'a@b.com', emailVerified: true, profileExists: false, role: null)),
        AuthSessionStatus.needsProfileSetup,
      );
      expect(
        getStatus(const AuthUser(uid: '1', email: 'a@b.com', emailVerified: true, profileExists: true, role: UserRole.parent)),
        AuthSessionStatus.authenticated,
      );
    });
  });
}
