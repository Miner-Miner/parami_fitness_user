import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/screens/classes_screen.dart';
import 'package:parami_fitness_user/services/gym_api.dart';
import 'package:parami_fitness_user/ui/app_theme.dart';

void main() {
  const session = AuthSession(
    sessionId: 'session-123',
    userId: 46,
    name: 'Member',
    login: 'member@example.com',
    userRole: 'customer',
    memberId: 'MEM-00025',
    partnerId: 12,
    isGymAdmin: false,
  );

  testWidgets('Paid classes show only the member enrolled classes', (
    tester,
  ) async {
    final requestedPaths = <String>[];
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        expect(request.headers['cookie'], 'session_id=session-123');

        if (request.url.path == '/gym/api/classes/free') {
          return _success(<Object?>[]);
        }
        if (request.url.path == '/gym/api/classes/enrolled') {
          expect(request.url.queryParameters, <String, String>{
            'user_id': '46',
          });
          return _success(<Object?>[
            <String, dynamic>{
              'id': 9,
              'class_name': 'Enrolled Yoga',
              'template_name': 'Yoga Basics',
              'date_start': '2026-09-01',
              'session_total': 12,
              'sessions_done': 3,
              'sessions_remaining': 9,
              'state': 'active',
              'instructor_name': 'Aye Aye',
              'timetable': <Object?>[
                <String, dynamic>{
                  'date': '2026-09-12',
                  'start_time': 9,
                  'end_time': 10,
                  'instructor_name': 'Aye Aye',
                  'state': 'scheduled',
                },
              ],
            },
          ]);
        }

        fail('Unexpected request: ${request.url}');
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme(),
        home: ClassesScreen(api: api, session: session),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();

    expect(find.text('Enrolled Yoga'), findsOneWidget);
    expect(requestedPaths, contains('/gym/api/classes/enrolled'));
    expect(requestedPaths, isNot(contains('/gym/api/classes/paid')));
  });
}

http.Response _success(Object? data) {
  return http.Response(
    jsonEncode(<String, dynamic>{'status': 'success', 'data': data}),
    200,
  );
}
