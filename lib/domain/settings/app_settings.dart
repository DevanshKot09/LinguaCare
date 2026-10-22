import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  final bool rewardAnimationsEnabled;
  final bool soundEnabled;

  const AppSettingsState({
    required this.rewardAnimationsEnabled,
    required this.soundEnabled,
  });

  AppSettingsState copyWith({
    bool? rewardAnimationsEnabled,
    bool? soundEnabled,
  }) {
    return AppSettingsState(
      rewardAnimationsEnabled: rewardAnimationsEnabled ?? this.rewardAnimationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  static const String _keyReward = 'settings_reward_animations_v1';
  static const String _keySound = 'settings_sound_enabled_v1';

  @override
  AppSettingsState build() {
    _load();
    return const AppSettingsState(rewardAnimationsEnabled: true, soundEnabled: true);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reward = prefs.getBool(_keyReward) ?? true;
      final sound = prefs.getBool(_keySound) ?? true;
      state = AppSettingsState(rewardAnimationsEnabled: reward, soundEnabled: sound);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppSettings] SharedPreferences error type: ${e.runtimeType}');
      }
    }
  }

  Future<void> toggleRewardAnimations(bool enabled) async {
    state = state.copyWith(rewardAnimationsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReward, enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppSettings] toggleRewardAnimations error type: ${e.runtimeType}');
      }
    }
  }

  Future<void> toggleSound(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppSettings] toggleSound error type: ${e.runtimeType}');
      }
    }
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettingsState>(() {
  return AppSettingsNotifier();
});
