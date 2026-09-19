import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/screens/change_password_screen.dart';
import 'package:parami_fitness_user/services/gym_api.dart';
import 'package:parami_fitness_user/ui/app_theme.dart';

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

void main() {
  testWidgets('password form requires matching new passwords', (tester) async {
    var requestCount = 0;
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient((_) async {
        requestCount += 1;
        return _success(<String, dynamic>{'user_id': 46});
      }),
    );

    await tester.pumpWidget(_app(api));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'current-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'different-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pump();

    expect(find.text('The new passwords do not match'), findsOneWidget);
    expect(requestCount, 0);
  });

  testWidgets('password form rejects surrounding whitespace', (tester) async {
    var requestCount = 0;
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient((_) async {
        requestCount += 1;
        return _success(<String, dynamic>{'user_id': 46});
      }),
    );

    await tester.pumpWidget(_app(api));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'current-password');
    await tester.enterText(fields.at(1), ' new-password ');
    await tester.enterText(fields.at(2), ' new-password ');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pump();

    expect(
      find.text('New password cannot start or end with spaces'),
      findsOneWidget,
    );
    expect(requestCount, 0);
  });

  testWidgets('password form shows the API error without leaving the screen', (
    tester,
  ) async {
    final api = GymApi(
      baseUrl: 'https://gym.example',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'error',
            'error': 'Current password is incorrect',
          }),
          401,
        ),
      ),
    );

    await tester.pumpWidget(_app(api));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'wrong-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'new-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(find.text('Current password is incorrect'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });
}

Widget _app(GymApi api) {
  return MaterialApp(
    theme: gymTheme(),
    home: ChangePasswordScreen(api: api, session: session),
  );
}

http.Response _success(Object? data) {
  return http.Response(
    jsonEncode(<String, dynamic>{'status': 'success', 'data': data}),
    200,
  );
}
