import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gym_models.dart';

class SessionStore {
  static const _sessionKey = 'parami_gym_session';

  Future<AuthSession?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      final session = AuthSession.fromJson(asJsonMap(decoded));
      return session.sessionId.isEmpty || session.userId == 0 ? null : session;
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }
}
