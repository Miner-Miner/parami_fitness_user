import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parami_fitness_user/core/api_config.dart';
import 'package:parami_fitness_user/services/connection_settings_store.dart';
import 'package:parami_fitness_user/services/gym_api.dart';

void main() {
  test('remote configuration supplies API URL and database header', () async {
    final store = ConnectionSettingsStore();
    final settings = await store.fetch(
      client: MockClient((request) async {
        expect(request.url.toString(), ApiConfig.configUrl);
        return http.Response(
          jsonEncode({
            'odoo_url': 'https://remote.example/',
            'db_name': 'remote_database',
          }),
          200,
        );
      }),
    );
    final api = GymApi(
      baseUrl: settings.baseUrl,
      database: settings.database,
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://remote.example/gym/api/login');
        expect(request.headers['X-Odoo-Database'], 'remote_database');
        return http.Response(
          jsonEncode({
            'data': {'session_id': 'session', 'user_id': 1},
          }),
          200,
        );
      }),
    );
    await api.login(login: 'member', password: 'password');
  });

  for (final body in [
    'not json',
    '[]',
    '{}',
    '{"odoo_url":"https://example.com"}',
    '{"odoo_url":"invalid","db_name":"db"}',
    '{"odoo_url":42,"db_name":"db"}',
    '{"odoo_url":"https://example.com","db_name":" "}',
  ]) {
    test('rejects invalid configuration: $body', () async {
      await expectLater(
        ConnectionSettingsStore().fetch(
          client: MockClient((_) async => http.Response(body, 200)),
        ),
        throwsFormatException,
      );
    });
  }

  test('rejects unsuccessful config response', () async {
    await expectLater(
      ConnectionSettingsStore().fetch(
        client: MockClient((_) async => http.Response('{}', 503)),
      ),
      throwsFormatException,
    );
  });

  test('propagates network failure for startup retry', () async {
    await expectLater(
      ConnectionSettingsStore().fetch(
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('propagates timeout for startup retry', () async {
    await expectLater(
      ConnectionSettingsStore().fetch(
        client: MockClient((_) async => throw TimeoutException('timeout')),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
