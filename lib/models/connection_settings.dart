import 'dart:convert';

import '../core/api_config.dart';

class ConnectionSettings {
  const ConnectionSettings({required this.baseUrl, required this.database});

  factory ConnectionSettings.defaults() {
    return const ConnectionSettings(
      baseUrl: ApiConfig.defaultBaseUrl,
      database: ApiConfig.defaultDatabase,
    );
  }

  factory ConnectionSettings.fromJson(Map<String, dynamic> json) {
    return ConnectionSettings(
      baseUrl: (json['base_url'] as String?)?.trim().isNotEmpty == true
          ? (json['base_url'] as String).trim()
          : ApiConfig.defaultBaseUrl,
      database: (json['database'] as String?)?.trim().isNotEmpty == true
          ? (json['database'] as String).trim()
          : ApiConfig.defaultDatabase,
    );
  }

  final String baseUrl;
  final String database;

  String get normalizedBaseUrl => ApiConfig.normalizeBaseUrl(baseUrl);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'base_url': baseUrl,
    'database': database,
  };

  String toStorageJson() => jsonEncode(toJson());
}
