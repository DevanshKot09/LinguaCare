import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_session.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/profile/profile.dart';
import '../../domain/profile/profile_repository.dart';
import '../clients/edge_functions_client.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(
    Supabase.instance.client,
    ref.read(edgeFunctionsClientProvider),
  );
});

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _supabase;
  final EdgeFunctionsClient _edgeClient;

  SupabaseProfileRepository(this._supabase, this._edgeClient);

  @override
  Future<Profile?> getProfile(String uid) async {
    try {
      final profileRes = await _supabase
          .from('profiles')
          .select('*, specialist_details(*), teacher_details(*)')
          .eq('uid', uid)
          .maybeSingle();

      if (profileRes == null) return null;

      final roleStr = profileRes['role'] as String?;
      final role = switch (roleStr) {
        'parent' => UserRole.parent,
        'teacher' => UserRole.teacher,
        'adult' => UserRole.adult,
        'specialist' => UserRole.specialist,
        'admin' => UserRole.admin,
        _ => UserRole.parent,
      };

      List<Child> children = [];
      if (role == UserRole.parent) {
        final childrenRes = await _supabase
            .from('children')
            .select('*')
            .eq('parent_uid', uid);
        children = (childrenRes as List).map((c) => Child.fromJson(c)).toList();
      }

      Map<String, dynamic>? roleDetails;
      if (role == UserRole.specialist) {
        roleDetails = profileRes['specialist_details'];
      } else if (role == UserRole.teacher) {
        roleDetails = profileRes['teacher_details'];
      }

      return Profile(
        uid: profileRes['uid'] as String,
        role: role,
        fullName: profileRes['full_name'] as String,
        email: profileRes['email'] as String,
        emailVerified: profileRes['email_verified'] as bool? ?? false,
        country: profileRes['country'] as String?,
        language: profileRes['language'] as String? ?? 'en',
        verified: profileRes['verified'] as bool? ?? false,
        roleDetails: roleDetails,
        children: children,
      );
    } catch (e) {
      throw UnexpectedAuthFailure('Failed to load profile: $e');
    }
  }

  @override
  Future<void> completeProfile({
    required UserRole role,
    required String fullName,
    required String country,
    required String language,
    Map<String, dynamic> roleDetails = const {},
    Map<String, dynamic>? initialChild,
    List<Map<String, dynamic>> consents = const [],
  }) async {
    try {
      final roleName = switch (role) {
        UserRole.parent => 'parent',
        UserRole.teacher => 'teacher',
        UserRole.adult => 'adult',
        UserRole.specialist => 'specialist',
        UserRole.admin => 'admin',
      };

      await _supabase.rpc('complete_profile', params: {
        'p_role': roleName,
        'p_name': fullName,
        'p_country': country,
        'p_language': language,
        'p_role_details': roleDetails,
        'p_initial_child': initialChild,
        'p_consents': consents,
      });
    } catch (e) {
      if (e is PostgrestException && e.message.contains('Email verification required')) {
        try {
          // Attempt OAuth verification sync and retry
          await _edgeClient.verifyOtp('GOOGLE_OAUTH');
          final roleName = switch (role) {
            UserRole.parent => 'parent',
            UserRole.teacher => 'teacher',
            UserRole.adult => 'adult',
            UserRole.specialist => 'specialist',
            UserRole.admin => 'admin',
          };
          await _supabase.rpc('complete_profile', params: {
            'p_role': roleName,
            'p_name': fullName,
            'p_country': country,
            'p_language': language,
            'p_role_details': roleDetails,
            'p_initial_child': initialChild,
            'p_consents': consents,
          });
          return;
        } catch (_) {}
      }
      if (e is PostgrestException) {
        throw UnexpectedAuthFailure(e.message);
      }
      throw UnexpectedAuthFailure('Failed to complete profile: $e');
    }
  }

  @override
  Future<String> addChild({
    required String nickname,
    required DateTime dob,
    List<String> homeLanguages = const [],
    List<String> interests = const [],
    List<String> concerns = const [],
    List<Map<String, dynamic>> consents = const [],
  }) async {
    try {
      final res = await _supabase.rpc('add_child', params: {
        'p_nickname': nickname,
        'p_dob': dob.toIso8601String().split('T')[0],
        'p_home_languages': homeLanguages,
        'p_interests': interests,
        'p_concerns': concerns,
        'p_consents': consents,
      });
      return res.toString();
    } catch (e) {
      if (e is PostgrestException) {
        throw UnexpectedAuthFailure(e.message);
      }
      throw UnexpectedAuthFailure('Failed to add child: $e');
    }
  }

  @override
  Future<void> deleteChild(String childId) async {
    try {
      await _supabase.from('children').delete().eq('id', childId);
    } catch (e) {
      throw UnexpectedAuthFailure('Failed to delete child: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _edgeClient.deleteAccount();
  }
}
