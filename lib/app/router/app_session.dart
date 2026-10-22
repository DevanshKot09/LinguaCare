import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/auth/auth_user.dart' as domain;
import '../../domain/profile/profile.dart';

enum UserRole { parent, teacher, adult, specialist }

enum AuthSessionStatus {
  loading,
  unauthenticated,
  unverifiedEmail,
  needsProfileSetup,
  authenticated,
  error,
}

class AppSessionState {
  final AuthSessionStatus status;
  final domain.AuthUser? user;
  final Profile? profile;
  final bool isFirstLaunch;
  final bool onboardingDone;
  final String? errorType;

  const AppSessionState({
    required this.status,
    required this.user,
    required this.profile,
    required this.isFirstLaunch,
    required this.onboardingDone,
    this.errorType,
  });

  bool get isSignedIn => status != AuthSessionStatus.unauthenticated && status != AuthSessionStatus.loading && status != AuthSessionStatus.error;
  bool get hasProfile => status == AuthSessionStatus.authenticated;
  UserRole? get role => profile?.role ?? user?.role;
  bool get isSpecialistVerified => profile?.verified ?? false;
  int get childCount => profile?.children.length ?? 0;

  AppSessionState copyWith({
    AuthSessionStatus? status,
    domain.AuthUser? user,
    Profile? profile,
    bool? isFirstLaunch,
    bool? onboardingDone,
    String? errorType,
  }) {
    return AppSessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      errorType: errorType ?? this.errorType,
    );
  }
}

class AppSessionNotifier extends ValueNotifier<AppSessionState> {
  final dynamic _ref;
  bool _disposed = false;

