import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

class StorageService {
  static const _prefsKey = 'user_preferences_v1';
  static const _progressKey = 'reading_progress_v1';

  Future<UserPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return UserPreferences.defaults();
    }
    try {
      return UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserPreferences.defaults();
    }
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(preferences.toJson());
    await prefs.setString(_prefsKey, raw);
  }

  Future<Map<String, ReadingProgress>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, ReadingProgress>{};
      decoded.forEach((key, value) {
        map[key] = ReadingProgress.fromJson(value as Map<String, dynamic>);
      });
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveProgress(Map<String, ReadingProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    progress.forEach((key, value) {
      encoded[key] = value.toJson();
    });
    await prefs.setString(_progressKey, jsonEncode(encoded));
  }
}
