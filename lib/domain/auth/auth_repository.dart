import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signUpWithEmail(String email, String password);
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<AuthUser?> getCurrentUser();
  Future<void> sendOtp();
  Future<void> verifyOtp(String code);
  Future<void> setClaims();
}
