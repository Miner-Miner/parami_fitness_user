import 'dart:convert';

import '../core/api_config.dart';

class ConnectionSettings {
  const ConnectionSettings({required this.baseUrl, required this.database});

  factory ConnectionSettings.fromJson(Map<String, dynamic> json) {
    final baseUrl = json['base_url'];
    final database = json['database'];
    final uri = baseUrl is String ? Uri.tryParse(baseUrl.trim()) : null;
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        database is! String ||
        database.trim().isEmpty) {
      throw const FormatException('Invalid connection configuration.');
    }
    return ConnectionSettings(
      baseUrl: ApiConfig.normalizeBaseUrl(baseUrl.toString().trim()),
      database: database.trim(),
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
