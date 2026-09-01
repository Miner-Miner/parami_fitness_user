import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection_settings.dart';

class ConnectionSettingsStore {
  static const _settingsKey = 'parami_gym_connection_settings';

  Future<ConnectionSettings> read() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSettings = preferences.getString(_settingsKey);
    if (rawSettings == null || rawSettings.isEmpty) {
      return ConnectionSettings.defaults();
    }

    try {
      final decoded = jsonDecode(rawSettings);
      if (decoded is Map<String, dynamic>) {
        return ConnectionSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return ConnectionSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      await clear();
    }
    return ConnectionSettings.defaults();
  }

  Future<void> save(ConnectionSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, settings.toStorageJson());
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_settingsKey);
  }
}
