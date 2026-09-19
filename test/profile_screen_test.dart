import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/screens/profile_screen.dart';
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

  testWidgets('a successful password change logs the member out', (
    tester,
  ) async {
    var loggedOut = false;
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/gym/api/profile':
            return _success(<String, dynamic>{
              'user_id': 46,
              'name': 'Member',
              'login': 'member@example.com',
              'email': 'member@example.com',
              'phone': '',
              'street': '',
              'city': '',
              'member_id': 'MEM-00025',
              'user_role': 'customer',
            });
          case '/gym/api/loyalty/points':
            return _success(<String, dynamic>{
              'program_id': 8,
              'program_name': 'Gym Rewards',
              'points': 42.5,
              'code': 'CARD-123',
            });
          case '/gym/api/user/change_password':
            return _success(<String, dynamic>{'user_id': 46});
        }
        fail('Unexpected request: ${request.url}');
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme(),
        home: ProfileScreen(
          api: api,
          session: session,
          onLogout: () async {
            loggedOut = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loyalty points'), findsOneWidget);
    expect(find.text('42.5 pts · Gym Rewards'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Change password'), 200);
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'current-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'new-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(loggedOut, isTrue);
    expect(
      find.text('Password changed. Sign in with your new password.'),
      findsOneWidget,
    );
  });
}

http.Response _success(Object? data) {
  return http.Response(
    jsonEncode(<String, dynamic>{'status': 'success', 'data': data}),
    200,
  );
}
