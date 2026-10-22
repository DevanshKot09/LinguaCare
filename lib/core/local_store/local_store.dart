import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  final String userId;
  static final Map<String, Map<String, String>> _inMemoryFallback = {};
  static bool _fallbackActive = false;

  LocalStore(this.userId);

  bool get isStorageUnavailable => _fallbackActive;

  static void resetFallbackForTesting() {
    _fallbackActive = false;
    _inMemoryFallback.clear();
  }

  Future<Map<String, dynamic>> readJson(
    String key,
    Map<String, dynamic> defaultValue, {
    int schemaVersion = 1,
    Map<String, dynamic> Function(Map<String, dynamic> data, int storedVersion)? migrate,
  }) async {
    try {
      String? rawJson;
      final fullKey = 'linguacare_${userId}_$key';
      if (!_fallbackActive) {
        try {
          final prefs = await SharedPreferences.getInstance();
          rawJson = prefs.getString(fullKey);
        } catch (e) {
          _fallbackActive = true;
          if (kDebugMode) {
            debugPrint('[LocalStore] SharedPreferences error, falling back to in-memory: $e');
          }
        }
      }
      if (_fallbackActive) {
        rawJson = _inMemoryFallback[userId]?[key];
      }

      if (rawJson == null) return defaultValue;

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return defaultValue;

      final storedVersion = decoded['schemaVersion'] is int ? decoded['schemaVersion'] as int : 1;
      var data = decoded['data'];
      if (data is! Map<String, dynamic>) return defaultValue;

      if (storedVersion < schemaVersion && migrate != null) {
        data = migrate(data, storedVersion);
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalStore] readJson error (returning default): $e');
      }
      return defaultValue;
    }
  }

  Future<List<dynamic>> readList(
    String key,
    List<dynamic> defaultValue, {
    int schemaVersion = 1,
    List<dynamic> Function(List<dynamic> data, int storedVersion)? migrateList,
  }) async {
    try {
      String? rawJson;
      final fullKey = 'linguacare_${userId}_$key';
      if (!_fallbackActive) {
        try {
          final prefs = await SharedPreferences.getInstance();
          rawJson = prefs.getString(fullKey);
        } catch (e) {
          _fallbackActive = true;
        }
      }
      if (_fallbackActive) {
        rawJson = _inMemoryFallback[userId]?[key];
      }

      if (rawJson == null) return defaultValue;

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return defaultValue;

      final storedVersion = decoded['schemaVersion'] is int ? decoded['schemaVersion'] as int : 1;
      var data = decoded['data'];
      if (data is! List) return defaultValue;

      if (storedVersion < schemaVersion && migrateList != null) {
        data = migrateList(data, storedVersion);
      }

      return data;
    } catch (e) {
      return defaultValue;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> data, {int schemaVersion = 1}) async {
    try {
      final wrapper = {
        'schemaVersion': schemaVersion,
        'data': data,
      };
      final rawJson = jsonEncode(wrapper);
      final fullKey = 'linguacare_${userId}_$key';

      bool saved = false;
      if (!_fallbackActive) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(fullKey, rawJson);
          saved = true;
        } catch (e) {
          _fallbackActive = true;
          if (kDebugMode) {
            debugPrint('[LocalStore] writeJson error, falling back to in-memory: $e');
          }
        }
      }
      if (_fallbackActive || !saved) {
        _inMemoryFallback.putIfAbsent(userId, () => {})[key] = rawJson;
      }
    } catch (e) {
      // Never throw
    }
  }

  Future<void> writeList(String key, List<dynamic> listData, {int schemaVersion = 1}) async {
    try {
      final wrapper = {
        'schemaVersion': schemaVersion,
        'data': listData,
      };
      final rawJson = jsonEncode(wrapper);
      final fullKey = 'linguacare_${userId}_$key';

      bool saved = false;
      if (!_fallbackActive) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(fullKey, rawJson);
          saved = true;
        } catch (e) {
          _fallbackActive = true;
        }
      }
      if (_fallbackActive || !saved) {
        _inMemoryFallback.putIfAbsent(userId, () => {})[key] = rawJson;
      }
    } catch (e) {
      // Never throw
    }
  }

  Future<void> clearAllForUser() async {
    try {
      if (!_fallbackActive) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final keys = prefs.getKeys();
          final prefix = 'linguacare_${userId}_';
          for (final k in keys) {
            if (k.startsWith(prefix)) {
              await prefs.remove(k);
            }
          }
        } catch (e) {
          _fallbackActive = true;
        }
      }
      _inMemoryFallback.remove(userId);
    } catch (e) {
      // Never throw
    }
  }
}