  AppSessionNotifier(this._ref, {bool autoInit = true})
      : super(const AppSessionState(
          status: AuthSessionStatus.loading,
          user: null,
          profile: null,
          isFirstLaunch: true,
          onboardingDone: false,
        )) {
    if (kDebugMode) {
      debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] constructor called');
    }
    if (autoInit) {
      _init();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> retry() async {
    if (_disposed) return;
    value = value.copyWith(status: AuthSessionStatus.loading, errorType: null);
    await _init();
  }

  Future<void> _init() async {
    final sw = Stopwatch()..start();
    if (kDebugMode) {
      debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] _init started at 0 ms');
    }
    final timeoutDuration = Platform.environment.containsKey('FLUTTER_TEST')
        ? const Duration(seconds: 8)
        : const Duration(seconds: 30);
    try {
      bool onboardingDone = false;
      try {
        final prefs = await SharedPreferences.getInstance().timeout(timeoutDuration);
        if (kDebugMode) {
          debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] SharedPreferences loaded in ${sw.elapsedMilliseconds} ms');
        }
        if (_disposed) return;
        onboardingDone = prefs.getBool('onboarding_done') ?? false;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Session] SharedPreferences error type: ${e.runtimeType}');
        }
        onboardingDone = false;
      }

      final authRepo = _ref.read(authRepositoryProvider);
      final currentUser = await authRepo.getCurrentUser().timeout(timeoutDuration);
      if (kDebugMode) {
        debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] Firebase current user fetched in ${sw.elapsedMilliseconds} ms');
      }

      if (_disposed) return;
      await _updateState(currentUser, onboardingDone);
      if (kDebugMode) {
        debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] initial state updated in ${sw.elapsedMilliseconds} ms');
      }

      authRepo.authStateChanges.listen((user) async {
        if (_disposed) return;
        if (kDebugMode) {
          debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] first/subsequent auth-stream event received in ${sw.elapsedMilliseconds} ms');
        }
        await _updateState(user, value.onboardingDone);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] init error type: ${e.runtimeType} at ${sw.elapsedMilliseconds} ms');
      }
      if (_disposed) return;
      if (!Platform.environment.containsKey('FLUTTER_TEST') && (e is TimeoutException || e is SocketException || e.toString().contains('Network') || e.toString().contains('network') || e.toString().contains('Timeout'))) {
        _updateStateWithProfile(null, null, value.onboardingDone);
      } else {
        value = value.copyWith(
          status: AuthSessionStatus.error,
          errorType: e.runtimeType.toString(),
        );
      }
    }
  }

  Future<void> refreshProfile() async {
    if (value.user == null) return;
    try {
      final profileRepo = _ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile(value.user!.uid).timeout(const Duration(seconds: 8));
      if (_disposed) return;
      _updateStateWithProfile(value.user, profile, value.onboardingDone);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Profile] refresh error type: ${e.runtimeType}');
      }
    }
  }

  Future<void> refreshSession() async {
    if (_disposed) return;
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final currentUser = await authRepo.getCurrentUser();
      if (_disposed) return;
      await _updateState(currentUser, value.onboardingDone);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Session] refreshSession error: $e');
      }
    }
  }

  int _updateGeneration = 0;

  Future<void> _updateState(domain.AuthUser? user, bool onboardingDone) async {
    final gen = ++_updateGeneration;
    if (user == null) {
      if (_disposed || gen != _updateGeneration) return;
      _updateStateWithProfile(null, null, onboardingDone);
      return;
    }

    Profile? profile;
    if (user.emailVerified) {
      try {
        final profileRepo = _ref.read(profileRepositoryProvider);
        profile = await profileRepo.getProfile(user.uid).timeout(const Duration(seconds: 8));
      } catch (_) {}
    }

    if (_disposed || gen != _updateGeneration) return;
    _updateStateWithProfile(user, profile, onboardingDone);
  }

  void _updateStateWithProfile(domain.AuthUser? user, Profile? profile, bool onboardingDone) {
    AuthSessionStatus status;
    if (user == null) {
      status = AuthSessionStatus.unauthenticated;
    } else if (!user.emailVerified) {
      status = AuthSessionStatus.unverifiedEmail;
    } else if (profile == null && !user.profileExists) {
      status = AuthSessionStatus.needsProfileSetup;
    } else {
      status = AuthSessionStatus.authenticated;
    }

    if (kDebugMode) {
      debugPrint('[Session] instance: ${identityHashCode(this)} [appSessionProvider] status transition: $status');
    }

    value = value.copyWith(
      status: status,
      user: user,
      profile: profile,
      isFirstLaunch: !onboardingDone,
      onboardingDone: onboardingDone,
      errorType: null,
    );
  }

  Future<void> completeOnboarding() async {
    if (_disposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      await prefs.setBool('onboarding_done', true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Session] completeOnboarding error type: ${e.runtimeType}');
      }
    }
    value = value.copyWith(isFirstLaunch: false, onboardingDone: true);
  }

  void debugSetState({
    AuthSessionStatus? status,
    domain.AuthUser? user,
    Profile? profile,
    bool? isFirstLaunch,
    bool? onboardingDone,
    bool? isSignedIn,
    bool? hasProfile,
    UserRole? role,
  }) {
    if (_disposed) return;
    AuthSessionStatus newStatus = status ?? value.status;
    domain.AuthUser? newUser = user ?? value.user;
    Profile? newProfile = profile ?? value.profile;

    if (status != null) {
      newStatus = status;
    } else if (isSignedIn == false) {
      newStatus = AuthSessionStatus.unauthenticated;
      newUser = null;
      newProfile = null;
    } else if (hasProfile == true && role != null) {
      newStatus = AuthSessionStatus.authenticated;
      newProfile = Profile(
        uid: newUser?.uid ?? 'debug-uid',
        role: role,
        fullName: 'Debug User',
        email: newUser?.email ?? 'debug@linguacare.app',
        emailVerified: true,
        country: 'US',
        language: 'en',
        verified: role == UserRole.specialist ? true : false,
        children: role == UserRole.parent ? [
          Child(
            id: 'c1',
            parentUid: 'debug-uid',
            nickname: 'Sam',
            dob: DateTime.now().subtract(const Duration(days: 2500)),
            band: AgeBand.band5_11,
            homeLanguages: ['English'],
            interests: ['Reading'],
            concerns: [],
          )
        ] : [],
      );
    }

    value = value.copyWith(
      status: newStatus,
      user: newUser,
      profile: newProfile,
      isFirstLaunch: isFirstLaunch,
      onboardingDone: onboardingDone,
    );
  }
}

final appSessionProvider = Provider<AppSessionNotifier>((ref) {
  final notifier = AppSessionNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final appSessionStateProvider = Provider<AppSessionState>((ref) {
  final notifier = ref.watch(appSessionProvider);
  void listener() {
    ref.invalidateSelf();
  }
  notifier.addListener(listener);
  ref.onDispose(() => notifier.removeListener(listener));
  return notifier.value;
});
