import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_session.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_user.dart' as domain;
import '../clients/edge_functions_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    fb.FirebaseAuth.instance,
    GoogleSignIn.instance,
    Supabase.instance.client,
    ref.read(edgeFunctionsClientProvider),
  );
});

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabase;
  final EdgeFunctionsClient _edgeClient;
  bool _googleInitialized = false;

  FirebaseAuthRepository(
    this._firebaseAuth,
    this._googleSignIn,
    this._supabase,
    this._edgeClient,
  );

  @override
  Stream<domain.AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return await _buildAuthUser(fbUser);
    });
  }

  Future<domain.AuthUser> _buildAuthUser(fb.User fbUser) async {
    bool emailVerified = fbUser.emailVerified;
    bool profileExists = false;
    UserRole? role;

    try {
      final evRes = await _supabase
          .from('email_verifications')
          .select('uid')
          .eq('uid', fbUser.uid)
          .maybeSingle();
      if (evRes != null) {
        emailVerified = true;
      }
    } catch (_) {}

    if (emailVerified) {
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('role')
            .eq('uid', fbUser.uid)
            .maybeSingle();
        if (profileRes != null) {
          profileExists = true;
          final roleStr = profileRes['role'] as String?;
          role = switch (roleStr) {
            'parent' => UserRole.parent,
            'teacher' => UserRole.teacher,
            'adult' => UserRole.adult,
            'specialist' => UserRole.specialist,
            'admin' => UserRole.specialist,
            _ => null,
          };
        }
      } catch (_) {}
    }

    return domain.AuthUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      emailVerified: emailVerified,
      profileExists: profileExists,
      role: role,
    );
  }

  @override
  Future<domain.AuthUser> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const UnexpectedAuthFailure();

      await setClaims();
      await user.getIdToken(true);
      await sendOtp();

      return await _buildAuthUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<domain.AuthUser> signInWithEmail(String email, String password) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const UnexpectedAuthFailure();

      await setClaims();
      await user.getIdToken(true);

      return await _buildAuthUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<domain.AuthUser> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        try {
          await _googleSignIn.initialize();
        } catch (_) {}
        _googleInitialized = true;
      }

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final cred = await _firebaseAuth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) throw const UnexpectedAuthFailure();

      await setClaims();
      await user.getIdToken(true);

      return await _buildAuthUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') || errStr.contains('aborted') || errStr.contains('sign_in_canceled')) {
        throw const CancelledAuthFailure('Sign-in cancelled.');
      }
      if (errStr.contains('client_configuration') || errStr.contains('configuration') || errStr.contains('sign_in_failed') || errStr.contains('developer_error') || errStr.contains('10:')) {
        if (kDebugMode) {
          debugPrint('check SHA fingerprints, package name and web OAuth client');
        }
        throw const UnexpectedAuthFailure('Google sign-in is not available in this build');
      }
      if (errStr.contains('socketexception') || errStr.contains('timeout') || errStr.contains('network')) {
        throw const NetworkFailure();
      }
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<domain.AuthUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _buildAuthUser(user);
  }

  @override
  Future<void> sendOtp() async {
    await _edgeClient.sendOtp();
  }

  @override
  Future<void> verifyOtp(String code) async {
    try {
      await _edgeClient.verifyOtp(code);
    } catch (e) {
      // If verification failed on edge function, check if user is already verified in db
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final evRes = await _supabase
            .from('email_verifications')
            .select('uid')
            .eq('uid', user.uid)
            .maybeSingle();
        if (evRes != null) {
          // Already verified, ignore error and continue
          await user.reload();
          await user.getIdToken(true);
          return;
        }
      }
      rethrow;
    }
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      await user.getIdToken(true);
    }
  }

  @override
  Future<void> setClaims() async {
    await _edgeClient.setClaims();
  }

  AuthFailure _mapFirebaseException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'user-disabled':
        return const UserDisabledFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return UnexpectedAuthFailure(e.message ?? 'Authentication failed.');
    }
  }
}
