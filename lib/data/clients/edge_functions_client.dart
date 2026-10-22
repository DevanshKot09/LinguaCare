import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/auth/auth_failure.dart';

final edgeFunctionsClientProvider = Provider<EdgeFunctionsClient>((ref) {
  return EdgeFunctionsClient(Supabase.instance.client);
});

class EdgeFunctionsClient {
  final SupabaseClient _supabase;

  EdgeFunctionsClient(this._supabase);

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<void> setClaims() async {
    final token = await _getToken();
    if (token == null) throw const UnexpectedAuthFailure('Not authenticated');

    try {
      await _supabase.functions.invoke(
        'set-claims',
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      _handleFunctionError(e);
    }
  }

  Future<void> sendOtp() async {
    final token = await _getToken();
    if (token == null) throw const UnexpectedAuthFailure('Not authenticated');

    try {
      await _supabase.functions.invoke(
        'send-otp',
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      _handleFunctionError(e);
    }
  }

  Future<void> verifyOtp(String code) async {
    final token = await _getToken();
    if (token == null) throw const UnexpectedAuthFailure('Not authenticated');

    try {
      await _supabase.functions.invoke(
        'verify-otp',
        headers: {'Authorization': 'Bearer $token'},
        body: {'code': code},
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      _handleFunctionError(e);
    }
  }

  Future<void> deleteAccount() async {
    final token = await _getToken();
    if (token == null) throw const UnexpectedAuthFailure('Not authenticated');

    try {
      await _supabase.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      _handleFunctionError(e);
    }
  }

  void _handleFunctionError(dynamic e) {
    if (kDebugMode) {
      debugPrint('[EdgeFunctions] error: $e');
    }
    try {
      final details = (e as dynamic).details;
      if (details != null) {
        throw _mapError(details);
      }
    } catch (authEx) {
      if (authEx is AuthFailure) {
        rethrow;
      }
    }

    final errStr = e.toString();
    if (errStr.contains('CONFIG_ERROR')) {
      throw const UnexpectedAuthFailure('Server configuration error (Ensure SMTP port 465 is used in Supabase secrets).');
    } else if (errStr.contains('EMAIL_SEND_ERROR')) {
      throw const UnexpectedAuthFailure('Failed to send verification email. Please check SMTP credentials.');
    } else if (errStr.contains('INVALID_OR_EXPIRED') || errStr.contains('INVALID_CODE')) {
      throw const InvalidOtpFailure('Invalid or expired verification code.');
    } else if (errStr.contains('COOLDOWN_ACTIVE')) {
      throw const OtpCooldownFailure('Please wait 60 seconds before requesting another code.');
    } else if (errStr.contains('RATE_LIMIT_EXCEEDED')) {
      throw const OtpRateLimitFailure('Maximum OTP requests reached. Please try again later.');
    } else if (errStr.contains('MAX_ATTEMPTS')) {
      throw const MaxOtpAttemptsFailure('Maximum verification attempts exceeded. Please request a new code.');
    }

    if (errStr.contains('message:')) {
      try {
        final parts = errStr.split('message:');
        if (parts.length > 1) {
          final cleanMsg = parts[1].split('}').first.trim().replaceAll("'", '').replaceAll('"', '');
          throw UnexpectedAuthFailure(cleanMsg);
        }
      } catch (_) {}
    }

    throw const NetworkFailure('Network connection error or Edge Function unreachable.');
  }

  AuthFailure _mapError(dynamic data) {
    String code = 'UNKNOWN';
    String message = 'An error occurred';
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        code = err['code'] ?? 'UNKNOWN';
        message = err['message'] ?? 'An error occurred';
      } else if (data['message'] != null) {
        message = data['message'];
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (code) {
      case 'UNAUTHORIZED':
        return UnexpectedAuthFailure(message);
      case 'COOLDOWN_ACTIVE':
        return OtpCooldownFailure(message);
      case 'RATE_LIMIT_EXCEEDED':
        return OtpRateLimitFailure(message);
      case 'INVALID_CODE':
      case 'INVALID_OR_EXPIRED':
        return InvalidOtpFailure(message);
      case 'MAX_ATTEMPTS':
        return MaxOtpAttemptsFailure(message);
      case 'EMAIL_SEND_ERROR':
        return UnexpectedAuthFailure('Failed to send verification email. Please try again: $message');
      default:
        return UnexpectedAuthFailure(message);
    }
  }
}
