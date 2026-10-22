import '../../app/router/app_session.dart';

class AuthUser {
  final String uid;
  final String email;
  final bool emailVerified;
  final bool profileExists;
  final UserRole? role;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.profileExists,
    required this.role,
  });

  AuthUser copyWith({
    bool? emailVerified,
    bool? profileExists,
    UserRole? role,
  }) {
    return AuthUser(
      uid: uid,
      email: email,
      emailVerified: emailVerified ?? this.emailVerified,
      profileExists: profileExists ?? this.profileExists,
      role: role ?? this.role,
    );
  }
}
