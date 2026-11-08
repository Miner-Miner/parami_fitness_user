import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

import '../models/connection_settings.dart';

class ConnectionSettingsStore {
  static const _settingsKey = 'parami_gym_connection_settings';

  Future<ConnectionSettings> fetch({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(
            Uri.parse(ApiConfig.configUrl),
            headers: {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw const FormatException('Unable to load connection configuration.');
      }
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid connection configuration.');
      }
      return ConnectionSettings.fromJson({
        'base_url': json['odoo_url'],
        'database': json['db_name'],
      });
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<ConnectionSettings?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSettings = preferences.getString(_settingsKey);
    if (rawSettings == null || rawSettings.isEmpty) {
      return null;
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
    return null;
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
