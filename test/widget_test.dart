import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parami_fitness_user/models/connection_settings.dart';
import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/screens/login_screen.dart';
import 'package:parami_fitness_user/screens/splash_screen.dart';
import 'package:parami_fitness_user/services/gym_api.dart';
import 'package:parami_fitness_user/ui/app_theme.dart';
import 'package:parami_fitness_user/ui/formatters.dart';
import 'package:parami_fitness_user/ui/ui_parts.dart';

void main() {
  test('session QR payload is stable', () {
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

    expect(session.qrPayload, '{"member_id":"MEM-00025","user_id":46}');
  });

  test('formatMoney inserts separators', () {
    expect(formatMoney(1234567), 'MMK 1,234,567');
  });

  testWidgets('entry screens show the bundled Parami Fitness logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: gymTheme(), home: const SplashScreen()),
    );
    expect(find.byType(ParamiLogo), findsOneWidget);
    expect(_logoAsset(tester), ParamiLogo.assetPath);

    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme(),
        home: LoginScreen(
          api: GymApi(),
          connectionSettings: ConnectionSettings.defaults(),
          onConnectionSettingsChanged: (_) async {},
          onLoggedIn: (_) {},
        ),
      ),
    );
    expect(find.byType(ParamiLogo), findsOneWidget);
    expect(_logoAsset(tester), ParamiLogo.assetPath);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connection settings dialog fits a short viewport', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 700));

    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme(),
        home: LoginScreen(
          api: GymApi(),
          connectionSettings: ConnectionSettings.defaults(),
          onConnectionSettingsChanged: (_) async {},
          onLoggedIn: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Connection settings'));
    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(const Size(390, 300));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'connection settings dialog keeps controllers alive while closing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme(),
          home: LoginScreen(
            api: GymApi(),
            connectionSettings: ConnectionSettings.defaults(),
            onConnectionSettingsChanged: (_) async {},
            onLoggedIn: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Connection settings'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      final baseUrlField = find
          .descendant(of: dialog, matching: find.byType(TextFormField))
          .first;
      await tester.tap(baseUrlField);
      await tester.enterText(baseUrlField, 'https://example.com');
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Cancel')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

String _logoAsset(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.descendant(of: find.byType(ParamiLogo), matching: find.byType(Image)),
  );
  return (image.image as AssetImage).assetName;
}
